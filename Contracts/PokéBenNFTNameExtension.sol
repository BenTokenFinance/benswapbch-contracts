// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IPokeBen {
    function ownerOf(uint256 tokenId) external view returns(address);
}

contract PokeBenNftNameExtension {
    IPokeBen public pokeben;

    event ChangeName(uint256 indexed tokenId, address indexed user, string name);

    mapping(uint256 => string) public getName;

    constructor(IPokeBen _pokeben) {
        pokeben = _pokeben;
    }

    function rename(uint256 tokenId, string memory name) external {
        require(bytes(name).length <=30, 'Name is too long!');
        require(pokeben.ownerOf(tokenId)==msg.sender, 'You are not the owner of that NFT!');

        getName[tokenId] = name;
        emit ChangeName(tokenId, msg.sender, name);
    }
}
