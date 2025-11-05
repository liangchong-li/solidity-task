const { expect } = require("chai");
const { ethers, deployments, upgrades } = require("hardhat");

describe("NFTAuction", function () {
    it("Should be ok", async function () {
        const [signer, buyer1, buyer2] = await ethers.getSigners();
        // console.log("signer:", signer);
        // console.log("buyer1:", buyer1);
        // console.log("buyer2:", buyer2);
        // 1. 部署业务合约
        // 令部署脚本在测试中运行
        await deployments.fixture(["deployNFCAuction"]);

        // 获取代理合约实例
        const nftAuctionProxy = await deployments.get("NftAuctionProxy");

        // 获取合约对象 link deploy scripts code: await save("NftAuctionProxy", {})
        const nftAuction = await ethers.getContractAt("NFTAuction", nftAuctionProxy.address);


        // 部署ERC20测试币（不用代理，直接部署）
        const TestERC20 = await ethers.getContractFactory("TestERC20");
        const testERC20 = await TestERC20.deploy();
        await testERC20.waitForDeployment();
        const UsdcAddress = await testERC20.getAddress();
        console.log("TestERC20 deployed to:", UsdcAddress);

        let tx = await testERC20.connect(signer).transfer(buyer1, ethers.parseEther("1000"));
        await tx.wait();
        
        // 查看signer余额
        const signerBal = await testERC20.balanceOf(signer.address);
        // 查看 buyer1余额
        const buyer1Bal = await testERC20.balanceOf(buyer1.address);

        expect(signerBal).to.equal(ethers.parseEther("99000"));
        expect(buyer1Bal).to.equal(ethers.parseEther("1000"));


        // 创建测试预言机
        const TestV3Aggregator = await ethers.getContractFactory("TestV3Aggregator");
        const priceFeedEthDeploy = await TestV3Aggregator.deploy(ethers.parseEther("10000"))
        const priceFeedEth = await priceFeedEthDeploy.waitForDeployment()
        const priceFeedEthAddress = await priceFeedEth.getAddress()
        console.log("ethFeed: ", priceFeedEthAddress)

        const priceFeedUSDCDeploy = await TestV3Aggregator.deploy(ethers.parseEther("1"))
        const priceFeedUSDC = await priceFeedUSDCDeploy.waitForDeployment()
        const priceFeedUSDCAddress = await priceFeedUSDC.getAddress()
        console.log("usdcFeed: ", await priceFeedUSDCAddress)

        const token2Usd = [{
            token: ethers.ZeroAddress,
            priceFeed: priceFeedEthAddress
        }, {
            token: UsdcAddress,
            priceFeed: priceFeedUSDCAddress
        }];

        // 设置预言机地址
        // 遍历token2Usd
        for (const item of token2Usd) {
            // const { token, priceFeed } = item;
            await nftAuction.setPriceFeed(item.token, item.priceFeed);
            // const tx = await nftAuction.connect(signer).setPriceFeed(item);
            // await tx.wait();
        }
        
        // 验证预言机地址
        const ethFeedOnchain = await nftAuction.priceFeeds(ethers.ZeroAddress);
        const usdcFeedOnchain = await nftAuction.priceFeeds(UsdcAddress);
        expect(ethFeedOnchain).to.equal(priceFeedEthAddress);
        expect(usdcFeedOnchain).to.equal(priceFeedUSDCAddress);


        // 部署ERC721拍品
        const TestERC721 = await ethers.getContractFactory("TestERC721");
        const testERC721 = await TestERC721.deploy();
        await testERC721.waitForDeployment();
        const testERC721Address = await testERC20.getAddress();
        console.log("TestERC721 deployed to:", testERC721Address);

        // mint 10 个 NFT
        for(let i = 0; i < 10; i++) {
            await testERC721.mint(signer);
        }

        // 查看账户NFT
        // 检查余额
        expect(await testERC721.balanceOf(signer.address)).to.equal(10);
    
        // 检查所有权
        for(let i = 0; i < 10; i++) {
            expect(await testERC721.ownerOf(i)).to.equal(signer.address);
        }
        
        // 给代理合约授权
        // 未授权时，在创建拍卖时，无法将NFT转到合约
        await testERC721.connect(signer).setApprovalForAll(nftAuctionProxy.address, true);

        // 2. 创建拍卖
        // uint256 duration, uint256 startingPrice, uint256 nftTokenId, address nftTokenAddress
        console.log("创建拍卖前");
            // await nftAuction.createAuction(10, ethers.parseEther("0.01"), 0, testERC721Address);
            await nftAuction.createAuction(
            10,
            ethers.parseEther("0.01"),
            testERC721Address,
            0
        );
        const auction = await nftAuction._auctions(0)
        console.log("创建拍卖成功：", auction);

        // 3. 参与拍卖
        // buyer1使用 ETH 竞拍
        // placeBid(uint256 auctionId, uint256 price, address tokenAddress)
        // tx = await nftAuction.connect(buyer1).placeBid(0, ethers.parseEther("0.02"), ethers.ZeroAddress);
        // await tx.wait();
        // buyer2使用 USDC 竞拍

        // 3. 购买者参与拍卖
        // await testERC721.connect(buyer).approve(nftAuctionProxy.address, tokenId);
        // ETH参与竞价
        // tx = await nftAuction.connect(buyer1).placeBid(0, 0, ethers.ZeroAddress, { value: ethers.parseEther("0.01") });
        // await tx.wait()

        // USDC参与竞价
        // tx = await testERC20.connect(buyer1).approve(nftAuctionProxy.address, ethers.MaxUint256)
        // await tx.wait()
        // tx = await nftAuction.connect(buyer1).placeBid(0, ethers.parseEther("101"), UsdcAddress);
        // await tx.wait()
    });
})