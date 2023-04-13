// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IMasterChef {
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
    }
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. EBENs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that EBENs distribution occurs.
        uint256 accGreenBenPerShare;   // Accumulated EBENs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    function poolInfo(uint256) external view returns (PoolInfo calldata);
    function userInfo(uint256, address) external view returns (UserInfo calldata);
    function poolLength() external view returns (uint256);
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) external;
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external;
    function massUpdatePools() external;
    function updatePool(uint256 _pid) external;
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function dev(address _devaddr) external;
    function setFeeAddress(address _feeAddress) external;
    function updateEmissionRate(uint256 _emissionPerBlock) external;
    function updateStartBlock(uint256 newStartBlock) external;
}

contract EBENGovernance is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public EBEN;
    IERC20 public WBCH;
    IUniswapV2Factory public Factory;
    IMasterChef public MasterBreeder;

    bool private initialized = false;
    function initialize(address newOwner, address eben, address wbch, address factory, address masterbreeder) external {
        require(newOwner != address(0) && !initialized);
        _transferOwnership(newOwner);

        EBEN = IERC20(eben);
        WBCH = IERC20(wbch);
        Factory = IUniswapV2Factory(factory);
        MasterBreeder = IMasterChef(masterbreeder);

        initialized = true;
    }

    function version() external pure returns(uint256){
        return 2;
    }

    function getBalanceInWallet(address token, address user) public view returns (uint256) {
        return IERC20(token).balanceOf(user);
    }

    function getBalanceInUniV2Pair(address token, address pair, address user) public view returns (uint256) {
        return IERC20(pair).balanceOf(user).mul(IERC20(token).balanceOf(pair)).div(IERC20(pair).totalSupply());
    }

    function getBalanceInUniV2PairStakedInMasterBreeder(address token, uint256 pid, address user) public view returns (uint256) {
        IERC20 pair = MasterBreeder.poolInfo(pid).lpToken;
        uint256 userAmount = MasterBreeder.userInfo(pid, user).amount;

        return userAmount.mul(IERC20(token).balanceOf(address(pair))).div(pair.totalSupply());
    }

    function getBalanceStakedInMasterBreeder(uint256 pid, address user) public view returns (uint256) {
        return MasterBreeder.userInfo(pid, user).amount;
    }

    function getTotalVotingPower() external view returns (uint256) {
        return EBEN.totalSupply()
            .sub(EBEN.balanceOf(address(EBEN))) 
            .sub(EBEN.balanceOf(address(0)))
            .sub(EBEN.balanceOf(0x000000000000000000000000000000000000dEaD))
            .sub(EBEN.balanceOf(address(0xd24d70B77db78bF8Bb7017a94be575Fb172C6C15)))   // Lottery
            .sub(EBEN.balanceOf(address(0x71D9C349e35f73B782022d912B5dADa4235fDa06)))   // Token Burner
        ;
    }

    function getVotingPower(address user) external view returns (uint256) {
        address eben_wbch = Factory.getPair(address(WBCH), address(EBEN));

        return EBEN.balanceOf(user)                                                         // Wallet Balance
            .add(getBalanceInUniV2Pair(address(EBEN), eben_wbch, user))                     // EBEN-BCH LP in Wallet
            .add(getBalanceInUniV2PairStakedInMasterBreeder(address(EBEN), 0, user))        // EBEN-BCH Farm
            .add(getBalanceStakedInMasterBreeder(1, user));                                 // EBEN Pool
    }
}
