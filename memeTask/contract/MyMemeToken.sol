// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract MyMemeToken is ERC20, Ownable {
    // ERC20 已实现
    // 代币名称
    // 代币符号
    // 代币单位

    // 总发行量
    uint256 private _totalSupply;

    // 账户余额
    mapping(address account => uint256) private _balances;

    // 单笔最大额度
    uint256 private _maxTxAmount;
    // 每日交易次数限制
    uint256 private _maxTxDailyTimes;

    // 每个地址每天交易次数mapping
    mapping(address => mapping(uint256 => uint256)) private _dailyTxes;

    // 税率（500 / 10000 高精度2）
    uint256 private _txFee = 500;

    // 税金账户
    address private _txFeeWallet;

    // 交易对mapping
    // mapping(address => address) name;

    // 公开的不可变（immutable）状态变量uniswapV2Router，类型为IUniswapV2Router02。
    // 这是Uniswap V2路由器的接口，用于与Uniswap交互。不可变变量在构造函数中设置后就不能更改。
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    // 流动性添加事件
    event AddLiquidity(
        address indexed account,
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    // 流动性移除事件
    event RemovedLiquidity(
        address indexed account,
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    // 代币税功能：实现交易税机制，对每笔代币交易征收一定比例的税费，并将税费分配给特定的地址或用于特定的用途。
    // 流动性池集成：设计并实现与流动性池的交互功能，支持用户向流动性池添加和移除流动性。
    // 交易限制功能：设置合理的交易限制，如单笔交易最大额度、每日交易次数限制等，防止恶意操纵市场。
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address route_,
        address txFeeWallet_
    ) ERC20(name_, symbol_) Ownable(_msgSender()) {
        _totalSupply = totalSupply_ * 10 ** decimals();
        // _mint(address(0), totalSupply_);

        // 设置Uniswap
        IUniswapV2Router02 route = IUniswapV2Router02(route_);
        uniswapV2Pair = IUniswapV2Factory(route.factory()).createPair(
            address(this),
            route.WETH()
        );
        uniswapV2Router = route;

        // 设置钱包
        _txFeeWallet = txFeeWallet_;

        // 设置交易限制
        // 1. 单笔最大额度 2%
        _maxTxAmount = (_totalSupply * 2) / 100;
        // 2. 每日交易次数限制
        _maxTxDailyTimes = 3;
    }

    // 重载totalSupply
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // 交易
    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        // 交易限制
        require(amount < _maxTxAmount, "Max tx amount exceeded");
        uint256 day = block.timestamp / 1 days;
        require(
            _dailyTxes[_msgSender()][day] < _maxTxDailyTimes,
            "Max daily trades exceeded"
        );
        // 税费计算
        uint256 txFee = _txFee * amount;

        // 调用 ERC20 转账
        // 税金转到专门账户
        _transfer(_msgSender(), _txFeeWallet, txFee);
        // 减去税金后，转账给to
        _transfer(_msgSender(), to, amount - txFee);

        return true;
    }

    // function _transfer(address from, address to, uint256 amount) internal  override {
    //     // 交易限制
    //     require(amount < _maxTxAmount, "Max tx amount exceeded");
    //     uint256 day = block.timestamp / 1 days;
    //     require(_dailyTxes[_msgSender()][day] < _maxTxDailyTimes, "Max daily trades exceeded");

    // }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        // 交易限制
        require(amount < _maxTxAmount, "Max tx amount exceeded");
        uint256 day = block.timestamp / 1 days;
        require(
            _dailyTxes[_msgSender()][day] < _maxTxDailyTimes,
            "Max daily trades exceeded"
        );

        // 调用 ERC20 检查 授权
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        // 税费计算
        uint256 txFee = _txFee * amount;
        // 调用 ERC20 转账
        // 税金转到专门账户
        _transfer(from, _txFeeWallet, txFee);
        // 减去税金后，转账给to
        _transfer(from, to, amount - txFee);

        return true;
    }

    // 添加流动性
    function addLiquidity(
        uint256 tokenAmount,
        uint256 tokenAmountMin,
        uint256 ethAmountMin
    ) external payable {
        // 先将代币转移到合约，然后合约才能授权路由器执行后面的操作
        // 代币转移到合约
        _transfer(_msgSender(), address(this), tokenAmount);

        // 合约授权路由器从合约地址转移tokenAmount数量的代币。
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // 添加流动性
        (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) = uniswapV2Router.addLiquidityETH{value: msg.value}(
                address(this),
                tokenAmount,
                tokenAmountMin,
                ethAmountMin,
                _msgSender(),
                block.timestamp
            );

        // 退还多余的代币。未使用的 ETH ，路由器会自动退回
        _transfer(address(this), _msgSender(), tokenAmount - amountToken);

        // 事件
        emit AddLiquidity(_msgSender(), amountToken, amountETH, liquidity);
    }

    // 移除流动性
    function removeLiquidity(
        uint256 liquidity,
        uint256 tokenAmountMin,
        uint256 ethAmountMin
    ) external {
        require(liquidity > 0, "Liquidity must be positive");
        // 将用户的LP token 转移到当前合约
        IUniswapV2Pair(uniswapV2Pair).transferFrom(
            _msgSender(),
            address(this),
            liquidity
        );
        // 当前合约授权uniswapV2Router使用这些 LP token
        IUniswapV2Pair(uniswapV2Pair).approve(
            address(uniswapV2Router),
            liquidity
        );

        // 将流动性移除，回收 ETH 和 合约token
        // 该函数会销毁LP Token，并将对应的两种资产（代币和ETH）转给用户（_msgSender()）
        (uint amountToken, uint amountETH) = uniswapV2Router.removeLiquidityETH(
            address(this),
            liquidity,
            tokenAmountMin,
            ethAmountMin,
            _msgSender(),
            block.timestamp
        );

        // 触发移除流动性事件
        emit RemovedLiquidity(_msgSender(), amountToken, amountETH, liquidity);
    }

    // ========================管理功能=======================
    // 修改税率
    function updateTxFee(uint256 txFee) public onlyOwner returns (bool) {
        require(txFee > 100, "The txFee/10000 must be greater than 0.01");
        require(txFee < 10000, "The txFee/10000 must be less than 1");
        _txFee = txFee;
        return true;
    }

    // 修改单笔最大额度
    function updateMaxTxAmount(
        uint256 maxTxAmount
    ) public onlyOwner returns (bool) {
        require(maxTxAmount > 0, "The maxTxAmount must be greater than 0");
        _maxTxAmount = maxTxAmount;
        return true;
    }

    // 修改每日交易次数限制
    function updateMaxTxDailyTimes(
        uint256 maxTxDailyTimes
    ) public onlyOwner returns (bool) {
        require(
            maxTxDailyTimes > 0,
            "The maxTxDailyTimes must be greater than 0"
        );
        _maxTxDailyTimes = maxTxDailyTimes;
        return true;
    }
}
