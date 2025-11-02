// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ✅ 作业 1：ERC20 代币
// 任务：参考 openzeppelin-contracts/contracts/token/ERC20/IERC20.sol实现一个简单的 ERC20 代币合约。
// 要求：合约包含以下标准 ERC20 功能：
// balanceOf：查询账户余额。
// transfer：转账。
// approve 和 transferFrom：授权和代扣转账。
// 使用 event 记录转账和授权操作。
// 提供 mint 函数，允许合约所有者增发代币。
// 提示：
// 使用 mapping 存储账户余额和授权信息。
// 使用 event 定义 Transfer 和 Approval 事件。
// 部署到sepolia 测试网，导入到自己的钱包

contract MyIERC20 {
    // 转账事件。谁向谁转账多少金额
    event Transfer(address indexed from, address indexed to, uint256 amount);
    // 授权事件
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    string private _name; //名称
    string private _symbol; //符号
    // 总发行量
    uint256 private _total;
    address private _self;

    // 映射，存储用户余额
    mapping(address owner => uint256 balance) public _balances;
    // 映射，存储授权用户，以及用户剩余授权额度
    // 我向本合约登记，允许某个地址最多从我的账户转走的金额。即mapping[_owner][_spender]
    mapping(address owner => mapping(address spender => uint256 balance)) public _approvales;

    constructor(string memory name, string memory symbol) {
        _total = 1000000;
        _name = name;
        _symbol = symbol;
        _self = msg.sender;
        mint(_self, _total * 10 **18);
    }

    // 查询账户余额
    function balanceOf(address owner) public view returns(uint balance) {
        require(owner != address(0), "volid address");
    // require(amount > 0, "转账金额必须大于0");
        return _balances[owner];
    }
    
    // 转账。向地址 _to 转账 _value 数量的代币。
    function transfer(address to, uint256 value) public returns(bool success) {
        return _transfer(msg.sender, to, value);
    }
    
    function _transfer(address from, address to, uint256 value) internal returns(bool success) {
        require(from != address(0), "volid from address");
        require(to != address(0), "volid to address");
        require(value > 0, "amount must greater than 0");
        require(_balances[from] > value, "Insufficient balance");
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    // 授权。_owner 授权 地址 _spender 可以从您的账户中转走最多 _value 数量的代币。
    function approve(address spender, uint256 value) public returns(bool success) {
        return _approve(msg.sender, spender, value);
    }

    function _approve(address owner, address spender, uint256 value) public returns(bool success) {
        require(owner != address(0), "volid owner address");
        require(spender != address(0), "volid spender address");
        require(value > 0, "amount must greater than 0");
        _approvales[owner][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // 代扣转账。不是_owner来发起交易，而是_spender发起
    function transferFrom(address from, address to, uint256 value) public returns(bool success) {
        // 查看授权额度是否足够
        bool ok = _approvales[from][msg.sender] - value > 0;
        if (ok) {
            _transfer(from, to, value);
        }
        return ok;
    }

    modifier onlyOwner(){
        require(msg.sender == _self, "ERC20Token: only owner allowed");
        _;
    }

    //合约所有者增发代币
    function mint(address account,uint256 amount) internal onlyOwner {
        require(account != address(0), "ERC20Token: mint to the zero address");
        //增加总发行量
        _total += amount;
        //给目标地址加钱
        _balances[account] += amount;
        //从0地址转过来（代表“新发行”）
        emit Transfer(address(0), account, amount);
    }
}