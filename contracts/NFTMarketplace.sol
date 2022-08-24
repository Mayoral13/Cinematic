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
interface INFTFactory{
    function CreateCollection(string memory _name,string memory _symbol,uint256 _royaltyFee,address _royaltyRecipient)external;
    function isNFT(address _nft)external view returns(bool);

}
contract Marketplace is Ownable,ReentrancyGuard{
    using SafeMath for uint;
    INFTFactory private Factory;
    
    uint256 private Fee;
   
    constructor(uint256 _fee,INFTFactory _factory){
        require(_fee <= 100,"Fee cannot be greater than 10%");
        Fee = _fee;
        _factory = Factory;

    }
    
    struct ListNFT{
        address NFTAddr;
        uint price;
        uint tokenID;
        address payable seller;
        address payable buyer;
        bool sold;
        bool canceled;
    }
  
      struct Auction{
        address payable creator;
        address nft;
        uint startingbid;
        uint start;
        uint end;
        uint tokenID;
        address payable lastBidder;
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
    mapping(address => mapping(uint => bool))private auctioned;
    mapping(address => mapping(uint => ListNFT))private listNFT;
    mapping(address => mapping(uint => uint))private highestbid;
    mapping(address => mapping(uint => Auction))private auctions;
    
    mapping(address => mapping(address =>mapping( uint => uint)))private bids;
    
    function CreateListing(address _nft,uint _price,uint _tokenID)external isNotListed(_nft,_tokenID) isNotAuctioned(_nft,_tokenID){
        IERC721 nft = IERC721(_nft);
        require(_price != 0);
        require(nft.ownerOf(_tokenID) == msg.sender);
        listed[_nft][_tokenID] = true;
        nft.transferFrom(msg.sender,address(this),_tokenID);
        listNFT[_nft][_tokenID].NFTAddr = _nft;
        listNFT[_nft][_tokenID].price = _price;
        listNFT[_nft][_tokenID].tokenID = _tokenID;
        listNFT[_nft][_tokenID].seller = payable(msg.sender);
        emit NFTListed(msg.sender,_nft,_tokenID, _price);
    }
    function CreateAuction(address _nft,uint _bid,uint _tokenID,uint _start,uint _end)isNotListed(_nft,_tokenID) isNotAuctioned(_nft,_tokenID)external{
      IERC721 nft = IERC721(_nft);
      nft.transferFrom(msg.sender,address(this),_tokenID);
      require(_bid != 0);
      require(_end > _start);
      require(nft.ownerOf(_tokenID) == msg.sender);
      auctioned[_nft][_tokenID] = true;
      auctions[_nft][_tokenID].creator = payable(msg.sender);
      auctions[_nft][_tokenID].nft = _nft;
      auctions[_nft][_tokenID].startingbid = _bid;
      auctions[_nft][_tokenID].start = _start.add(block.timestamp);
      auctions[_nft][_tokenID].end = _end.add(block.timestamp);
      auctions[_nft][_tokenID].tokenID = _tokenID;
      emit AuctionCreated(msg.sender, _nft, _tokenID,_bid);
    }
    function BuyNFT(address _nft,uint _tokenID)external payable isListed(_nft,_tokenID){
        ListNFT storage listNFTs = listNFT[_nft][_tokenID];
        require(msg.sender != listNFTs.seller);
        require(_tokenID == listNFTs.tokenID);
        require(msg.value >= listNFTs.price);
        require(listNFTs.sold == false);
        require(listNFTs.canceled == false);
        require(listed[_nft][_tokenID] == true);
        INFT nft = INFT(listNFTs.NFTAddr);
        uint256 Total = listNFTs.price;
        uint256 royalty = nft.RoyaltyFee();
        uint256 sellershare;
        address royaltyreciever = nft.RoyaltyReciever();
        address payable lister = listNFTs.seller;
        if(royalty > 0){
            uint256 royaltyTotal = CalculateRoyaltyFee(listNFTs.price,royalty);
            payable(royaltyreciever).transfer(royaltyTotal);
            Total = Total.sub(royaltyTotal);
        }
        sellershare = Total.sub(CalculateMarketFee(listNFTs.price));
        lister.transfer(sellershare);
        IERC721(listNFTs.NFTAddr).safeTransferFrom(address(this),msg.sender,listNFTs.tokenID);
        listed[_nft][_tokenID] = false;
        emit NFTBought(msg.sender,_nft,_tokenID,msg.value);
    }
    function CancelListing(address _nft,uint _tokenID)external isListed(_nft,_tokenID){
      ListNFT memory listNFTs = listNFT[_nft][_tokenID];
      require(msg.sender == listNFTs.seller);
      require(listNFTs.sold == false);
      require(listNFTs.canceled == false);
      IERC721 nft = IERC721(_nft);
      nft.safeTransferFrom(address(this),msg.sender,_tokenID);
      listed[_nft][_tokenID] = false;
      delete listNFT[_nft][_tokenID];
      emit ListingCanceled(msg.sender,_nft,_tokenID); 
    }
    function CancelAuction(address _nft,uint _tokenID)external isAuctioned(_nft,_tokenID){
        Auction memory auction = auctions[_nft][_tokenID];
        require(msg.sender == auction.creator);
        require(block.timestamp > auction.end);
        IERC721 nft = IERC721(_nft);
        nft.safeTransferFrom(address(this),msg.sender,_tokenID);
        auctioned[_nft][_tokenID] = false;
        delete auctions[_nft][_tokenID];
        emit AuctionCanceled(msg.sender,_nft,_tokenID);
    }
    function Bid(address _nft,uint _tokenID)external payable nonReentrant isAuctioned(_nft,_tokenID){
        Auction storage auction = auctions[_nft][_tokenID];
        highestbid[_nft][_tokenID] = auction.startingbid;
        require(msg.sender != auction.creator);
        require(msg.value >= highestbid[_nft][_tokenID]);
        require(block.timestamp < auction.end);
        require(block.timestamp > auction.start);
        if(auction.lastBidder != address(0)){
            bids[msg.sender][_nft][_tokenID] = bids[msg.sender][_nft][_tokenID].add(msg.value);
        }
        auction.lastBidder = payable(msg.sender);
        auction.highestbid = msg.value;
        emit Bidding(msg.sender,_nft,_tokenID,msg.value);
    }
    function WithdrawPendingBids(address _nft,uint _tokenID)external{
        require(msg.sender != auctions[_nft][_tokenID].lastBidder);
        require(bids[msg.sender][_nft][_tokenID] != 0);
        bids[msg.sender][_nft][_tokenID] = 0;
        payable(msg.sender).transfer(bids[msg.sender][_nft][_tokenID]);
        emit Withdrawn(msg.sender,msg.sender,bids[msg.sender][_nft][_tokenID]);
    }
    function ClaimNFT(address _nft,uint _tokenID)external{
         Auction storage auction = auctions[_nft][_tokenID];
        require(block.timestamp > auction.end);
        require(msg.sender == auction.lastBidder);
        bids[msg.sender][_nft][_tokenID] = 0;
        INFT nft = INFT(auction.nft);
        uint256 Total = auction.highestbid;
        uint256 royalty = nft.RoyaltyFee();
        uint256 sellershare;
        address royaltyreciever = nft.RoyaltyReciever();
        address payable creator = auction.creator;
        if(royalty > 0){
            uint256 royaltyTotal = CalculateRoyaltyFee(auction.highestbid,royalty);
            payable(royaltyreciever).transfer(royaltyTotal);
            Total = Total.sub(royaltyTotal);
        }
        sellershare = Total.sub(CalculateMarketFee(auction.highestbid));
        creator.transfer(sellershare);
        IERC721(auction.nft).safeTransferFrom(address(this),msg.sender,auction.tokenID);
        auctioned[_nft][_tokenID] = false;
        emit NFTClaimed(msg.sender,_nft,_tokenID);
    }
      function SearchListing(address _nft,uint _tokenID)public view returns(address nft,uint _price,
    uint _ID,address payable _seller,address payable _buyer,bool _sold,bool _canceled){
        ListNFT memory list = listNFT[_nft][_tokenID];
        list.NFTAddr = nft;
        list.price = _price;
        list.tokenID = _ID;
        list.seller = _seller;
        list.buyer = _buyer;
        list.sold = _sold;
        list.canceled = _canceled;     
    }
         function SearchAuction(address _nft,uint _tokenID)public view returns(address payable _creator,
        address nft,uint _bid,
        uint _start,uint _end,uint _ID,address payable _lastbidder,uint _lastbid){
        Auction memory auction = auctions[_nft][_tokenID];
        auction.creator = _creator;
        auction.nft = nft;
        auction.startingbid = _bid;
        auction.start = _start;
        auction.end = _end;
        auction.tokenID = _ID;
        auction.lastBidder = _lastbidder;
        auction.highestbid = _lastbid;     
    }
    function Withdraw(address payable _to,uint _amount)external onlyOwner{
        _to.transfer(_amount);
        emit Withdrawn(msg.sender,_to, _amount);

    }
    
    function CalculateRoyaltyFee(uint _price,uint _royalty)public pure returns(uint256){
     return (_royalty.mul(_price)).div(1000);
    }
    function CalculateMarketFee(uint _price)public view returns(uint256){
        return (Fee.mul(_price)).div(1000);
    }

}