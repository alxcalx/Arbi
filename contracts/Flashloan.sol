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

contract Flashloan is FlashLoanReceiverBase {
     using SafeMath for uint;

    address public receiver = address(this);
    address public constant BNB_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address payable public owner;

    // properties for swapping
   // IUniswapV2Pair public exchangeA;
  //  IUniswapV2Pair public exchangeB;
    address routerA;
    address routerB;
    address token0;
    address token1;
  //  address pairAddress0;
  //  address pairAddress1;
    address private constant WBNB_ = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;  
     WBNB wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    address public _tokenPay;
    address public _tokenSwap;
    uint256 public _amountTokenPay;
  //  address public _sourceFactory;
  //  address public _targetFactory;
    address public _sourceRouter;
    address public _targetRouter;

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
      
        WrapBNB();

        /////////////////////////////////// swap logic here
      require(
        IERC20(token0).approve(_sourceRouter, _amount),
        "Could not approve sell of token0"
      );

        /* old approve
        require(
            TokenA.approve(address(exchangeA), _amount),
            "Could not approve token0 sell"
        ); */

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

        uint amountoutfeesandgas = (tokenBought[1].mul(199)).div(200);

        //old approve
        require(
            tokenBought[1] > 0,
            "tokenBought must be gt 0"
        );  
        
        require(
        IERC20(token1).approve(_targetRouter, amountoutfeesandgas),
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
            amountoutfeesandgas,
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

        UnwrapBNB(token1Bought[1]);

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
	//	address _sourceFactory1,
	//	address _targetFactory1,
		address _sourceRouter1,
		address _targetRouter1 ) external{
        
        // setting parameters
        _tokenPay = _tokenPay1;
        _tokenSwap = _tokenSwap1;
        _amountTokenPay = _amountTokenPay1;
      //  _sourceFactory = _sourceFactory1;
     //   _targetFactory = _targetFactory1;
        _sourceRouter = _sourceRouter1;
        _targetRouter = _targetRouter1;
        // end setting parameters

        if(_tokenPay==WBNB_)
        {
            token0 = BNB_ADDRESS; 
        } else{ 
            token0 = _tokenPay; 
        }

        token1= _tokenSwap;

        // recheck for stopping and gas usage

        // https://docs.uniswap.org/protocol/V2/reference/smart-contracts/factory#getpair

        require(
            _tokenPay !=_tokenSwap,
            "Same pairs"
        ); /*

        pairAddress0 = IUniswapV2Factory(_sourceFactory).getPair(_tokenPay, _tokenSwap);
        require(pairAddress0 != address(0), "first pair not available");
        pairAddress1 = IUniswapV2Factory(_targetFactory).getPair(_tokenPay, _tokenSwap);
       require(pairAddress0 != address(0), "second pair not available");


        exchangeA = IUniswapV2Pair(pairAddress0);
        exchangeB = IUniswapV2Pair(pairAddress1);
*/

        routerA= _sourceRouter;
        routerB = _targetRouter;

        bytes memory data = "";

        ILendingPool lendingPool = ILendingPool(
        addressesProvider.getLendingPool()
        );


        // invoke a flashloan and receive a loan on this contract address 
        lendingPool.flashLoan(receiver, token0, _amountTokenPay, data);
    }


    function WrapBNB() public payable{
        wbnb.deposit.value(msg.value)(); //wrap BNB to WBNB
    }


    function UnwrapBNB(uint _amount) public payable{
        wbnb.withdraw(_amount); //unwrap WBNB to BNB
    }


    
}
