// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract NFTFactorySingle is ERC721,Ownable,ERC721Enumerable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeERC20 for ERC20;
    Counters.Counter private _tokenIdCounter;
       
    string private _uri;

    ERC20 public feeToken;
    address public feeTo;
    uint256 public creationFee;

    function setCreationFee(uint256 _creationFee) external onlyOwner {
        creationFee = _creationFee;
    }

    function setFeeToken(address _feeToken) external onlyOwner {
        feeToken = ERC20(_feeToken);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    struct NftInfo { 
        string name;
        string description;
        string image;
        string externalUrl;
        string attributes;
    }

    mapping(uint256 => address) public getCreator;
    mapping(uint256 => NftInfo) public getNftInfo;

    event NftMinted(address indexed user, uint256 indexed tokenId, string name, string description, string image, string externalUrl, string attributes);

    constructor(string memory name_, string memory symbol_, string memory uri_, ERC20 feeToken_, address feeTo_, uint256 creationFee_) ERC721(name_, symbol_) {
        _uri = uri_;
        feeToken = feeToken_;
        feeTo = feeTo_;
        creationFee = creationFee_;
        
        _tokenIdCounter.increment();   // skip 0
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setURI(string memory newuri) external onlyOwner {
        _uri = newuri;
    }

    function safeMint(string memory na, string memory desc, string memory img, string memory extUrl, string memory attrs) public returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();

        getCreator[tokenId] = msg.sender;
        getNftInfo[tokenId] = NftInfo({ name: na, description: desc, image: img, externalUrl: extUrl, attributes: attrs });
        
        _safeMint(msg.sender, tokenId);
        _tokenIdCounter.increment();        
        
        // creation fee
        feeToken.safeTransferFrom(address(msg.sender), feeTo, creationFee);

        emit NftMinted(msg.sender, tokenId, na, desc, img, extUrl, attrs);

        return tokenId;
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
