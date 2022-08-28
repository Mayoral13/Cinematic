const Factory = artifacts.require("NFTFactory")
const Market = artifacts.require("Marketplace");
const NFT = artifacts.require("NFT");

module.exports = async (deployer) =>{
await deployer.deploy(Factory);
const factoryaddress = Factory.address;
console.log("The Factory address is : ",factoryaddress.toString());
await deployer.deploy(Market,50);
const marketaddress = Market.address;
console.log("The Market address is : ",marketaddress.toString());
await deployer.deploy(NFT,marketaddress,"TRIAL","TT",50,marketaddress);
/// CONTINUE READING AND WRITING FUNCTIONS
};

