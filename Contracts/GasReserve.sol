// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/access/Ownable.sol";
contract GasReserve is Ownable{
    constructor() {
    }
    function transferGas(address payable recipient, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance in the contract");
        recipient.transfer(amount);
    }
    receive() external payable {}

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
