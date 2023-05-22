// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface IPokeBen {
    function update(uint256 tokenId, uint256 level, uint256 basePower, uint256 power) external;
    function ownerOf(uint256 tokenId) external view returns(address);
    function getPokeBenInfo(uint256 tokenId) external view returns(uint256,uint256,uint256,uint256,uint256);
}

interface IPokeBenItem {
    function getPokeBenItemInfo(uint256 tokenId) external view returns(uint256,uint256,string memory);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns(address);
    function burn(uint256 tokenId) external;
}

interface IPokeBenTypeSetting {
    function hasType(uint256 kindId, uint256 tId) external view returns(bool);
}

interface IPokeBenAbilityScrollSetting {
    function getAbility(uint256 sId) external view returns(uint256);
}

interface IPokeBenAbilitySetting {
    function getType(uint256 aId) external view returns(uint256);
}

interface IPokeBenPowerExtension {
    function getPower(uint256 tokenId, uint256 basePower) external view returns(uint256);
}

interface IPokeBenAbilityExtension {
    function learn(uint256 tokenId, uint256 slot, uint256 abilityId) external;
}

interface IPokeBenMultipurposeExtension {
    function getMaxSlots(uint256 tokenId) external view returns(uint256);
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

contract PokeBenAbilityTrainingRoom is ERC721Holder, Ownable {
    bool private initialized = false;
    function initialize(address newOwner) external {
        require(newOwner != address(0) && !initialized);
        _transferOwnership(newOwner);
        initialized = true;

        pokeben = IPokeBen(0xFDEd6cD4B88a24e00d9Ea242338367fe734CBff5);
        pokebenitem = IPokeBenItem(0x335bF14Af7c6b2993434bB700AF0f1Afcf27d782);
        pokebenTypeSetting = IPokeBenTypeSetting(0x9CdD9a21B8A5eA28B96d6a2B3B86adF21aE52001);
        pokebenAbilitySetting = IPokeBenAbilitySetting(0x53c555A2C38B432519c0e1C450daeee3360e9Cf4);
        pokeBenAbilityScrollSetting = IPokeBenAbilityScrollSetting(0x196fe2998d767CC54f1052540dD3740F2046A157);
        pokebenpower = IPokeBenPowerExtension(0xa02Bd13da796DcCABf18ae513DDB327Fa5cB3672);
        pokebenAbilityExt = IPokeBenAbilityExtension(0x23662b10e4067480A39d337BA08ac898B90b7F80);
        pokebenMultipurposeExt = IPokeBenMultipurposeExtension(0xc84d10135275bf3dDc713D7fAe9Dd811517c2830);
    }

    function version() external pure returns(uint256){
        return 2;
    }

    using SafeERC20 for IERC20;

    IPokeBen public pokeben;
    IPokeBenItem public pokebenitem;
    IPokeBenTypeSetting public pokebenTypeSetting;
    IPokeBenAbilitySetting public pokebenAbilitySetting;
    IPokeBenAbilityScrollSetting public pokeBenAbilityScrollSetting;
    IPokeBenPowerExtension public pokebenpower;
    IPokeBenAbilityExtension public pokebenAbilityExt;
    IPokeBenMultipurposeExtension public pokebenMultipurposeExt;

    function setPokeBen(address _pokeben) external onlyOwner {
        pokeben = IPokeBen(_pokeben);
    }

    function setPokeBenItem(address _pokebenitem) external onlyOwner {
        pokebenitem = IPokeBenItem(_pokebenitem);
    }

    function setPokeBenTypeSetting(address _pokebenTypeSetting) external onlyOwner {
        pokebenTypeSetting = IPokeBenTypeSetting(_pokebenTypeSetting);
    }

    function setPokeBenAbilitySetting(address _pokebenAbilitySetting) external onlyOwner {
        pokebenAbilitySetting = IPokeBenAbilitySetting(_pokebenAbilitySetting);
    }

    function setPokeBenAbilityScrollSetting(address _pokeBenAbilityScrollSetting) external onlyOwner {
        pokeBenAbilityScrollSetting = IPokeBenAbilityScrollSetting(_pokeBenAbilityScrollSetting);
    }

    function setPokeBenPowerExtension(address _pokebenpower) external onlyOwner {
        pokebenpower = IPokeBenPowerExtension(_pokebenpower);
    }

    function setPokeBenAbilityExtension(address _pokebenAbilityExt) external onlyOwner {
        pokebenAbilityExt = IPokeBenAbilityExtension(_pokebenAbilityExt);
    }

    function setPokeBenMultipurposeExtension(address _pokebenMultipurposeExt) external onlyOwner {
        pokebenMultipurposeExt = IPokeBenMultipurposeExtension(_pokebenMultipurposeExt);
    }

    IERC20 public feeToken;
    address public feeTo;

    function setFeeToken(address _feeToken) external onlyOwner {
        feeToken = IERC20(_feeToken);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    function rescue(uint256 itemId) external onlyOwner {
        pokebenitem.safeTransferFrom(address(this), msg.sender, itemId);
    }

    uint256 private constant SCALE = 1e18;
    uint256 private constant HALFSCALE = 1e9;
    address private constant VrfgovAddress = 0x18C51aa3d1F018814716eC2c7C41A20d4FAf023C;
    address private constant JustinSunAddress = 0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296;

    uint256 private constant BASIC_CHANCE = 25 * SCALE;

    function getMaxSlots(uint256 pokeBenId) public view returns(uint256) {
        return pokebenMultipurposeExt.getMaxSlots(pokeBenId);
    }

    struct TrainingInfo { 
        uint256 pokeBenId;
        uint256 itemId;
        uint256 abilityId;
        uint256 startBlock;
        uint256[] fees;
    }

    mapping(address => TrainingInfo) public getTrainingInfo;

    event TrainingStart(address indexed user, TrainingInfo info);
    event TrainingEnd(address indexed user, TrainingInfo info, bool success, uint256 slot);

    function getChance(uint256 fee) public pure returns(uint256) {
        if (fee == 0) return BASIC_CHANCE;
        return (BASIC_CHANCE) + Babylonian.sqrt(fee) * HALFSCALE;
    }

    function canLearn(uint256 pokeBenId, uint256 itemId) public view returns (uint256 aId, bool canlearn){
        canlearn = false;

        (,uint256 kindId,) = pokebenitem.getPokeBenItemInfo(itemId);

        aId = pokeBenAbilityScrollSetting.getAbility(kindId);

        if (aId > 0) {
            (,uint256 pokeBenKindId,,,) = pokeben.getPokeBenInfo(pokeBenId);
            uint256 aType = pokebenAbilitySetting.getType(aId);
            if (aType == 18 || pokebenTypeSetting.hasType(pokeBenKindId,aType)) canlearn = true;
        }
    }

    function startTraining(uint256 pokeBenId, uint256 itemId, uint256[] calldata fees) external {
        require(fees.length <= getMaxSlots(pokeBenId), "Invalid length of fees!");
        require(pokeben.ownerOf(pokeBenId)==msg.sender, "You are not the owner of that pokeben!");
        require(pokebenitem.ownerOf(itemId)==msg.sender, "You are not the owner of that item!");
        (uint256 aId, bool canlearn) = canLearn(pokeBenId, itemId);
        require(canlearn, "Cannot learn!");

        pokebenitem.safeTransferFrom(msg.sender, address(this), itemId);

        uint256 totalFee = 0;
        for(uint i = 0; i < fees.length; i++) {
            totalFee += fees[i];
        }
        if(totalFee>0) feeToken.safeTransferFrom(address(msg.sender), feeTo, totalFee);
        
        getTrainingInfo[msg.sender] = TrainingInfo({ pokeBenId: pokeBenId, itemId: itemId, abilityId: aId, startBlock: block.number, fees: fees });
        
        emit TrainingStart(msg.sender, getTrainingInfo[msg.sender]);
    }

    function getResult(uint256 rdm, bytes calldata pi) external {
        TrainingInfo memory info = getTrainingInfo[msg.sender];
        require(pokeben.ownerOf(info.pokeBenId)==msg.sender, "You are not the owner of that pokeben!");
        bytes32 hash = blockhash(info.startBlock);
        require (uint256(hash) > 0, "Invalid block hash!");

        uint256 maxSlots = getMaxSlots(info.pokeBenId);

        require(VrfGovIfc(VrfgovAddress).verify(uint256(hash), rdm, pi), "Invalid vrf!");
        delete getTrainingInfo[msg.sender];
        pokebenitem.burn(info.itemId);

        uint256[] memory chances = new uint[](maxSlots);
        uint256 totalChance = BASIC_CHANCE;
        for(uint i = 0; i < maxSlots; i++) {
            chances[i] =  getChance(i<info.fees.length?info.fees[i]:0);
            totalChance += chances[i];
        }

        uint256 rand = uint256( keccak256(abi.encodePacked(rdm, info.startBlock, msg.sender, JustinSunAddress)) );
        rand = rand % totalChance;
        uint256 runningChance = 0;
        for(uint j = 0; j < maxSlots; j++) {
            runningChance += chances[j];
            if (rand < runningChance) {
                addAbility(info.pokeBenId, j, info.abilityId);

                (,,uint256 level,uint256 basePower,) = pokeben.getPokeBenInfo(info.pokeBenId);
                uint256 newPower = pokebenpower.getPower(info.pokeBenId, basePower);
                pokeben.update(info.pokeBenId, level, basePower, newPower);

                emit TrainingEnd(msg.sender, info, true, j);
                
                return;
            }
        }

        emit TrainingEnd(msg.sender, info, false, 999999);
    }

    function addAbility(uint256 pokeBenId, uint256 slot, uint256 aId) private {
        pokebenAbilityExt.learn(pokeBenId, slot, aId);
    }

    function calculateChancePctBps(uint256 maxSlots, uint256[] calldata fees) external pure returns(uint256[] memory) {
        uint256[] memory chances = new uint[](maxSlots);

        uint256 total = BASIC_CHANCE;
        for(uint i = 0; i < maxSlots; i++) {
            chances[i] =  getChance(i<fees.length?fees[i]:0);
            total += chances[i];
        }
        for(uint j = 0; j < maxSlots; j++) {
            chances[j] = chances[j] * 10000 / total;
        }

        return chances;
    }
}
