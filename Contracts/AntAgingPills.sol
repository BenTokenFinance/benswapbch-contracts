// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/proxy/utils/Initializable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface BasicNft is IERC721,IERC721Enumerable {
    function mint(address to) external;
    function setTokenURL(string memory prefix_,string memory suffix_) external;
}
contract AntAgingPills is Initializable,Ownable{
    struct lockedInfo{
       uint256 lockedAmount;
       uint256 startTime;
       uint256 totalReleaseTime;
       uint8   exponent;
    }
    // private _data;
    address public  feeToken;
    address public  nftAddress;
    mapping (uint256=>lockedInfo) lockedInfoByTokenId;

    event lockAntAgingCreated(uint256 tokenId,address to,uint256 startTime,uint256 totalReleaseTime,uint256 exponent,uint256 tokenAmount);

    function initialize(address _feeToken) public initializer {
        feeToken=_feeToken;
    }
    
    function createAntAging(address to,uint256 tokenAmount,uint256 totalReleaseTime,uint8 exponent) public {
       require(to!=address(0),"faild address");
       require(tokenAmount>0,"Can't be less than 0");
       require(totalReleaseTime>block.timestamp,"Can't be less than now");

       IERC20 tokenContract=IERC20(feeToken);
       tokenContract.transferFrom(msg.sender,address(this),tokenAmount);
       // 发送代币
       BasicNft nftContract=BasicNft(nftAddress);
       nftContract.mint(to);
       uint256 tokenId=nftContract.totalSupply();
       lockedInfoByTokenId[tokenId]=lockedInfo(tokenAmount,block.timestamp,totalReleaseTime,exponent);
       emit lockAntAgingCreated(tokenId,to,block.timestamp,totalReleaseTime,exponent,tokenAmount);
    }

    function withdrawReleasedTokens(uint256 tokenId) external {
       uint256 elapsedTime = block.timestamp - lockedInfoByTokenId[tokenId].startTime; // 已过时间
        // 确保时间不超过总释放时间
       if (elapsedTime > lockedInfoByTokenId[tokenId].totalReleaseTime) {
            elapsedTime = lockedInfoByTokenId[tokenId].totalReleaseTime;
       }
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