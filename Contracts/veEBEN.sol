// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/access/Ownable.sol";

contract VeEben is ERC20, Ownable {
    // Constructor to initialize the token with a name and symbol
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // Override transfer function to block transfers
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        revert("Transfers are disabled.");
    }

    // Override transferFrom function to block transfers from another account
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        revert("Transfers are disabled.");
    }

    // Optionally, you can implement a mint function to increase the supply of tokens
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Optionally, you can implement a burn function to decrease the supply of tokens
    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }
}
