// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

pragma solidity ^0.8.4;

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


pragma solidity ^0.8.4;
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
        uint256 newAllowance = token.allowance(address(this), spender)+value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
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



pragma solidity ^0.8.4;
interface ISingleAddressValidator {
    function validate(address addr) external view returns (bool);
}

import "https://raw.githubusercontent.com/abdk-consulting/abdk-libraries-solidity/master/ABDKMathQuad.sol";
pragma solidity ^0.8.4;

contract BenLockV2 {
    using ABDKMathQuad for bytes16;
    using SafeBEP20 for IBEP20;

    // Locked token
    IBEP20 public token;

    // Unlock time
    uint256 public startTime;
    // Unlock time
    uint256 public endTime;
    // Factory address
    address public factory;
    // Owner address
    address public owner;
    // Is withdrawn
    bool public isWithdrawn;

    // lock token amount
    uint256 public lockedAmount;
    // withdrawn amount
    uint256 public withdrawnAmount;    
    // exponent
    uint256 public exponent;
    

    event Withdraw(address indexed caller, uint256 balance);

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token, uint256 _unlockTime, address _owner,uint256 _lockedAmount,uint256 _exponent) external {
        require(msg.sender == factory, 'BenSwap: FORBIDDEN'); // sufficient check
        token = IBEP20(_token);
        startTime=block.timestamp;
        endTime = _unlockTime;

        owner = _owner;
        lockedAmount = _lockedAmount;
        exponent=_exponent;
         isWithdrawn = false;
    }

    function balance()
        external
        view
        returns (uint256)
    {
        return token.balanceOf(address(this));
    }


    // function withdraw() public {
    //     require(owner == msg.sender, 'caller must be the owner!');
    //     require(endTime <= block.timestamp, 'not unlocked!');

    //     uint256 _balance = token.balanceOf(address(this));
    //     token.safeTransfer(address(msg.sender), _balance);

    //     isWithdrawn = true;
    //     emit Withdraw(owner, _balance);
    // }

    function withdrawReleasedTokens() external {
      require(owner == msg.sender, 'caller must be the owner!');

      require(lockedAmount>withdrawnAmount,"The token has been extracted.");
      uint256 releasedTokens=getReleasedTokens();
      require(releasedTokens>0,"Invalid token count");

      uint256 amount=releasedTokens-withdrawnAmount;
      require(amount>0,"Invalid token amount");
      withdrawnAmount+=amount;

      uint256 _balance = token.balanceOf(address(this));
      require(_balance>=amount,"Invalid token amount");
      token.safeTransfer(address(msg.sender), amount);
      // locked status
      if(withdrawnAmount  >= lockedAmount){ isWithdrawn = true; }
      emit Withdraw(owner, amount);
    }

    function getReleasedTokens() view public  returns(uint256 releasedTokens) {
           if(block.timestamp<=startTime){
              return 0;
           }
           uint256 elapsedTime = block.timestamp - startTime; // 已过时间
           uint256 totalReleaseTime=endTime-startTime;// 总释放时间
           if (elapsedTime >= totalReleaseTime) {
               return lockedAmount;
           }
           releasedTokens=calculatePower(lockedAmount,elapsedTime,totalReleaseTime,exponent,100);
           return  releasedTokens;
    }     

    function calculatePower(
      uint256 totalTokens, 
      uint256 elapsedTime,
      uint256 totalTime,
      uint256 exponentNumerator,
      uint256 exponentDenominator
    ) internal  pure returns (uint256) {

      require(totalTime > 0, "Total time must be greater than zero");

      require(elapsedTime <= totalTime, "Elapsed time cannot exceed total time");

      require(exponentDenominator > 0, "Exponent denominator must be greater than zero");

      // ratio = elapsedTime / totalTime
      bytes16 ratio = ABDKMathQuad.div(
         ABDKMathQuad.fromUInt(elapsedTime),
         ABDKMathQuad.fromUInt(totalTime)
      );


      require(
         ABDKMathQuad.cmp(ratio, ABDKMathQuad.fromUInt(0)) > 0,
         "Ratio must be greater than zero"
      );

      // exponent = exponentNumerator / exponentDenominator
      bytes16 localExponent = ABDKMathQuad.div(
         ABDKMathQuad.fromUInt(exponentNumerator),
         ABDKMathQuad.fromUInt(exponentDenominator)
      );

      // powerResult = exp(exponent * ln(ratio))
      bytes16 powerResult = ABDKMathQuad.exp(
         ABDKMathQuad.mul(
               localExponent,
               ABDKMathQuad.ln(ratio)
         )
      );

      // releasedTokensQuad = totalTokens * powerResult
      bytes16 releasedTokensQuad = ABDKMathQuad.mul(
         ABDKMathQuad.fromUInt(totalTokens),
         powerResult
      );

      // uint256
      uint256 releasedTokens = ABDKMathQuad.toUInt(releasedTokensQuad);

      return releasedTokens;
    } 


    function setOwnerTo(address _To) external {
        require(msg.sender == factory, 'BenSwap: FORBIDDEN');
        owner = _To;
    }
}

contract BenLockV2Factory {
    using SafeBEP20 for IBEP20;

    ISingleAddressValidator public priviledgeValidator;
    address public adminAddress;
    IBEP20 public feeToken;
    address public feeTo;
    uint256 public creationFee;
    uint256 public count;

    mapping(address => address[]) public getBenLocks;
    mapping(address => address) public getCreator; 
    mapping(uint256 => address) public getBenLockByIndex;

    event BenLockCreated(address indexed token, address indexed creator, address lock);
    event BenLockOwnerChanged(address indexed lock, address indexed from, address indexed to);

    constructor(address _admin, ISingleAddressValidator _priviledgeValidator, IBEP20 _feeToken, address _feeTo, uint256 _creationFee) {
        adminAddress = _admin;
        priviledgeValidator = _priviledgeValidator;
        feeToken = _feeToken;
        feeTo = _feeTo;
        creationFee = _creationFee;
        count = 0;
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

    function setPriviledgeValidator(address _priviledgeValidator) external {
        require(msg.sender == adminAddress, 'BenSwap: FORBIDDEN');
        priviledgeValidator = ISingleAddressValidator(_priviledgeValidator);
    }

    function getBenLockCount(address _add) external view returns (uint256) {
        return getBenLocks[_add].length;
    }

    function createBenLock(address token, address creator, uint256 unlockTime, uint256 amount,uint256 exponent) external returns (address benLock) {
        require(creator != address(0), 'BenSwap: invalid creator address');

        bytes memory bytecode = type(BenLockV2).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(creator, getBenLocks[creator].length));
        assembly {
            benLock := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        BenLockV2(benLock).initialize(token, unlockTime, creator,amount,exponent);


        // creation fee
        feeToken.safeTransferFrom(address(msg.sender), feeTo, creationFee);

        // locked token amount
        TransferHelper.safeTransferFrom(token, msg.sender, benLock, amount);

        getBenLocks[creator].push(benLock);
        getCreator[benLock] = creator;
        getBenLockByIndex[count] = benLock;
        count = count + 1;

        emit BenLockCreated(token, creator, benLock);
    }

    function createBenLockWithPriviledge(address token, address creator, uint256 unlockTime, uint256 amount,uint256 exponent) external returns (address benLock) {
        require(creator != address(0), 'BenSwap: invalid creator address');
        require(priviledgeValidator.validate(token), 'BenSwap: token is not priviledged!');

        bytes memory bytecode = type(BenLockV2).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(creator, getBenLocks[creator].length));
        assembly {
            benLock := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        BenLockV2(benLock).initialize(token, unlockTime, creator,amount,exponent);

        // locked token amount
        TransferHelper.safeTransferFrom(token, msg.sender, benLock, amount);

        getBenLocks[creator].push(benLock);
        getCreator[benLock] = creator;
        getBenLockByIndex[count] = benLock;
        count = count + 1;

        emit BenLockCreated(token, creator, benLock);
    }

    function transferOwnership(address benLock, address newOwner) external {
        require(getCreator[benLock] != address(0), 'BenSwap: invalid benlock address');

        BenLock lock = BenLock(benLock);

        require(lock.owner() == msg.sender, 'BenSwap: not owner!');
        lock.setOwnerTo(newOwner);

        emit BenLockOwnerChanged(benLock, msg.sender, newOwner);
    }
}
