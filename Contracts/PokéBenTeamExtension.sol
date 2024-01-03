// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/release-v4.4/contracts/access/Ownable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/release-v4.4/contracts/token/ERC721/ERC721.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/release-v4.4/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";


contract PokeBenTeamExtension is Ownable {
    bool private initialized = false;
    function initialize(address newOwner) external {
        require(newOwner != address(0) && !initialized);
        _transferOwnership(newOwner);
        initialized = true;
    }

    function version() external pure returns(uint256) {
        return 2;
    }

    ERC721 public pokeben;
    ERC721 public hero;

    function setPokeBen(address _pb) external onlyOwner {
        pokeben = ERC721(_pb);
    }

    function setHero(address _h) external onlyOwner {
        hero = ERC721(_h);
    }

    uint256 public total;

    event NameChaned(address indexed user, string name);
    event StatusChanged(address indexed user, string status);
    event TeamChanged(address indexed user, uint256[] team);
    event HeroChanged(address indexed user, uint256 heroId);
    event UserAdded(address indexed user, uint256 teamId);

    mapping(address => string) public getName;
    mapping(address => string) public getStatus;
    mapping(address => uint256) public getHero;
    mapping(address => uint256[]) private _getTeam;
    mapping(address => uint256) public getTeamIdByUser;
    mapping(uint256 => address) public getUserByTeamId;

    function addUser(address user) private {
        if (getTeamIdByUser[user]==0) {
            total ++;
            getTeamIdByUser[user] = total;
            getUserByTeamId[total] = user;
            emit UserAdded(user, total);
        }
    }

    function getTeam(address owner) public view returns(uint256[] memory){
        uint256[] memory team = _getTeam[owner];
        uint256 count = 0;
        uint256[] memory valid = new uint256[](team.length);

        for(uint i = 0; i <team.length; i++) {
            try pokeben.ownerOf(team[i]) returns (address o) {
                if (o == owner) {
                    valid[i] = team[i];
                    count++;
                }
            } catch (bytes memory /*lowLevelData*/) { }
        }

        uint256[] memory corrected = new uint256[](count);
        uint256 index = 0;

        for (uint j=0; j<valid.length; j++) {
            if (valid[j] > 0) {
                corrected[index++] = valid[j];
            }
        }

        return corrected;
    }

    function _name(address user, string memory name) private {
        require(bytes(name).length <=30, 'Name is too long!');
        getName[user] = name;
        emit NameChaned(user, name);
        addUser(user);
    }

    function _status(address user, string memory status) private {
        require(bytes(status).length <=300, 'Status is too long!');
        getStatus[user] = status;
        emit StatusChanged(user, status);
        addUser(user);
    }

    function _team(address user, uint256[] memory team) private {
        require(team.length <=5, 'Too many team members');

        for(uint i = 0; i <team.length; i++) {
            require(pokeben.ownerOf(team[i])==user, 'Not owner!');
        }

        _getTeam[user] = team;
        emit TeamChanged(user, team);
        addUser(user);
    }

    function _hero(address user, uint256 tokenId) private {
        require(tokenId == 0 || hero.ownerOf(tokenId)==user, 'Not Owner!');

        getHero[user] = tokenId;
        emit HeroChanged(user, tokenId);
        addUser(user);
    }

    function changeName(string memory name) public {
        _name(msg.sender, name);
    }

    function changeStatus(string memory status) public {
        _status(msg.sender, status);
    }

    function changeTeam(uint256[] memory team) public {
        _team(msg.sender, team);
    }

    function changeHero(uint256 tokenId) public {
        _hero(msg.sender, tokenId);
    }

    function change1(string memory name, string memory status) public {
        _name(msg.sender, name);
        _status(msg.sender, status);
    }

    function change2(string memory name, string memory status, uint256[] memory team) public {
        _name(msg.sender, name);
        _status(msg.sender, status);
        _team(msg.sender, team);
    }

    function change3(string memory name, string memory status, uint256[] memory team, uint256 heroId) public {
        _name(msg.sender, name);
        _status(msg.sender, status);
        _team(msg.sender, team);
        _hero(msg.sender, heroId);
    }

    // Version 2
    function getHeroAndTeam(address owner) external view returns(uint256 heroId, uint256[] memory team){
        if (getHero[owner] > 0) {
            try hero.ownerOf(getHero[owner]) returns (address o) {
                if (o == owner) {
                    heroId = getHero[owner];
                }
            } catch (bytes memory /*lowLevelData*/) { }
        }

        team = getTeam(owner);
    }
}
