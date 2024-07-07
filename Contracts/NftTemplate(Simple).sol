// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Counters.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/utils/Strings.sol";


contract SimpleNft is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    bool private _isInitialized;
    bool private _isEdit;
    // Redefine the name and symbol variables
    string private _name;
    string private _symbol;
    uint256 public maxSupply;
    address public templteAdress;
  
    struct NftInfo { 
        string name;
        string description;
        string image;
        string externalUrl;
        string attributes;
    }
    mapping(uint256 => NftInfo) public getNftInfo;
    event NftMinted(address indexed user, uint256 indexed tokenId, string name, string description, string image, string externalUrl, string attributes);
    event NftInfoUpdated(address indexed updater,uint256 indexed tokenId,string name,string description,string image,string externalUrl,string attributes);



    constructor() ERC721("", "") {_isInitialized = false;}
    function initialize(
        address create_,
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        address templteAdress_,
        bool isEdit_
    ) external onlyOwner {
        require(!_isInitialized, 'NFT: not initialized!');
        // set owner
        transferOwnership(create_);
        _name = name_;
        _symbol = symbol_;
        maxSupply=maxSupply_;
        templteAdress=templteAdress_;
        _isEdit=isEdit_;
        _tokenIdCounter.increment();   // skip 0
        _isInitialized = true;
    }


    function name() public view override returns (string memory) {
        return _name;
    }
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function safeMint(address to,string memory na, string memory desc, string memory img, string memory extUrl, string memory attrs) external onlyOwner returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= maxSupply, "Max supply reached");

        getNftInfo[tokenId] = NftInfo({ name: na, description: desc, image: img, externalUrl: extUrl, attributes: attrs });
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();  
              
        emit NftMinted(msg.sender, tokenId, na, desc, img, extUrl, attrs);
        return tokenId;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string  memory newUrl=compositeURI();
        string memory url=string(abi.encodePacked(newUrl,"/",tokenId.toString()));
        return bytes(newUrl).length > 0 ? url : "";
    }

    function compositeURI() private view returns (string memory) {
        SimpleNftTemplate simpleTemplate = SimpleNftTemplate(templteAdress);
        string memory mainUrl=simpleTemplate.mainUrl();
        return string(abi.encodePacked(mainUrl,addressToString(address(this))));
    }
    // The helper function to convert an address to a string
    function addressToString(address _addr) private pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function updateNftInfo(
        uint256 tokenId,
        string memory na, 
        string memory desc, 
        string memory img, 
        string memory extUrl, 
        string memory attrs
    ) external  onlyOwner{
       require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
       require(_isEdit,"NFT:Cannot edit");
       getNftInfo[tokenId] = NftInfo(na, desc, img, extUrl, attrs);
       emit NftInfoUpdated(msg.sender,tokenId, na, desc, img, extUrl, attrs);
    }
}


interface NftTemplate {
    function name() external view returns (string memory);
    function createNft(address,bytes memory) external  returns (address);
}

pragma solidity ^0.8.4;
contract SimpleNftTemplate is NftTemplate {
    address owner;
    string  public  mainUrl="http://test.com/";
    uint256 private _count = 0;
    string  private _name = "Simple";

    constructor(){
        owner=msg.sender;
    }
    function name() external override view returns (string memory) {
        return _name;
    }

    function setMainUrl(string memory newUrl_) external{
        require(msg.sender == owner, "Unauthorized");
        mainUrl=newUrl_;
    }
  

    
    function createNft(address create_,bytes memory callData) external override returns (address token) {
        bytes memory bytecode = type(SimpleNft).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(callData, msg.sender, _count));
        assembly {
            token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(token != address(0), "Deployment failed!");
        
        (string memory name_, string memory symbol_, uint256 maxSupply_,bool isEdit_) = abi.decode(callData, (string, string, uint256,bool));
        bytes memory initializeCallData = abi.encodeWithSelector(
            bytes4(keccak256("initialize(address,string,string,uint256,address,bool)")),
            create_,name_, symbol_, maxSupply_, address(this),isEdit_
        );
        (bool success, ) = token.call(initializeCallData);
        require(success, "Something is wrong!");
        _count = _count + 1;
    }
}