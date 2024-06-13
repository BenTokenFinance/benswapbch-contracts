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
    // Redefine the name and symbol variables
    string private _name;
    string private _symbol;
    // token url
    string private _uri;

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
    mapping(uint256 => address) public getCreator;
    event NftMinted(address indexed user, uint256 indexed tokenId, string name, string description, string image, string externalUrl, string attributes);




    constructor() ERC721("", "") {_isInitialized = false;}
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory tokenURI_,
        uint256 maxSupply_,
        address templteAdress_
    ) external onlyOwner {
        _name = name_;
        _symbol = symbol_;
        _uri= tokenURI_;
        maxSupply=maxSupply_;
        templteAdress=templteAdress_;
        _tokenIdCounter.increment();   // skip 0
        _isInitialized = true;
    }


    function name() public view override returns (string memory) {
        return _name;
    }
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setURI(string memory newuri) external onlyOwner {
        _uri = newuri;
    }

    function safeMint(string memory na, string memory desc, string memory img, string memory extUrl, string memory attrs) external onlyOwner returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= maxSupply, "Max supply reached");

        getCreator[tokenId] = msg.sender;
        getNftInfo[tokenId] = NftInfo({ name: na, description: desc, image: img, externalUrl: extUrl, attributes: attrs });
        _safeMint(msg.sender, tokenId);
        _tokenIdCounter.increment();  
              
        emit NftMinted(msg.sender, tokenId, na, desc, img, extUrl, attrs);
        return tokenId;
    }

    //get Img Url
    function tokenImgURI(uint256 tokenId) public view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string  memory newUrl=compositeURI();
        string memory url=string(abi.encodePacked(newUrl,"/",tokenId.toString()));
        return bytes(newUrl).length > 0 ? url : "";
    }

    function compositeURI() internal view returns (string memory) {
        NftTemplate simpleNftTemplate = NftTemplate(templteAdress);
        string memory mainUrl=simpleNftTemplate.mainUrl();
        return string(abi.encodePacked(mainUrl,addressToString(address(this))));
    }
    // 将地址转换为字符串的辅助函数
    function addressToString(address _addr) internal pure returns (string memory) {
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
}


interface NftTemplate {
    function mainUrl() external view returns (string memory);
    function setMainUrl(string memory) external;
    function name() external view returns (string memory);
    function createNft(address,bytes memory) external  returns (address);
}

pragma solidity ^0.8.4;
contract SimpleNftTemplate is NftTemplate {
    address owner;
    string override public  mainUrl="http://test.com/";
    uint256 private _count = 0;
    string private _name = "Simple";

    constructor(){
        owner=msg.sender;
    }
    function name() external override view returns (string memory) {
        return _name;
    }

    function setMainUrl(string memory newUrl_) external override{
        require(msg.sender == owner, "Unauthorized");
        mainUrl=newUrl_;
    }
  

    
    function createNft(address create_,bytes memory callData) external override returns (address token) {
        // eg:calldata 
        bytes memory bytecode = type(SimpleNft).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(callData, msg.sender, _count));
        assembly {
            token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // 假设 callData 包含除 address(this) 以外的所有参数
        (string memory name_, string memory symbol_, string memory baseTokenURI_, uint256 maxSupply_) = abi.decode(callData, (string, string, string, uint256));
        // 使用 abi.encodeWithSelector 正确编码参数
        bytes memory initializeCallData = abi.encodeWithSelector(
            bytes4(keccak256("initialize(string,string,string,uint256,address)")),
            name_, symbol_, baseTokenURI_, maxSupply_, address(this)
        );

        (bool success, ) = token.call(initializeCallData);

        require(success, "Something is wrong!");
        // transferOwner
        SimpleNft newNft = SimpleNft(token);
        newNft.transferOwnership(create_);
        _count = _count + 1;
    }
}