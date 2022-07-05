// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PokeBenAbilitySetting is Ownable {
    mapping(uint256 => uint256) public getType;
    mapping(uint256 => uint256) public getRarity;
    mapping(uint256 => uint256) public getPowerBoostBp;

    function setAbility(uint256 aId, uint256 aType, uint256 aRarity, uint256 aPowerBoostBp) external onlyOwner {
        getType[aId] = aType;
        getRarity[aId] = aRarity;
        getPowerBoostBp[aId] = aPowerBoostBp;
    }

    function getAbility(uint256 aId) external view returns(uint256 aType, uint256 aRarity, uint256 aPowerBoostBp) {
        aType = getType[aId];
        aRarity = getRarity[aId];
        aPowerBoostBp = getPowerBoostBp[aId];
    }
}
