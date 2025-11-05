require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  // 配置命名账户,若不定义。在部署脚本中无法读取 
  // const {deployer} = await getNamedAccounts();
  // console.log("Deploying NFTAuction with account:", deployer);
  // 配置网络，准备部署
  networks: {
    sepolia: {
      url: "https://sepolia.infura.io/v3/e98785ce63ef4bf9a8b977697a83e786",
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    // namedAccounts: {
    //   deployer: {
    //     default: 0,
    //     user1: 1,
    //     user2: 2,
    //   },
    // },
  },
};
