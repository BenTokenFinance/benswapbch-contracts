// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface IPokeBenItem {
    function ownerOf(uint256 tokenId) external view returns(address);
    function update(uint256 tokenId, string memory data) external;
    function getPokeBenItemInfo(uint256 tokenId) external view returns(uint256,uint256,string memory);
}

interface IPokeBenHeroPartSetting {
    function getHeroPartInfo(uint256 itemKindId) external view returns(uint256,uint256,uint256);
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

contract PokeBenHeroPartAppraiser is Ownable {
    using SafeERC20 for IERC20;

    bool private initialized = false;
    function initialize(address newOwner) external {
        require(newOwner != address(0) && !initialized);
        _transferOwnership(newOwner);
        initialized = true;

        pokebenitem = IPokeBenItem(0x335bF14Af7c6b2993434bB700AF0f1Afcf27d782);
        heropartsetting = IPokeBenHeroPartSetting(0xd2c5574F96FD229dDde47d30903376e841C9c25b);

        feeToken = IERC20(0x7fa2DC7F8671544E301085CB76FfDA19c78AcD75);
        feeTo = 0x71D9C349e35f73B782022d912B5dADa4235fDa06;
        fee = 1e18 * 10000;
    }

    function version() external pure returns(uint256){
        return 1;
    }

    IPokeBenItem public pokebenitem;
    IPokeBenHeroPartSetting public heropartsetting;
    
    function setPokeBenItem(address _pokebenitem) external onlyOwner {
        pokebenitem = IPokeBenItem(_pokebenitem);
    }
    function setHeroPartSetting(address _heropartsetting) external onlyOwner {
        heropartsetting = IPokeBenHeroPartSetting(_heropartsetting);
    }

    IERC20 public feeToken;
    address public feeTo;

    function setFeeToken(address _feeToken) external onlyOwner {
        feeToken = IERC20(_feeToken);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    uint256 public fee;

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    uint256 private constant SCALE = 1e18;
    address private constant VrfgovAddress = 0x18C51aa3d1F018814716eC2c7C41A20d4FAf023C;
    address private constant BabyDogeAddress = 0xAC57De9C1A09FeC648E93EB98875B212DB0d460B;

    mapping(uint256 => bool) public isLocked;

    function unlock(uint256 itemId) external onlyOwner {
        isLocked[itemId] = false;
    }

    struct AppraisalInfo { 
        uint256 itemId;
        uint256 startBlock;
    }

    mapping(address => AppraisalInfo) public getAppraisalInfo;

    event AppraisalStart(address indexed user, uint256 indexed itemId, uint256 cost);
    event AppraisalEnd(address indexed user, uint256 indexed itemId, uint256 result);

    function startAppraisal(uint256 itemId) external {
        require(pokebenitem.ownerOf(itemId)==msg.sender, "You are not the owner of that item!");
        require(!isLocked[itemId], "Item is being appraised");
        (,uint256 kind,string memory data) = pokebenitem.getPokeBenItemInfo(itemId);
        (uint256 heroPartId,,) = heropartsetting.getHeroPartInfo(kind);
        require(heroPartId>0, "Item is not hero part!");
        require(bytes(data).length==0, "Already been appraised!");

        feeToken.safeTransferFrom(address(msg.sender), address(this), fee);

        getAppraisalInfo[msg.sender] = AppraisalInfo({ itemId: itemId, startBlock: block.number });

        isLocked[itemId] = true;
        
        emit AppraisalStart(msg.sender, itemId, fee);
    }

    function abs(uint x) private pure returns (int) {
        return x >= 0 ? int(x) : -int(x);
    }

    function appraise(uint256 rdm, bytes calldata pi) external {
        AppraisalInfo memory appraisal = getAppraisalInfo[msg.sender];

        bytes32 hash = blockhash(appraisal.startBlock);
        require (uint256(hash) > 0, "Invalid block hash!");

        require(VrfGovIfc(VrfgovAddress).verify(uint256(hash), rdm, pi), "Invalid vrf!");

        delete getAppraisalInfo[msg.sender];
        isLocked[appraisal.itemId] = false;

        uint256 rand = uint256( keccak256(abi.encodePacked(rdm, address(this), appraisal.startBlock, msg.sender, BabyDogeAddress)) );

        (,uint256 kind,) = pokebenitem.getPokeBenItemInfo(appraisal.itemId);
        (,,uint256 rarity) = heropartsetting.getHeroPartInfo(kind);

        uint result = getResult(rand, rarity);

        pokebenitem.update(appraisal.itemId, Strings.toString(result));

        emit AppraisalEnd(msg.sender, appraisal.itemId, result);
    }

    function getResult(uint256 rand, uint256 rarity) public pure returns (uint256) {
        uint[] memory rarityChances = new uint[](5);
        uint totalChances = 0;
        for (uint i=1; i<=5; i++) {
            uint x = rarity >= i ? rarity-i : i-rarity;
            rarityChances[i] = 10000000 / 10**x;
            totalChances += rarityChances[i];
        }

        uint r = rand % totalChances;
        uint runningChance = 0;
        for (uint i=1; i<=4; i++) {
            runningChance += rarityChances[i];
            if (r < runningChance) {
                return (i-1) * 1000 + Babylonian.sqrt(rand%1000000);
            }
        }

        return 4000 + Babylonian.sqrt(rand%1000000);
    }
}
