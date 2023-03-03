// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract PokeBenAbilityExtension is AccessControl {
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    event AbilityLearned(uint256 indexed tokenId, uint256 slot, uint256 abilityId);

    mapping(uint256 => uint256[]) public getAbilityByIdAndIndex;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPDATER_ROLE, msg.sender);
    }

    function learn(uint256 tokenId, uint256 slot, uint256 abilityId) external onlyRole(UPDATER_ROLE) {
        require(slot < 10, 'Invalid slot!');

        if (getAbilityByIdAndIndex[tokenId].length < 10 ) {
            // Init array
            getAbilityByIdAndIndex[tokenId] = [0,0,0,0,0,0,0,0,0,0];
        }
        
        getAbilityByIdAndIndex[tokenId][slot] = abilityId;

        emit AbilityLearned(tokenId, slot, abilityId);
    }

    function getAbilities(uint256 tokenId) external view returns(uint256[] memory) {
        return getAbilityByIdAndIndex[tokenId];
    }

    function getAbility(uint256 tokenId, uint256 slot) external view returns(uint256) {
        require(slot <10, 'Invalid slot!');

        if (getAbilityByIdAndIndex[tokenId].length>slot) return getAbilityByIdAndIndex[tokenId][slot];
        return 0;
    }
}
