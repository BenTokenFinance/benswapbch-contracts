// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PokeBenHeroPartSetting is Ownable {
    struct HeroPart { 
        uint256 id;
        uint256 typeId;
        uint256 rarity;
    }

    mapping(uint256 => HeroPart) public getHeroPartInfo;

    function setData(uint256 itemKind, uint256 heroPartId, uint256 heroPartTypeId, uint256 rarity) external onlyOwner {
        getHeroPartInfo[itemKind] = HeroPart({ id: heroPartId, typeId: heroPartTypeId, rarity: rarity });
    }

    function getHeroPartId(uint256 itemKind) external view returns(uint256) {
        return getHeroPartInfo[itemKind].id;
    }

    function getHeroPartType(uint256 itemKind) external view returns(uint256) {
        return getHeroPartInfo[itemKind].typeId;
    }

    function getHeroPartRarity(uint256 itemKind) external view returns(uint256) {
        return getHeroPartInfo[itemKind].rarity;
    }
}
