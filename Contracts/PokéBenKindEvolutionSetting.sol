// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PokeBenKindEvolutionSetting is Ownable {
    mapping(uint256 => uint256[]) public getNextByKindAndIndex;
    mapping(uint256 => mapping(uint256=>bool)) public hasNext;

    function setNexts(uint256 kind, uint256[] memory nexts) external onlyOwner {
        resetNexts(kind);
        getNextByKindAndIndex[kind] = nexts;
        uint i;
        for(i = 0; i < nexts.length; i++)
        {
            hasNext[kind][nexts[i]] = true;
        }
    }

    function resetNexts(uint256 kind) private {
        uint256[] storage nexts = getNextByKindAndIndex[kind];
        uint i;
        for(i = 0; i < nexts.length; i++)
        {
            hasNext[kind][nexts[i]] = false;
        }
    }

    function getNexts(uint256 kind) external view returns(uint256[] memory) {
        return getNextByKindAndIndex[kind];
    }
}
