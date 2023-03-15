// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

interface IPokeBen {
    function ownerOf(uint256 tokenId) external view returns(address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getPokeBenInfo(uint256 tokenId) external view returns(uint256,uint256,uint256,uint256,uint256);
    function safeMint(address to, uint256 _source, uint256 _kind, uint256 _level, uint256 _basePower) external returns(uint256);
    function burn(uint256 tokenId) external;
}

interface IPokeBenKindRaritySetting {
    function getRarity(uint256 kindId) view external returns (uint256);
    function getKindByRarityAndIndex(uint256 rarity, uint256 index) view external returns (uint256);
    function getLengthByRarity(uint256 rarity) view external returns (uint256);
}

interface IPokeBenKindEvolutionSetting {
    function hasNext(uint256 kindId, uint256 nId) external view returns(bool);
    function getNexts(uint256 kind) external view returns(uint256[] memory);
}

interface IPokeBenPowerExtension {
    function getPower(uint256 tokenId, uint256 basePower) external view returns(uint256);
}

interface IPokeBenAbilityExtension {
    function learn(uint256 tokenId, uint256 slot, uint256 abilityId) external;
    function getAbilities(uint256 tokenId) external view returns(uint256[] memory);
}

interface VrfGovIfc {
    function verify(
        uint256 blockHash,
        uint256 rdm,
        bytes calldata pi
    ) external view returns (bool);
}

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

contract PokeBenEvoluterV1 is ERC721Holder, Ownable {
    using SafeERC20 for IERC20;

    IPokeBen public pokeben;

    IPokeBenKindRaritySetting public pokebenKindRaritySetting;
    IPokeBenKindEvolutionSetting public pokebenEvolutonSetting;

    function setPokeBen(address _pokeben) external onlyOwner {
        pokeben = IPokeBen(_pokeben);
    }
    
    function setPokeBenKindRaritySetting(address _pokebenKindRaritySetting) external onlyOwner {
        pokebenKindRaritySetting = IPokeBenKindRaritySetting(_pokebenKindRaritySetting);
    }

    function setPokeBenEvolutionSetting(address _pokebenEvolutonSetting) external onlyOwner {
        pokebenEvolutonSetting = IPokeBenKindEvolutionSetting(_pokebenEvolutonSetting);
    }

    IERC20 public feeToken;
    address public feeTo;

    function setFeeToken(address _feeToken) external onlyOwner {
        feeToken = IERC20(_feeToken);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }
        
    function rescue(uint256 pokeBenId) external onlyOwner {
        pokeben.safeTransferFrom(address(this), msg.sender, pokeBenId);
    }

    uint256 private constant SCALE = 1e18;
    uint256 private constant HALFSCALE = 1e9;
    address private constant VrfgovAddress = 0x18C51aa3d1F018814716eC2c7C41A20d4FAf023C;
    address private constant CurveAddress = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address private constant DaiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant OneInchAddress = 0x111111111117dC0aa78b770fA6A738034120C302;

    struct EvolutionInfo { 
        uint256 pokeBenId;
        uint256 startBlock;
        uint256 cost;
    }

    mapping(address => EvolutionInfo) public getEvolutionInfo;

    event EvolutionStart(address indexed user, EvolutionInfo info);
    event EvolutionEnd(address indexed user, EvolutionInfo info, uint256 newPokeBenId);

    function startEvolution(uint256 pokeBenId, uint256 cost) external {
        require(pokeben.ownerOf(pokeBenId)==msg.sender, "You are not the owner of that pokeben!");
        require(getPokeBenRarity(pokeBenId)<5, "This pokeben cannot evolve any more!");

        pokeben.safeTransferFrom(msg.sender, address(this), pokeBenId);

        if(cost>0) feeToken.safeTransferFrom(address(msg.sender), feeTo, cost);
        
        getEvolutionInfo[msg.sender] = EvolutionInfo({ pokeBenId: pokeBenId, startBlock: block.number, cost: cost });
        
        emit EvolutionStart(msg.sender, getEvolutionInfo[msg.sender]);
    }

    function getResult(uint256 rdm, bytes calldata pi) external returns(uint256) {
        EvolutionInfo memory info = getEvolutionInfo[msg.sender];
        bytes32 hash = blockhash(info.startBlock);
        require (uint256(hash) > 0, "Invalid block hash!");

        require(VrfGovIfc(VrfgovAddress).verify(uint256(hash), rdm, pi), "Invalid vrf!");
        delete getEvolutionInfo[msg.sender];
        pokeben.burn(info.pokeBenId);

        (,uint256 kindId,,,uint256 power) = pokeben.getPokeBenInfo(info.pokeBenId);
        uint256 rarity = pokebenKindRaritySetting.getRarity(kindId);
        (uint256 successChance,, uint256 totalChance) = getChance(rarity, power, info.cost);
        uint256 rand1 = uint256( keccak256(abi.encodePacked(rdm, info.startBlock, msg.sender, CurveAddress)) );
        uint256 rand2 = uint256( keccak256(abi.encodePacked(rdm, info.startBlock, msg.sender, DaiAddress)) );
        uint256 rand3 = uint256( keccak256(abi.encodePacked(rdm, info.startBlock, msg.sender, OneInchAddress)) );
        rand1 = rand1 % totalChance;

        uint256[] memory nexts = pokebenEvolutonSetting.getNexts(kindId);
        if (nexts.length > 0 && rand1 < (successChance*2/3)) {
            // Evolution
            uint256 index = rand2 % nexts.length;
            uint256 tokenId = mintPokeBen(rand3, msg.sender, rarity+1, nexts[index], 1);
            emit EvolutionEnd(msg.sender, info, tokenId);
            return tokenId;
        }

        if (rand1 < successChance) {
            // Mutation
            uint256 newKind = getRandomKindByRarity(rand2, rarity+1);
            uint256 tokenId = mintPokeBen(rand3, msg.sender, rarity+1, newKind, 2);
            emit EvolutionEnd(msg.sender, info, tokenId);
            return tokenId;
        }

        // Failure
        emit EvolutionEnd(msg.sender, info, 0);
        return 0;
    }

    function getPokeBenRarity(uint256 pokeBenId) public view returns(uint256) {
        (,uint256 kindId,,,) = pokeben.getPokeBenInfo(pokeBenId);
        return pokebenKindRaritySetting.getRarity(kindId);
    }

    function getChance(uint256 rarity, uint256 power, uint256 cost) public pure returns(uint256 successChance, uint256 failureChance, uint256 totalChance) {
        uint256 base = (10**(rarity+1)) * SCALE;
        successChance = (power * SCALE / 10 ) + cost;
        if (successChance > base * 8) {
            failureChance = base * 2;
        } else {
            failureChance = base * 10 - successChance;
        }
        totalChance = successChance + failureChance;
    }
    
    function getRandomKindByRarity(uint256 rand, uint256 rarity) private view returns (uint256) {
        uint256 length = pokebenKindRaritySetting.getLengthByRarity(rarity);
        uint256 index = rand % length;
        return pokebenKindRaritySetting.getKindByRarityAndIndex(rarity, index);
    }

    function mintPokeBen(uint256 rand, address to, uint256 rarity, uint256 kind, uint256 source) private returns (uint256) {
        uint256 s = 10**rarity;
        uint256 power = 80 * s + rand % (40 * s);
        uint256 tokenId = pokeben.safeMint(to, source, kind, 1, power);

        return tokenId;
    }

    function getChanceByKindAndPower(uint256 kindId, uint256 power, uint256 cost) public view returns(uint256 evolutionChance, uint256 mutationChance, uint256 failureChance, uint256 totalChance) {
        uint256 rarity = pokebenKindRaritySetting.getRarity(kindId);
        (uint256 s,uint256 f,uint256 t) = getChance(rarity, power, cost);
        failureChance = f;
        totalChance = t;
        uint256[] memory nexts = pokebenEvolutonSetting.getNexts(kindId);
        if (nexts.length > 0) {
            evolutionChance = s *2 / 3;
            mutationChance = s - evolutionChance;
        } else {
            mutationChance = s;
        }
    }
    
    function getChanceById(uint256 pokeBenId, uint256 cost) external view returns(uint256, uint256, uint256, uint256) {
        (,uint256 kindId,,,uint256 power) = pokeben.getPokeBenInfo(pokeBenId);
        return getChanceByKindAndPower(kindId, power, cost);
    }
}
