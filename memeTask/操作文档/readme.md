# MyMemeToken 操作指南

## 合约部署

### 1. 准备部署参数

部署合约时需要提供以下参数：

- **name_**: 代币名称（如："MyMemeToken"）
- **symbol_**: 代币符号（如："MMT"）
- **totalSupply_**: 总供应量（如：1000000）
- **route_**: Uniswap V2 Router 地址
  - 主网: `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D`
  - 测试网: 请查询对应网络的Router地址
- **txFeeWallet_**: 税金接收钱包地址

### 2. 部署步骤

1. 使用 Remix、Hardhat 或 Truffle 等工具编译合约
2. 连接到相应的以太坊网络（主网或测试网）
3. 提供足够的ETH支付Gas费用
4. 调用构造函数部署合约

## 代币交易

### 普通转账

javascript

```
// 调用 transfer 函数
await myMemeToken.transfer(recipientAddress, amount);

// 示例：转账100个代币
await myMemeToken.transfer("0x...", ethers.utils.parseUnits("100", 18));
```



### 授权转账

javascript

```
// 第一步：授权其他地址使用你的代币
await myMemeToken.approve(spenderAddress, amount);

// 第二步：被授权地址执行转账
await myMemeToken.transferFrom(fromAddress, toAddress, amount);
```



### 交易限制说明

- **单笔交易限额**: 总供应量的2%
- **每日交易次数**: 每个地址每天最多3次交易
- **交易税费**: 0.5%（500/10000）

## 流动性管理

### 添加流动性

#### 准备工作

1. 确保拥有足够的代币和ETH
2. 代币需要先授权给合约

javascript

```
// 授权代币给合约
await myMemeToken.approve(contractAddress, tokenAmount);

// 添加流动性
await myMemeToken.addLiquidity(
  tokenAmount,                    // 代币数量
  tokenAmountMin,                // 代币最小数量（防滑点）
  ethAmountMin,                  // ETH最小数量（防滑点）
  { value: ethAmount }           // 发送的ETH数量
);
```



#### 参数说明

- `tokenAmount`: 要添加的代币数量
- `tokenAmountMin`: 可接受的最少代币数量
- `ethAmountMin`: 可接受的最少ETH数量
- `ethAmount`: 实际发送的ETH数量

### 移除流动性

#### 准备工作

1. 拥有LP Token（流动性凭证）
2. 授权LP Token给合约

javascript

```
// 授权LP Token给合约
const lpToken = await ethers.getContractAt("IUniswapV2Pair", uniswapV2PairAddress);
await lpToken.approve(contractAddress, liquidity);

// 移除流动性
await myMemeToken.removeLiquidity(
  liquidity,                     // 要移除的流动性数量
  tokenAmountMin,               // 期望收到的最少代币数量
  ethAmountMin                  // 期望收到的最少ETH数量
);
```



## 管理功能

### 仅合约所有者可调用的功能

#### 修改税率

javascript

```
// 设置交易税率为1%（100/10000）
await myMemeToken.updateTxFee(100);
```



#### 修改单笔交易限额

javascript

```
// 设置单笔最大交易量为总供应量的5%
await myMemeToken.updateMaxTxAmount(newMaxTxAmount);
```



#### 修改每日交易次数限制

javascript

```
// 设置每日最大交易次数为5次
await myMemeToken.updateMaxTxDailyTimes(5);
```