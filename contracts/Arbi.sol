pragma solidity ^0.5.0;

import "./base/FlashLoanReceiverBase.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";
import "./interfaces/ILendingPool.sol";
import "./WBNB.sol";

import './UniswapV2Library.sol';
import './utils/IERC20.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';

contract Arbi is FlashLoanReceiverBase {
     using SafeMath for uint;

    address public receiver = address(this);
    address public constant BNB_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address payable public owner;
    address public reserve;

    address routerA;
    address routerB;
    address token0;
    address token1;
    address private constant WBNB_ = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;  
    WBNB wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    address public _tokenPay;
    address public _tokenSwap;
    uint256 public _amountTokenPay;
    address public _sourceRouter;
    address public _targetRouter;
    uint256 public sell_amount;

    // end properties for swapping

    
    constructor() public {
            owner = msg.sender;
           
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
      require(
        IERC20(token0).approve(_sourceRouter, _amount),
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
         
        tokenBought = IUniswapV2Router02(routerA).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this), // or address(this), and transfer the swapped token to msg.sender
            block.timestamp + 300
        );

        uint sell_amount = (tokenBought[1]);

        //old approve
        require(
            tokenBought[1] > 0,
            "tokenBought must be gt 0"
        );  
        
        require(
        IERC20(token1).approve(_targetRouter, sell_amount),
         "Could not approve sell of token1"
        );

        address[] memory path1;

        if (token0 == WBNB_ || token1 == WBNB_) {
            path1 = new address[](2);
            path1[0] = token1;
            path1[1] = token0;
        } else {
            path = new address[](3);
            path1[0] = token1;
            path1[1] = WBNB_;
            path1[2] = token0;
        }
        uint[] memory token1Bought;
        
        token1Bought= IUniswapV2Router02(routerB).swapExactTokensForTokens(
            sell_amount,
            0,
            path1,
            address(this), // or address(this), and transfer the swapped token to msg.sender
            block.timestamp + 300
        );

        
        require(
            token1Bought[1] > 0,
            "token1Bought must be gt 0"
        );
         
        /////////////////////////////////// swap ends here

        if (reserve == BNB_ADDRESS){

             UnwrapBNB(token1Bought[1]);
        }

        uint256 totalDebt = _amount.add(_fee);



        require(token1Bought[1]> totalDebt, "Did not profit");

    
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    function rescueBNB(uint256 amount) external{
        owner.transfer(amount);
    }




    
    // This is the last function to call to execute arbitrage
    function executeArbi( address _tokenPay1, // source currency when we will get; example BNB
		address _tokenSwap1, // swapped currency with the source currency; example BUSD
		uint256 _amountTokenPay1, // example: BNB => 10 * 1e18
		address _sourceRouter1,
		address _targetRouter1 ) external{
        
        // setting parameters
        _tokenPay = _tokenPay1;
        _tokenSwap = _tokenSwap1;
        _amountTokenPay = _amountTokenPay1;
        _sourceRouter = _sourceRouter1;
        _targetRouter = _targetRouter1;
        // end setting parameters

        token0 = _tokenPay;

        if(_tokenPay==WBNB_)
        {
           reserve = BNB_ADDRESS; // token that is being lended (BNB)
        }else{

          reserve = _tokenPay;  // token that is being lended (USDT, USDC, ETH, BUSD)
        } 

        token1= _tokenSwap;

        // recheck for stopping and gas usage

        // https://docs.uniswap.org/protocol/V2/reference/smart-contracts/factory#getpair

        require(
            _tokenPay !=_tokenSwap,
            "Same pairs"
        ); 

        routerA= _sourceRouter;
        routerB = _targetRouter;

        bytes memory data = "";

        ILendingPool lendingPool = ILendingPool(
        addressesProvider.getLendingPool()
        );


        // invoke a flashloan and receive a loan on this contract address 
        lendingPool.flashLoan(receiver, reserve, _amountTokenPay, data);
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
