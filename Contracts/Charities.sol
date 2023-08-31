// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

pragma solidity ^0.8.4;
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.8.4;
contract Charities is Ownable {
    address public EBENAddress;
    mapping(address => bool) public whitelist;
    mapping(address => uint256 ) public getTotalDonation;
    mapping(address => mapping(address => uint256)) public getTotalDonationByCharity;

    event donated(address indexed user, address indexed charity, uint256 amount);

    bool private initialized = false;
    function initialize(address newOwner) external {
        require(newOwner != address(0) && !initialized);
        _transferOwnership(newOwner);
        EBENAddress = 0x77CB87b57F54667978Eb1B199b28a0db8C8E1c0B;
        initialized = true;
    }

    function version() external pure returns(uint256){
        return 2;
    }
      

    function donate(address charity, uint256 amount) external {
        require(amount>0,"Amount is zero");
        require(whitelist[charity],"Not whitelisted");
        getTotalDonation[msg.sender]+=amount;
        getTotalDonationByCharity[msg.sender][charity]+=amount;
        IBEP20 EBENContract=IBEP20(EBENAddress);
        EBENContract.transferFrom(msg.sender,charity,amount);
        emit donated(msg.sender,charity,amount);
    }

    function addWhitelist(address[] memory addressList) external onlyOwner{
        for(uint256 i=0;i<addressList.length;i++){
            whitelist[addressList[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory addressList) external onlyOwner{
        for(uint256 i=0;i<addressList.length;i++){
            whitelist[addressList[i]] = false;
        }
    }
}