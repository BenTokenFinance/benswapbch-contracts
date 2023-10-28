// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

interface VrfGovIfc {
    function verify (
        uint256 blockHash,
        uint256 rdm,
        bytes calldata pi
    ) external view returns (bool);
}

contract BlindBoxes is ERC721, ERC721Enumerable, Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
       
    string private _uri;
    
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

    uint256 public maxSupply = 200;
    uint256 public price = 99 * 1e18;
    uint256 public reward = 8888 * 1e18;
    uint256 public claimCount = 0;

    event Minted(address indexed user, uint256 tokenId);
    event OffsetPairsSet(address indexed user, uint256[] offsetPairs);
    event Opened(address indexed user, uint256 tokenId, uint256 cardType);
    event Claimed(address indexed user, uint256 reward, uint256[] tokenIds);

    uint256[] unshuffled = [1,1,2,2,3,3,3,3,3,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10];
    mapping(uint256 => uint256) public getCardType;
    mapping(uint256 => bool) public isClaimed;

    constructor(string memory name_, string memory symbol_, string memory uri_) ERC721(name_, symbol_) {
        _uri = uri_;

        _tokenIdCounter.increment();   // skip 0
    }

    address private constant VrfgovAddress = 0x18C51aa3d1F018814716eC2c7C41A20d4FAf023C;
    uint256 public vrfBlock;
    function overrideVrfBlock() external onlyOwner {
        require(_tokenIdCounter.current() > maxSupply, "Not all minted!");
        require(offsetPairs.length == 0, "Already set!");

        // In the rare cases when the backend bot failed to set offsetPairs in time, this is maybe necessary.
        vrfBlock = block.number;
    }

    function mint(address to) public returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= maxSupply, "All minted!");
        
        feeToken.safeTransferFrom(address(msg.sender), address(this), price);
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();

        emit Minted(to, tokenId);

        if (tokenId == maxSupply) {
            vrfBlock = block.number;
        }

        return tokenId;
    }

    function batchMint(address to, uint256 qty) public returns(uint256[] memory) {
        require(qty > 0, "Invalid qty!");

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId + qty -1 <= maxSupply, "Max supply exceeded!");

        feeToken.safeTransferFrom(address(msg.sender), address(this), price * qty);

        uint256[] memory tokenIds =  new uint256[](qty);
        for (uint i=0; i<qty; i++) {
            _safeMint(to, tokenId+i);
            _tokenIdCounter.increment();
            tokenIds[i] = tokenId+i;
            emit Minted(to, tokenId+i);
        }

        if (tokenId + qty -1 == maxSupply) {
            vrfBlock = block.number;
        }

        return tokenIds;
    }

    uint256[] public offsetPairs;
    function setOffsetParis(uint256 rdm, bytes calldata pi) external {
        require(vrfBlock > 0, "VRF block not ready!");
        require(offsetPairs.length == 0, "Already set!");

        bytes32 hash = blockhash(vrfBlock);
        require (uint256(hash) > 0, "Invalid block hash!");
        require(VrfGovIfc(VrfgovAddress).verify(uint256(hash), rdm, pi), "Invalid vrf!");

        for (uint i=0; i<16; i++) {
            offsetPairs.push(uint256( keccak256(abi.encodePacked(rdm, address(this), vrfBlock, i)) ) % maxSupply);
        }

        emit OffsetPairsSet(msg.sender, offsetPairs);
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
        for (uint i=0; i<offsetPairs.length; i=i+2) {
            x = rotate_pos(x, offsetPairs[i], length);
            x = reverse_pos(x, offsetPairs[i+1]);
            x = dovetail_pos(x, length);
        }
        return x;
    }

    function openBox(uint256 tokenId) external returns(uint256) {
        require(offsetPairs.length > 0, "Not ready!");
        require(ownerOf(tokenId)==msg.sender, "Not owner!");
        require(getCardType[tokenId]==0, "Already opened!");

        uint256 cardType = unshuffled[shuffle_pos(tokenId, maxSupply)];
        getCardType[tokenId] = cardType;
        return cardType;
    }

    function claim(uint256[] calldata tokenIds) external {
        // tokenIds are already sorted by cardType in the frontend code
        require(tokenIds.length == 10, "Wrong cards!");
        for(uint i=0; i<10; i++) {
            require(ownerOf(tokenIds[i])==msg.sender, "Not owner!");
            require(getCardType[tokenIds[i]]==i+1, "Wrong card type!");
            require(!isClaimed[tokenIds[i]], "Already claimed!");

            isClaimed[tokenIds[i]] = true;
        }

        feeToken.safeTransfer(msg.sender, reward);
        claimCount++;
        emit Claimed(msg.sender, reward, tokenIds);
    }

    function status() external view returns(uint256) {
        if (_tokenIdCounter.current() <= maxSupply) return 1;    // Selling
        if (offsetPairs.length == 0) return 2;    // Awaiting offsetPairs
        if (claimCount < 2) return 3;   // Claiming
        return 4;   // All claimed
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
