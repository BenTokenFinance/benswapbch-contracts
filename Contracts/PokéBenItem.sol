// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PokeBenItem is ERC721, ERC721Enumerable, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    Counters.Counter private _tokenIdCounter;

    struct PokeBenItemInfo { 
        uint256 source;
        uint256 kind;
        string data;
    }

    string private _uri;
    mapping(uint256 => address) public getCreator;
    mapping(uint256 => PokeBenItemInfo) public getPokeBenItemInfo;
    mapping(uint256 => uint256) public getKindCount;
    mapping(uint256 => uint256) public getBurnedKindCount;
    mapping(uint256 => uint256) public getSourceCount;

    event PokeBenItemCreated(address indexed user, uint256 indexed tokenId, uint256 source, uint256 kind, string data);
    event PokeBenItemUpdated(uint256 indexed tokenId, string data);

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

    function safeMint(address to, uint256 _source, uint256 _kind, string memory _data) public onlyRole(MINTER_ROLE) returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();

        getCreator[tokenId] = to;
        getPokeBenItemInfo[tokenId] = PokeBenItemInfo({ source: _source, kind: _kind, data: _data });
        
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();

        getKindCount[_kind] = getKindCount[_kind] + 1;
        getSourceCount[_source] = getSourceCount[_source] + 1;

        emit PokeBenItemCreated(to, tokenId, _source, _kind, _data);

        return tokenId;
    }

    function update(uint256 tokenId, string memory data) public onlyRole(UPDATER_ROLE) {
        require(tokenId < _tokenIdCounter.current(), "Not Minted!");

        PokeBenItemInfo storage p = getPokeBenItemInfo[tokenId];
        p.data = data;

        emit PokeBenItemUpdated(tokenId, data);
    }

    function _afterTokenTransfer(address, address to, uint256 tokenId) internal override
    {
        PokeBenItemInfo storage p = getPokeBenItemInfo[tokenId];
        if (to == address(0)) {
            getBurnedKindCount[p.kind] = getBurnedKindCount[p.kind] + 1;
        }
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
