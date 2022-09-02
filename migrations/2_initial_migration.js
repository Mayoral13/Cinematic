const CMATIC = artifacts.require("CMatic");
const Stake = artifacts.require("Staking");

module.exports = async (deployer) =>{
await deployer.deploy(CMATIC,"CINEMATIC","CMATIC",50000000);
const CmaticAddress = CMATIC.address;
console.log("Cinematic address is: ",CmaticAddress.toString());
await deployer.deploy(Stake,CmaticAddress);
const StakeAddress = Stake.address;
console.log("Staking Address is: ",StakeAddress.toString());
let matic = await CMATIC.deployed();
};

