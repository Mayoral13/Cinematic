const assert = require("chai/lib/chai/interface/assert");
const { default: Web3 } = require("web3");
const market = artifacts.require("Marketplace");
const nft = artifacts.require("NFT");
const factory = artifacts.require("NFTFactory");
let catchRevert = require("../execption").catchRevert;
contract("Marketplace x Factory x NFT",(accounts)=>{
    let alpha = await factory.deployed();
    let mark = await market.deployed();
    let ns = await nft.deployed();
    let admin = accounts[0]; //OWNER OF MARKETPLACE
    let user = accounts[1]; //OWNER OF COLLECTION
    let nonuser = accounts[2]; // NOT OWNER
    let royaltyaddress = accounts[3]; //ROYALTY ADDRESS V1
    let royaltyaddress2 = accounts[4]; //ROYALTY ADDRESS V2
    alpha.CreateCollection("BOYS","SAPS",50,royaltyaddress,{from:user});
    let clonecollection = await alpha.RevealClones(0,{from:user});
    let collectionaddress = clonecollection.address;
    let clone = await NFT.at(collectionaddress);

    it("Can deploy successfully",async()=>{
        let nftaddress = ns.address;
        let marketaddress = mark.address;
        let address = alpha.address;
        assert(address != "");
        console.log('Market address is: ',marketaddress.toString());
        console.log("NFT address is: ",nftaddress.toString());
        console.log('Factory address is: ',address.toString());
        console.log("Collection address is: ",collectionaddress.toString());
    });
    //START OF FACTORY TESTING
    it("Can create Collection",async()=>{
        alpha.CreateCollection("SAPABOYS","SAPS",50,royaltyaddress,{from:user});
        let collection = await alpha.RevealCollection({from:user});
        assert(collection != "");
    });
    it("Can reveal Clones of NFT",async()=>{
        let clone = await alpha.RevealClones(0);
        assert(clone != "");
    });
    it("Should revert if user tries to view invalid clone",async()=>{
        await catchRevert(alpha.RevealClones(3));
    });
    it("Should verify if collection contract is an NFT",async()=>{
        let verify = await isNFT(clonecollection);
        assert.equal(verify,true);
    });
    it("Should revert if a user tries to check an address not created by collection",async()=>{
        await catchRevert(alpha.isNFT(marketaddress));
    });
    //END OF FACTORY TESTING
    
    //START OF NFT TESTING
    it("Created Collection should assign correct owner",async()=>{
        let owner = await clone.owner();
        console.log("The owner address is: ",owner.toString());
        assert.equal(owner,user);
    });
    it("Created Collection should have the correct name",async()=>{
        let name = await clone.name();
        console.log("The name is: ",owner.toString());
        assert.equal(name,"BOYS");
    });
    it("Created Collection should have the correct symbol",async()=>{
        let symbol = await clone.symbol();
        console.log("The symbol is: ",owner.toString());
        assert.equal(symbol,"SAPS");
    });
    it("Royalty fee is correctly set",async()=>{
        const expected = 50;
        let fee = await clone.RoyaltyFee();
        assert.equal(expected,fee);
    });
    it("Royalty Reciever is correctly set",async()=>{
        let reciever = await clone.RoyaltyReciever();
        assert.equal(reciever,royaltyaddress);
    });
    it("Owner can Mint NFT",async()=>{
        await clone.MintNFT("ABEG",{from:user});
        let tokens = await clone.RevealTokenID({from:user});
        assert(tokens != "");
    });
    it("Owner can change Royalty Reciever",async()=>{
        await clone.ChangeRoyaltyReciever(royaltyaddress2,{from:user});
        let reciever = await clone.RoyaltyReciever();
        assert.equal(reciever,royaltyaddress2);
    });
    it("Should revert if user tries to create collection with a fee greater than 10%",async()=>{ //10% => 100
        await catchRevert(alpha.CreateCollection("SAPABOYS","SAPS",101,royaltyaddress,{from:user}));
    });
      
    it("Should revert if non owner tries to MintNFT",async()=>{
        await catchRevert(clone.MintNFT("ABEG",{from:nonuser}));
    });
    it("Should revert if non owner tries to Change Royalty Reciever",async()=>{
        await catchRevert(clone.ChangeRoyaltyReciever(royaltyaddress2,{from:nonuser}));
    });
    it("Owner can change fee",async()=>{
        await clone.ChangeFee(20,{from:user});
        let fee = await clone.RoyaltyFee();
        assert.equal(fee,20);
    });
    it("Owner cannot set fee to greater than 10%",async()=>{ //10% => 100
        await catchRevert(clone.ChangeFee(101,{from:user}));
    });
    it("TokenURI should be set correctly",async()=>{
        let uri = await clone.tokenURI(1);
        assert.equal(uri,"ABEG");
    });
    //END OF NFT TESTING

    //START OF MARKETPLACE TESTING
    it("Marketplace fee should be set correctly",async()=>{
        let fee = await mark.fee();
        assert.equal(fee,50);
    });
    it("Can create a Listing",async()=>{
        await mark.CreateListing(collectionaddress,150,1,{from:user});
        let listing = await clone.ownerOf(1);
        assert.equal(listing,marketaddress);
    });
    it("Cannot List an already listed item",async()=>{
        await catchRevert(mark.CreateListing(collectionaddress,150,1,{from:user}));
    });
    it("Cannot list an already listed item",async()=>{
        await catchRevert(mark.CreateAuction(collectionaddress,150,1,1,360,{from:user}));
    });
    it("Can create Auction",async()=>{
        await clone.MintNFT("BOSS",{from:user});
        await mark.CreateAuction(collectionaddress,150,2,0,360,{from:user});
        let listing = await clone.ownerOf(2);
        assert.equal(listing,marketaddress);
    });
    it("Cannot List an Auctioned Item",async()=>{
        await mark.CreateListing(collectionaddress,150,2,{from:user});
    });
    it("Collection Owner cannot buy own listing",async()=>{
        await catchRevert(mark.BuyNFT(collectionaddress,1,{value:150,from:user}));
    });
    it("User cannot set price to zero when creating listing",async()=>{
        await catchRevert(mark.CreateListing(collectionaddress,150,3,{from:user}));
    });
    it("User can buy listing and ownership is transferred",async()=>{
        await mark.BuyNFT(collectionaddress,1,{value:150,from:nonuser});
        let check = await clone.ownerOf(1);
        assert.equal(check,nonuser);
    })
    it("User can Buy NFT and every fee will be subtracted",async()=>{
        let beforeroyaltyaddressbalance = web3.eth.getBalance(royaltyaddress2);
        let beforeownerbalance = web3.eth.getBalance(user);
        await clone.MintNFT("BOSS",{from:user});
        await mark.CreateListing(collectionaddress,10e18,3,{from:user});
        await mark.BuyNFT(collectionaddress,3,{value:10e18,from:nonuser});
        const marketexpected = 50e15;
        let aftermarketbalance = await web3.eth.getBalance(marketaddress);
        let afterroyaltyaddressbalance = await web3.eth.getBalance(royaltyaddress2);
        let afterownerbalance = await web3.eth.getBalance(user);
        assert.equal(aftermarketbalance,marketexpected);
        assert(beforeroyaltyaddressbalance != afterroyaltyaddressbalance);
        assert(beforeownerbalance != afterownerbalance);
    });
    it("User cannot buy already bought NFT",async()=>{
        await catchRevert(mark.BuyNFT(collectionaddress,3,{value:10e18,from:accounts[5]}));
    });
    it("User cannot list already bought NFT",async()=>{
        await catchRevert(mark.CreateListing(collectionaddress,10e18,3,{from:user}));
    });
    it("Can calculate royalty fee",async()=>{
        const royalty = await mark.CalculateRoyaltyFee(10e18,20);
        assert.equal(royalty,20e15);
    });
    it("Can calculate Market fee",async()=>{
        const market = await mark.CalculateMarketFee(10e18);
        assert.equal(market,50e15);
    });
    it("Owner is properly assigned to",async()=>{
        const owneradd = await market.owner();
        console.log("Address of owner of marketplace is : ",owneradd.toString());
        assert.equal(owner,owneradd);
    });
    it("Only admin can withdraw funds from contract",async()=>{
        await catchRevert(mark.Withdraw(owner,50,{from:royaltyaddress}));
    });
    it("Non Owner Can cancel Auction",async()=>{
        await catchRevert(market.CancelAuction(collectionaddress,2,{from:admin}));
    });
    it("Non Owner Can cancel Auction if auction has started",async()=>{
        await catchRevert(market.CancelAuction(collectionaddress,2,{from:admin}));
    });
    it("Non user cannot cancel Listing",async()=>{
        await clone.MintNFT("BIG BOSS",{from:user});
        await mark.CreateListing(collectionaddress,150,{from:user});
        await catchRevert(market.CancelListing(collectionaddress,4,{from:admin}));
    });
    it("User can cancel Listing",async()=>{
        await market.CancelListing(collectionaddress,4,{from:user});
        const check = await clone.ownerOf(4);
        assert.equal(check,user);
    });
    it("Cannot Bid for Not listed NFT",async()=>{
       await catchRevert(market.Bid(collectionaddress,4,{value:150,from:nonuser}));
    });
    it("Cannot Buy Not Listed NFT",async()=>{
        await catchRevert(market.BuyNFT(collectionaddress,2,{from:nonuser,value:150}));
    });
    it("Can Bid for an Auctioned Listed NFT",async()=>{
        let balancebefore = await web3.eth.getBalance(nonuser);
        await clone.MintNFT("BIG BOSS",{from:user});
        await mark.CreateAuction(collectionaddress,150,5,0,3,{from:user});
        await mark.Bid(collectionaddress,5,{from:nonuser,value:150});
        let balanceafter = await web3.eth.getBalance(nonuser);
        assert(balancebefore != balanceafter);
    });
     it("User cannot claim NFT unless winner",async()=>{
        await catchRevert(mark.ClaimNFT(collectionaddress,5,{from:admin}));
     });
     it("Can View highest bid of Auctioned NFT",async()=>{
        const bid = await market.ViewHighestBid(collectionaddress,5);
        assert.equal(bid,150)
     });
     it("Only highest bidder can claim NFT",async()=>{
        await market.ClaimNFT(collectionaddress,5,{from:user});
        let clone = await clone.ownerOf(5);
        assert.equal(clone,nonuser);
     })
    

});







  