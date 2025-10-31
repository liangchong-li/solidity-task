// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReverseString {
    // ✅ 反转字符串 (Reverse String)
    // 题目描述：反转一个字符串。输入 "abcde"，输出 "edcba"
    // 字符串无法直接操作，转换为bytes
    function reverse (string calldata str) public pure returns(string memory) {
        bytes memory bytesStr = bytes(str);
        bytes memory reversed = new bytes(bytesStr.length);
        for (uint i = 0;i < bytesStr.length; i++) {
            reversed[i] = bytesStr[bytesStr.length - 1 - i];
        }
        return string(reversed);
    }
}