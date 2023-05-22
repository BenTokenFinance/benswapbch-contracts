// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract PokeBenMultipurposeExtension is AccessControl {
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    bool private initialized = false;
    function initialize(address newOwner) external {
        require(newOwner != address(0) && !initialized);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _grantRole(UPDATER_ROLE, newOwner);
        initialized = true;
    }

    function version() external pure returns(uint256){
        return 1;
    }

    event MaxSlotsUpdated(uint256 indexed tokenId, uint256 newMaxSlots);

    mapping(uint256 => uint256) private maxSlots;

    function getMaxSlots(uint256 pokeBenId) external view returns(uint256) {
        uint256 max = maxSlots[pokeBenId];

        return max >= 4 ? max : 4;
    }

    function updateSlots(uint256 pokeBenId, uint256 newMaxSlots) external onlyRole(UPDATER_ROLE) {
        require(newMaxSlots<=10, "too many!");
        maxSlots[pokeBenId] = newMaxSlots;

        emit MaxSlotsUpdated(pokeBenId, newMaxSlots);
    }
}
