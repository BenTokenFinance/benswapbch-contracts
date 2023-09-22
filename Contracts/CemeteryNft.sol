// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 


contract CemeteryNft is ERC721,Ownable,ERC721Enumerable {
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





    struct MemorialNftInfo {
        string name;
        uint256 deathDate;
        address engraver;
        string hometown;
        string epitaph;

        string image;
        string externalUrl;
    } 
    mapping(uint256 => address) public getCreator;
    mapping(uint256 => MemorialNftInfo) public getMemorialNftInfo;
    mapping(uint256 => mapping(uint256 => uint256)) public getNftGiftInfo;

    event condolence(address indexed user, uint256 indexed tokenId,uint256 giftType,uint256 number);
    event NftMinted(address indexed user, uint256 indexed tokenId, string  name, uint256 deathDate, address engraver, string hometown, string epitaph,  string  img, string  extUrl);
   

    // gift sol
    mapping(uint256 => uint256) public giftCost;
    mapping(address => mapping(uint256=>uint256)) public getGiftRecord;
    event buyInfo(address indexed user, uint256  giftType,uint256 nums,uint256 cost);

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



    // Cemetery  Nft
    function safeMint(MemorialNftInfo memory params) public returns(uint256) {

        uint256 tokenId = _tokenIdCounter.current();
        getCreator[tokenId] = msg.sender;
        getMemorialNftInfo[tokenId] = params;
        
        _safeMint(msg.sender, tokenId);
        _tokenIdCounter.increment();        
        
        // creation fee
        feeToken.safeTransferFrom(address(msg.sender), feeTo, creationFee);
        emit NftMinted(msg.sender, tokenId, params.name, params.deathDate, params.engraver, params.hometown, params.epitaph, params.image, params.externalUrl);
        return tokenId;
    }
    // Gift giving
    function giveCondolence(uint256 tokenId,uint256 giftType,uint256 amount) public {
        require(_exists(tokenId), "Token does not exist");
        require(giftCost[giftType]>0, "Invalid gift type");
        require(amount>0, "Invalid amount");
        require(getGiftRecord[msg.sender][giftType]>0&&getGiftRecord[msg.sender][giftType]>=amount, "quantity not sufficient");


        getNftGiftInfo[tokenId][giftType]+=amount;
        getGiftRecord[msg.sender][giftType]-=amount;
        emit condolence(msg.sender,tokenId,giftType,amount);
    }

    // Gift buying
    function buyGifts(uint256 giftType,uint256 amount) external {
             require(giftCost[giftType]>0,"The gift does not exist");
             require(amount>0,"Invalid quantity");
             ERC20 tokenContract=ERC20(feeToken);
             uint256 tokenDecimals=tokenContract.decimals();

             uint256 tokenAmount=(amount*giftCost[giftType])*(10**tokenDecimals);
             getGiftRecord[msg.sender][giftType]+=amount;
             tokenContract.transferFrom(msg.sender,feeTo,tokenAmount);
             emit buyInfo(msg.sender,giftType,amount,tokenAmount);
    }
    // Set Gift cost
    function setGiftCost(uint256[] memory costs) external onlyOwner {
              for(uint256 i=0;i<costs.length;i++){
                 this._setGiftCost(i,costs[i]);
              }
    }
    function _setGiftCost(uint256 giftType,uint256 cost) external onlyOwner {
             giftCost[giftType]=cost;
    }
    


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory url=string(abi.encodePacked(_uri, tokenId.toString()));
        return bytes(_uri).length > 0 ? url : "";
    }
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId,uint256 batchSize)
        internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId,batchSize);
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
