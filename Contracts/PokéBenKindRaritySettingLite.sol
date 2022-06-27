// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PokeBenKindRaritySetting is Ownable {
    mapping(uint256 => uint256[]) public getKindByRarityAndIndex;
    mapping(uint256 => uint256) public getRarity;

    function addKind(uint256 rarity, uint256 kindId) external onlyOwner {
        getKindByRarityAndIndex[rarity].push(kindId);
        getRarity[kindId] = rarity;
    }

    function addKinds(uint256 rarity, uint256[] calldata kindIds) external onlyOwner {
        uint i;
        for(i = 0; i < kindIds.length; i++)
        {
            getKindByRarityAndIndex[rarity].push(kindIds[i]);
            getRarity[kindIds[i]] = rarity;
        }
    }

    function setRarity(uint256 rarity, uint256[] calldata kindIds) external onlyOwner {
        getKindByRarityAndIndex[rarity] = kindIds;
        uint i;
        for(i = 0; i < kindIds.length; i++)
        {
            getRarity[kindIds[i]] = rarity;
        }
    }

    function getKindsByRarity(uint256 rarity) external view returns(uint256[] memory) {
        return getKindByRarityAndIndex[rarity];
    }

    function getLengthByRarity(uint256 rarity) external view returns(uint256) {
        return getKindByRarityAndIndex[rarity].length;
    }
}
