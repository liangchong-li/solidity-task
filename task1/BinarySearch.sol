// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ✅  二分查找 (Binary Search)
// 题目描述：在一个有序数组中查找目标值。

contract BinarySearch {
    function find(uint[] calldata arr, uint target) public pure returns(uint) {
        // 二分查找，先左右边界，然后指定中间位置
        uint left = 0;
        uint right = arr.length - 1;
        // 左右指针交叉时推出
        while(left <= right) {
            uint mid = left + (right - left) / 2;
            if (arr[mid] == target) {
                return mid;
            }else if (arr[mid] < target) {
                left = mid + 1;
            }else {
                right = mid - 1;
            }
        }
        return 0;
    }
}