// SPDX-License-Identifier: MIT
//Dev : Mayoral13
pragma solidity ^0.8.11;
import "./NFT.sol";
contract NFTFactory{
    NFT private nftz;
    mapping(address => address[])private nftCollection;
    mapping(address => bool)private nft;
    address[] private Clones;
    event CollectionCreated(address _creator,address nft,string name,string symbol);
    //function Create collection
    function CreateCollection(
        address _market,
        string memory _name,
        string memory _symbol,
        uint256 _royaltyFee,
        address payable _royaltyRecipient) external{
            nftz = new NFT(_market,_name,_symbol,_royaltyFee,_royaltyRecipient);
            nftCollection[msg.sender].push(address(nftz));
            nft[address(nftz)] = true;
            Clones.push(address(nftz));
            emit CollectionCreated(msg.sender,address(nftz),_name,_symbol);

        }
        //function to reveal NFT's in collection
        function RevealCollection()public view returns(address[]memory){
            return nftCollection[msg.sender];
        }
        //function to reveal if address is part of NFT
        function isNFT(address _nft)public view returns(bool){
            return nft[_nft];
        }
        function RevealClones(uint i)public view returns(address){
            return Clones[i];
        }
}