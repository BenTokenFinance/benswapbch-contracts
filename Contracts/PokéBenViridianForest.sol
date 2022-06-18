// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPokeBen {
    function update(uint256 tokenId, uint256 level, uint256 basePower, uint256 power) external;
    function ownerOf(uint256 tokenId) external view returns(address);
    function getPokeBenInfo(uint256 tokenId) external view returns(uint256,uint256,uint256,uint256,uint256);
}

interface IPokeBenKindRaritySetting {
    function getRarity(uint256 kindId) view external returns (uint256);
}

interface IPokeBenItem {
    function safeMint(address to, uint256 _source, uint256 _kind, string memory _data) external returns(uint256);
}

interface IPokeBenPowerExtension {
    function getPower(uint256 tokenId, uint256 basePower) external view returns(uint256);
}

interface VrfGovIfc {
    function verify(
        uint256 blockHash,
        uint256 rdm,
        bytes calldata pi
    ) external view returns (bool);
}

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

contract PokeBenViridianForest is Ownable {
    using SafeERC20 for IERC20;

    IPokeBen public pokeben;
    IPokeBenKindRaritySetting public pokebenKindRaritySetting;
    IPokeBenItem public pokebenitem;
    IPokeBenPowerExtension public pokebenpower;

    uint256 private constant SCALE = 1e18;
    address private constant VrfgovAddress = 0x18C51aa3d1F018814716eC2c7C41A20d4FAf023C;
    address private constant BenTokenAddress = 0x8eE4924BD493109337D839C23f628e75Ef5f1C4D;
    address private constant GoldenBenAddress = 0x8173dDa13Fd405e5BcA84Bd7F64e58cAF4810A32;
    address private constant ShibaInuAddress = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    address private constant UniswapAddress = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    IERC20 public feeToken;
    address public feeTo;
    uint256 public baseFee;

    struct AdventureInfo { 
        uint256 tokenId;
        uint256 cost;
        uint256 startBlock;
        uint256 treasure;
    }

    mapping(address => AdventureInfo) public getAdventureInfo;

    uint256[] public drops = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17];

    uint256 public treasureChanceTotal = 20000;
    uint256 public lootChanceTotal = 200000;
    function getLevelUpChanceTotal(uint256 tokenId) external view returns(uint256) {
        (,uint256 kindId,,,) = pokeben.getPokeBenInfo(tokenId);
        uint256 rarity = pokebenKindRaritySetting.getRarity(kindId);
        return 2 * (10**rarity);
    }

    event AdventureStart(address indexed user, uint256 tokenId, uint256 cost);
    event TreasureFound(address indexed user, uint256 treasure);
    event LevelUp(address indexed user, uint256 tokenId, uint256 newLevel, uint256 oldBasePower, uint256 oldPower, uint256 basePower, uint256 power);
    event Loot(address indexed user, uint256 itemId);

    function getTreasureAmount() public view returns(uint256) {
        return feeToken.balanceOf(address(this));
    }

    function setPokeBen(address _pokeben) external onlyOwner {
        pokeben = IPokeBen(_pokeben);
    }

    function setPokeBenKindRaritySetting(address _pokebenKindRaritySetting) external onlyOwner {
        pokebenKindRaritySetting = IPokeBenKindRaritySetting(_pokebenKindRaritySetting);
    }

    function setPokeBenItem(address _pokebenitem) external onlyOwner {
        pokebenitem = IPokeBenItem(_pokebenitem);
    }

    function setPokeBenPowerExtension(address _pokebenpower) external onlyOwner {
        pokebenpower = IPokeBenPowerExtension(_pokebenpower);
    }

    function setBaseFee(uint256 _baseFee) external onlyOwner {
        baseFee = _baseFee;
    }

    function setFeeToken(address _feeToken) external onlyOwner {
        feeToken = IERC20(_feeToken);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }
    
    function startAdventure(uint256 pokeBenId, uint256 _cost) external {
        require(pokeben.ownerOf(pokeBenId)==msg.sender, "You are not the owner of that pokeben!");
        require(baseFee > 0, "basefee is not set!");
        require(_cost >= baseFee, "cost is too low!");

        feeToken.safeTransferFrom(address(msg.sender), address(this), _cost);
        feeToken.safeTransfer(feeTo, _cost / 2);
        getAdventureInfo[msg.sender] = AdventureInfo({ tokenId: pokeBenId, cost: _cost, startBlock: block.number, treasure: getTreasureAmount() });
        
        emit AdventureStart(msg.sender, pokeBenId, _cost);
    }

    function processAdventure(uint256 rdm, bytes calldata pi) external {
        AdventureInfo memory adventure = getAdventureInfo[msg.sender];
        require(pokeben.ownerOf(adventure.tokenId)==msg.sender, "You are not the owner of that pokeben!");
        bytes32 hash = blockhash(adventure.startBlock);
        require (uint256(hash) > 0, "Invalid block hash!");

        require(VrfGovIfc(VrfgovAddress).verify(uint256(hash), rdm, pi), "Invalid vrf!");
        delete getAdventureInfo[msg.sender];

        uint256 totalChance;
        uint256 chance;

        uint256 rand = uint256( keccak256(abi.encodePacked(rdm, adventure.startBlock, msg.sender, BenTokenAddress)) );
        (totalChance, , chance) = getTreasureChance(adventure.cost);
        rand = rand % totalChance;
        if (rand < chance) {    // Treasure
            uint256 balance = getTreasureAmount();
            if (balance >= adventure.treasure) {
                feeToken.safeTransfer(msg.sender, adventure.treasure);
                emit TreasureFound(msg.sender, adventure.treasure);
            }
        }

        (,uint256 kindId,uint256 level,uint256 basePower,uint256 power) = pokeben.getPokeBenInfo(adventure.tokenId);
        uint256 rarity = pokebenKindRaritySetting.getRarity(kindId);

        rand = uint256( keccak256(abi.encodePacked(rdm, adventure.startBlock, msg.sender, GoldenBenAddress)) );
        (totalChance, , chance) = getLevelUpChance(rarity, adventure.cost);
        rand = rand % totalChance;
        if (rand < chance) {   // Level up
            rand = uint256( keccak256(abi.encodePacked(rdm, adventure.startBlock, msg.sender, address(this))) );
            level++;
            uint256 newBasePower = basePower + getRandomPowerBoostByRarity(rand, rarity);
            uint256 newPower = pokebenpower.getPower(adventure.tokenId, newBasePower);
            pokeben.update(adventure.tokenId, level, newBasePower, newPower);
            emit LevelUp(msg.sender, adventure.tokenId, level, basePower, power, newBasePower, newPower);
        }

        rand = uint256( keccak256(abi.encodePacked(rdm, adventure.startBlock, msg.sender, ShibaInuAddress)) );
        (totalChance, , chance) = getLootChance(power, adventure.cost);
        rand = rand % totalChance;
        if (rand < chance) {  // Loot
            rand = uint256( keccak256(abi.encodePacked(rdm, adventure.startBlock, msg.sender, UniswapAddress)) );
            mintPokebenItem(rand, msg.sender);
        }
    }

    function getTreasureChance(uint256 cost) public view returns(uint256 totalChance, uint256 maxChance, uint256 chance) {
        totalChance = treasureChanceTotal * SCALE;
        maxChance = totalChance / 2;
        chance = cost > maxChance ? maxChance : cost;
    }

    function getLevelUpChance(uint256 rarity, uint256 cost) public pure returns(uint256 totalChance, uint256 maxChance, uint256 chance) {
        totalChance = 2 * (10**rarity) * SCALE;
        maxChance = totalChance / 2;
        chance = cost > maxChance ? maxChance : cost;
    }

    function getLootChance(uint256 power, uint256 cost) public view returns(uint256 totalChance, uint256 maxChance, uint256 chance) {
        totalChance = lootChanceTotal * SCALE;
        maxChance = totalChance / 10;
        chance = cost * Babylonian.sqrt(power*SCALE*SCALE) / SCALE;
        chance = chance > maxChance ? maxChance : chance;
    }

    function getRandomPowerBoostByRarity(uint256 rand, uint256 rarity) private pure returns (uint256) {
        uint256 s = 10**rarity;
        return 8 * s + rand % (4 * s);
    }

    function mintPokebenItem(uint256 rand, address to) private {
        uint256 index = rand % (drops.length);
        uint256 lootId = pokebenitem.safeMint(to, 0, drops[index], "");

        emit Loot(to, lootId);
    }
}
