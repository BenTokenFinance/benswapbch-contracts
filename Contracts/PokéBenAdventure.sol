// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

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

interface IPokeBenCrystal {
    function mint(uint256 amount) external returns(bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
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

contract PokeBenAdventure is ERC721Holder, Ownable {
    using SafeERC20 for IERC20;

    bool private initialized = false;
    function initialize(address newOwner) external {
        require(newOwner != address(0) && !initialized);
        _transferOwnership(newOwner);
        initialized = true;

        pokeben = IPokeBen(0xFDEd6cD4B88a24e00d9Ea242338367fe734CBff5);
        pokebenKindRaritySetting = IPokeBenKindRaritySetting(0xf8f7e6632A223E674631825b4D23E67224307665);
        pokebenitem = IPokeBenItem(0x335bF14Af7c6b2993434bB700AF0f1Afcf27d782);
        pokebenpower = IPokeBenPowerExtension(0xa02Bd13da796DcCABf18ae513DDB327Fa5cB3672);
        pbc = IPokeBenCrystal(0x7fa2DC7F8671544E301085CB76FfDA19c78AcD75);

        feeToken = IERC20(0x77CB87b57F54667978Eb1B199b28a0db8C8E1c0B);
        feeTo = 0x71D9C349e35f73B782022d912B5dADa4235fDa06;

        baseFee = 1e18 * 2;
        treasureChanceTotal = 20000;
        bossCaptureChanceTotal = 15000;
    }

    function version() external pure returns(uint256){
        return 1;
    }

    IPokeBen public pokeben;
    IPokeBenKindRaritySetting public pokebenKindRaritySetting;
    IPokeBenItem public pokebenitem;
    IPokeBenPowerExtension public pokebenpower;
    IPokeBenCrystal public pbc;

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

    function setPokeBenCrystal(address _pokebencrystal) external onlyOwner {
        pbc = IPokeBenCrystal(_pokebencrystal);
    }

    IERC20 public feeToken;
    address public feeTo;

    function setFeeToken(address _feeToken) external onlyOwner {
        feeToken = IERC20(_feeToken);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    uint256 public baseFee;

    function setBaseFee(uint256 _baseFee) external onlyOwner {
        baseFee = _baseFee;
    }

    uint256 private constant SCALE = 1e18;
    address private constant VrfgovAddress = 0x18C51aa3d1F018814716eC2c7C41A20d4FAf023C;
    address private constant BenTokenAddress = 0x8eE4924BD493109337D839C23f628e75Ef5f1C4D;
    address private constant GoldenBenAddress = 0x8173dDa13Fd405e5BcA84Bd7F64e58cAF4810A32;
    address private constant ShibaInuAddress = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    address private constant UniswapAddress = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address private constant PepeAddress = 0x6982508145454Ce325dDbE47a25d4ec3d2311933;
    address private constant FlokiAddress = 0xcf0C122c6b73ff809C693DB761e7BaeBe62b6a2E;
    address private constant CurveAddress = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    mapping(address => bool) public bossSupported;

    function setBossSupported(address erc721Address, bool supported) external onlyOwner {
        bossSupported[erc721Address] = supported;
    }

    function addSupportedBosses(address[] calldata addresses) external onlyOwner {
        for (uint i=0; i<addresses.length; i++) {
            bossSupported[addresses[i]] = true;
        }
    }

    struct BossInfo { 
        address token;
        uint256 tokenId;
        string message;
    }

    BossInfo public boss;

    event BossAssigned(address indexed user, BossInfo boss);

    function sendBoss(address token, uint256 tokenId, string calldata message) external {
        require(boss.token==address(0), "Occupied!");
        require(bossSupported[token], "Not supported!");
        IERC721 bossContract = IERC721(token);
        require(bossContract.ownerOf(tokenId)==msg.sender, "Not Owner!");

        bossContract.safeTransferFrom(msg.sender, address(this), tokenId);

        boss = BossInfo({token:token, tokenId:tokenId, message: message});
        emit BossAssigned(msg.sender, boss);
    }

    event BossCaptured(address indexed user, BossInfo boss);

    function captureBoss(address user, bool isAdmin) private {
        if (boss.token!=address(0)) {
            IERC721 bossContract = IERC721(boss.token);
            if (bossContract.ownerOf(boss.tokenId)==address(this)) {
                bossContract.safeTransferFrom(address(this), user, boss.tokenId);
                if (!isAdmin) emit BossCaptured(user, boss);
                boss = BossInfo({token:address(0), tokenId:0, message: ""});
            }
        }
    }

    function rescueBoss() external onlyOwner {
        captureBoss(msg.sender, true);
    }

    function resetBoss() external onlyOwner {
        boss = BossInfo({token:address(0), tokenId:0, message: ""});
    } 

    uint256[] public drops;
    uint256 public dropRarity;
    function setDrops(uint256 rarity, uint256[] calldata kinds) external onlyOwner {
        require(rarity <=5, "Invalid rarity!");
        require(kinds.length>0, "Invalid kinds!");
        dropRarity = rarity;
        drops = kinds;
    }
    function getDrops() external view returns(uint256[] memory) {
        return drops;
    }

    function getLevelUpChanceTotal(uint256 tokenId) external view returns(uint256) {
        (,uint256 kindId,,,) = pokeben.getPokeBenInfo(tokenId);
        uint256 rarity = pokebenKindRaritySetting.getRarity(kindId);
        return 4 * (10**rarity);
    }

    function getLevelUpChance(uint256 rarity, uint256 cost) public pure returns(uint256 totalChance, uint256 maxChance, uint256 chance) {
        totalChance = 4 * (10**rarity) * SCALE;
        maxChance = totalChance / 2;
        chance = cost > maxChance ? maxChance : cost;
    }

    uint256 public treasureChanceTotal;
    function setTreasureChanceTotal(uint256 v) external onlyOwner {
        treasureChanceTotal = v;
    }
    function getTreasureChance(uint256 cost) public view returns(uint256 totalChance, uint256 maxChance, uint256 chance) {
        totalChance = treasureChanceTotal * SCALE;
        maxChance = totalChance / 2;
        chance = cost > maxChance ? maxChance : cost;
    }

    function getRandomPbcDrop(uint256 rand, uint256 cost) public pure returns(uint256) {
        return rand % (cost * 500);
    }

    function getScaledTesseractRoot(uint256 power) public pure returns (uint256) {
        return Babylonian.sqrt(Babylonian.sqrt(power*SCALE*SCALE)*SCALE);
    }

    function getLootChanceTotal() public view returns(uint256) {
        return 28 * (10**(dropRarity+1));
    }

    function getLootChance(uint256 power, uint256 cost) external view returns(uint256 totalChance, uint256 maxChance, uint256 chance) {
        totalChance = getLootChanceTotal() * SCALE;
        maxChance = totalChance / 2;
        chance = cost * getScaledTesseractRoot(power) / SCALE;
        chance = chance > maxChance ? maxChance : chance;
    }

    uint256 public bossCaptureChanceTotal;
    function setBossCaptureChanceTotal(uint256 v) external onlyOwner {
        bossCaptureChanceTotal = v;
    }
    function getBossCaptureChance(uint256 power, uint256 cost) public view returns(uint256 totalChance, uint256 maxChance, uint256 chance) {
        totalChance = bossCaptureChanceTotal * SCALE;
        maxChance = totalChance / 10;
        chance = cost * getScaledTesseractRoot(power) / SCALE;
        chance = chance > maxChance ? maxChance : chance;
    }

    function getTreasureAmount() public view returns(uint256) {
        return feeToken.balanceOf(address(this));
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

    struct AdventureInfo { 
        uint256 tokenId;
        uint256 cost;
        uint256 startBlock;
        uint256 treasure;
    }

    mapping(address => AdventureInfo) public getAdventureInfo;

    event AdventureStart(address indexed user, uint256 tokenId, uint256 cost);
    event TreasureFound(address indexed user, uint256 treasure);
    event LevelUp(address indexed user, uint256 tokenId, uint256 newLevel, uint256 oldBasePower, uint256 oldPower, uint256 basePower, uint256 power);
    event Loot(address indexed user, uint256 itemId);
    event PBCRewarded(address indexed user, uint256 amount);

    function startAdventure(uint256 pokeBenId, uint256 _cost) external {
        require(pokeben.ownerOf(pokeBenId)==msg.sender, "You are not the owner of that pokeben!");
        require(baseFee > 0, "basefee is not set!");
        require(_cost >= baseFee, "cost is too low!");

        feeToken.safeTransferFrom(address(msg.sender), address(this), _cost);
        feeToken.safeTransfer(feeTo, _cost * 3 / 4);
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

        uint256 rand = uint256( keccak256(abi.encodePacked(rdm, address(this), adventure.startBlock, msg.sender, BenTokenAddress)) );
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

        rand = uint256( keccak256(abi.encodePacked(rdm, address(this), adventure.startBlock, msg.sender, GoldenBenAddress)) );
        (totalChance, , chance) = getLevelUpChance(rarity, adventure.cost);
        rand = rand % totalChance;
        if (rand < chance) {   // Level up
            rand = uint256( keccak256(abi.encodePacked(rdm, address(this), adventure.startBlock, msg.sender, PepeAddress)) );
            level++;
            uint256 newBasePower = basePower + getRandomPowerBoostByRarity(rand, rarity);
            uint256 newPower = pokebenpower.getPower(adventure.tokenId, newBasePower);
            pokeben.update(adventure.tokenId, level, newBasePower, newPower);
            emit LevelUp(msg.sender, adventure.tokenId, level, basePower, power, newBasePower, newPower);
        }

        rand = uint256( keccak256(abi.encodePacked(rdm, address(this), adventure.startBlock, msg.sender, ShibaInuAddress)) );
        uint256 scaledTesseractRootOfPower = getScaledTesseractRoot(power);
        totalChance = getLootChanceTotal() * SCALE;
        chance = adventure.cost * scaledTesseractRootOfPower / SCALE;
        chance = chance > (totalChance / 2) ? (totalChance / 2) : chance;
        rand = rand % totalChance;
        if (rand < chance) {  // Item Loot
            rand = uint256( keccak256(abi.encodePacked(rdm, address(this), adventure.startBlock, msg.sender, UniswapAddress)) );
            mintPokebenItem(rand, msg.sender);
        }

        rand = uint256( keccak256(abi.encodePacked(rdm, address(this), adventure.startBlock, msg.sender, FlokiAddress)) );
        totalChance = bossCaptureChanceTotal * SCALE;
        chance = adventure.cost * scaledTesseractRootOfPower / SCALE;
        chance = chance > (totalChance / 10) ? (totalChance / 10) : chance;
        rand = rand % totalChance;
        if (rand < chance) {  // Boss Capture
            captureBoss(msg.sender, false);
        }
        
        // PBC
        rand = uint256( keccak256(abi.encodePacked(rdm, address(this), adventure.startBlock, msg.sender, CurveAddress)) );
        uint256 pbcAmount = getRandomPbcDrop(rand, adventure.cost);
        pbc.mint(pbcAmount);
        pbc.transfer(msg.sender, pbcAmount);
        emit PBCRewarded(msg.sender, pbcAmount);
    }
}
