// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PokeBenKindTypeSetting is Ownable {
    mapping(uint256 => uint256[]) public getTypeByKindAndIndex;
    mapping(uint256 => mapping(uint256=>bool)) public hasType;

    function setTypes(uint256 kind, uint256[] memory types) external onlyOwner {
        resetTypes(kind);
        getTypeByKindAndIndex[kind] = types;
        uint i;
        for(i = 0; i < types.length; i++)
        {
            hasType[kind][types[i]] = true;
        }
    }

    function resetTypes(uint256 kind) private {
        uint256[] storage types = getTypeByKindAndIndex[kind];
        uint i;
        for(i = 0; i < types.length; i++)
        {
            hasType[kind][types[i]] = false;
        }
    }

    function getTypes(uint256 kind) external view returns(uint256[] memory) {
        return getTypeByKindAndIndex[kind];
    }
}
