require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("@openzeppelin/hardhat-upgrades");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  // 配置命名账户,若不定义。在部署脚本中无法读取 
  // const {deployer} = await getNamedAccounts();
  // console.log("Deploying NFTAuction with account:", deployer);
  namedAccounts: {
    deployer: {
      default: 0,
      user1: 1,
      user2: 2,
    },
  },
};
