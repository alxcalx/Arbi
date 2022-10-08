pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;



import "./base/FlashLoanReceiverBase.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";
import "./interfaces/ILendingPool.sol";
import "./WBNB.sol";

import './UniswapV2Library.sol';
import './utils/IERC20.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';



contract MultiSwapContract is FlashLoanReceiverBase {
     using SafeMath for uint;


    address public receiver = address(this);
    address public constant BNB_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address payable public owner;
    address public reserve;

 
    address private constant WBNB_ = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;  
    WBNB wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    bytes[] data1;

    // end properties for swapping

    
    constructor() public {
            owner = msg.sender;
           
    }

 function MultiSwap(bytes[] memory data) internal {
   
   address token0;
   address token1;
   address router;
   uint amountIn;



  for (uint i = 0; i < data.length; i++) {
      router =  address(uint160(bytes20(data[i][0])));
      amountIn= uint256(uint160(bytes20(data[i][1])));
      token0=  address(uint160(bytes20(data[i][2])));
      token1= address(uint160(bytes20(data[i][3])));

        
    //router, amountin, path0, path1
     require(
        IERC20(token0).approve(router,amountIn),
        "Could not approve sell of token0"
      );

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
        
        
        uint[] memory tokenBought;
         
        tokenBought = IUniswapV2Router02(router).swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this), // or address(this), and transfer the swapped token to msg.sender
            block.timestamp + 300
        );

        uint sell_amount = (tokenBought[1]);
 }
 }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external {

        require(
            _amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance, was the flashLoan successful?"
        );
      
        if (reserve == BNB_ADDRESS){

             WrapBNB(_amount);
        }
      /////////////////////////////////// swap logic here
    
      MultiSwap(data1);  
         
        /////////////////////////////////// swap ends here
      _amount <= getBalanceInternal(address(this), _reserve);
        if (reserve == BNB_ADDRESS){
           

             UnwrapBNB(_amount);
        }

        uint256 totalDebt = _amount.add(_fee);



        require(_amount > totalDebt, "Did not profit");

    
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    function rescueBNB(uint256 amount) external{
        owner.transfer(amount);
    }



    
    // This is the last function to call to execute arbitrage
    function executeArbi( bytes[] memory paths, address sourcetoken, uint amountToken) public{
      data1 = paths;
        
      

        if(sourcetoken==WBNB_)
        {
           reserve = BNB_ADDRESS; // token that is being lended (BNB)
        }else{

          reserve = sourcetoken;  // token that is being lended (USDT, USDC, ETH, BUSD)
        } 
        ILendingPool lendingPool = ILendingPool(
        addressesProvider.getLendingPool()
        );

         bytes memory data = "";

        // invoke a flashloan and receive a loan on this contract address 
        lendingPool.flashLoan(receiver, reserve, amountToken, data);
    }



 function WrapBNB(uint _amount) internal{

   
       require(address(this).balance >0, "no money ");
       WBNB_.call.value(_amount).gas(5000000)("");
       wbnb.transfer(address(this),_amount);
    }

    function UnwrapBNB(uint _amount) public payable{
        wbnb.withdraw(_amount); //unwrap WBNB to BNB
    }

  function rescuetoken(uint256 _amount, address token) external{
       IERC20(token).safeTransfer(owner, _amount);

    }
    
}
