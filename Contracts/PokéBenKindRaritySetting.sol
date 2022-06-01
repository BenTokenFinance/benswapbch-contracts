// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IPokeBen {
    function getKindCount(uint256 kindId) view external returns (uint256);
}

contract PokeBenKindRaritySetting is Ownable {
    IPokeBen public pokeben;

    mapping(uint256 => uint256[]) public getKindByRarityAndIndex;
    mapping(uint256 => uint256) public getRarity;
    mapping(uint256 => uint256) public getLimit;

    function setPokeBen(address _pokeben) external onlyOwner {
        pokeben = IPokeBen(_pokeben);
    }

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

    function setLimit(uint256 kindId, uint256 limit) external onlyOwner {
        getLimit[kindId] = limit;
    }

    function getKindsByRarity(uint256 rarity) external view returns(uint256[] memory) {
        return getKindByRarityAndIndex[rarity];
    }

    function getLengthByRarity(uint256 rarity) external view returns(uint256) {
        return getKindByRarityAndIndex[rarity].length;
    }

    function getAvailableLengthByRarity(uint256 rarity) external view returns(uint256) {
        uint256[] storage arr = getKindByRarityAndIndex[rarity];

        if (rarity == 6) {  // Limited
            uint i;
            uint j;
            for(i = 0; i < arr.length; i++)
            {
                if(pokeben.getKindCount(arr[i])<getLimit[arr[i]])
                {
                    j++;
                }
            }
            return j;
        }

        if (rarity == 7) {  // Unique
            uint i;
            uint j;
            for(i = 0; i < arr.length; i++)
            {
                if(pokeben.getKindCount(arr[i]) == 0)
                {
                    j++;
                }
            }
            return j;
        }

        return arr.length;
    }

    function getAvailableKindsByRarity(uint256 rarity) external view returns(uint256[] memory) {
        uint256[] storage arr = getKindByRarityAndIndex[rarity];

        if (rarity == 6) {  // Limited
            uint256[] memory availLimited1 = new uint256[](arr.length);
            uint i;
            uint j;
            for(i = 0; i < arr.length; i++)
            {
                if(pokeben.getKindCount(arr[i])<getLimit[arr[i]])
                {
                    availLimited1[j++]=arr[i];
                }
            }
            uint256[] memory availLimited2 = new uint256[](j);
            for(i = 0; i < j; i++)
            {
                availLimited2[i] = availLimited1[i];
            }
            return availLimited2;
        }

        if (rarity == 7) {  // Unique
            uint256[] memory availUnique1 = new uint256[](arr.length);
            uint i;
            uint j;
            for(i = 0; i < arr.length; i++)
            {
                if(pokeben.getKindCount(arr[i]) == 0)
                {
                    availUnique1[j++]=arr[i];
                }
            }
            uint256[] memory availUnique2 = new uint256[](j);
            for(i = 0; i < j; i++)
            {
                availUnique2[i] = availUnique1[i];
            }
            return availUnique2;
        }

        return arr;
    }

    function getAvailableKindByRarityAndIndex(uint256 rarity, uint256 index) external view returns(uint256) {
        uint256[] storage arr = getKindByRarityAndIndex[rarity];

        if (rarity == 6) {  // Limited
            uint256[] memory availLimited = new uint256[](arr.length);
            uint i;
            uint j;
            for(i = 0; i < arr.length; i++)
            {
                if(pokeben.getKindCount(arr[i])<getLimit[arr[i]])
                {
                    availLimited[j++]=arr[i];
                }
            }
            require(index<j, "Index is out of bound!");
            return availLimited[index];
        }

        if (rarity == 7) {  // Unique
            uint256[] memory availLimited = new uint256[](arr.length);
            uint i;
            uint j;
            for(i = 0; i < arr.length; i++)
            {
                if(pokeben.getKindCount(arr[i]) == 0)
                {
                    availLimited[j++]=arr[i];
                }
            }
            require(index<j, "Index is out of bound!");
            return availLimited[index];
        }

        require(index<arr.length, "Index is out of bound!");
        return arr[index];
    }
}
