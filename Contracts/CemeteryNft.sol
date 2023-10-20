// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract CemeteryNft is ERC721, ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
       
    string private _uri;
 
    mapping(uint256 => address) public getCreator;

    event TokenMinted(address indexed user, uint256 tokenId);

    constructor(string memory name_, string memory symbol_, string memory uri_) ERC721(name_, symbol_) {
        _uri = uri_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _tokenIdCounter.increment();   // skip 0
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();

        getCreator[tokenId] = to;
        
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();

        emit TokenMinted(to, tokenId);

        return tokenId;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setURI(string memory newuri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _uri = newuri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory url=string(abi.encodePacked(_uri, tokenId.toString()));
        return bytes(_uri).length > 0 ? url : "";
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
