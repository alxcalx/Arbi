// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.0;

import './utils/Ownable.sol';
import './utils/SafeMath.sol';
import './UniswapV2Library.sol';
import './utils/IERC20.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';

contract Swapcontract {
     using SafeMath for uint;
    // https://bscscan.com/address/0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
    address private constant pancakeRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    // https://bscscan.com/address/0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    

    constructor() public {}
    

    function startSwap(  //TEST PARAMETERS
        address token0,  //0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd (WBNB)
        address token1,  //0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7 (BUSD)
        uint amount0,   //1000000000000000
        uint amount1    //0
    ) external {
        // transfer input tokens to this contract address

        // approve pancakeRouter to transfer tokens from this contract
       IERC20(token0).approve(pancakeRouter, amount0);

        address[] memory path;
        if (token0 == WBNB || token1 == WBNB) {
            path = new address[](2);
            path[0] = token0;
            path[1] = token1;
        } else {
            path = new address[](3);
            path[0] = token0;
            path[1] = WBNB;
            path[2] = token1;
        } 
       
         uint256 [] memory tokenBought;
        tokenBought=IUniswapV2Router02(pancakeRouter).swapExactTokensForTokens(
            amount0,
            amount1,
            path,
            address(this), //and transfer the swapped token to msg.sender
            block.timestamp + 300
        );  
        
         uint amountoutfeesandgas = (tokenBought[1].mul(199)).div(200);
        
        address[] memory path1;
        if (token0 == WBNB || token1 == WBNB) {
            path1 = new address[](2);
            path1[0] = token1;
            path1[1] = token0;
        } else {
            path1 = new address[](3);
            path1[0] = token1;
            path1[1] = WBNB;
            path1[2] = token0;
        } 

         IERC20(token1).approve(pancakeRouter, amountoutfeesandgas); 


         uint [] memory tokenBought1;
          tokenBought1=IUniswapV2Router02(pancakeRouter).swapExactTokensForTokens(
            amountoutfeesandgas,
            amount1,
            path1,
            msg.sender, // or address(this), and transfer the swapped token to msg.sender
            block.timestamp + 300
        );  




    }

     function() external payable {}

}
