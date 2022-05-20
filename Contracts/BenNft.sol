// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract BENNFT is ERC721,Ownable,ERC721Enumerable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;
       
    string private _uri;
    uint256 private _maxSupply;

    constructor(string memory name_, string memory symbol_, string memory uri_, uint256 maxSupply_) ERC721(name_, symbol_) {
        _uri = uri_;
        _maxSupply = maxSupply_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setURI(string memory newuri) public virtual {
        _uri = newuri;
    }


    function safeMint(address to) public onlyOwner {
        require(_tokenIdCounter.current() <= _maxSupply - 1, "Max amount minted");

        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    //批量铸造 
    function batchMint(address to, uint256 number) public payable onlyOwner {
        for(uint i=0; i < number; i++) {
            safeMint(to);
        }
    }


   //查询合约余额
   function getBalance()  public onlyOwner view returns(uint bala){
      return address(this).balance;
   }
   //Contract is destroyed
   function destroyContract()  public onlyOwner {
        selfdestruct(payable(msg.sender));
   }
   //提取合约余额 
   function TranOwner() public onlyOwner  payable {
       payable(owner()).transfer(address(this).balance);
   }
   
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    //注册 ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    //覆盖tokenUrl返回 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        string memory tokenJson=string(abi.encodePacked('nft_', tokenId.toString()));
        string memory url=string(abi.encodePacked(baseURI, tokenJson));
        string memory fullUrl=string(abi.encodePacked(url, '.json'));
        
        return bytes(baseURI).length > 0 ? fullUrl : "";
    }

}