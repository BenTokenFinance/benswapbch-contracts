// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IPokeBen {
    function safeMint(address to, uint256 _source, uint256 _kind, uint256 _level, uint256 _basePower) external returns(uint256);
}

interface IPokeBenKindRaritySetting {
    function getKindByRarityAndIndex(uint256 rarity, uint256 index) view external returns (uint256);
    function getLengthByRarity(uint256 rarity) view external returns (uint256);
}

interface VrfGovIfc {
    function verify(
        uint256 blockHash,
        uint256 rdm,
        bytes calldata pi
    ) external view returns (bool);
}

contract PokeBenHuntV1 is Ownable {
    using SafeERC20 for IERC20;

    IPokeBen public pokeben;
    IPokeBenKindRaritySetting public pokebenKindRaritySetting;

    uint256 private constant SCALE = 1e18;
    address private constant VrfgovAddress = 0x18C51aa3d1F018814716eC2c7C41A20d4FAf023C;
    address private constant VitalikButerinAddress = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;

    IERC20 public feeToken;
    address public feeTo;
    uint256 public fee;
    mapping(address => uint256) public getHuntStartBlock;

    uint256 public chanceTotal = 10000;
    uint256 public chanceVeryCommon = 4000;
    uint256 public chanceCommon = 1000;
    uint256 public chanceUncommon = 100;
    uint256 public chanceRare = 10;
    uint256 public chanceEpic = 1; 

    event HuntStart(address indexed user);
    event Catch(address indexed user, uint256 tokenId);

    function setPokeBen(address _pokeben) external onlyOwner {
        pokeben = IPokeBen(_pokeben);
    }

    function setPokeBenKindRaritySetting(address _pokebenKindRaritySetting) external onlyOwner {
        pokebenKindRaritySetting = IPokeBenKindRaritySetting(_pokebenKindRaritySetting);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setFeeToken(address _feeToken) external onlyOwner {
        feeToken = IERC20(_feeToken);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }
    
    function hunt() external {
        feeToken.safeTransferFrom(address(msg.sender), feeTo, fee);
        getHuntStartBlock[msg.sender] = block.number;
        
        emit HuntStart(msg.sender);
    }

    function catchPokeBen(uint256 rdm, bytes calldata pi) external returns(uint256) {
        uint256 height = getHuntStartBlock[msg.sender];
        bytes32 hash = blockhash(height);
        require (uint256(hash) > 0, "Invalid block hash!");

        bool ok = VrfGovIfc(VrfgovAddress).verify(uint256(hash), rdm, pi);
        require(ok, "Invalid vrf!");
        delete getHuntStartBlock[msg.sender];

        uint256 rand1 = uint256( keccak256(abi.encodePacked(rdm, height, msg.sender)) );
        uint256 rand2 = uint256( keccak256(abi.encodePacked(rdm, height, msg.sender, VitalikButerinAddress)) );
        uint256 rand3 = uint256( keccak256(abi.encodePacked(rdm, height, msg.sender, address(pokeben))) );

        rand1 = rand1 % (chanceTotal * SCALE);
        uint256 runningChance = chanceVeryCommon * SCALE;
        if (rand1 < runningChance) {    // Very Common
            uint256 kind = getRandomKindByRarity(rand2, 0);
            return mintPokeBenByRarityAndKind(rand3, msg.sender, 0, kind);
        }
        runningChance += chanceCommon * SCALE;
        if (rand1 < runningChance) {    // Common
            uint256 kind = getRandomKindByRarity(rand2, 1);
            return mintPokeBenByRarityAndKind(rand3, msg.sender, 1, kind);
        }
        runningChance += chanceUncommon * SCALE;
        if (rand1 < runningChance) {    // Uncommon
            uint256 kind = getRandomKindByRarity(rand2, 2);
            return mintPokeBenByRarityAndKind(rand3, msg.sender, 2, kind);
        }
        runningChance += chanceRare * SCALE;
        if (rand1 < runningChance) {    // Rare
            uint256 kind = getRandomKindByRarity(rand2, 3);
            return mintPokeBenByRarityAndKind(rand3, msg.sender, 3, kind);
        }
        runningChance += chanceEpic * SCALE;
        if (rand1 < runningChance) {    // Epic
            uint256 kind = getRandomKindByRarity(rand2, 4);
            return mintPokeBenByRarityAndKind(rand3, msg.sender, 4, kind);
        }

        return 0;
    }

    function getRandomKindByRarity(uint256 rand, uint256 rarity) private view returns (uint256) {
        uint256 length = pokebenKindRaritySetting.getLengthByRarity(rarity);
        uint256 index = rand % length;
        return pokebenKindRaritySetting.getKindByRarityAndIndex(rarity, index);
    }

    function mintPokeBenByRarityAndKind(uint256 rand, address to, uint256 rarity, uint256 kind) private returns (uint256) {
        uint256 s = 10**rarity;
        uint256 power = 80 * s + rand % (40 * s);
        uint256 tokenId = pokeben.safeMint(to, 0, kind, 1, power);

        emit Catch(to, tokenId);
        return tokenId;
    }
}
