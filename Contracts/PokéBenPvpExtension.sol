// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/release-v4.4/contracts/access/Ownable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/release-v4.4/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface IPokeBen {
    function ownerOf(uint256 tokenId) external view returns(address);
    function getPokeBenInfo(uint256 tokenId) external view returns(uint256,uint256,uint256,uint256,uint256);
}

interface IPokeBenHero {
    function ownerOf(uint256 tokenId) external view returns(address);
    function getHeroParts(uint256 tokenId, uint256 maxParts) external view returns (uint256[] memory);
    function getHeroStats(uint256 tokenId, uint256 maxStats) external view returns (string[] memory);
}

interface IPokeBenAbilityExtension {
    function getAbilities(uint256 tokenId) external view returns(uint256[] memory);
}

interface IPokeBenNftNameExtension {
    function getName(uint256 tokenId) external view returns(string memory);
}

interface IPokeBenTeamExtension {
    function getName(address owner) external view returns(string memory);
    function getStatus(address owner) external view returns(string memory);
    function getHeroAndTeam(address owner) external view returns(uint256, uint256[] memory);
    function getTeamIdByUser(address owner) external view returns(uint256);
}

contract PokeBenPvpExtension is Ownable {
    bool private initialized = false;
    function initialize(address newOwner) external {
        require(newOwner != address(0) && !initialized);
        _transferOwnership(newOwner);
        initialized = true;
    }

    function version() external pure returns(uint256){
        return 2;
    }

    IPokeBen pb;
    IPokeBenAbilityExtension pbae;
    IPokeBenNftNameExtension pbne;
    IPokeBenTeamExtension pbte;

    struct PokeBenPvpInfo { 
        uint256 tokenId;
        uint256 kind;
        uint256 level;
        uint256 basePower;
        uint256 power;
        string name;
        uint256[] abilities;
    }

    struct PokeBenPvpTeam {
        uint256 teamId;
        address user;
        string name;
        string status;
        PokeBenPvpInfo[] team;
        uint256 heroId;
        uint256[] heroParts;
        string[] heroStats;
    }

    function setPokeBenAbilityExtension(address _pbae) external onlyOwner {
        pbae = IPokeBenAbilityExtension(_pbae);
    }

    function setPokeBen(address _pb) external onlyOwner {
        pb = IPokeBen(_pb);
    }

    function setPokeBenNftNameExtension(address _pbne) external onlyOwner {
        pbne = IPokeBenNftNameExtension(_pbne);
    }

    function setPokeBenTeamExtension(address _pbte) external onlyOwner {
        pbte = IPokeBenTeamExtension(_pbte);
    }
    

    function getPvpInfoById(uint256 tokenId) public view returns(PokeBenPvpInfo memory) {
        (,uint256 kindId,uint256 level,uint256 basePower,uint256 power) = pb.getPokeBenInfo(tokenId);
        uint256[] memory abilities = pbae.getAbilities(tokenId);
        string memory name = pbne.getName(tokenId);

        return (PokeBenPvpInfo({ tokenId:tokenId, kind:kindId, level:level, basePower:basePower, power:power, name:name, abilities:abilities }));
    }

    function getPvpInfosByIds(uint256[] memory tokenIds) public view returns(PokeBenPvpInfo[] memory pokebens) {
        pokebens = new PokeBenPvpInfo[](tokenIds.length);

        for (uint i = 0; i<tokenIds.length; i++) {
            pokebens[i] = getPvpInfoById(tokenIds[i]);
        }
    }

    function getTeamByUser(address user) public view returns(PokeBenPvpTeam memory) {
        string memory name = pbte.getName(user);
        string memory status = pbte.getStatus(user);
        uint256 teamId = pbte.getTeamIdByUser(user);
        (uint256 heroId, uint256[] memory tokenIds) = pbte.getHeroAndTeam(user);
        PokeBenPvpInfo[] memory team = getPvpInfosByIds(tokenIds);

        if (heroId > 0) {
            uint256[] memory heroParts = pbh.getHeroParts(heroId, 7);
            string[] memory heroStats = pbh.getHeroStats(heroId, 7);

            return PokeBenPvpTeam({name:name, status:status, team: team, user: user, teamId: teamId, heroId: heroId, heroParts: heroParts, heroStats: heroStats});
        }

        return PokeBenPvpTeam({name:name, status:status, team: team, user: user, teamId: teamId, heroId: heroId, heroParts: new uint[](0), heroStats: new string[](0)});
    }

    function getTeamsByUsers(address[] memory users) public view returns(PokeBenPvpTeam[] memory teams) {
        teams = new PokeBenPvpTeam[](users.length);

        for (uint i = 0; i<users.length; i++) {
            teams[i] = getTeamByUser(users[i]);
        }
    }

    function getPokeBens(uint256[] memory tokenIds) external view returns(uint256 height, uint256 timestamp, PokeBenPvpInfo[] memory pokebens) {
        height = block.number;
        timestamp = block.timestamp;
        pokebens = getPvpInfosByIds(tokenIds);
    }

    function getTeams(address[] memory users) external view returns(uint256 height, uint256 timestamp, PokeBenPvpTeam[] memory teams) {
        height = block.number;
        timestamp = block.timestamp;
        teams = getTeamsByUsers(users);
    }

    // Version 2
    IPokeBenHero pbh;
    function setPokeBenHero(address _pbh) external onlyOwner {
        pbh = IPokeBenHero(_pbh);
    }
}
