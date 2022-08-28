// SPDX-License-Identifier: MIT
//Dev: Mayoral13
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFT is ERC721,ERC721URIStorage{

   using Counters for Counters.Counter;
   Counters.Counter private _tokenID;
   uint256 private royaltyFee;
   address private royaltyReciever;
   address public Marketplace;
   address public owner;
   mapping(address => uint[])private tokenIDs;
   event Minted(address indexed _by,uint _tokenID);
   event FeeChange(address indexed _by,uint current);
   event RecieverChange(address indexed _by,address indexed _current);

   //Constructor to initialize NFT name, symbol and royalty fee
   constructor(address _market,string memory _name,string memory _symbol,uint _fee,address payable _to)
   ERC721(_name,_symbol){
    require(_fee <= 100,"cannot be more than 10%");
    royaltyFee = _fee;
    royaltyReciever = _to;
    Marketplace = _market;
    owner = tx.origin;
   }
   modifier OnlyOwner(){
    require(msg.sender == owner,"You are not the owner");
    _;
   }
   //Function to mint NFT
   function MintNFT(string memory _tokenURI)public OnlyOwner returns(uint){
   _tokenID.increment();
   uint256 id = _tokenID.current();
   _safeMint(msg.sender,id);
   _setApprovalForAll(msg.sender,Marketplace,true);
   _setTokenURI(id,_tokenURI);
   tokenIDs[msg.sender].push(id);
   emit Minted(msg.sender,id);
   return id;
   }
    
    //Without this an error will be flagged
   function _burn(uint256 _tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(_tokenId);
    }

  //Without this an error will be flagged

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }
//function to reveal RoyaltyFee
    function RoyaltyFee()public view returns(uint){
        return royaltyFee;
    }
//Function to reveal recipient of royalty
    function RoyaltyReciever()public view returns(address){
        return royaltyReciever;
    }
    //function to change royalty fee
    function ChangeFee(uint _fee) OnlyOwner external{
        require(_fee <= 100,"cannot be more than 10%");
        royaltyFee = _fee;
        emit FeeChange(msg.sender,_fee);
    }
    //function to reveal TokenID's of NFT's minted
    function RevealTokenID()public view returns(uint[]memory){
    return tokenIDs[msg.sender];
    }
    //function to change royalty reciever
    function ChangeRoyaltyReciever(address payable _to)external OnlyOwner{
        royaltyReciever = _to;
        emit RecieverChange(msg.sender,_to);
    }

    

}