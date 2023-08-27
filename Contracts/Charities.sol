// SPDX-License-Identifier: GPL-3.0

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
contract Charities {
    address public owner;
    address[] public whitelist;

    address public EBENAddress = 0x77CB87b57F54667978Eb1B199b28a0db8C8E1c0B;
    //test eben
    // address public EBENAddress = 0x77beB0D017C743eCa0d22951A3b051A17D50f108;

    mapping(address => uint256 ) public getTotalDonation;
    mapping(address => mapping(address => uint256)) public getTotalDonationByCharity;
    event donated(address indexed user, address indexed charity, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(){
        owner=msg.sender;
    }
      

    function donate(uint256 amount,address charity) external{
        require(isWhitelist(charity),"Not whitelist");
        getTotalDonation[msg.sender]+=amount;
        getTotalDonationByCharity[msg.sender][charity]+=amount;
        IBEP20 EBENContract=IBEP20(EBENAddress);
        EBENContract.transferFrom(msg.sender,charity,amount);
        emit donated(msg.sender,charity,amount);
    }

    function addWhitelist(address[] memory addressList) external onlyOwner{
        for(uint256 i=0;i<addressList.length;i++){
            address addr=addressList[i];
            if(!isWhitelist(addr)){
               whitelist.push(addr);
            }
        }
    }

    function removeFromWhitelist(address[] memory addressList) external onlyOwner{
        for(uint256 i=0;i<addressList.length;i++){
            address addr=addressList[i];

            for(uint256 j=0;j<whitelist.length;j++){
                if(whitelist[j]==addr){
                   whitelist[j]= whitelist[whitelist.length-1];
                   whitelist.pop();
                   break;
                }
            }
        }
    }

    function isWhitelist(address user) public view returns(bool){
        for(uint256 i=0;i<whitelist.length;i++){
            if(whitelist[i]==user){
              return true;
            }
        }
        return false;
    }
}