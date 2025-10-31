// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ✅  合并两个有序数组 (Merge Sorted Array)
// 题目描述：将两个有序数组合并为一个有序数组。

contract MergeSortedArray {
    function merger(uint[] calldata arr1, uint[] calldata arr2) public pure returns(uint[] memory arr) {
        uint[] memory res = new uint[](arr1.length + arr2.length);
        uint index1 = 0;
        uint index2 = 0;
        uint indexRes = 0;
        // 有一个索引越界了就结束。无法再比较了
        while(index1 < arr1.length && index2 < arr2.length) {
            if (arr1[index1] < arr2[index2]) {
                res[indexRes++] = arr1[index1++];
            }else {
                res[indexRes++] = arr2[index2++];
            }
        }
        // 跳出循环后，必然有一个索引越界，而另一个没有
        if (index1 >= arr1.length) {
            while(index2 < arr2.length) {
                res[indexRes++] = arr2[index2++];
            }
        }else {
            while(index1 < arr1.length) {
                res[indexRes++] = arr1[index1++];
            }
        }
        return res;
    }
}