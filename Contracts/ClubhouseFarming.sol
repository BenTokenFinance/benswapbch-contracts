// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC20/IERC20.sol";
import "https://raw.githubusercontent.com/abdk-consulting/abdk-libraries-solidity/master/ABDKMathQuad.sol";


interface IDEX {
    // function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt, uint256 rewardLockedUp, uint256 nextHarvestUntil);  // Emberswap
    function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt);    // Mistswap & Tango & 1BCH & BEN
    function deposit(uint256 _pid, uint256 _amount) external;                                                   // Mistswap & Emberswap & Tango & 1BCH & BEN
    function withdraw(uint256 _pid, uint256 _amount) external;                                                  // Mistswap & Emberswap & Tango & 1BCH & BEN
    function emergencyWithdraw(uint256 _pid) external;  
    function pendingGreenBen(uint256 _pid, address _user) external view returns (uint256);                                                      // Mistswap & Emberswap & Tango & 1BCH & BEN
}
interface VEERC20 is IERC20 {
    function mint(address _to, uint256 _amount) external;                                                   // Mistswap & Emberswap & Tango & 1BCH & BEN                                                // Mistswap & Emberswap & Tango & 1BCH & BEN
}

// pragma solidity >=0.4.0;
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
// 质押单币池 deposit(1,token数量)
// 收获挖矿收益 deposit(1,0)
// 复投 deposit(1,挖矿奖励数量)
// 提取质押代币 withdraw 提取质押代币

// 锁定代币合约
contract ClubhouseFarming is Ownable {
    using ABDKMathQuad for bytes16;
    uint256 public constant ONE_YEAR_IN_SECONDS = 365 days;
    uint256 public TEN_YEARS_IN_SECONDS = 315360000;  // 10 年的秒数

    address public veEBEN;  // veEBEN
    // address public EBEN_TOKEN = 0x77CB87b57F54667978Eb1B199b28a0db8C8E1c0B;  // EBEN
    // address public EBEN_DEX = 0xDEa721EFe7cBC0fCAb7C8d65c598b21B6373A2b6;//MasterBreeder address
    address public EBEN_TOKEN;  // 锁定的代币
    address public EBEN_DEX;// MasterBreeder address

    uint256 public DEX_POOL_PID = 1;//pool DEX id
    uint256 public constant PID_NOT_SET = 2**256 - 1;      

    uint256 public totalLocked;  // 总锁仓量

    // 存储用户锁仓信息
    struct UserInfo {
        uint256 veEBENAmount;
        uint256 dexRewardDebt; // extra reward debt

        uint256 amount;  // 锁定的代币数量
        uint256 startTime;   // 锁定开始时间
        uint256 endTime;     // 锁定结束时间
    }
    // 使用 mapping 来存储每个地址对应的锁仓信息
    mapping(address => UserInfo) public userInfos;


    //池子奖励信息
    struct PoolInfo {
        uint256 activeAddresses;        // number of unique addresses with LP in pool
        IERC20 lpToken;                 // Address of LP token contract.
        uint256 lastRewardBlock;        // Last block number that FOGs distribution occurs.
        uint256 dexPID;                 // External DEX PID
        uint256 accDexPerShare;         // Accumulated extra token per share, times 1e12.
    }
    PoolInfo public poolInfo;


    // 事件
    event Deposit(address indexed user,address operUser,uint256 amount, uint256 currentTime,uint256 startTime,uint256 endTime);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event TokensUnlocked(address indexed user, uint256 amount);
    constructor(address veEBEN_,address tokenEben,address ebenLpDex) {
        EBEN_TOKEN = tokenEben; 
        EBEN_DEX = ebenLpDex;//MasterBreeder address

        veEBEN=veEBEN_;
        poolInfo=PoolInfo({
            lpToken: IERC20(EBEN_TOKEN),
            lastRewardBlock: 0,
            dexPID:DEX_POOL_PID,
            accDexPerShare: 0,
            activeAddresses: 0
        });
    }



    // Safe DEX transfer function, just in case if rounding error causes pool to not have enough reward tokens.
    function safeDEXTransfer(address _to, uint256 _amount,address token) internal {
        uint256 dexBal = IERC20(token).balanceOf(address(this));
        if (_amount > dexBal) {
            IERC20(token).transfer(_to, dexBal);
        } else {
            IERC20(token).transfer(_to, _amount);
        }
    }

    // Update reward variables of the given pool to be up-to-date.更新dex的每股费用
    function updatePool() public {
 
        uint256 lpSupply;
        // PoolInfo storage pool = poolInfo[_pid];
        // address DEX = address(0);  

        address DEX = EBEN_DEX;
        PoolInfo storage pool = poolInfo;
       

        (lpSupply,) = IDEX(DEX).userInfo(pool.dexPID, address(this));
        if (lpSupply == 0) {
            if (pool.lastRewardBlock < block.number) {
                pool.lastRewardBlock = block.number;
            }
            return;
        }

        uint256 dexReward = IDEX(DEX).pendingGreenBen(pool.dexPID, address(this));
        pool.accDexPerShare = pool.accDexPerShare+(dexReward * 1e12 / lpSupply);
        IDEX(DEX).withdraw(pool.dexPID, 0);   

        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        pool.lastRewardBlock = block.number;
    }


    // 质押锁定代币
    // 1.用户自己质押 deposit(100,17091231)
    // 2.在质押      deposit(100,17091231)
    // 3.用户给他人质押  deposit(other,100,17091231)
    
    // 3.复投
    function deposit(address user_,uint256 amount_,uint256 endTime_) external {
        //记录信息
        PoolInfo storage pool = poolInfo;
        // address  operUser=msg.sender==user_?msg.sender:user_;
        bool isSelf = (user_ == msg.sender);
        UserInfo storage user = userInfos[user_];
        //更新accDexPerShare
        updatePool();
        uint256 userAmountOld = user.amount;

        //TO DO：进行质押
        if (amount_ > 0) {
            //TO DO:test 只有是用户自己才能设置自己的时间，才需要验证时间
            if(isSelf){
                require(endTime_ > block.timestamp, "The end time must be greater than the current time");
                require(endTime_ <= (block.timestamp+TEN_YEARS_IN_SECONDS), "The end time must be within 10 years from now");
                require(endTime_ >= user.endTime, "End time must be greater than or equal to the previous end time");
            }
            
            // harvest any rewards 地址统计
            if (user.amount == 0) {
                pool.activeAddresses++;
                //给没被质押过的用户质押，结束时间就是当前时间
                if(!isSelf){user.endTime=block.timestamp;}
            }
            
            // user.rewardDebt = user.amount.mul(pool.accFOGPerShare).div(1e12);
            user.startTime=block.timestamp;
            if(isSelf && endTime_ > user.endTime){ user.endTime=endTime_; }
            require(user.startTime <= user.endTime, "Start time cannot be greater than end time");
            poolInfo.lpToken.transferFrom(msg.sender, address(this), amount_);
        }



        // 质押到单币池
        address DEX = EBEN_DEX;
        require(DEX != address(0));
        // 合并质押金额 (包括用户的新增质押 amount_ 和复投的 dexPending)
        uint256 dexPending = ((userAmountOld * pool.accDexPerShare) / 1e12) - user.dexRewardDebt;
        uint256 totalAmount = amount_ + dexPending;
        if (totalAmount > 0) {
            // 批准并存入 DEX
            pool.lpToken.approve(DEX, totalAmount);
            IDEX(DEX).deposit(pool.dexPID, totalAmount);
            // 这里加上 dexPending
            user.amount += totalAmount; 
            //记录用户在质押之前，能获得的奖励， 下次计算奖励，减去这部分，就是实得的奖励dexPending;
            /*
            例如用户存100个，在之前的区块变化时间里，能获得的奖励是多少，因为 pool.accDexPerShare 是叠加的，
            所以需要减去直接时间内能获得的奖励，就是用户真实的奖励
            */
            user.dexRewardDebt = (user.amount * pool.accDexPerShare) / 1e12;
            // 计算获得 veEBEN
            uint256 elapsedTime=user.endTime-user.startTime;
            if(elapsedTime>0){
                uint256 rewardToken=calculatePower(totalAmount,elapsedTime,ONE_YEAR_IN_SECONDS,200,100);
                if(rewardToken>0){
                    VEERC20(veEBEN).mint(user_,rewardToken);
                    user.veEBENAmount+=rewardToken;
                }
            }
            // 记录总量 这里添加质押数量，会把之前的产出也质押，所以: user.amount+产出收益, 总量=总量+产出收益
            totalLocked+=totalAmount;
            emit Deposit(msg.sender,user_,totalAmount, block.timestamp,user.startTime,endTime_);
        }

    }

   


    // 提取lp token 和奖励.
    function withdraw(uint256 amount_) external {
        
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfos[msg.sender];
        //未到解释时间
        require(block.timestamp>=user.endTime,"Not unlocked");
        // 更新 dex实时的 每份lp的accDexPerShare 奖励信息
        updatePool();

        uint256 userOldAmount = user.amount;

        // remove from active address count
        if (amount_ == user.amount) {
            poolInfo.activeAddresses--;
            user.startTime=0;
            user.endTime=0;
        }


        user.amount = user.amount - amount_;
        totalLocked = totalLocked - amount_;
        // claim any pending DEX rewards
        uint256 dexPending = (userOldAmount * pool.accDexPerShare) / 1e12 - user.dexRewardDebt;
        if (dexPending > 0) {
            user.dexRewardDebt = (user.amount * pool.accDexPerShare) / 1e12;
            safeDEXTransfer(msg.sender, dexPending, EBEN_TOKEN);
        }

        // send withdraw
        if (amount_ > 0) {
                require(pool.dexPID != PID_NOT_SET);
                address DEX = EBEN_DEX;
                IDEX(DEX).withdraw(pool.dexPID, amount_);
                pool.lpToken.transfer(address(msg.sender), amount_);
        }

        emit Withdraw(msg.sender, 1, amount_);
    }



    // 查询dex的产出收益  View function to see pending DEX rewards on frontend.
    function pendingTokens(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfos[_user];
        uint256 accDexPerShare = pool.accDexPerShare;
        uint256 lpSupply;


        // dual farming active
        require(pool.dexPID != PID_NOT_SET);
        address DEX = EBEN_DEX;
        (lpSupply,) = IDEX(DEX).userInfo(pool.dexPID, address(this));

        if (lpSupply != 0) {
            uint256 dexReward = IDEX(DEX).pendingGreenBen(pool.dexPID, address(this));
            accDexPerShare = accDexPerShare+((dexReward*1e12)/lpSupply);
        }
        return ((user.amount*accDexPerShare)/1e12)-user.dexRewardDebt;   
    }
    

    
    function calculatePower(
      uint256 totalTokens, 
      uint256 elapsedTime,
      uint256 oneYearInTime,
      uint256 exponentNumerator,
      uint256 exponentDenominator
    ) public  pure returns (uint256) {
      require(elapsedTime > 0, "Elapsed time must be greater than zero");
      require(oneYearInTime > 0, "Total time must be greater than zero");
      //   require(elapsedTime <= totalTime, "Elapsed time cannot exceed total time");
      require(exponentDenominator > 0, "Exponent denominator must be greater than zero");

      // ratio = elapsedTime / totalTime
      bytes16 ratio = ABDKMathQuad.div(
         ABDKMathQuad.fromUInt(elapsedTime),
         ABDKMathQuad.fromUInt(oneYearInTime)
      );



      require(
         ABDKMathQuad.cmp(ratio, ABDKMathQuad.fromUInt(0)) > 0,
         "Ratio must be greater than zero"
      );

      // exponent = exponentNumerator / exponentDenominator
      bytes16 exponent = ABDKMathQuad.div(
         ABDKMathQuad.fromUInt(exponentNumerator),
         ABDKMathQuad.fromUInt(exponentDenominator)
      );

      // powerResult = exp(exponent * ln(ratio))
      bytes16 powerResult = ABDKMathQuad.exp(
         ABDKMathQuad.mul(
               exponent,
               ABDKMathQuad.ln(ratio)
         )
      );

      // releasedTokensQuad = totalTokens * powerResult
      bytes16 releasedTokensQuad = ABDKMathQuad.mul(
         ABDKMathQuad.fromUInt(totalTokens),
         powerResult
      );

     
      // TO DO:
      // powerResult精度丢失,弥补精度问题,四舍五入
      // 将 powerResult 转换为整数部分
      uint256 resultToken = ABDKMathQuad.toUInt(releasedTokensQuad);
      // 计算 powerResult 的小数部分：powerResult - resultToken
      bytes16 frac = ABDKMathQuad.sub(releasedTokensQuad, ABDKMathQuad.fromUInt(resultToken));

      // 定义 0.5
      bytes16 criticalValue = ABDKMathQuad.fromUInt(5);
      bytes16 fracScaled = ABDKMathQuad.mul(frac, ABDKMathQuad.fromUInt(10));

      // 判断小数部分是否大于0.5,四舍五入 hasFraction >1,=0,<-1
      int8 resultValue = ABDKMathQuad.cmp(fracScaled, criticalValue);
      if(resultValue>0){
         resultToken+=1;
      }


      // uint256
      uint256 releasedTokens = resultToken;

      //   return (releasedTokens,resultValue);
      return releasedTokens;
    }


}
