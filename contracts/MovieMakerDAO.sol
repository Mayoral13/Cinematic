// SPDX-License-Identifier: MIT
//Dev: Mayoral13
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract MovieMakerDAO{
    /******FEATURES 
    USES C-MATIC TOKEN TO VOTE
    USERS CAN LIST CONTENTS WITH(TITLE,THUMBNAIL,VIDEO,TRAILER.....?)
    CROWDSOURCE FOR UNDERFUNDED PROJECTS
    AN EQUITY SLOT WHICH IS LIMITED FOR CROWDSOURCE
    AN EQUITY PERCENTAGE IF NECESSARY
    FUNDING DURATION
    FUNDING TARGET
    WITHDRAWAL NOTICE IF TARGET IS REACHED
    WITHDRAW THEIR FUNDS
    ACCESS FUNDS BY CREATOR
    USERS CAN VOTE ON CONTENT TO BE ADDED{
        NAME
        PROPOSAL CREATOR
    }
    DOWNLOADABLE CONTENT TO BE INCLUDED WITH NUMBERS
     */
     address public tokenAddress;
     constructor(address _address){
        tokenAddress = IERC20(_address);
     }
     struct Content{
        string title;
        string thumbnail;
        string video;
        string trailer;
     }
     struct Fund{
        address creator;
        uint target;
        uint8 equityslot;
        uint8 equitypercentage;
        bool failed;
        uint duration;
     }

}