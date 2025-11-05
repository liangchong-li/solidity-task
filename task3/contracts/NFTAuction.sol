// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

// ✅  大作业：实现一个 NFT 拍卖市场
// 任务目标
// 使用 Hardhat 框架开发一个 NFT 拍卖市场。
// 使用 Chainlink 的 feedData 预言机功能，计算 ERC20 和以太坊到美元的价格。
// 使用 UUPS/透明代理模式实现合约升级。
// 使用类似于 Uniswap V2 的工厂模式管理每场拍卖。


// 任务步骤
// 项目初始化
// 使用 Hardhat 初始化项目：
// npx hardhat init
// 安装必要的依赖：
//   npm install @openzeppelin/contracts @chainlink/contracts @nomiclabs/hardhat-ethers hardhat-deploy
// 实现 NFT 拍卖市场
// NFT 合约：
// 使用 ERC721 标准实现一个 NFT 合约。
// 支持 NFT 的铸造和转移。
// 拍卖合约：
// 实现一个拍卖合约，支持以下功能：
// 创建拍卖：允许用户将 NFT 上架拍卖。
// 出价：允许用户以 ERC20 或以太坊出价。
// 结束拍卖：拍卖结束后，NFT 转移给出价最高者，资金转移给卖家。
// 工厂模式：
// 使用类似于 Uniswap V2 的工厂模式，管理每场拍卖。
// 工厂合约负责创建和管理拍卖合约实例。
// 集成 Chainlink 预言机
// 价格计算：
// 使用 Chainlink 的 feedData 预言机，获取 ERC20 和以太坊到美元的价格。
// 在拍卖合约中，将出价金额转换为美元，方便用户比较。
// 跨链拍卖：
// 使用 Chainlink 的 CCIP 功能，实现 NFT 跨链拍卖。
// 允许用户在不同链上参与拍卖。
// 合约升级
// UUPS/透明代理：
// 使用 UUPS 或透明代理模式实现合约升级。
// 确保拍卖合约和工厂合约可以安全升级。
// 测试与部署
// 测试：
// 编写单元测试和集成测试，覆盖所有功能。
// 部署：
// 使用 Hardhat 部署脚本，将合约部署到测试网（如 Goerli 或 Sepolia）。

// 任务要求
// 代码质量：
// 代码清晰、规范，符合 Solidity 最佳实践。
// 功能完整性：
// 实现所有要求的功能，包括 NFT 拍卖、价格计算和合约升级。
// 测试覆盖率：
// 编写全面的测试，覆盖所有功能。
// 文档：
// 提供详细的文档，包括项目结构、功能说明和部署步骤。

// 提交内容
// 代码：提交完整的 Hardhat 项目代码。
// 测试报告：提交测试报告，包括测试覆盖率和测试结果。
// 部署地址：提交部署到测试网的合约地址。
// 文档：提交项目文档，包括功能说明和部署步骤。

// 额外挑战（可选）
// 动态手续费：根据拍卖金额动态调整手续费。

contract NFTAuction is Initializable, UUPSUpgradeable {

    // 定义拍卖结构体
    struct Auction {
        // 卖家
        address seller;
        // 拍卖持续时间
        uint256 duration;
        // 起始价格
        uint256 startPrice;
        // 拍卖开始时间
        uint256 startTime;
        // 拍卖是否结束
        bool ended;
        // 加价幅度，多种代币可以参与拍卖，加价幅度也要统一。先不要了
        // uint256 bidIncrement;
        // 最高出价人
        address highestBidder;
        // 最高出价
        uint256 highestBid;
        // 拍卖的tokenId
        uint256 nftTokenId;
        // 拍卖的NFT 地址
        address nftTokenAddress;        
        // 竞拍出价的资产类型
        address bidTokenAddress;
    }

    address public _owner;
    uint256 private _nextAuctionId;
    // 多个拍卖
    mapping(uint256 => Auction) public _auctions;

    // Chainlink 价格预言机地址映射
    mapping(address => AggregatorV3Interface) public priceFeeds;
    
    function initialize() public initializer {
        _owner = msg.sender;
    }

    // 创建拍卖：允许用户将 NFT 上架拍卖。
    function createAuction(uint256 duration, uint256 startPrice, uint256 nftTokenId, address nftTokenAddress) public {
        // 只有管理员可以创建拍卖
        require(msg.sender == _owner, "Only owner can create auction.");
        require(duration > 0, "Duration must be greater than zero.");
        require(startPrice > 0, "Starting price must be greater than zero.");

        // 先将拍品放到合约里面
        IERC721(nftTokenAddress).safeTransferFrom(msg.sender, address(this), nftTokenId);

        // 创建拍卖
        _auctions[_nextAuctionId++] = Auction({
            seller: msg.sender,
            duration: duration,
            startTime: block.timestamp,
            startPrice: startPrice,
            highestBid: 0,
            highestBidder: address(0),
            ended: false,
            bidTokenAddress: address(0),
            nftTokenId: nftTokenId,
            nftTokenAddress: nftTokenAddress
        });
    }
    

    // 出价：允许用户以 ERC20 或以太坊出价。
    // 对哪个拍卖出价
    function placeBid(uint256 auctionId, address tokenAddress, uint256 price) external payable {
        Auction storage auctionItem = _auctions[auctionId];
        require(!auctionItem.ended && block.timestamp < auctionItem.startTime + auctionItem.duration, "Auction has ended.");

        // 统一价值
        uint payValue;
        // console.log("tokenAddress:", tokenAddress);
        // console.log("price:", price);
        // console.log("msg.value:", msg.value);
        if (tokenAddress == address(0)) {
            price = msg.value;
            payValue = price * uint(getChainlinkDataFeedLatestAnswer(address(0)));
            // payValue = msg.value * uint(getChainlinkDataFeedLatestAnswer(address(0))) / 1e8;
        }else {
            // ERC20 代币出价
            payValue = price * uint(getChainlinkDataFeedLatestAnswer(tokenAddress));
        }
        // console.log("ETH  peeds", uint(getChainlinkDataFeedLatestAnswer(address(0))));
        // console.log("USDC peeds", uint(getChainlinkDataFeedLatestAnswer(tokenAddress)));

        // console.log("payValue:", payValue);
        // console.log("startPrice:", auctionItem.startPrice * uint(getChainlinkDataFeedLatestAnswer(address(0))));
        require(payValue >= auctionItem.startPrice * uint(getChainlinkDataFeedLatestAnswer(address(0))), "Bid must be at least the starting price.");
        require(payValue >= auctionItem.highestBid * uint(getChainlinkDataFeedLatestAnswer(auctionItem.bidTokenAddress)), "Bid must be at least the highest bid");

        // 转移代币到合约
        // 如果是ERC20，手动处理；如果是ETH，receive函数已经处理
        if (tokenAddress != address(0)) {
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), price);
        }
        

        // 如果之前已有报价,退回之前的最高出价
        if (auctionItem.highestBidder != address(0)) {
            // 退回 ETH 或 REC20
            if (auctionItem.bidTokenAddress == address(0)) {
                payable(auctionItem.highestBidder).transfer(auctionItem.highestBid);
            }else {
                IERC20(auctionItem.bidTokenAddress).transfer(auctionItem.highestBidder, auctionItem.highestBid);
            }
        }
        // 更新最高出价和出价人
        auctionItem.highestBid = price;
        auctionItem.highestBidder = msg.sender;
        auctionItem.bidTokenAddress = tokenAddress;
    }

    // 结束拍卖：拍卖结束后，NFT 转移给出价最高者，资金转移给卖家。
    function endAuction(uint256 auctionId) public {
        Auction storage auctionItem = _auctions[auctionId];
        require(block.timestamp >= auctionItem.startTime + auctionItem.duration, "Auction is still ongoing.");
        require(!auctionItem.ended, "Auction has already been ended.");

        _auctions[auctionId].ended = true;
        // 转移 NFT 给最高出价者
        // IERC721(auctionItem.nftTokenAddress).safeTransferFrom(address(this), auctionItem.highestBidder, auctionItem.nftTokenId);
        // 转移资金给卖家
        // 如果有人出价
        if (auctionItem.highestBidder != address(0)) {
            // 转移 NFT 给最高出价者
            IERC721(auctionItem.nftTokenAddress).safeTransferFrom(
                address(this), 
                auctionItem.highestBidder, 
                auctionItem.nftTokenId
            );
            
            // 根据代币类型转移资金给卖家
            if (auctionItem.bidTokenAddress == address(0)) {
                // ETH 转账
                payable(auctionItem.seller).transfer(auctionItem.highestBid);
            } else {
                // ERC20 代币转账
                IERC20(auctionItem.bidTokenAddress).transfer(
                    auctionItem.seller, 
                    auctionItem.highestBid
                );
            }
        } else {
            // 如果没有人出价，将NFT退回给卖家
            IERC721(auctionItem.nftTokenAddress).safeTransferFrom(
                address(this), 
                auctionItem.seller, 
                auctionItem.nftTokenId
            );
        }
    }

    // 设置代币对应美金的喂价
    // tokenAddress: 代币地址，
    // priceFeed: Chainlink 价格预言机地址。
    // 固定地址： ETC  -> USD : 0x694AA1769357215DE4FAC081bf1f309aDC325306
    // 固定地址： USDC -> USD : 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E
    function setPriceFeed(address tokenAddress, address priceFeed) public {
        priceFeeds[tokenAddress] = AggregatorV3Interface(priceFeed);
    }

    function getChainlinkDataFeedLatestAnswer(address tokenAddress) public view returns (int) {
        AggregatorV3Interface priceFeed = priceFeeds[tokenAddress];
        // 返回一个代币可以兑换的美金
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        // int answer = priceFeed.latestRoundData();
        // console.log("answer:", answer);
        return answer;
    }

    


    // 合约升级
    // UUPS/透明代理：
    // 使用 UUPS 或透明代理模式实现合约升级。
    // 确保拍卖合约和工厂合约可以安全升级。
    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == _owner, "Only owner can upgrade the contract.");
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}