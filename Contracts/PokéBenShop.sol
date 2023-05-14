// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface IPokeBen {
    function safeMint(address to, uint256 _source, uint256 _kind, uint256 _level, uint256 _basePower) external returns(uint256);
    function getKindCount(uint256 kindId) view external returns (uint256);
}

interface IPokeBenKindRaritySetting {
    function getRarity(uint256 kind) view external returns (uint256);
    function getLimit(uint256 kind) view external returns (uint256);
}

interface IPokeBenItem {
    function safeMint(address to, uint256 _source, uint256 _kind, string memory _data) external returns(uint256);
}

contract PokeBenShop is Ownable {
    using SafeERC20 for IERC20;

    bool private initialized = false;
    function initialize(address newOwner) external {
        require(newOwner != address(0) && !initialized);
        _transferOwnership(newOwner);
        initialized = true;
    }

    function version() external pure returns(uint256){
        return 1;
    }

    address public feeTo;
    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    IERC20 public pokebencrystal;
    function setPokeBenCrystal(address _pbc) external onlyOwner {
        pokebencrystal = IERC20(_pbc);
    }

    IPokeBen public pokeben;
    function setPokeBen(address _pb) external onlyOwner {
        pokeben = IPokeBen(_pb);
    }

    IPokeBenKindRaritySetting public pokebenKindRaritySetting;
    function setPokeBenKindRaritySetting(address _pokebenKindRaritySetting) external onlyOwner {
        pokebenKindRaritySetting = IPokeBenKindRaritySetting(_pokebenKindRaritySetting);
    }
    
    IPokeBenItem public pokebenitem;
    function setPokeBenItem(address _pi) external onlyOwner {
        pokebenitem = IPokeBenItem(_pi);
    }

    mapping(uint256 => uint256) public pokeBenKindPrice;
    mapping(uint256 => bool) public pokeBenKindSupported;
    function setPokeBenKindPrice(uint256 kind, uint256 price) external onlyOwner {
        pokeBenKindPrice[kind] = price;
    }
    function setPokeBenKindSupported(uint256 kind, bool _supported) external onlyOwner {
        pokeBenKindSupported[kind] = _supported;
    }

    mapping(uint256 => uint256) public pokeBenBasicItemKindPrice;
    mapping(uint256 => bool) public pokeBenBasicItemKindSupported;
    function setPokeBenBasicItemKindPrice(uint256 itemKind, uint256 price) external onlyOwner {
        pokeBenBasicItemKindPrice[itemKind] = price;
    }
    function setPokeBenBasicItemKindSupported(uint256 itemKind, bool _supported) external onlyOwner {
        pokeBenBasicItemKindSupported[itemKind] = _supported;
    }

    event PokeBenBought(address indexed user, uint256 tokenId, uint256 price);
    event PokeBenItemBought(address indexed user, uint256 itemId, uint256 price);

    function getInitialPokeBenPower(uint256 kind) public view returns(uint256) {
        uint256 rarity = pokebenKindRaritySetting.getRarity(kind);
        uint256 baseRarity = rarity >5 ? 5 : rarity;
        uint256 s = 10**baseRarity;
        uint256 power = ((rarity >5 ? (rarity-5)*25 : 0) + 100) * s;
        return power;
    }

    function isPokeBenMintable(uint256 kind) public view returns(bool) {
        uint256 limit = pokebenKindRaritySetting.getLimit(kind);
        if (limit > 0) return pokeben.getKindCount(kind) < limit;
        return true;
    }

    function mintPokeBen(uint256 kind, address to) private returns (uint256) {
        uint256 tokenId = pokeben.safeMint(to, 4, kind, 1, getInitialPokeBenPower(kind));
        return tokenId;
    }

    function buyPokeBen(uint256 kind) external returns(uint256) {
        require(pokeBenKindSupported[kind], "Not supported!");
        require(isPokeBenMintable(kind), "Kind is not available!");

        uint256 price = pokeBenKindPrice[kind];
        require(price>0, "Invalid price!");

        pokebencrystal.safeTransferFrom(address(msg.sender), feeTo, price);
        uint256 tokenId = mintPokeBen(kind, address(msg.sender));

        emit PokeBenBought(address(msg.sender), tokenId, price);
        return tokenId;
    }

    function mintPokeBenBasicItem(uint256 kind, address to) private returns (uint256) {
        uint256 tokenId = pokebenitem.safeMint(to, 2, kind, "");
        return tokenId;
    }

    function buyPokeBenBasicItem(uint256 kind) external returns(uint256) {
        require(pokeBenBasicItemKindSupported[kind], "Not supported!");

        uint256 price = pokeBenBasicItemKindPrice[kind];
        require(price>0, "Invalid price!");

        pokebencrystal.safeTransferFrom(address(msg.sender), feeTo, price);
        uint256 itemId = mintPokeBenBasicItem(kind, address(msg.sender));

        emit PokeBenItemBought(address(msg.sender), itemId, price);
        return itemId;
    }
}
