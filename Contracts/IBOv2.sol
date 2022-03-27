// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


pragma solidity ^0.6.0;




/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}


pragma solidity >=0.4.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity 0.6.12;

interface IIboV2Concluder {
    // 0 = Running;  999 = Concluded;  Anything in between = Concluding;
    function status() external view returns (uint256);

    function name() external view returns (string memory);
    function template() external view returns (address);

    function raisingToken() external view returns (address);
    function offeringToken() external view returns (address);
    function ibo() external view returns (address);
    function owner() external view returns (address);

    // Used by the IBO to add the other concluder and then it can trigger token transfer if needed.
    function addWhitelist(address target) external;     
    function transfer(address token, address recipient, uint256 amount) external;

    // function initialize0(...) external;   // This has dynamic arguments
    // function initialize(...) external;   // This has dynamic arguments
    function conclude() external;
}

interface IIboV2ConcluderTemplate {
    function createConcluder(address ibo, address raisingToken, address offeringToken, address owner, bytes memory callData) external returns (address);
}

contract IBOv2 {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // The raising token
    IBEP20 public raisingToken;
    // The offering token
    IBEP20 public offeringToken;
    // the price (offeringToken per raisingToken)
    uint256 public price;
    // factory address
    address public factory;
    // admin address
    address public adminAddress;

    // conditions
    uint256 public minBlock;
    uint256 public minTimestamp;
    uint256 public minSold;
    bool public conditionsSet;

    // concluders
    IIboV2Concluder public raisingTokenConcluder;
    IIboV2Concluder public offeringTokenConcluder;
    // sold
    uint256 public sold;

    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut);

    function raisingTokenConcluderTemplate() external view returns(address) {
        return raisingTokenConcluder.template();
    }

    function offeringTokenConcluderTemplate() external view returns(address) {
        return offeringTokenConcluder.template();
    }

    // 0 = Running;  999 = Concluded;  Anything in between = Concluding;
    function status() public view returns(uint256) {
        uint256 status1 = raisingTokenConcluder.status();
        uint256 status2 = offeringTokenConcluder.status();

        if (status1==status2) {
            return status1;
        } else if (status1 >= 999 && status2 >= 999) {
            return 999;
        }

        return 100;
    }

    function isConcluded() public view returns(bool) {
        return status() >= 999;
    }
    
    function isActive() public view returns(bool) {
        return status() == 0;
    }

    function canConclude() public view returns(bool) {
        return (block.number >= minBlock) && (block.timestamp >= minTimestamp) && (sold >= minSold);
    }

    constructor() public {
        factory = msg.sender;

        conditionsSet = false;
    }

    // called once by the factory
    function initialize(
        address rasing, 
        address offering, 
        uint256 _price, 
        address _adminAddress, 
        address _raisingTokenConcluder, 
        address _offeringTokenConcluder
    ) external {
        require(msg.sender == factory, 'BenSwap: FORBIDDEN'); // sufficient check
        require(_price > 0, 'Invalid price!');
        
        raisingToken = IBEP20(rasing);
        offeringToken = IBEP20(offering);
        price = _price;
        adminAddress = _adminAddress;

        raisingTokenConcluder = IIboV2Concluder(_raisingTokenConcluder);
        raisingTokenConcluder.addWhitelist(_offeringTokenConcluder);
        offeringTokenConcluder = IIboV2Concluder(_offeringTokenConcluder);
        offeringTokenConcluder.addWhitelist(_raisingTokenConcluder);

        sold = 0;

        minBlock = 0;
        minTimestamp = 0;
        minSold = 0;
    }

    function balance()
        public
        view
        returns (uint256)
    {
        return offeringToken.balanceOf(address(offeringTokenConcluder));
    }

    function swap(uint256 _amount) external {
        require(isActive(), 'Not active!');

        uint256 result = _amount.mul(price).div(1e28);
        require(balance() >= result, 'Not enough balance!');
       
        raisingToken.safeTransferFrom(address(msg.sender), address(raisingTokenConcluder), _amount);
        offeringTokenConcluder.transfer(address(offeringToken), address(msg.sender), result);

        sold = sold.add(result);

        emit Swap(msg.sender, _amount, result);
    }

    function conclude() external {
        require(adminAddress == msg.sender, 'caller must be the admin!');
        require(canConclude(), 'conditions not met!');

        if (offeringTokenConcluder.status() < 999) {
            offeringTokenConcluder.conclude();
        }

        if (raisingTokenConcluder.status() < 999) {
            raisingTokenConcluder.conclude();
        }
    }

    function setMinBlock(uint256 _minBlock) external {
        require(adminAddress == msg.sender, 'caller must be the admin!');
        require(!conditionsSet, 'already set!');

        minBlock = _minBlock;
    }

    function setMinTimestamp(uint256 _minTimestamp) external {
        require(adminAddress == msg.sender, 'caller must be the admin!');
        require(!conditionsSet, 'already set!');

        minTimestamp = _minTimestamp;
    }

    function setMinSold(uint256 _minSold) external {
        require(adminAddress == msg.sender, 'caller must be the admin!');
        require(!conditionsSet, 'already set!');

        minSold = _minSold;
    }

    function setConditionsInStone() external {
        require(adminAddress == msg.sender, 'caller must be the admin!');

        conditionsSet = true;
    }
}

contract IBOv2Factory {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    IBEP20 public feeToken;
    address public feeTo;
    uint256 public creationFee;
    address public adminAddress;
    uint256 public count;

    mapping(address => bool) public offeringTokenConclusionStrategy;
    mapping(address => bool) public raisingTokenConclusionStrategy;

    mapping(address => address[]) public getIBOs;
    mapping(address => address) public getCreator;
    mapping(uint256 => address) public getIboByIndex;

    event IBOCreated(address indexed raisingToken, address indexed offeringToken, address indexed creator, address ibo);

    constructor(address _admin, IBEP20 _feeToken, address _feeTo, uint256 _creationFee) public {
        adminAddress = _admin;
        feeToken = _feeToken;
        feeTo = _feeTo;
        creationFee = _creationFee;
    }

    function setAdminTo(address _To) external {
        require(msg.sender == adminAddress, 'BenSwap: FORBIDDEN');
        adminAddress = _To;
    }

    function setCreationFee(uint256 _creationFee) external {
        require(msg.sender == adminAddress, 'BenSwap: FORBIDDEN');
        creationFee = _creationFee;
    }

    function setFeeToken(address _feeToken) external {
        require(msg.sender == adminAddress, 'BenSwap: FORBIDDEN');
        feeToken = IBEP20(_feeToken);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == adminAddress, 'BenSwap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function getIBOCount(address _add) external view returns (uint256) {
        return getIBOs[_add].length;
    }

    function addOfferingTokenConclusionStrategy(address _t) external {
        require(msg.sender == adminAddress, 'BenSwap: FORBIDDEN');
        offeringTokenConclusionStrategy[_t] = true;
    }

    function removeOfferingTokenConclusionStrategy(address _t) external {
        require(msg.sender == adminAddress, 'BenSwap: FORBIDDEN');
        offeringTokenConclusionStrategy[_t] = false;
    }

    function addRaisingTokenConclusionStrategy(address _t) external {
        require(msg.sender == adminAddress, 'BenSwap: FORBIDDEN');
        raisingTokenConclusionStrategy[_t] = true;
    }

    function removeRaisingTokenConclusionStrategy(address _t) external {
        require(msg.sender == adminAddress, 'BenSwap: FORBIDDEN');
        raisingTokenConclusionStrategy[_t] = false;
    }

    function createIBO(
        address raisingToken, 
        address offeringToken, 
        address _raisingTokenConclusionStrategy, 
        address _offeringTokenConclusionStrategy,
        uint256 _price, 
        uint256 amount,
        bytes memory rtcsCallData,
        bytes memory otcsCallData
    ) external returns (address ibo) {
        require(raisingTokenConclusionStrategy[_raisingTokenConclusionStrategy], 'error: _raisingTokenConclusionStrategy not registered!');
        require(offeringTokenConclusionStrategy[_offeringTokenConclusionStrategy], 'error: _offeringTokenConclusionStrategy not registered');

        // Create IBO
        bytes memory bytecode = type(IBOv2).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, getIBOs[msg.sender].length));
        assembly {
            ibo := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Offering token strategy
        address offeringTokenConcluder = IIboV2ConcluderTemplate(_offeringTokenConclusionStrategy).createConcluder(ibo, raisingToken, offeringToken, msg.sender, otcsCallData);
        
        // Raising token strategy
        address raisingTokenConcluder = IIboV2ConcluderTemplate(_raisingTokenConclusionStrategy).createConcluder(ibo, raisingToken, offeringToken, msg.sender, rtcsCallData);

        // Initialize IBO
        IBOv2(ibo).initialize(raisingToken, offeringToken, _price, msg.sender, raisingTokenConcluder, offeringTokenConcluder);

        // creation fee
        feeToken.safeTransferFrom(address(msg.sender), feeTo, creationFee);

        // initial token amount, can be added simply by sending more to the offeringTokeembernConcluder contract
        TransferHelper.safeTransferFrom(offeringToken, msg.sender, offeringTokenConcluder, amount);

        getIBOs[msg.sender].push(ibo);
        getCreator[ibo] = address(msg.sender);
        getIboByIndex[count] = ibo;
        count = count + 1;

        emit IBOCreated(raisingToken, offeringToken, msg.sender, ibo);
    }
}