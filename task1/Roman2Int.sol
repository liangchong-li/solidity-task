// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ✅  用 solidity 实现罗马数字转数整数
// 题目描述在 https://leetcode.cn/problems/integer-to-roman/description/

contract Roman2Int {
    
    mapping(bytes1 => int) romanValues;

    constructor() {
        // 初始化罗马数字映射
        romanValues['I'] = 1;
        romanValues['V'] = 5;
        romanValues['X'] = 10;
        romanValues['L'] = 50;
        romanValues['C'] = 100;
        romanValues['D'] = 500;
        romanValues['M'] = 1000;
    }

    function transfer(string calldata roman) public view returns(int) {
        bytes memory temp = bytes(roman);
        int result = 0;
        for (uint i = 0; i < temp.length; i++) {
            int cur = romanValues[(temp[i])];
            // 与下一个字符比较，若有，且当前值较小，则减去当前值
            if (i < temp.length - 1 && cur < romanValues[(temp[i + 1])]) {
                result -= cur;
                continue;
            }
            result += cur;
        }
        return result;
    }
}