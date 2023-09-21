// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 




pragma solidity ^0.8.4;
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



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




    struct MemorialNftInfo {
        string name;
        uint256 deathDate;

        address engraver;
        string hometown;
        string epitaph;

        string image;
        string externalUrl;
    } 
    // struct NftInfo { 
    //     string name;
    //     string description;
    //     string image;
    //     string externalUrl;
    //     string attributes;
    // }

    mapping(uint256 => address) public getCreator;
    mapping(uint256 => MemorialNftInfo) public getMemorialNftInfo;
    mapping(uint256 => mapping(uint256 => uint256)) public getGiftInfo;


    event condolence(address indexed user, uint256 indexed tokenId,uint256 giftType,uint256 number);
    event NftMinted(address indexed user, uint256 indexed tokenId, string  name, uint256 deathDate, address engraver, string hometown, string epitaph,  string  img, string  extUrl);
   
   
    // event NftMinted(address indexed user, uint256 indexed tokenId, string name, string description, string image, string externalUrl, string attributes);
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
        // string memory na, uint256 deathDate, address engraver, string memory hometown, string memory epitaph,  string memory img, string memory extUrl
        
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
    function giveCondolence(uint256 tokenId,uint256 giftType,uint256 amount) public {
        require(_exists(tokenId), "Token does not exist");
        require(giftType <= 3, "Invalid gift type");
        require(getGiftRecord[msg.sender][giftType]>0, "Invalid quantity");
        require(getGiftRecord[msg.sender][giftType]>amount, "quantity not sufficient");


        getGiftInfo[tokenId][giftType]+=amount;
        getGiftRecord[msg.sender][giftType]-=amount;
        emit condolence(msg.sender,tokenId,giftType,amount);
    }



    // gift sol
    address public EBENAddress;
    mapping(uint256 => uint256) public giftCost;
    mapping(address => mapping(uint256=>uint256)) public getGiftRecord;
    event buyInfo(address indexed user, uint256  giftType,uint256 nums,uint256 cost);

    function buyGifts(uint256 giftType,uint256 amount) external {
             require(giftCost[giftType]>0,"The gift does not exist");
             require(amount>0,"Invalid quantity");
             uint256 tokenAmount=(amount*giftCost[giftType])*10**18;
            
             getGiftRecord[msg.sender][giftType]+=amount;
             IBEP20 EBENContract=IBEP20(EBENAddress);
             EBENContract.transferFrom(msg.sender,owner(),tokenAmount);
             emit buyInfo(msg.sender,giftType,amount,tokenAmount);
    }

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
