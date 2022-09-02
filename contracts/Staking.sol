// SPDX-License-Identifier: MIT
//Dev : Mayoral13
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./SafeMath.sol";
contract Staking is ERC20{
  using Counters for Counters.Counter;
  Counters.Counter private _stakeID;
  using SafeMath for uint;
  uint private APY = 20;
  uint private DIVISOR = 100;
  uint private RATE = 31536000;
  uint private MIN = 604800;
  address[]private Stakeholders;
  address public tokenAddress;
  mapping(address => uint[])private StakeID;
  mapping(uint => mapping(address => Stake))private stakes;
  struct Stake{
  uint amount;
  uint reward;
  uint duration;
  uint expires;
  bool claimed;
  }
  constructor(address _tokenAddress)
  ERC20("REWARD","RWRD"){
    require(_tokenAddress != address(0));
    tokenAddress = _tokenAddress;
  }
  
  function CheckStakeholder(address _user)public view returns(bool success){
    for (uint i = 0; i<Stakeholders.length;i++){
      if (_user == Stakeholders[i])
      return true;
    }
  }

//REMOVE REWRDS FIRST FEATURE AND MAKE IT MORE FLEXIBLE
  function CreateStake(uint _value,uint _duration)external{
    _stakeID.increment();
    uint256 id = _stakeID.current();
    IERC20 token = IERC20(tokenAddress);
    require(CheckStakeholder(msg.sender) == true,"Not a Stakeholder");
    require(_value >= 1000,"Set value to 1000 or more");
    require(_duration >= MIN,"Duration must be greater than 7 days");//CHANGE TO 7 DAYS 604800
    require (token.balanceOf(msg.sender) >= _value,"Insufficient Funds");
    stakes[id][msg.sender].amount = _value;
    stakes[id][msg.sender].duration = _duration;
    stakes[id][msg.sender].expires = _duration.add(block.timestamp);
    stakes[id][msg.sender].reward = _value.mul(APY.mul(_duration)).div(RATE.mul(DIVISOR)); //CHANGE .DIV()TO
    //31536000.MUL(100)
    StakeID[msg.sender].push(id);
    token.transferFrom(msg.sender,address(this),_value);
  }
  
  //REMOVE REWARDS FEATURE FIRST TO MAKE IT MORE FLEXIBLE USER CAN COMPOUND REWARDS
  function RemoveStake(uint id)external{
    IERC20 token = IERC20(tokenAddress);
    require(block.timestamp > stakes[id][msg.sender].expires,"Wait till expires");
    require(CheckStakeholder(msg.sender) == true,"Not a Stakeholder");
    require(stakes[id][msg.sender].amount != 0,"You must have a Stake");
    require(stakes[id][msg.sender].claimed == true,"Remove your Rewards first");
    token.transfer(msg.sender,stakes[id][msg.sender].amount);
    delete stakes[id][msg.sender];
  }

  function AddStakeholder()external{
    require(CheckStakeholder(msg.sender) == false,"Already a Stakeholder");
    Stakeholders.push(msg.sender);
  }
 
 //REMOVE WITHDRAW ENTIRE REWARDS NEW REWARDS WILL BE CALCULATED ON CURRENT BALANCE
  function WithdrawRewards(uint id)external{
     require(CheckStakeholder(msg.sender) == true,"Not a Stakeholder");
     require(stakes[id][msg.sender].claimed == false,"Rewards Claimed");
     require(block.timestamp > stakes[id][msg.sender].expires,"Wait till expires");
     require(stakes[id][msg.sender].amount != 0,"Not exist");
     require(stakes[id][msg.sender].reward != 0,"Not exist");
      stakes[id][msg.sender].claimed = true;
      _mint(msg.sender,stakes[id][msg.sender].reward);
  }

  function ViewStake(uint id) public view returns(Stake memory){
    require(CheckStakeholder(msg.sender) == true,"Not a Stakeholder");
    require(stakes[id][msg.sender].amount != 0,"Not exist");
    return stakes[id][msg.sender];
  }
  function ViewStakeID()public view returns(uint[]memory){
    require(CheckStakeholder(msg.sender) == true,"Not a Stakeholder");
    require(StakeID[msg.sender].length != 0,"No Stake");
    return StakeID[msg.sender];
  }
  

}
