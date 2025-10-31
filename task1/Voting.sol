// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 创建一个名为Voting的合约，包含以下功能：
// 一个mapping来存储候选人的得票数
// 一个vote函数，允许用户投票给某个候选人
// 一个getVotes函数，返回某个候选人的得票数
// 一个resetVotes函数，重置所有候选人的得票数

contract Voting {
    mapping(string name => uint256 votes) public candidateVote;
    string[] public candidaters;

    // calldata: 用于存储函数参数的特殊数据位置。
    function voite (string calldata name) public {
        if (candidateVote[name] == 0) {
            // candidaters[length(candidaters) - 1] = name;
            candidaters.push(name);
            // candidaters[candidaters.length - 1] = name;
        }
        candidateVote[name] += 1;
    }

    function getVotes (string calldata name) public view returns(uint256) {
        return candidateVote[name];
    }

    // solidity中不支持对映射进行遍历
    // 借助一个可变数组来遍历。（更优方案：结构体 + 版本号）
    function resetVotes () public returns(uint) {
        for (uint256 i = 0; i < candidaters.length; i++) {
            candidateVote[candidaters[i]] = 0;
        }
    }
}