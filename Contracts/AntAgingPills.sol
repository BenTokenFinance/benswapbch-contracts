// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/proxy/utils/Initializable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol";
import "https://raw.githubusercontent.com/abdk-consulting/abdk-libraries-solidity/master/ABDKMathQuad.sol";


interface BasicNft is IERC721,IERC721Enumerable {
    function mint(address to) external;
    function setTokenURL(string memory prefix_,string memory suffix_) external;
}
contract AntAgingPills is Initializable,Ownable{
    
    struct lockedInfo{
       uint256 lockedAmount;
       uint256 startTime;
       uint256 endTime;
       uint8   exponent;
    }
    // private _data;
    address public  feeToken;
    address public  nftAddress;
    mapping (uint256=>lockedInfo) lockedInfoByTokenId;

    event lockAntAgingCreated(uint256 tokenId,address to,uint256 startTime,uint256 endTime,uint256 exponent,uint256 tokenAmount);

    function initialize(address _feeToken) public initializer {
        feeToken=_feeToken;
    }
    
    function createAntAging(address to,uint256 tokenAmount,uint256 endTime,uint8 exponent) public {
       require(to!=address(0),"faild address");
       require(tokenAmount>0,"Can't be less than 0");
       require(endTime>block.timestamp,"Can't be less than now");

       IERC20 tokenContract=IERC20(feeToken);
       tokenContract.transferFrom(msg.sender,address(this),tokenAmount);
       // 发送代币
       BasicNft nftContract=BasicNft(nftAddress);
       nftContract.mint(to);
       uint256 tokenId=nftContract.totalSupply();
       lockedInfoByTokenId[tokenId]=lockedInfo(tokenAmount,block.timestamp,endTime,exponent);
       emit lockAntAgingCreated(tokenId,to,block.timestamp,endTime,exponent,tokenAmount);
    }

    function getReleasedTokens(uint256 tokenId) view external returns(uint256 releasedTokens) {
           uint256 elapsedTime = block.timestamp - lockedInfoByTokenId[tokenId].startTime; // 已过时间
           uint256 totalReleaseTime=lockedInfoByTokenId[tokenId].endTime-lockedInfoByTokenId[tokenId].startTime;
           releasedTokens=calculatePower(lockedInfoByTokenId[tokenId].lockedAmount,elapsedTime,totalReleaseTime,lockedInfoByTokenId[tokenId].exponent/100,100);
           return  releasedTokens;
    } 

    // using ABDKMath64x64 for int128;
    // function calculatePower(
    //     uint256 totalTokens, 
    //     uint256 elapsedTime,
    //     uint256 totalTime,
    //     uint256 exponentNumerator,
    //     uint256 exponentDenominator
    // ) public pure returns (uint256) {
    //     // 确保 totalTime 不为零
    //     require(totalTime > 0, "Total time must be greater than zero");
    //     // 确保 elapsedTime 不大于 totalTime
    //     require(elapsedTime <= totalTime, "Elapsed time cannot exceed total time");
    //     // 将时间转换为定点数
    //     int128 elapsedTimeFixed = ABDKMath64x64.fromUInt(elapsedTime);
    //     int128 totalTimeFixed = ABDKMath64x64.fromUInt(totalTime);

    //     // 计算时间比例
    //     int128 ratio = elapsedTimeFixed.div(totalTimeFixed);

    //     // 确保比例大于零
    //     require(ratio > 0, "Ratio must be greater than zero");

    //     // 将幂指数转换为定点数
    //     int128 exponent = ABDKMath64x64.divu(exponentNumerator, exponentDenominator);

    //     // 计算 ln(ratio)
    //     int128 lnRatio = ratio.ln();

    //     // 计算 exponent * ln(ratio)
    //     int128 exponentLnRatio = exponent.mul(lnRatio);
    //     int128 powerResult = exponentLnRatio.exp();

    //     // 将 totalTokens 转换为定点数
    //     // int128 totalTokensFixed = ABDKMath64x64.fromUInt(totalTokens);
    //     int128 totalTokensFixed = ABDKMath64x64.div(
    //      ABDKMath64x64.fromUInt(totalTokens),
    //      ABDKMath64x64.fromUInt(1e18)
    //     );

    //     // 计算 releasedTokens = totalTokens * powerResult
    //     int128 releasedTokensFixed = totalTokensFixed.mul(powerResult);
    //     uint256 scalingFactor = 10 ** uint256(18);
    //     uint256 releasedTokens = releasedTokensFixed.mulu(scalingFactor);
    //     return releasedTokens;
    // }


    using ABDKMathQuad for bytes16;

    function calculatePower(
        uint256 totalTokens, 
        uint256 elapsedTime,
        uint256 totalTime,
        uint256 exponentNumerator,
        uint256 exponentDenominator
    ) public pure returns (uint256) {
        // 确保 totalTime 不为零
        require(totalTime > 0, "Total time must be greater than zero");
        // 确保 elapsedTime 不大于 totalTime
        require(elapsedTime <= totalTime, "Elapsed time cannot exceed total time");
        // 确保 exponentDenominator 不为零
        require(exponentDenominator > 0, "Exponent denominator must be greater than zero");

        // 计算时间比例 ratio = elapsedTime / totalTime
        bytes16 ratio = ABDKMathQuad.div(
            ABDKMathQuad.fromUInt(elapsedTime),
            ABDKMathQuad.fromUInt(totalTime)
        );

        // 确保比例大于零
        require(
            ABDKMathQuad.cmp(ratio, ABDKMathQuad.fromUInt(0)) > 0,
            "Ratio must be greater than zero"
        );

        // 计算 exponent = exponentNumerator / exponentDenominator
        bytes16 exponent = ABDKMathQuad.div(
            ABDKMathQuad.fromUInt(exponentNumerator),
            ABDKMathQuad.fromUInt(exponentDenominator)
        );

        // 计算 powerResult = exp(exponent * ln(ratio))
        bytes16 powerResult = ABDKMathQuad.exp(
            ABDKMathQuad.mul(
                exponent,
                ABDKMathQuad.ln(ratio)
            )
        );

        // 计算 releasedTokensQuad = (totalTokens / 1e18) * powerResult
        bytes16 releasedTokensQuad = ABDKMathQuad.mul(
            ABDKMathQuad.div(
                ABDKMathQuad.fromUInt(totalTokens),
                ABDKMathQuad.fromUInt(1e18)
            ),
            powerResult
        );

        // 将结果乘以 1e18，恢复代币的精度
        releasedTokensQuad = ABDKMathQuad.mul(
            releasedTokensQuad,
            ABDKMathQuad.fromUInt(1e18)
        );

        // 将结果转换回 uint256
        uint256 releasedTokens = ABDKMathQuad.toUInt(releasedTokensQuad);

        return releasedTokens;
    }

    function withdrawReleasedTokens(uint256 tokenId) external {
    //    uint256 elapsedTime = block.timestamp - lockedInfoByTokenId[tokenId].startTime; // 已过时间
    //    uint256 totalReleaseTime=lockedInfoByTokenId[tokenId].endTime-lockedInfoByTokenId[tokenId].startTime;
    //     // 确保时间不超过总释放时间
    //    if (elapsedTime > totalReleaseTime) {
    //         elapsedTime = lockedInfoByTokenId[tokenId].totalReleaseTime;
    //    }
    //    uint256 releasedAmount = lockedInfoByTokenId[tokenId].lockedAmount * ((elapsedTime/totalReleaseTime) ** lockedInfoByTokenId[tokenId].exponent);

       // 计算释放的代币数量: 总锁定数量 * (已过时间 / 总释放时间) ^ 幂
       //    uint256 releasedAmount = totalLockedAmount * (elapsedTime ** exponent) / (totalReleaseTime ** exponent);
       //    return 0;
       //    {总锁定数量} * Math.pow({已经过时间}/{总释放时间}, {幂});  
    }

    function setTokenURL(string memory prefix,string memory suffix) external onlyOwner{
       BasicNft nftContract=BasicNft(nftAddress);
       nftContract.setTokenURL(prefix,suffix);
    }

}