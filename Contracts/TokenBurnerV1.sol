// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract TokenBurnerV1 is Ownable, ERC721Holder {
    using SafeERC20 for ERC20;
    
    function SendErc721(address addr, uint256 id, address to) external onlyOwner {
        ERC721(addr).safeTransferFrom(address(this), to, id);
    }

    function BurnErc721(address addr, uint256 id) external onlyOwner {
        ERC721Burnable(addr).burn(id);
    }

    function Erc20Balance(address addr) external view onlyOwner returns (uint256) {
        return ERC20(addr).balanceOf(address(this));
    } 

    function SendErc20(address addr, address to, uint256 amount) external onlyOwner {
        ERC20(addr).safeTransfer(to, amount);
    } 

    function SendErc20All(address addr, address to) external onlyOwner {
        ERC20 token = ERC20(addr);
        token.safeTransfer(to, token.balanceOf(address(this)));
    } 

    function BurnErc20(address addr, uint256 amount) external onlyOwner {
        ERC20Burnable(addr).burn(amount);
    } 

    function BurnErc20All(address addr) external onlyOwner {
        ERC20Burnable(addr).burn(ERC20(addr).balanceOf(address(this)));
    } 
}
