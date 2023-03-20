// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


interface IPokeBen {
    function safeMint(address to, uint256 _source, uint256 _kind, uint256 _level, uint256 _basePower) external returns(uint256);
}

interface IPokeBenKindRaritySetting {
    function getKindByRarityAndIndex(uint256 rarity, uint256 index) view external returns (uint256);
    function getLengthByRarity(uint256 rarity) view external returns (uint256);
}

interface VrfGovIfc {
    function verify(
        uint256 blockHash,
        uint256 rdm,
        bytes calldata pi
    ) external view returns (bool);
}

contract PokeBenHuntV2 is Ownable {
    using SafeERC20 for IERC20;

    IPokeBen public pokeben;
    IPokeBenKindRaritySetting public pokebenKindRaritySetting;

    uint256 private constant SCALE = 1e18;
    address private constant VrfgovAddress = 0x18C51aa3d1F018814716eC2c7C41A20d4FAf023C;
    address private constant VitalikButerinAddress = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;

    mapping(address => bool) public getFeeTokenSupported;
    mapping(address => uint256) public getFee;

    mapping(address => bool) public getFeeNftSupported;
    mapping(address => uint256) public getNftHuntCount;

    mapping(address => bool) public getFeeNftN21Supported;
    mapping(address => uint256) public getNftN21Count;

    address public feeTo;

    uint256 public chanceTotal = 10000;
    uint256 public chanceVeryCommon = 4000;
    uint256 public chanceCommon = 1000;
    uint256 public chanceUncommon = 100;
    uint256 public chanceRare = 10;
    uint256 public chanceEpic = 1; 

    struct HuntInfo { 
        uint256 startBlock;
        uint256 count;
    }

    mapping(address => HuntInfo) public getHuntInfo;

    event HuntStart(address indexed user, HuntInfo info);
    event HuntEnd(address indexed user, HuntInfo info, uint256[] caught);

    function setPokeBen(address _pokeben) external onlyOwner {
        pokeben = IPokeBen(_pokeben);
    }

    function setPokeBenKindRaritySetting(address _pokebenKindRaritySetting) external onlyOwner {
        pokebenKindRaritySetting = IPokeBenKindRaritySetting(_pokebenKindRaritySetting);
    }

    function setFee(address tokenAddress, uint256 _fee) external onlyOwner {
        getFee[tokenAddress] = _fee;
    }

    function setFeeTokenSupported(address _feeToken, bool _supported) external onlyOwner {
        getFeeTokenSupported[_feeToken] = _supported;
    }

    function setNftHuntCount(address nftAddress, uint256 _count) external onlyOwner {
        getNftHuntCount[nftAddress] = _count;
    }

    function setFeeNftSupported(address _feeNft, bool _supported) external onlyOwner {
        getFeeNftSupported[_feeNft] = _supported;
    }

    function setNftN21Count(address nftAddress, uint256 _count) external onlyOwner {
        getNftN21Count[nftAddress] = _count;
    }

    function setFeeNftN21Supported(address _feeNft, bool _supported) external onlyOwner {
        getFeeNftN21Supported[_feeNft] = _supported;
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }
    
    function huntWithErc20(address tokenAddress, uint256 count) external {
        require(count <= 10, "Too many times");
        require(getFeeTokenSupported[tokenAddress], "This token is not supported!");
        require(getFee[tokenAddress] > 0, "Fee is not set!");

        IERC20(tokenAddress).safeTransferFrom(address(msg.sender), feeTo, getFee[tokenAddress] * count);
        getHuntInfo[msg.sender] = HuntInfo({ startBlock: block.number, count: count });
        
        emit HuntStart(msg.sender, getHuntInfo[msg.sender]);
    }

    function huntWithErc721(address nftAddress, uint256 nftId) external {
        require(getFeeNftSupported[nftAddress], "This NFT is not supported!");
        require(getNftHuntCount[nftAddress] > 0, "Count is not set!");

        ERC721(nftAddress).safeTransferFrom(address(msg.sender), feeTo, nftId);
        getHuntInfo[msg.sender] = HuntInfo({ startBlock: block.number, count: getNftHuntCount[nftAddress] });
        
        emit HuntStart(msg.sender, getHuntInfo[msg.sender]);
    }

    function huntWithErc721N21(address nftAddress, uint256[] calldata nftIds) external {
        require(getFeeNftN21Supported[nftAddress], "This NFT is not supported!");
        require(getNftN21Count[nftAddress] > 0, "Count is not set!");
        require(getNftN21Count[nftAddress] == nftIds.length, "Count does not match!");

        ERC721 nftToken = ERC721(nftAddress);
        for (uint256 i =0; i< nftIds.length; i++) {
            nftToken.safeTransferFrom(address(msg.sender), feeTo, nftIds[i]);
        }
        getHuntInfo[msg.sender] = HuntInfo({ startBlock: block.number, count: 1 });
        
        emit HuntStart(msg.sender, getHuntInfo[msg.sender]);
    }

    uint256[] private lastCaught;
    function getLastCaught() external view returns(uint256[] memory) {
        return lastCaught;
    }

    function catchPokeBen(uint256 rdm, bytes calldata pi) external returns(uint256[] memory) {
        HuntInfo memory info = getHuntInfo[msg.sender];
        bytes32 hash = blockhash(info.startBlock);
        require (uint256(hash) > 0, "Invalid block hash!");

        require(VrfGovIfc(VrfgovAddress).verify(uint256(hash), rdm, pi), "Invalid vrf!");
        delete getHuntInfo[msg.sender];

        delete lastCaught;

        for (uint256 i =0; i< info.count; i++) {
            uint256 tokenId = catchOnce(rdm, info.startBlock, i, msg.sender);
            if (tokenId > 0) lastCaught.push(tokenId);
        }

        emit HuntEnd(msg.sender, info, lastCaught);

        return lastCaught;
    }

    function catchOnce(uint256 rdm, uint256 height, uint256 index, address to) private returns(uint256) {
        uint256 rand1 = uint256( keccak256(abi.encodePacked(rdm, height, to, index)) );
        uint256 rand2 = uint256( keccak256(abi.encodePacked(rdm, height, to, index, VitalikButerinAddress)) );
        uint256 rand3 = uint256( keccak256(abi.encodePacked(rdm, height, to, index, address(pokeben))) );

        rand1 = rand1 % (chanceTotal * SCALE);
        uint256 runningChance = chanceVeryCommon * SCALE;
        if (rand1 < runningChance) {    // Very Common
            uint256 kind = getRandomKindByRarity(rand2, 0);
            return mintPokeBenByRarityAndKind(rand3, to, 0, kind);
        }
        runningChance += chanceCommon * SCALE;
        if (rand1 < runningChance) {    // Common
            uint256 kind = getRandomKindByRarity(rand2, 1);
            return mintPokeBenByRarityAndKind(rand3, to, 1, kind);
        }
        runningChance += chanceUncommon * SCALE;
        if (rand1 < runningChance) {    // Uncommon
            uint256 kind = getRandomKindByRarity(rand2, 2);
            return mintPokeBenByRarityAndKind(rand3, to, 2, kind);
        }
        runningChance += chanceRare * SCALE;
        if (rand1 < runningChance) {    // Rare
            uint256 kind = getRandomKindByRarity(rand2, 3);
            return mintPokeBenByRarityAndKind(rand3, to, 3, kind);
        }
        runningChance += chanceEpic * SCALE;
        if (rand1 < runningChance) {    // Epic
            uint256 kind = getRandomKindByRarity(rand2, 4);
            return mintPokeBenByRarityAndKind(rand3, to, 4, kind);
        }

        return 0;
    }

    function getRandomKindByRarity(uint256 rand, uint256 rarity) private view returns (uint256) {
        uint256 length = pokebenKindRaritySetting.getLengthByRarity(rarity);
        uint256 index = rand % length;
        return pokebenKindRaritySetting.getKindByRarityAndIndex(rarity, index);
    }

    function mintPokeBenByRarityAndKind(uint256 rand, address to, uint256 rarity, uint256 kind) private returns (uint256) {
        uint256 s = 10**rarity;
        uint256 power = 80 * s + rand % (40 * s);
        uint256 tokenId = pokeben.safeMint(to, 0, kind, 1, power);

        return tokenId;
    }
}
