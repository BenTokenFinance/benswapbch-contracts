// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/proxy/utils/Initializable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "https://raw.githubusercontent.com/abdk-consulting/abdk-libraries-solidity/master/ABDKMathQuad.sol";


interface BasicNft is IERC721,IERC721Enumerable {
    function mint(address to) external;
    function setTokenURL(string memory prefix_,string memory suffix_) external;
}
contract AntAgingPotionController is Initializable,Ownable{
    using ABDKMathQuad for bytes16;
    struct lockedInfo{
       uint256 lockedAmount;
       uint256 startTime;
       uint256 endTime;
       uint256 exponent;
       uint256 withdrawnAmount;
       bool exists;
       address creator;
    }
    address public  feeToken;
    address public  nftAddress;
    mapping (uint256=>lockedInfo) public lockInfoById;
    event lockAntAgingCreated(uint256 tokenId,address to,uint256 startTime,uint256 endTime,uint256 exponent,uint256 tokenAmount,address creator);
    event lockAntAgingWithdrawal(uint256 tokenId,address user,uint256 withdrawnAmount,uint256 releasedTokens);
    
    function initialize(address newOwner, address nftAddress_,address feeToken_) public initializer {
      _transferOwnership(newOwner);
      feeToken=feeToken_;
      nftAddress=nftAddress_;
    }

   function version() external pure returns(uint256){
        return 1;
    }
    
    /*
     exponent eg:0.25*100=25
    */
    function createAntAging(address to,uint256 tokenAmount,uint256 startTime,uint256 endTime,uint256 exponent) public {
       require(to!=address(0),"faild address");
       require(tokenAmount>0,"Can't be less than 0");
       require(endTime>startTime,"Can't be less than now");

       IERC20 tokenContract=IERC20(feeToken);
       tokenContract.transferFrom(msg.sender,address(this),tokenAmount);
       BasicNft nftContract=BasicNft(nftAddress);
       nftContract.mint(to);
       uint256 tokenId=nftContract.totalSupply();
       lockInfoById[tokenId]=lockedInfo(tokenAmount,startTime,endTime,exponent,0,true,msg.sender);
       emit lockAntAgingCreated(tokenId,to,startTime,endTime,exponent,tokenAmount,msg.sender);
    }
    

    function getReleasedTokens(uint256 tokenId) view public  returns(uint256 releasedTokens) {
           require(lockInfoById[tokenId].exists,"The tokenId does not exist");
           //   require(block.timestamp>lockInfoById[tokenId].startTime,"The token is not released");
           if(block.timestamp<=lockInfoById[tokenId].startTime){
              return 0;
           }
           uint256 elapsedTime = block.timestamp - lockInfoById[tokenId].startTime; // 已过时间
           uint256 totalReleaseTime=lockInfoById[tokenId].endTime-lockInfoById[tokenId].startTime;// 总释放时间
           if (elapsedTime >= totalReleaseTime) {
               return lockInfoById[tokenId].lockedAmount;
           }
           releasedTokens=calculatePower(lockInfoById[tokenId].lockedAmount,elapsedTime,totalReleaseTime,lockInfoById[tokenId].exponent,100);
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

      // uint256
      uint256 releasedTokens = ABDKMathQuad.toUInt(releasedTokensQuad);

      return releasedTokens;
   }


    function withdrawReleasedTokens(uint256 tokenId) external {
      require(lockInfoById[tokenId].exists,"The tokenId does not exist");
      BasicNft nftContract=BasicNft(nftAddress);
      require(nftContract.ownerOf(tokenId)==msg.sender,"Not the tokenId owner");

      require(lockInfoById[tokenId].lockedAmount>lockInfoById[tokenId].withdrawnAmount,"The token has been extracted.");
      uint256 releasedTokens=getReleasedTokens(tokenId);
      require(releasedTokens>0,"Invalid token count");
      uint256 amount=releasedTokens-lockInfoById[tokenId].withdrawnAmount;
      require(amount>0,"Invalid token amount");
      lockInfoById[tokenId].withdrawnAmount+=amount;
      emit lockAntAgingWithdrawal(tokenId,msg.sender,amount,releasedTokens);

      IERC20 tokenContract=IERC20(feeToken);
      require(amount>0,"Invalid token amount");
      tokenContract.transfer(msg.sender,amount);
    }

    function setTokenURL(string memory prefix,string memory suffix) external onlyOwner{
       BasicNft nftContract=BasicNft(nftAddress);
       nftContract.setTokenURL(prefix,suffix);
    }

}