const { ethers, upgrades} = require("hardhat")
const fs = require("fs")
const path = require("path")

module.exports = async ({getNamedAccounts, deployments}) => {
    const {save} = deployments;
    const {deployer} = await getNamedAccounts();
    console.log("Deploying NFTAuction with account:", deployer);

    // 读取配置文件
    const storePath = path.resolve(__dirname, "./.cache/proxyNFTAuction.json");
    const storeData = fs.readFileSync(storePath, "utf-8");
    const { proxyAddress, implAddress, abi } = JSON.parse(storeData);

    // 升级合约
    const NFTAuctionV2 = await ethers.getContractFactory("NFTAuctionV2")

    // 升级代理合约
    const nftAuctionProxyV2 = await upgrades.upgradeProxy(proxyAddress, NFTAuctionV2, { call: "_owner" })
    await nftAuctionProxyV2.waitForDeployment()
    const proxyAddressV2 = await nftAuctionProxyV2.getAddress()

    //   // 保存代理合约地址
//   fs.writeFileSync(
//     storePath,
//     JSON.stringify({
//       proxyAddress: proxyAddressV2,
//       implAddress,
//       abi,
//     })
//   );

  await save("NftAuctionProxyV2", {
    abi,
    address: proxyAddressV2,
  })

};
module.exports.tags = ['upgradeNFCAuction'];