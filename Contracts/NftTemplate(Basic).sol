// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/access/Ownable.sol";


contract BasicNft is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Redefine the name and symbol variables
    string private _name;
    string private _symbol;
    // img url
    string public baseImgURI;
    // data url
    string public baseTokenURI;
    uint256 public maxSupply;
    // constructor() ERC721('MyNFT', 'MNFT') {
    //     admin = msg.sender;
    // }
    constructor(string memory name_, string memory symbol_,string memory baseImgURI_,string memory baseURI_,uint256 maxSupply_) ERC721(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;
        baseImgURI= baseImgURI_;
        baseTokenURI = baseURI_;

        maxSupply=maxSupply_;
        _tokenIdCounter.increment();   // skip 0
    }
    function setBaseURI(string memory tokenURI) external onlyOwner {
        baseTokenURI = tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseImgURI;
    }



    function mint(address to) external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current(); 
        require(tokenId < maxSupply, "Max supply reached");
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
    }
}


interface NftTemplate {
    function name() external view returns (string memory);
    function createNft(address,string memory, string memory, string memory,string memory, uint256) external  returns (address);
    // function createNft(bytes memory) external returns (address);
}

pragma solidity ^0.8.4;
contract BasicNftTemplate is NftTemplate {
    uint256 private _count = 0;
    string private _name = "Basic";

    constructor(){}
    function name() external override view returns (string memory) {
        return _name;
    }

  

   function createNft(address create_,string memory name_, string memory symbol_,string memory imgUrl_, string memory tokenDataURI_, uint256 maxSupply_) external override returns (address token) {
        BasicNft newNft = new BasicNft(name_, symbol_,imgUrl_, tokenDataURI_, maxSupply_);
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