// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/access/Ownable.sol";

contract BasicNft is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    address public templteAdress;
    // Redefine the name and symbol variables
    string private _name;
    string private _symbol;
    string private _baseTokenURI;
    uint256 public maxSupply;
  
    struct NftInfo { 
        string name;
        string description;
        string image;
        string externalUrl;
        string attributes;
    }

    constructor(string memory name_, string memory symbol_, string memory baseURI_,uint256 maxSupply_,address templteAdress_) ERC721(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;
        _baseTokenURI = baseURI_;
        maxSupply=maxSupply_;
        templteAdress=templteAdress_;
    }
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        NftTemplate SimpleNft = NftTemplate(templteAdress);
        return SimpleNft.mainUrl();
    }

    // function mint(address to) external onlyOwner {
    //     require(nextTokenId < maxSupply, "Max supply reached");
    //     uint256 tokenId = nextTokenId;
    //     nextTokenId++;
    //     _safeMint(to, tokenId);
    // }

    function safeMint(string memory na, string memory desc, string memory img, string memory extUrl, string memory attrs) public returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "Max supply reached");
        // TO DO;
        // getCreator[tokenId] = msg.sender;
        // getNftInfo[tokenId] = NftInfo({ name: na, description: desc, image: img, externalUrl: extUrl, attributes: attrs });
        _safeMint(msg.sender, tokenId);
        _tokenIdCounter.increment();        
        
        // creation fee
        // feeToken.safeTransferFrom(address(msg.sender), feeTo, creationFee);
        // emit NftMinted(msg.sender, tokenId, na, desc, img, extUrl, attrs);
        return tokenId;
    }
}


interface NftTemplate {
    function mainUrl() external view returns (string memory);
    function setMainUrl(string memory) external;
    function name() external view returns (string memory);
    function createNft(address,string memory, string memory, string memory, uint256) external  returns (address);
    // function createNft(bytes memory) external returns (address);
}

pragma solidity ^0.8.4;
contract SimpleNftTemplate is NftTemplate {

    string override public  mainUrl="http://test.com";
    uint256 private _count = 0;
    string private _name = "Basic";

    constructor(){}
    function name() external override view returns (string memory) {
        return _name;
    }

    function setMainUrl(string memory newUrl_) external override{
        mainUrl=newUrl_;
    }
  

   function createNft(address create_,string memory name_, string memory symbol_, string memory baseURI_, uint256 maxSupply_) external override returns (address token) {
        BasicNft newNft = new BasicNft(name_, symbol_, baseURI_, maxSupply_,address(this));
        token=address(newNft);
        require(token != address(0), "Failed to create contract");
        // transferOwner
        newNft.transferOwnership(create_);
        _count = _count + 1;
    }
    // function createNft(bytes memory callData) external override  returns (address token) {
    //     bytes memory bytecode = type(BasicNft).creationCode;
    //     bytes32 salt = keccak256(abi.encodePacked(callData, msg.sender, _count));
    //     assembly {
    //         token := create2(0, add(bytecode, 32), mload(bytecode), salt)
    //     }
    //     require(token != address(0), "Failed to create contract");
    //     _count = _count + 1;
    // }
}