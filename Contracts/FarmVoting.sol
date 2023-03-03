// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ISingleAddressValidator {
    function validate(address addr) external view returns (bool);
}

contract FarmVoting is Ownable {
    ISingleAddressValidator public lpValidator;

    function setLpValidator(address v) external onlyOwner {
        lpValidator = ISingleAddressValidator(v);
    }

    mapping(address => bool) public excluded;
    function setExcluded(address lp, bool isExcluded) external onlyOwner {
        excluded[lp] = isExcluded;
    }

    struct VotingInfo { 
        address lp;
        uint256 pctBp;
    }

    mapping(address => VotingInfo[]) public getVotingInfoByUserAndIndex;
    mapping(uint256 => address) public getUserByIndex;
    mapping(address => bool) public hasUserVoted;
    uint256 public userCount = 0;

    function getVotingInfo(address user) external view returns(VotingInfo[] memory) {
        return getVotingInfoByUserAndIndex[user];
    }

    event voted(address indexed user, VotingInfo[] info);

    function vote(address[] calldata lps, uint256[] calldata pctBps) external {
        require(lps.length > 0, 'empty!');
        require(lps.length == pctBps.length, 'length mismatch!');
        uint i = 0;
        uint256 totalPctBp = 0;

        delete getVotingInfoByUserAndIndex[msg.sender];
        for(i = 0; i < lps.length; i++)
        {
            require(lpValidator.validate(lps[i]), 'Not BenSwap LP!');
            require(!excluded[lps[i]], 'LP excluded!');
            totalPctBp+=pctBps[i];
            require(totalPctBp <= 10000, 'More than 100%');
            getVotingInfoByUserAndIndex[msg.sender].push(VotingInfo({ lp: lps[i], pctBp: pctBps[i] }));
        }
        
        if (!hasUserVoted[msg.sender]) {
            getUserByIndex[userCount] = msg.sender;
            hasUserVoted[msg.sender] = true;
            userCount = userCount + 1;
        }

        emit voted(msg.sender, getVotingInfoByUserAndIndex[msg.sender]);
    }
}
