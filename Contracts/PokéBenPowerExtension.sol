// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPokeBenPowerExtension {
    function getPower(uint256 tokenId, uint256 basePower) external view returns(uint256);
}

contract PokeBenPowerExtensionV1 is IPokeBenPowerExtension {
    function getPower(uint256, uint256 basePower) external override pure returns(uint256) {
        return basePower;
    }
}
