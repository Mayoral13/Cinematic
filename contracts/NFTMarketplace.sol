// SPDX-License-Identifier: MIT
//Dev : Mayoral13
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SafeMath.sol";
interface INFT{
    function RoyaltyFee()external view returns(uint256);
    function RoyaltyReciever()external view returns(address);
}
contract Marketplace is Ownable,ReentrancyGuard{
    using SafeMath for uint;
    
    
    uint256 public Fee;
   
    constructor(uint256 _fee){
        require(_fee <= 100,"Fee cannot be greater than 10%");
        Fee = _fee;
    }
    
    struct ListNFT{
        address NFTAddr;
        uint price;
        uint tokenID;
        address seller;
    }
  
      struct Auction{
        address creator;
        address nft;
        uint startingbid;
        uint start;
        uint end;
        uint tokenID;
        address lastBidder;
        uint highestbid;
    }
   
    modifier isListed(address _nft,uint _tokenID){
        require(listed[_nft][_tokenID] == true,"NFT not listed");
        _;
    }
      modifier isNotListed(address _nft,uint _tokenID){
        require(listed[_nft][_tokenID] == false,"NFT is listed");
        _;
    }
    modifier isLister(address _nft,uint _tokenID){
        require(msg.sender == listNFT[_nft][_tokenID].seller,"You are not the owner");
        _;
    }
      modifier isAuctioner(address _nft,uint _tokenID){
        require(msg.sender == listNFT[_nft][_tokenID].seller,"You are not the owner");
        _;
    }
    modifier isAuctioned(address _nft,uint _tokenID){
        require(auctioned[_nft][_tokenID] == true,"NFT not auctioned");
        _;
    }
     modifier isNotAuctioned(address _nft,uint _tokenID){
        require(auctioned[_nft][_tokenID] == false,"NFT is auctioned");
        _;
    }

    event Withdrawn(address indexed _by,address _to,uint _amount);
    event NFTClaimed(address indexed _by,address _nft,uint _tokenID);
    event ListingCanceled(address indexed _by,address _nft,uint _tokenID);
    event AuctionCanceled(address indexed _by,address _nft,uint _tokenID);
    event NFTBought(address indexed _by,address _nft,uint _tokenID,uint _price);
    event NFTListed(address indexed _by,address _nft,uint _tokenID,uint _price);
    event AuctionCreated(address indexed _by,address _nft,uint _tokenID,uint _startingbid);
    event Bidding(address indexed _by,address _nft,uint _tokenID,uint _currentbid);

    mapping(address => mapping(uint => bool))private listed;
    mapping(address => mapping(uint => address))private nftAddress;
    mapping(address => mapping(uint => bool))private auctioned;
    mapping(address => mapping(uint => ListNFT))private listNFT;
    mapping(address => mapping(uint => uint))private highestbid;
    mapping(address => mapping(uint => Auction))private auctions;
    
    
    function CreateListing(address _nft,uint _price,uint _tokenID)external isNotListed(_nft,_tokenID) isNotAuctioned(_nft,_tokenID){
        IERC721 nft = IERC721(_nft);
        require(_price != 0);
        listed[_nft][_tokenID] = true;
        nft.transferFrom(msg.sender,address(this),_tokenID);
        listNFT[_nft][_tokenID].NFTAddr = _nft;
        listNFT[_nft][_tokenID].price = _price;
        listNFT[_nft][_tokenID].tokenID = _tokenID;
        listNFT[_nft][_tokenID].seller = payable(msg.sender);
        nftAddress[msg.sender][_tokenID] = _nft;
        emit NFTListed(msg.sender,_nft,_tokenID, _price);
    }
    function CreateAuction(address _nft,uint _bid,uint _tokenID,uint _start,uint _end) isNotListed(_nft,_tokenID) isNotAuctioned(_nft,_tokenID)external{
      IERC721 nft = IERC721(_nft);
      nft.transferFrom(msg.sender,address(this),_tokenID);
      require(_bid != 0);
      require(_end > _start);
      auctioned[_nft][_tokenID] = true;
      auctions[_nft][_tokenID].creator = payable(msg.sender);
      auctions[_nft][_tokenID].nft = _nft;
      auctions[_nft][_tokenID].startingbid = _bid;
      auctions[_nft][_tokenID].start = _start.add(block.timestamp);
      auctions[_nft][_tokenID].end = _end.add(block.timestamp);
      auctions[_nft][_tokenID].tokenID = _tokenID;
      nftAddress[msg.sender][_tokenID] = _nft;
      emit AuctionCreated(msg.sender, _nft, _tokenID,_bid);
    }
    function BuyNFT(address _nft,uint _tokenID)external payable nonReentrant isListed(_nft,_tokenID){ 
        require(msg.sender != listNFT[_nft][_tokenID].seller);
        require(msg.value >= listNFT[_nft][_tokenID].price);
        INFT nft = INFT(listNFT[_nft][_tokenID].NFTAddr);
        uint256 Total = listNFT[_nft][_tokenID].price;
        uint256 royalty = nft.RoyaltyFee();
        uint256 sellershare;
        address royaltyreciever = nft.RoyaltyReciever();
        address lister = listNFT[_nft][_tokenID].seller;
        if(royalty > 0){
            uint256 royaltyTotal = CalculateRoyaltyFee(listNFT[_nft][_tokenID].price,royalty);
            payable(royaltyreciever).transfer(royaltyTotal);
            Total = Total.sub(royaltyTotal);
        }
        sellershare = Total.sub(CalculateMarketFee(listNFT[_nft][_tokenID].price));
        payable(lister).transfer(sellershare);
        IERC721(listNFT[_nft][_tokenID].NFTAddr).safeTransferFrom(address(this),msg.sender,listNFT[_nft][_tokenID].tokenID);
        delete listNFT[_nft][_tokenID];
        listed[_nft][_tokenID] = false;
        emit NFTBought(msg.sender,_nft,_tokenID,msg.value);
    }
    function CancelListing(address _nft,uint _tokenID)external isListed(_nft,_tokenID){
      require(msg.sender == listNFT[_nft][_tokenID].seller);
      IERC721 nft = IERC721(_nft);
      nft.safeTransferFrom(address(this),msg.sender,_tokenID);
      listed[_nft][_tokenID] = false;
      delete listNFT[_nft][_tokenID];
      emit ListingCanceled(msg.sender,_nft,_tokenID); 
    }
    function CancelAuction(address _nft,uint _tokenID)external isAuctioned(_nft,_tokenID){
        require(msg.sender == auctions[_nft][_tokenID].creator);
        require(auctions[_nft][_tokenID].highestbid == 0);
        require(auctions[_nft][_tokenID].lastBidder == address(0));
        IERC721 nft = IERC721(_nft);
        nft.transferFrom(address(this),msg.sender,_tokenID);
        auctioned[_nft][_tokenID] = false;
        delete auctions[_nft][_tokenID];
        emit AuctionCanceled(msg.sender,_nft,_tokenID);
    }
    function Bid(address _nft,uint _tokenID)external payable nonReentrant isAuctioned(_nft,_tokenID){
        require(msg.sender != auctions[_nft][_tokenID].creator);
        require(msg.value >  auctions[_nft][_tokenID].highestbid);
        require(block.timestamp < auctions[_nft][_tokenID].end);
        require(block.timestamp > auctions[_nft][_tokenID].start);
        if(auctions[_nft][_tokenID].lastBidder != address(0)){
            payable(auctions[_nft][_tokenID].lastBidder).transfer(auctions[_nft][_tokenID].highestbid);
        }
        auctions[_nft][_tokenID].lastBidder = payable(msg.sender);
        auctions[_nft][_tokenID].highestbid = msg.value;
        emit Bidding(msg.sender,_nft,_tokenID,msg.value);
    }
    function ViewHighestBid(address _nft,uint _tokenID) public view returns(uint){
         require(block.timestamp > auctions[_nft][_tokenID].start);
         require(auctions[_nft][_tokenID].startingbid != 0);
         return auctions[_nft][_tokenID].highestbid;
         }
    function ClaimNFT(address _nft,uint _tokenID)nonReentrant external{
        require(block.timestamp > auctions[_nft][_tokenID].end);
        require(msg.sender == auctions[_nft][_tokenID].lastBidder);
        INFT nft = INFT(auctions[_nft][_tokenID].nft);
        uint256 Total = auctions[_nft][_tokenID].highestbid;
        uint256 royalty = nft.RoyaltyFee();
        uint256 sellershare;
        address royaltyreciever = nft.RoyaltyReciever();
        address creator = auctions[_nft][_tokenID].creator;
        if(royalty > 0){
            uint256 royaltyTotal = CalculateRoyaltyFee(auctions[_nft][_tokenID].highestbid,royalty);
            payable(royaltyreciever).transfer(royaltyTotal);
            Total = Total.sub(royaltyTotal);
        }
        sellershare = Total.sub(CalculateMarketFee(auctions[_nft][_tokenID].highestbid));
        payable(creator).transfer(sellershare);
        IERC721(auctions[_nft][_tokenID].nft).safeTransferFrom(address(this),msg.sender,auctions[_nft][_tokenID].tokenID);
        auctions[_nft][_tokenID].lastBidder = msg.sender;
        auctioned[_nft][_tokenID] = false;
        delete auctions[_nft][_tokenID];
        emit NFTClaimed(msg.sender,_nft,_tokenID);
    }
      function SearchListing(address _nft,uint _tokenID)public view returns(ListNFT memory){
        return listNFT[_nft][_tokenID];
    }
         function SearchAuction(address _nft,uint _tokenID)public view returns(Auction memory){
        return auctions[_nft][_tokenID];    
    }
    function Withdraw(address payable _to,uint _amount)external onlyOwner{
        require(_amount <= address(this).balance);
        _to.transfer(_amount);
        emit Withdrawn(msg.sender,_to, _amount);
    }
    
    function CalculateRoyaltyFee(uint _price,uint _royalty)public pure returns(uint256){
     return (_royalty.mul(_price)).div(1000);
    }
    function CalculateMarketFee(uint _price)public view returns(uint256){
        return (Fee.mul(_price)).div(1000);
    }
  
    receive()external payable{

    }

}