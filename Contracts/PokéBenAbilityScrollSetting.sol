// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PokeBenAbilityScrollSetting is Ownable {
    mapping(uint256 => uint256) public getAbility;

    function setAbility(uint256 sId, uint256 aId) external onlyOwner {
        getAbility[sId] = aId;
    }
}
