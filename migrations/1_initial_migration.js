const NFT = artifacts.require("NFT");
const Market = artifacts.require("NFTMarket");


module.exports = async (deployer) => {
  await deployer.deploy(Market,100);
  let marketaddress = Market.address;
  await deployer.deploy(NFT,marketaddress);
};
