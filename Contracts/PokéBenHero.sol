// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PokeBenHero is ERC721, ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    Counters.Counter private _tokenIdCounter;

    string private _uri;
    mapping(uint256 => address) public getCreator;
    mapping(uint256 => string) public getName;
    mapping(uint256 => mapping(uint256 => uint256)) public getPokeBenHeroParts;
    mapping(uint256 => mapping(uint256 => string)) public getPokeBenHeroStats;

    event PokeBenHeroCreated(address indexed user, uint256 indexed tokenId);
    event PokeBenHeroUpdated(uint256 indexed tokenId, uint256 slotIndex, uint256 partId, string data);
    event PokeBenHeroNameChanged(uint256 indexed tokenId, address indexed user, string name);

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPDATER_ROLE, msg.sender);

        _tokenIdCounter.increment();  // skip 0
    }
    
    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _uri = newuri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();

        getCreator[tokenId] = to;
        
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();

        emit PokeBenHeroCreated(to, tokenId);

        return tokenId;
    }

    function update(uint256 tokenId, uint256 slotIndex, uint256 partId, string calldata data) public onlyRole(UPDATER_ROLE) {
        require(tokenId < _tokenIdCounter.current(), "Not Minted!");

        getPokeBenHeroParts[tokenId][slotIndex] = partId;
        getPokeBenHeroStats[tokenId][slotIndex] = data;

        emit PokeBenHeroUpdated(tokenId, slotIndex, partId, data);
    }

    function rename(uint256 tokenId, string memory name) external {
        require(bytes(name).length <=30, 'Name is too long!');
        require(ownerOf(tokenId)==msg.sender, 'You are not the owner of that NFT!');

        getName[tokenId] = name;
        emit PokeBenHeroNameChanged(tokenId, msg.sender, name);
    }

    function getHeroParts(uint256 tokenId, uint256 maxParts) external view returns (uint256[] memory) {
        uint256[] memory parts = new uint[](maxParts);

        for(uint i=0; i<maxParts; i++){
            parts[i] = getPokeBenHeroParts[tokenId][i];
        }

        return parts;
    }

    function getHeroStats(uint256 tokenId, uint256 maxStats) external view returns (string[] memory) {
        string[] memory parts = new string[](maxStats);

        for(uint i=0; i<maxStats; i++){
            parts[i] = getPokeBenHeroStats[tokenId][i];
        }

        return parts;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
