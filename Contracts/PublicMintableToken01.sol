// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/release-v4.4/contracts/token/ERC20/ERC20.sol";

contract PublicMintableToken01 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}