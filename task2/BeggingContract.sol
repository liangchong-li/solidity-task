// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ✅ 作业3：编写一个讨饭合约
// 任务目标
// 使用 Solidity 编写一个合约，允许用户向合约地址发送以太币。
// 记录每个捐赠者的地址和捐赠金额。
// 允许合约所有者提取所有捐赠的资金。

// 任务步骤
// 编写合约
// 创建一个名为 BeggingContract 的合约。
// 合约应包含以下功能：
// 一个 mapping 来记录每个捐赠者的捐赠金额。
// 一个 donate 函数，允许用户向合约发送以太币，并记录捐赠信息。
// 一个 withdraw 函数，允许合约所有者提取所有资金。
// 一个 getDonation 函数，允许查询某个地址的捐赠金额。
// 使用 payable 修饰符和 address.transfer 实现支付和提款。
// 部署合约
// 在 Remix IDE 中编译合约。
// 部署合约到 Goerli 或 Sepolia 测试网。
// 测试合约
// 使用 MetaMask 向合约发送以太币，测试 donate 功能。
// 调用 withdraw 函数，测试合约所有者是否可以提取资金。
// 调用 getDonation 函数，查询某个地址的捐赠金额。

// 任务要求
// 合约代码：
// 使用 mapping 记录捐赠者的地址和金额。
// 使用 payable 修饰符实现 donate 和 withdraw 函数。
// 使用 onlyOwner 修饰符限制 withdraw 函数只能由合约所有者调用。
// 测试网部署：
// 合约必须部署到 Goerli 或 Sepolia 测试网。
// 功能测试：
// 确保 donate、withdraw 和 getDonation 函数正常工作。

// 提交内容
// 合约代码：提交 Solidity 合约文件（如 BeggingContract.sol）。
// 合约地址：提交部署到测试网的合约地址。
// 测试截图：提交在 Remix 或 Etherscan 上测试合约的截图。

// 额外挑战（可选）
// 捐赠事件：添加 Donation 事件，记录每次捐赠的地址和金额。
// 捐赠排行榜：实现一个功能，显示捐赠金额最多的前 3 个地址。
// 时间限制：添加一个时间限制，只有在特定时间段内才能捐赠。

// 创建一个名为 BeggingContract 的合约。
contract BeggingContract {
    // 捐赠事件（额外）
    event Donation(address sender, uint amount);

    // 时间段更新事件
    event DonationTimeUpdated(uint256 startTime, uint256 endTime);

    address private _owner;


    // 合约应包含以下功能：
    // 一个 mapping 来记录每个捐赠者的捐赠金额。
    mapping(address donor => uint256 amount) private _donors;

    // 维护两个数组，包含前三的捐赠者
    address[3] private top3Donors;
    uint256[3] private top3Amount3;

    // 捐赠时间段
    uint256 private _donationStartTime;
    uint256 private _donationEndTime;

    constructor() {
        _owner = msg.sender;
        // 默认时间段，全天
    }


    // 一个 donate 函数，允许用户向合约发送以太币，并记录捐赠信息。
    function donate() public payable {
        require(msg.value > 0, "amount must be greater than 0");
        // 时间限制：添加一个时间限制，只有在特定时间段内才能捐赠。(额外)
        require(isInDonationTime(), "not in donation time");
        _donors[msg.sender] += msg.value;
        _updateTop3(msg.sender, _donors[msg.sender]);
    }
    

    function _updateTop3(address donor, uint256 amount) private {
        // 如果新值比第三大的值大，则更新
        if (amount > top3Amount3[2]) {
            // 找到插入位置
            if (amount > top3Amount3[0]) {
                // 插入到第一位
                top3Amount3[2] = top3Amount3[1];
                top3Amount3[1] = top3Amount3[0];
                top3Amount3[0] = amount;
                
                top3Donors[2] = top3Donors[1];
                top3Donors[1] = top3Donors[0];
                top3Donors[0] = donor;
            } else if (amount > top3Amount3[1]) {
                // 插入到第二位
                top3Amount3[2] = top3Amount3[1];
                top3Amount3[1] = amount;
                
                top3Donors[2] = top3Donors[1];
                top3Donors[1] = donor;
            } else {
                // 插入到第三位
                top3Amount3[2] = amount;
                top3Donors[2] = donor;
            }
        }
    }

    receive() external payable {
        donate();
        emit Donation(msg.sender, msg.value);
    }


    // 一个 withdraw 函数，允许合约所有者提取所有资金。
    // 使用 payable 修饰符和 address.transfer 实现支付和提款。
    // 使用 onlyOwner 修饰符限制 withdraw 函数只能由合约所有者调用。
    // 自定义修饰符，仅允许合约所有者调用
    modifier onlyOwner {
        require(msg.sender == _owner, "not owner");
        _;
    }

    function withdraw() public payable onlyOwner {
        // (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        // require(success, "Call failed");
        payable(msg.sender).transfer(address(this).balance);
    }

    // 一个 getDonation 函数，允许查询某个地址的捐赠金额。
    function getDonation(address donor) public view returns(uint amount) {
        return _donors[donor];
    }
    
    // 捐赠排行榜：实现一个功能，显示捐赠金额最多的前 3 个地址。
    function donateTop3() public view returns(address top1, address top2, address top3) {
        return (top3Donors[0], top3Donors[0], top3Donors[0]);
    }

    // 设置捐赠时间段（仅合约所有者）
    function setDonationTime(uint256 startTime, uint256 endTime) public onlyOwner {
        require(startTime < endTime, "Start time must be before end time");
        require(endTime < 1 days, "Time must be within 24 hours");
        
        _donationStartTime = startTime;
        _donationEndTime = endTime;
        
        emit DonationTimeUpdated(startTime, endTime);
    }

    // 获取当前捐赠时间段
    function getDonationTime() public view returns (uint256 startTime, uint256 endTime) {
        return (_donationStartTime, _donationEndTime);
    }

    // 检查当前是否在捐赠时间段内（公共视图函数）
    function isInDonationTime() public view returns (bool) {
        return _isInDonationTime();
    }

    // 检查当前是否在捐赠时间段内
    function _isInDonationTime() private view returns (bool) {
        // 获取当前时间在一天中的秒数（0-86399）
        uint256 currentTimeOfDay = block.timestamp % 1 days;
        
        return currentTimeOfDay >= _donationStartTime && currentTimeOfDay <= _donationEndTime;
    }

    // 获取当前时间在一天中的秒数（辅助函数）
    function getCurrentTimeOfDay() public view returns (uint256) {
        return block.timestamp % 1 days;
    }
}