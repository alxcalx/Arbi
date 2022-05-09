pragma solidity ^0.5.0;


import "./WBNB.sol";
import "./utils/IERC20.sol";
import "./utils/SafeERC20.sol";


contract WBNBTest{
  using SafeERC20 for IERC20;

address payable public WBNB_ = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
WBNB wbnb = WBNB(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
address public constant BNB_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;



function depositBNB(uint _amount) public {

WrapBNB(_amount);

}

function rescueWBNB(uint _amount) public payable{


IERC20(WBNB_).safeTransfer(0xD34957f728Dc8Bf37992F48B891b3091af66427c,_amount);

}

function WrapBNB(uint _amount) internal{

       //require(msg.value>0, "no value for deposit ");
       require(address(this).balance >0, "no money ");
       //wbnb.deposit.value(msg.value)(); //wrap BNB to WBNB
       WBNB_.call.value(_amount).gas(5000000)("");
       wbnb.transfer(address(this),_amount);
    }


function UnwrapBNB(uint _amount) public payable{

        require(_amount>0, "no amount for withdraw ");
       // wbnb.transferFrom(address(this),0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd,_amount);
        wbnb.withdraw(_amount); //unwrap WBNB to BNB
        
    }

function() external payable{}


}