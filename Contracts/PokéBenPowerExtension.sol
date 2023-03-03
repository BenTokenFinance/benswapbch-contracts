// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IPokeBenPowerExtension {
    function getPower(uint256 tokenId, uint256 basePower) external view returns(uint256);
}

interface IPokeBenAbilityExtension {
    function getAbilities(uint256 tokenId) external view returns(uint256[] memory);
}

interface IPokeBenAbilitySetting {
    function getPowerBoostBp(uint256 aId) external view returns(uint256);
}

contract PokeBenPowerExtensionV1 is IPokeBenPowerExtension {
    function getPower(uint256, uint256 basePower) external override pure returns(uint256) {
        return basePower;
    }
}

// With Ability Support
contract PokeBenPowerExtensionV2 is IPokeBenPowerExtension, Ownable {
    IPokeBenAbilityExtension pbae;
    IPokeBenAbilitySetting pbas;

    function setPokeBenAbilityExtension(address _pbae) external onlyOwner {
        pbae = IPokeBenAbilityExtension(_pbae);
    }

    function setIPokeBenAbilitySetting(address _pbas) external onlyOwner {
        pbas = IPokeBenAbilitySetting(_pbas);
    }

    function getPower(uint256 tokenId, uint256 basePower) external override view returns(uint256) {
        uint256[] memory abilities = pbae.getAbilities(tokenId);
        uint256 multiplierBp = 10000;
        uint i;
        for(i = 0; i < abilities.length; i++)
        {
            multiplierBp += pbas.getPowerBoostBp(abilities[i]);
        }

        return basePower * multiplierBp / 10000;
    }
}
