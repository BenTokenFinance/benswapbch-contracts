// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/release-v4.4/contracts/token/ERC20/IERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/release-v4.4/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/release-v4.4/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/release-v4.4/contracts/access/Ownable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/release-v4.4/contracts/utils/Strings.sol"; 

contract BlindBoxes is ERC721Enumerable, Ownable {
    using SafeERC20 for IERC20;
    using Strings for uint256;
       
    string private _uri;
    uint256 private counter;
    
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function setURI(string memory newuri) external onlyOwner {
        _uri = newuri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory url=string(abi.encodePacked(_uri, tokenId.toString()));
        return bytes(_uri).length > 0 ? url : "";
    }

    IERC20 public feeToken;
    address public burningAddress;

    function setFeeToken(address _feeToken) external onlyOwner {
        feeToken = IERC20(_feeToken);
    }

    function setBurningAddress(address _feeTo) external onlyOwner {
        burningAddress = _feeTo;
    }

    function burnFee() external onlyOwner {
        feeToken.safeTransfer(burningAddress, feeToken.balanceOf(address(this)));
    }

    uint256 public constant MaxSupply = 200;
    uint256 public constant Price = 99 * 1e18;
    uint256 public constant Reward = 8888 * 1e18;
    address private constant VrfSigner = 0x19Ac81dFE73238699550EfEdB792D5e14f683849;
    string constant private PREFIX = "\x19Ethereum Signed Message:\n40";

    uint64 public claimCount = 0; 
    uint64 public randSeedBlock;
    uint256 public randomSeedForClaim;
    uint256 public openedBoxMask;

    event Minted(address indexed user, uint256 tokenId);
    event Opened(address indexed user, uint256 tokenId, uint256 cardType);
    event Claimed(address indexed user, uint256[] tokenIds);

    mapping(uint256 => bool) public isClaimed;

    constructor(string memory name_, string memory symbol_, string memory uri_) ERC721(name_, symbol_) {
        _uri = uri_;

        counter = 1;
    }

    function getCardType(uint tokenId) public view returns (uint) {
	if((openedBoxMask&(1<<tokenId))==0) return 0;
	return _getCardType(tokenId);
    }

    function _getCardType(uint tokenId) internal view returns (uint) {
        uint i = shuffle_pos(tokenId, MaxSupply);
        if(i < 14) return uint8(0xf&(0x44444333332211>>(i*4))); 
        return (i-14)/31 + 5;
    }


    function mint(address to) public returns(uint256) {
        uint256 tokenId = counter;
        require(tokenId <= MaxSupply, "All minted!");
        
        feeToken.safeTransferFrom(address(msg.sender), address(this), Price);
        _safeMint(to, tokenId);
        counter++;

        emit Minted(to, tokenId);

        if (tokenId == MaxSupply) {
            randSeedBlock = uint64(block.number);
        }

        return tokenId;
    }

    function batchMint(address to, uint256 qty) public returns(uint256[] memory) {
        require(qty > 0, "Invalid qty!");

        uint256 tokenId = counter;
        require(tokenId + qty -1 <= MaxSupply, "Max supply exceeded!");

        feeToken.safeTransferFrom(address(msg.sender), address(this), Price * qty);

        uint256[] memory tokenIds =  new uint256[](qty);
        for (uint i=0; i<qty; i++) {
            _safeMint(to, tokenId+i);
            counter++;
            tokenIds[i] = tokenId+i;
            emit Minted(to, tokenId+i);
        }

        if (tokenId + qty -1 == MaxSupply) {
            randSeedBlock = uint64(block.number);
        }

        return tokenIds;
    }

    function openBox(uint256 tokenId) public returns(uint256) {
        require(randomSeedForClaim > 0, "Not ready!");
        require(ownerOf(tokenId)==msg.sender, "Not owner!");
        uint oldMask = openedBoxMask;
        uint newMask = oldMask|(1<<tokenId);
        require(oldMask!=newMask, "Already opened!");
        openedBoxMask = newMask;

        return _getCardType(tokenId);
    }

    function openBoxes(uint256[] calldata tokenIds) external returns(uint256[] memory) {
        uint256[] memory cardTypes = new uint256[](tokenIds.length);

        for (uint i=0; i<tokenIds.length; i++) {
            cardTypes[i] = openBox(tokenIds[i]);
        }

        return cardTypes;
    }

    function setRandomSeedForClaim(uint256 rdm, uint8 v, bytes32 r, bytes32 s) external {
        require(randSeedBlock > 0, "VRF block not ready!");
        require(randomSeedForClaim == 0, "Already set!");

        bytes32 hash = keccak256(abi.encodePacked(PREFIX, randSeedBlock, rdm));
	    address signer = ecrecover(hash, v, r, s);
        require(signer == VrfSigner, "Invalid Signer");

        randomSeedForClaim = rdm;
    }

    function rotate_pos(uint256 x, uint256 offset, uint256 length) private pure returns(uint256) {
        return (x + length - offset) % length;
    }

    function reverse_pos(uint256 x, uint256 offset) private pure returns(uint256) {
        if (x >= offset) return x;
        return offset - 1 - x;
    }

    function dovetail_pos(uint256 s, uint256 length) private pure returns(uint256) {
        if (s%2 == 0) return s/2;
        return length/2 + length%2 + s/2; 
    }

    function shuffle_pos(uint256 x, uint256 length) private view returns(uint256) {
        uint r = randomSeedForClaim;
        for (uint i=0; i<16; i++) {
            x = rotate_pos(x, r%MaxSupply, length);
            r = r >> 8;
            x = reverse_pos(x, r%MaxSupply);
            r = r >> 8;
            x = dovetail_pos(x, length);
        }
        return x;
    }

    function claim(uint256[] calldata tokenIds) external {
        // tokenIds are already sorted by cardType in the frontend code
        require(tokenIds.length == 10, "Wrong cards!");
        for(uint i=0; i<10; i++) {
            require(ownerOf(tokenIds[i])==msg.sender, "Not owner!");
            require(_getCardType(tokenIds[i])==i+1, "Wrong card type!");
            require(!isClaimed[tokenIds[i]], "Already claimed!");

            isClaimed[tokenIds[i]] = true;
        }

        feeToken.safeTransfer(msg.sender, Reward);
        claimCount++;
        emit Claimed(msg.sender, tokenIds);
    }

    function status() external view returns(uint256) {
        if (counter <= MaxSupply) return 1;    // Selling
        if (randomSeedForClaim <= 0) return 2;    // Awaiting offsetPairs
        if (claimCount < 2) return 3;   // Claiming
        return 4;   // All claimed
    }

}
