// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/access/Ownable.sol";


contract BasicNft is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    bool private _isInitialized;
    // Redefine the name and symbol variables
    string private _name;
    string private _symbol;
    // token url
    string public tokenUrl;
    uint256 public maxSupply;

    constructor() ERC721("", "") {_isInitialized = false;}
    function initialize(
        address create_,
        string memory name_,
        string memory symbol_,
        string memory tokenURI_,
        uint256 maxSupply_
    ) external onlyOwner {
        require(!_isInitialized, 'NFT: not initialized!');
        // set owner
        transferOwnership(create_);
        _name = name_;
        _symbol = symbol_;
        tokenUrl= tokenURI_;
        maxSupply=maxSupply_;
        _tokenIdCounter.increment();   // skip 0
        _isInitialized = true;
    }

    function name() public view override returns (string memory) {
        return _name;
    }
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return tokenUrl;
    }
    function setTokenUrl(string memory tokenURI_) external onlyOwner {
        tokenUrl = tokenURI_;
    }
    function mint(address to) external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current(); 
        require(tokenId <= maxSupply, "Max supply reached");
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
    }
}


interface NftTemplate {
    function name() external view returns (string memory);
    function createNft(address,bytes memory) external  returns (address);
}

pragma solidity ^0.8.4;
contract BasicNftTemplate is NftTemplate {
    uint256 private _count = 0;
    string private _name = "Basic";

    constructor(){}
    function name() external override view returns (string memory) {
        return _name;
    }

    function createNft(address create_,bytes memory callData) external override returns (address token) {
        bytes memory bytecode = type(BasicNft).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(callData, msg.sender, _count));
        assembly {
            token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(token != address(0), "Deployment failed!");
        
        (string memory name_, string memory symbol_,string memory tokenURI_,uint256 maxSupply_) = abi.decode(callData, (string,string,string,uint256));
        bytes memory initializeCallData = abi.encodeWithSelector(
            bytes4(keccak256("initialize(address,string,string,string,uint256)")),
            create_,name_,symbol_,tokenURI_,maxSupply_
        );
        (bool success, ) = token.call(initializeCallData);
        require(success, "Something is wrong!");

        _count = _count + 1;
    }
}