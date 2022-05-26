// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.0;

import './utils/Ownable.sol';
import './utils/SafeMath.sol';
import './UniswapV2Library.sol';
import './utils/IERC20.sol';
import './utils/SafeERC20.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';
import './WBNB.sol';

contract Swapcontract {
     using SafeERC20 for IERC20;
     using SafeMath for uint;
         address payable public owner;
    // https://bscscan.com/address/0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
   // address private constant pancakeRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    // https://bscscan.com/address/0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
     address private constant WBNB_ = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;  
     WBNB wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
     uint256 public sell_amount;


    

    constructor() public {

        owner = msg.sender;
    }
    

    function buy(  //TEST PARAMETERS
        address token0,  //0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd (WBNB)
        address token1,  //0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7 (BUSD)
        uint amount0,   //10000000000000000
        address routerA //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    ) external {
        // transfer input tokens to this contract address

        if( token0 == WBNB_){
        WrapBNB(amount0);
        }

        // approve pancakeRouter to transfer tokens from this contract
       IERC20(token0).approve(routerA, amount0);

        address[] memory path;
        if (token0 == WBNB_ || token1 == WBNB_) {
            path = new address[](2);
            path[0] = token0;
            path[1] = token1;
        } else {
            path = new address[](3);
            path[0] = token0;
            path[1] = WBNB_;
            path[2] = token1;
        } 
       
        uint256 [] memory tokenBought;
        tokenBought=IUniswapV2Router02(routerA).swapExactTokensForTokens(
            amount0,
            0,
            path,
            address(this), //and transfer the swapped token to msg.sender
            block.timestamp + 100
        );  

     sell_amount = tokenBought[1];
    }

    function sell(
        address token0,  //0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd (WBNB)
        address token1,  //0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7 (BUSD)
        uint amount0,   //1000000000000000
        address routerB
    )external{
      //   uint amountoutfeesandgas = (sell_amount.mul(1992)).div(2000);
        
        address[] memory path1;
        if (token0 == WBNB_ || token1 == WBNB_) {
            path1 = new address[](2);
            path1[0] = token1;
            path1[1] = token0;
        } else {
            path1 = new address[](3);
            path1[0] = token1;
            path1[1] = WBNB_;
            path1[2] = token0;
        } 

         IERC20(token1).approve(routerB, sell_amount); 


         uint [] memory tokenBought1;
          tokenBought1=IUniswapV2Router02(routerB).swapExactTokensForTokens(
            sell_amount,
            0,
            path1,
            address(this), // or address(this), and transfer the swapped token to msg.sender
            block.timestamp + 100
        );  

       if(token0==WBNB_){
       UnwrapBNB(tokenBought1[1]);
       }

    }

function WrapBNB(uint _amount) internal{

       //require(msg.value>0, "no value for deposit ");
       require(address(this).balance >0, "no money ");
       //wbnb.deposit.value(msg.value)(); //wrap BNB to WBNB
       WBNB_.call.value(_amount).gas(5000000)("");
       wbnb.transfer(address(this),_amount);
    }

    function UnwrapBNB(uint _amount) public payable{
        wbnb.withdraw(_amount); //unwrap WBNB to BNB
    }
    


    function rescueBNB(uint256 amount) external{
        owner.transfer(amount);
    
    }

    function rescuetoken(uint256 _amount, address token) external{
       IERC20(token).safeTransfer(owner, _amount);

    }


     function() external payable {}

}
