// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface CemeteryNft {
    function safeMint(address to) external returns(uint256);
    function ownerOf(uint256 tokenId) external view returns(address);
    function totalSupply() external view returns (uint256);
}

contract CemeteryController is Ownable {
    using Strings for uint256;
    using SafeERC20 for ERC20;

    bool private initialized = false;
    function initialize(address newOwner) external {
        require(newOwner != address(0) && !initialized);
        _transferOwnership(newOwner);
        initialized = true;

        nft = CemeteryNft(0x850C860C9288Cd4e8bfcEff46ebCA4E358563d91);

        feeToken = ERC20(0x77CB87b57F54667978Eb1B199b28a0db8C8E1c0B);
        feeTo = 0x71D9C349e35f73B782022d912B5dADa4235fDa06;
        creationFee = 1e18 * 10;
    }

    function version() external pure returns(uint256){
        return 1;
    }
       
    ERC20 public feeToken;
    address public feeTo;
    uint256 public creationFee;
    CemeteryNft public nft;

    function setCreationFee(uint256 _creationFee) external onlyOwner {
        creationFee = _creationFee;
    }

    function setFeeToken(address _feeToken) external onlyOwner {
        feeToken = ERC20(_feeToken);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    struct GraveInfo {
        string name;
        uint256 birthDate;
        uint256 deathDate;
        string engraver;
        string epitaph;
    }

    mapping(uint256 => address) public getCreator;
    mapping(uint256 => GraveInfo) public getGraveInfo;

    event GiftSent(address indexed user, uint256 indexed tokenId, uint256 giftType, uint256 quantity, uint256 totalCost);
    event GraveCreated(address indexed user, uint256 tokenId, GraveInfo info);
   
    mapping(uint256 => uint256) public getGiftPrice;
    mapping(uint256 => mapping(uint256=>uint256)) public getGiftCount;
    mapping(address => mapping(uint256 => mapping(uint256=>uint256))) public getGiftCountByUser;

    // Set Gift Price
    function setGiftPrice(uint256 typeId, uint256 price) external onlyOwner {
        getGiftPrice[typeId] = price;
    }

    function createGrave(uint256 birthDate, uint256 deathDate, string memory name, string memory engraver, string memory epitaph) external returns(uint256) {
        require(bytes(name).length > 0, 'Name is required!');
        require(bytes(name).length <= 30, 'Name is too long!');
        require(deathDate > birthDate, 'Invalid death date!');

        uint256 tokenId = nft.safeMint(msg.sender);
        getCreator[tokenId] = msg.sender;
        getGraveInfo[tokenId] = GraveInfo({ birthDate: birthDate, deathDate: deathDate, name: name, engraver: engraver, epitaph: epitaph });   
        
        // Fee
        feeToken.safeTransferFrom(address(msg.sender), feeTo, creationFee);

        emit GraveCreated(msg.sender, tokenId, getGraveInfo[tokenId]);
        return tokenId;
    }

    // Send Gift
    function sendGift(uint256 tokenId, uint256 typeId, uint256 quantity) external {
        require(tokenId > 0, 'NFT does not exist!');
        require(tokenId <= nft.totalSupply(), 'NFT does not exist!');
        require(getGiftPrice[typeId] > 0, 'Gift does not exist!');
        require(quantity <= 10000, 'Too many!');

        getGiftCount[tokenId][typeId] += quantity;
        getGiftCountByUser[msg.sender][tokenId][typeId] += quantity;

        // Fee
        uint256 totalCost = getGiftPrice[typeId] * quantity;
        feeToken.safeTransferFrom(address(msg.sender), feeTo, totalCost);
        emit GiftSent(msg.sender, tokenId, typeId, quantity, totalCost);
    }
}
