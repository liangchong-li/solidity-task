const { expect } = require("chai");
const { ethers, deployments, upgrades } = require("hardhat");

describe("NFTAuction", function () {
    it("Should be ok", async function () {
        // 1. 部署业务合约
        // 令部署脚本在测试中运行
        await deployments.fixture(["deployNFCAuction"]);

        // 获取代理合约实例
        const nftAuctionProxy = await deployments.get("NftAuctionProxy");

        // 获取合约对象 link deploy scripts code: await save("NftAuctionProxy", {})
        const nftAuction = await ethers.getContractAt("NFTAuction", nftAuctionProxy.address);


        // 2. 创建拍卖
        await nftAuction.createAuction(100 * 1000, ethers.parseEther("0.01"), 1,  ethers.ZeroAddress);
            

        const auction = await nftAuction._auctions(0);
        console.log("创建拍卖成功::", auction);
        
        // 3. 升级合约
        await deployments.fixture(["upgradeNFCAuction"]);

        // 4. 读取合约的 auction 0
        const auction2 = await nftAuction._auctions(0);

        expect(auction.startTime).to.equal(auction2.startTime);
        
        
        const nftAuctionV2 = await ethers.getContractAt("NFTAuctionV2", nftAuctionProxy.address);
        // v2能执行，v1不能执行
        console.log(await nftAuctionV2.testHello());
        // console.log(await nftAuction.testHello());
        // await main();
    });
})

// async function main() {
//     // const NFTAuction = await ethers.getContractFactory("NFTAuction");
//     // const [owner, otherAccount] = await ethers.getSigners();

//     // 根据工厂测试部署
//     const Constract = await ethers.getContractFactory("NFTAuction");
//     const contract = await Constract.deploy();
//     await contract.waitForDeployment();
//     // console.log("Contract deployed to:", contract.address);

//     // 测试创建拍卖
//     const tx = await contract.createAuction(
//         "0x8De3e4b5DAbFf9aC6A2c4080a1c1A2b1d6BAdE3B", // nft合约地址
//         1, // nft tokenId
//         60, // 拍卖时长，秒
//     );
//     await tx.wait();
//     console.log("Auction created");

//     // 测试出价
//     const bidTx = await contract.bid(0, { value: ethers.utils.parseEther("1") });
//     await bidTx.wait();
//     console.log("Bid placed");

//     // 测试结束拍卖
//     // 等待拍卖时间结束
//     await new Promise(resolve => setTimeout(resolve, 61000)); // 等待61秒

//     const endTx = await contract.endAuction(0);
//     await endTx.wait();
//     console.log("Auction ended");
    

// }