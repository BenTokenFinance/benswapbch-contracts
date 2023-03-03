// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract UpdatableErc721WithLimitSupply01 is ERC721,Ownable,ERC721Enumerable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;
       
    string private _uri;
    uint256 private _maxSupply;

    constructor(string memory name_, string memory symbol_, string memory uri_, uint256 maxSupply_) ERC721(name_, symbol_) {
        _uri = uri_;
        _maxSupply = maxSupply_;
        
        _tokenIdCounter.increment();   // skip 0
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setURI(string memory newuri) external onlyOwner {
        _uri = newuri;
    }

    function safeMint(address to) public onlyOwner {
        require(_tokenIdCounter.current() <= _maxSupply , "Max amount minted");

        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function batchMint(address to, uint256 number) public onlyOwner {
        for(uint i=0; i < number; i++) {
            safeMint(to);
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory url=string(abi.encodePacked(_uri, tokenId.toString()));
        string memory fullUrl=string(abi.encodePacked(url, '.json'));
        
        return bytes(_uri).length > 0 ? fullUrl : "";
    }

}
