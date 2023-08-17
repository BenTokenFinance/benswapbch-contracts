// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface IPokeBenHero {
    function update(uint256 tokenId, uint256 slotIndex, uint256 partId, string calldata data) external;
    function ownerOf(uint256 tokenId) external view returns(address);
}

interface IPokeBenItem {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getPokeBenItemInfo(uint256 tokenId) external view returns(uint256,uint256,string memory);
    function ownerOf(uint256 tokenId) external view returns(address);
    function burn(uint256 tokenId) external;
}

interface IPokeBenHeroPartSetting {
    function getHeroPartInfo(uint256 itemKindId) external view returns(uint256,uint256,uint256);
}

contract PokeBenHeroBeautician is Ownable {
    using SafeERC20 for IERC20;

    bool private initialized = false;
    function initialize(address newOwner) external {
        require(newOwner != address(0) && !initialized);
        _transferOwnership(newOwner);
        initialized = true;

        pokebenitem = IPokeBenItem(0x335bF14Af7c6b2993434bB700AF0f1Afcf27d782);
        heropartsetting = IPokeBenHeroPartSetting(0xd2c5574F96FD229dDde47d30903376e841C9c25b);
        pokebenhero = IPokeBenHero(0x014da337dd4e097935797602332a4649c3F436c1);

        feeToken = IERC20(0x7fa2DC7F8671544E301085CB76FfDA19c78AcD75);
        feeTo = 0x71D9C349e35f73B782022d912B5dADa4235fDa06;
        fee = 1e18 * 10000;
    }

    function version() external pure returns(uint256){
        return 1;
    }

    IPokeBenHero public pokebenhero;
    IPokeBenItem public pokebenitem;
    IPokeBenHeroPartSetting public heropartsetting;
    
    function setPokeBenItem(address _pokebenitem) external onlyOwner {
        pokebenitem = IPokeBenItem(_pokebenitem);
    }
    function setHeroPartSetting(address _heropartsetting) external onlyOwner {
        heropartsetting = IPokeBenHeroPartSetting(_heropartsetting);
    }
    function setPokeBenHero(address _pokebenhero) external onlyOwner {
        pokebenhero = IPokeBenHero(_pokebenhero);
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

    event heroPartApplied(address indexed user, uint256 indexed heroId, uint256 itemId, uint256 heroPartId, string data, uint256 cost);

    function applyHeroPart(uint256 heroId, uint256 itemId) external {
        require(pokebenhero.ownerOf(heroId)==msg.sender, "You are not the owner of that hero!");
        require(pokebenitem.ownerOf(itemId)==msg.sender, "You are not the owner of that item!");
        (,uint256 kind,string memory data) = pokebenitem.getPokeBenItemInfo(itemId);
        (uint256 heroPartId,uint256 typeId,) = heropartsetting.getHeroPartInfo(kind);
        require(heroPartId>0, "Item is not hero part!");
        require(bytes(data).length>0, "Item has not been appraised!");

        feeToken.safeTransferFrom(address(msg.sender), address(this), fee);

        pokebenitem.burn(itemId);

        pokebenhero.update(heroId, typeId, heroPartId, data);

        emit heroPartApplied(msg.sender, heroId, itemId, heroPartId, data, fee);
    }
}
