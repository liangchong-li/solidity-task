const { deployments, upgrades, ethers } = require("hardhat");
const fs = require("fs")
const path = require("path")

module.exports = async ({getNamedAccounts, deployments}) => {
    const {save} = deployments;
    const {deployer} = await getNamedAccounts();
    console.log("Deploying NFTAuction with account:", deployer);

    const NFTAuction = await ethers.getContractFactory("NFTAuction");
    // 通过代理合约部署
    const nftAuctionProxy = await upgrades.deployProxy(NFTAuction, [], {initializer: 'initialize'});
    await nftAuctionProxy.waitForDeployment();

    const proxyAddress = nftAuctionProxy.target
    console.log("NFTAuction Proxy deployed to:", proxyAddress);
    // 实现合约的地址
    const implAddress = await upgrades.erc1967.getImplementationAddress(nftAuctionProxy.target);
    console.log("NFTAuction Implementation deployed to:", implAddress);

    // 保存部署信息
    const storePath = path.resolve(__dirname, "./.cache/proxyNFTAuction.json");
    fs.writeFileSync(
        storePath,
        JSON.stringify({
            proxyAddress,
            implAddress,
            abi: NFTAuction.interface.format("json"),
        })
    );

  await save("NftAuctionProxy", {
    abi: NFTAuction.interface.format("json"),
    address: proxyAddress,
  })

};
module.exports.tags = ['deployNFCAuction'];