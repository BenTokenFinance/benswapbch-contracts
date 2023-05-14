// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface IPokeBenAbilityExtension {
    function getAbilities(uint256 tokenId) external view returns(uint256[] memory);
}

interface IPokeBenAbilitySetting {
    function getPowerBoostBp(uint256 aId) external view returns(uint256);
}

contract PokeBenPowerExtension is Ownable {
    bool private initialized = false;
    function initialize(address newOwner) external {
        require(newOwner != address(0) && !initialized);
        _transferOwnership(newOwner);
        initialized = true;
    }

    function version() external pure returns(uint256){
        return 2;
    }

    IPokeBenAbilityExtension pbae;
    IPokeBenAbilitySetting pbas;

    function setPokeBenAbilityExtension(address _pbae) external onlyOwner {
        pbae = IPokeBenAbilityExtension(_pbae);
    }

    function setIPokeBenAbilitySetting(address _pbas) external onlyOwner {
        pbas = IPokeBenAbilitySetting(_pbas);
    }

    function getPower(uint256 tokenId, uint256 basePower) external view returns(uint256) {
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
