pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SafeMath.sol";
contract BorrowandUse is ERC20{
    //using safemath for arithmetic operations
    using SafeMath for uint;
    //address to store owner of contract
    address private owner;
    //uint to keep tract of times ETH has been borrowed
    uint private ETHcount;
    //uint to keep track of times Token has been borrowed
    uint private Tokenscount;
    //rate at which Token is bought
    uint private rate = 500;
    //uint to increment msg.value
    uint private BalanceRecieved;
    
    //mapping to store value of ETH Borrowed of an address 
    mapping(address => uint)ETHBorrowed;
    //mapping to store value of Tokens Borrowed by an address
    mapping(address => uint)TokensBorrowed;
    //mapping to check if address has borrowed ETH
    mapping(address => bool)BorrowedETH;
    //mapping to check if address has borrowed Tokens
    mapping(address => bool)BorrowedTokens;
    //mapping to check how many times a user has borrowed ETH
    mapping(address => uint)TimesBorrowedETH;
    //mapping to check how many times a user has borrowed Tokens
    mapping(address => uint)TimesBorrowedTokens;
    
    event BorrowEth(address indexed _by,uint _amount,uint _time);
    event BorrowToken(address indexed _by,uint _amount,uint _time);
    event ReturnBorrowEth(address indexed _by,uint _amount,uint _time);
    event ReturnBorrowToken(address indexed _by,uint _amount,uint _time);
    event AuthorizedTransfer(address _to,uint _value);

    modifier OnlyOwner(){
        require(msg.sender == owner,"You are not the owner");
        _;
    }
    constructor()
    ERC20("BorrowUSE","BandUSE"){
        
        owner = msg.sender;
    }
    
    //function to check ETH Balance of user
    function ETHBalanceChecker()public view returns(uint){
        return (msg.sender).balance;
    }
    
    //function to check Token Balance of user
    function TokenBalance()public view returns(uint){
        return balanceOf(msg.sender);
    }
    
    //function for contract to recieve ETH
    function RecieveETH()public payable returns(bool success){
    BalanceRecieved = BalanceRecieved.add(msg.value);
    return true;
    } 
     
    //function to Borrow ETH
    //To borrow 20 wei for example the user must have at least 10000 Tokens / rate = 20 wei before user can borrow
    // NOTE WHEN INPUTING THE VALUE ONE SHOULD REMEMBER THAT IT IS IN WEI AND NOT ETHER
    function BorrowETH(uint _value)public returns(bool success){
    uint TokentoEth = balanceOf(msg.sender).div(rate);
     require(BorrowedETH[msg.sender] == false,"Return Borrowed ETH");
     require(_value != 0,"Nice Try");
     require(BorrowedTokens[msg.sender] == false,"Return Borrowed Tokens");
     require(TokentoEth >= _value,"Insufficient Tokens Buy More");
     require(address(this).balance > _value,"Insufficient ETH in Contract");
     ETHBorrowed[msg.sender] = ETHBorrowed[msg.sender].add(_value);
     _burn(msg.sender,_value.mul(rate));
     payable(msg.sender).transfer(_value.mul(1 wei));
     TimesBorrowedETH[msg.sender]++;
     emit BorrowEth(msg.sender,_value,block.timestamp);
     BorrowedETH[msg.sender] = true;
     ETHcount++;
     return true;
    }
    //function for one to borrow Tokens
    // for one to borrow 10000 Tokens they must send 20wei to the contract using this function 
    // 20wei * rate  = 10000 Tokens
      function BorrowTokens(uint _value)public payable returns(bool success){
    uint EthtoToken = ((msg.sender).balance).mul(rate);
    require(msg.value == (_value).div(rate),"Send the required Amount");
    require(_value != 0,"Nice Try");
    require(msg.value != 0,"Nice Try");
    require(BorrowedETH[msg.sender] == false,"Return Borrowed ETH");
    require(BorrowedTokens[msg.sender] == false,"Return Borrowed Tokens");
    require(EthtoToken >= _value,"Insufficient ETH Buy More");
    require(balanceOf(address(this)) > _value,"Insufficient Tokens in Contract");
    TokensBorrowed[msg.sender] = TokensBorrowed[msg.sender].add(_value);
    _mint(msg.sender,_value);
    TimesBorrowedTokens[msg.sender]++;
    emit BorrowToken(msg.sender, _value,block.timestamp);
    Tokenscount++;
    BorrowedTokens[msg.sender] = true;
    return true;   
    }
    //function to check max number of Tokens user can borrow 
    //with their available balance
    function CheckMaxBorrowTokens()public view returns(uint){
        uint EthtoToken = ((msg.sender).balance).mul(rate);
        return EthtoToken;
    }
    //function to check max number of ETH user can borrow 
    //with their available Token balance
    function CheckMaxBorrowETH()public view returns(uint){
        uint TokentoEth =balanceOf(msg.sender).div(rate);
        return TokentoEth;
    }
    //function to return borrowed ETH
    //IF user borrows 20 wei the user must send exactly 20wei to the contract using this function
    //to return the borrowed ETH
    function ReturnBorrowedETH()public payable returns(bool success){
        require((msg.sender).balance >= ETHBorrowed[msg.sender],"Insufficient ETH Balance");
        require(BorrowedETH[msg.sender] == true,"Borrow ETH before you can Return it");
        require(msg.value == ETHBorrowed[msg.sender],"Pay The Exact Amount You Owe");
        _mint(msg.sender,ETHBorrowed[msg.sender].mul(rate));
        ETHBorrowed[msg.sender] = 0;
        BorrowedETH[msg.sender] = false;
        emit ReturnBorrowEth(msg.sender,ETHBorrowed[msg.sender],block.timestamp);
        return true;
    }
    //function to return Tokens borrowed
       function ReturnBorrowedTokens()public returns(bool success){
       require(balanceOf(msg.sender) >= TokensBorrowed[msg.sender],"Insufficient Token Balance");
        require(BorrowedTokens[msg.sender] == true,"Borrow Tokens before you can Return it");
        _burn(msg.sender,TokensBorrowed[msg.sender]);
        payable(msg.sender).transfer(TokensBorrowed[msg.sender].div(rate));
        TokensBorrowed[msg.sender] = 0;
        BorrowedTokens[msg.sender] = false;
        emit ReturnBorrowToken(msg.sender,TokensBorrowed[msg.sender],block.timestamp);
        return true;
    }
    
    //function to check ETH balance of contract
    function ContractETHBalance()public view returns(uint){
        return address(this).balance;
    }
    //function to check Token balance of contract
    function ContractTokens()public view returns(uint){
      return balanceOf(address(this));
    }
    
    //function to Transfer tokens to users only owner can use it
    function TransferTokens(address _to,uint _value)public OnlyOwner returns(bool success){
        _mint(msg.sender,_value);
        _burn(address(this),_value);
        emit AuthorizedTransfer(_to, _value);
        return true;
    }

    //function to return value of ETH Borrowed
    function ValueETHBorrowed()public view returns(uint){
        return ETHBorrowed[msg.sender];
    }
     
     //function to return value of Tokens Borrowed
     function ValueTokensBorrowed()public view returns(uint){
        return TokensBorrowed[msg.sender];
    }
    
    //function to check if user borrowed ETH
    function isETHBorrowed()public view returns(bool){
        return BorrowedETH[msg.sender];
    }
    //function to check if user borrowed Tokens
      function isTokenBorrowed()public view returns(bool){
        return BorrowedTokens[msg.sender];
    }
    //function to check number of times users have borrowed ETH from the contract
    function ReturnTimesETHBorrowed()public view returns(uint){
        return ETHcount;
    }
     //function to check number of times users have borrowed Tokens from the contract
    function ReturnTimesTokensBorrowed()public view returns(uint){
        return Tokenscount;
    }
    //function to return owner of the contract
    function ReturnOwner()public view returns(address){
        return owner;
    }
    //function to return rate
    function ReturnRate()public view returns(uint){
        return rate;
    }

    
}