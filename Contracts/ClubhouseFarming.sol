// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC20/IERC20.sol";
import "https://raw.githubusercontent.com/abdk-consulting/abdk-libraries-solidity/master/ABDKMathQuad.sol";


interface IDEX {
    function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt);    // Mistswap & Tango & 1BCH & BEN
    function deposit(uint256 _pid, uint256 _amount) external;                                                   // Mistswap & Emberswap & Tango & 1BCH & BEN
    function withdraw(uint256 _pid, uint256 _amount) external;                                                  // Mistswap & Emberswap & Tango & 1BCH & BEN
    function emergencyWithdraw(uint256 _pid) external;  
    function pendingGreenBen(uint256 _pid, address _user) external view returns (uint256);                                                      // Mistswap & Emberswap & Tango & 1BCH & BEN
}
interface VEERC20 is IERC20 {
    function mint(address _to, uint256 _amount) external;                                                   // Mistswap & Emberswap & Tango & 1BCH & BEN                                                // Mistswap & Emberswap & Tango & 1BCH & BEN
}


contract ClubhouseFarming is Ownable {
    using ABDKMathQuad for bytes16;
    uint256 public constant ONE_YEAR_IN_SECONDS = 365 days;
    uint256 public TEN_YEARS_IN_SECONDS = 315360000;  // 10 years of seconds

    address public veEBEN;  // veEBEN
    address public EBEN_TOKEN;  // Locked tokens
    address public EBEN_DEX;// MasterBreeder address

    uint256 public DEX_POOL_PID = 1;//pool DEX id
    uint256 public constant PID_NOT_SET = 2**256 - 1;      

    uint256 public totalLocked;  // Total lock-up capacity

    // Store user lock-up information
    struct UserInfo {
        uint256 veEBENAmount;    // The amount of veEBEN (voting-escrowed EBEN) the user holds
        uint256 dexRewardDebt;   // Extra reward debt
        uint256 amount;          // The amount of tokens locked
        uint256 startTime;       // Lock-up start time
        uint256 endTime;         // Lock-up end time
    }

    // user Info
    mapping(address => UserInfo) public userInfos;


    // Pool reward information
    struct PoolInfo {
        uint256 activeAddresses;        // number of unique addresses with LP in pool
        IERC20 lpToken;                 // Address of LP token contract.
        uint256 lastRewardBlock;        // Last block number that FOGs distribution occurs.
        uint256 dexPID;                 // External DEX PID
        uint256 accDexPerShare;         // Accumulated extra token per share, times 1e12.
    }
    PoolInfo public poolInfo;


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


    // Pledge locked tokens
    function deposit(address user_,uint256 amount_,uint256 endTime_) external {
        PoolInfo storage pool = poolInfo;
        bool isSelf = (user_ == msg.sender);
        UserInfo storage user = userInfos[user_];
        updatePool();
        uint256 userAmountOld = user.amount;

        // pledge
        if (amount_ > 0) {
            // Only users can set their own time and need to verify the time
            if(isSelf){
                require(endTime_ > block.timestamp, "The end time must be greater than the current time");
                require(endTime_ <= (block.timestamp+TEN_YEARS_IN_SECONDS), "The end time must be within 10 years from now");
                require(endTime_ >= user.endTime, "End time must be greater than or equal to the previous end time");
            }
            
            // Address statistics
            if (user.amount == 0) {
                pool.activeAddresses++;
                // For users who have not been pledged, the end time is the current time
                if(!isSelf){user.endTime=block.timestamp;}
            }
            
            user.startTime=block.timestamp;
            if(isSelf && endTime_ > user.endTime){ user.endTime=endTime_; }
            require(user.startTime <= user.endTime, "Start time cannot be greater than end time");
            poolInfo.lpToken.transferFrom(msg.sender, address(this), amount_);
        }



        // Pledge to single coin pool
        address DEX = EBEN_DEX;
        require(DEX != address(0));
        // Combined pledge amount (including the user's new pledge amount_ and dexPending for re-investment)
        uint256 dexPending = ((userAmountOld * pool.accDexPerShare) / 1e12) - user.dexRewardDebt;
        uint256 totalAmount = amount_ + dexPending;
        if (totalAmount > 0) {
            // Approve and deposit in DEX
            pool.lpToken.approve(DEX, totalAmount);
            IDEX(DEX).deposit(pool.dexPID, totalAmount);
            user.amount += totalAmount; 
            // Record the reward that the user can get before the pledge. When calculating the reward next time, subtract this part, which is the reward dexPending;
            user.dexRewardDebt = (user.amount * pool.accDexPerShare) / 1e12;
            // calculate veEBEN
            uint256 elapsedTime=user.endTime-user.startTime;
            if(elapsedTime>0){
                uint256 rewardToken=calculatePower(totalAmount,elapsedTime,ONE_YEAR_IN_SECONDS,200,100);
                if(rewardToken>0){
                    VEERC20(veEBEN).mint(user_,rewardToken);
                    user.veEBENAmount+=rewardToken;
                }
            }

            totalLocked+=totalAmount;
            emit Deposit(msg.sender,user_,totalAmount, block.timestamp,user.startTime,endTime_);
        }

    }

   


    // Extract tokens and rewards.
    function withdraw(uint256 amount_) external {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfos[msg.sender];
        require(block.timestamp>=user.endTime,"Not unlocked");
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



    //View function to see pending DEX rewards on frontend.
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
    ) internal   pure returns (uint256) {
      require(elapsedTime > 0, "Elapsed time must be greater than zero");
      require(oneYearInTime > 0, "Total time must be greater than zero");
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

     
      // powerResult precision loss, make up for accuracy problems, round off
      // Convert powerResult to an integer part
      uint256 resultToken = ABDKMathQuad.toUInt(releasedTokensQuad);
      // Calculate the fractional part of powerResult: powerResult-ResultToken
      bytes16 frac = ABDKMathQuad.sub(releasedTokensQuad, ABDKMathQuad.fromUInt(resultToken));

      // Definition 0.5
      bytes16 criticalValue = ABDKMathQuad.fromUInt(5);
      bytes16 fracScaled = ABDKMathQuad.mul(frac, ABDKMathQuad.fromUInt(10));

      // To determine if the fraction is greater than 0.5, round hasFraction >1,=0,<-1
      int8 resultValue = ABDKMathQuad.cmp(fracScaled, criticalValue);
      if(resultValue>0){
         resultToken+=1;
      }


      uint256 releasedTokens = resultToken;
      return releasedTokens;
    }


}
