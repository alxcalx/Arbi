// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.0;

import './utils/Ownable.sol';
import './utils/SafeMath.sol';
import './UniswapV2Library.sol';
import './utils/IERC20.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';
import "./WBNB.sol";

contract Swapcontract {
     using SafeMath for uint;
         address payable public owner;
    // https://bscscan.com/address/0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
   // address private constant pancakeRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    // https://bscscan.com/address/0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
     address private constant WBNB_ = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;  
     WBNB wbnb = WBNB(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);


    uint256 public sell_amount;
    uint256 public sell_amoun1;

    constructor() public {

        owner = msg.sender;
    }
    

    function startSwap(  //TEST PARAMETERS
        address token0,  //0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd (WBNB)
        address token1,
        address token2,  //0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7 (BUSD)
        uint amount0,   //1000000000000000
        address routerA,
        address routerB,
        address routerC
            //0
    ) external {
        // transfer input tokens to this contract address

        // approve pancakeRouter to transfer tokens from this contract
        require(
       IERC20(token0).approve(routerA, amount0),
       "Could not approve sell of token0"
        );
         address[] memory path;

            path[0] = token0;
            path[1] = token1;
    
       
         uint256 [] memory tokenBought;
        tokenBought=IUniswapV2Router02(routerA).swapExactTokensForTokens(
            amount0,
            0,
            path,
            address(this), //and transfer the swapped token to msg.sender
            block.timestamp + 300
        );  
        
        uint sell_amount = tokenBought[1];
        
        address[] memory path1;
     
            path1[0] = token1;
            path1[1] = token2;
    
         
         require(
         IERC20(token1).approve(routerB, sell_amount),
         "Could not approve sell of token1" 
         );

         uint [] memory tokenBought1;
          tokenBought1=IUniswapV2Router02(routerB).swapExactTokensForTokens(
          sell_amount,
            0,
            path1,
            address(this), // or address(this), and transfer the swapped token to msg.sender
            block.timestamp + 300
        );  

        uint sell_amount1=tokenBought1[1];

        require(
        IERC20(token2).approve(routerC, sell_amount1),
         "Could not approve sell of token2"
        );

        address[] memory path2;

   
            path2[0] = token2;
            path2[1] = token0;
       
        uint[] memory token2Bought;
        
        token2Bought= IUniswapV2Router02(routerC).swapExactTokensForTokens(
            sell_amount1,
            0,
            path2,
            address(this), // or address(this), and transfer the swapped token to msg.sender
            block.timestamp + 300
        );





    }


    


    function rescueBNB(uint256 amount) external{
        owner.transfer(amount);
    }


     function() external payable {}

}
