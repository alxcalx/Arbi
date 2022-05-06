pragma solidity ^0.5.0;

import "./base/FlashLoanReceiverBase.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";
import "./interfaces/ILendingPool.sol";

import './UniswapV2Library.sol';
import './utils/IERC20.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';

contract Flashloan is FlashLoanReceiverBase {

    address public receiver = address(this);
    address public constant BNB_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address payable public owner;

    // properties for swapping
    IUniswapV2Pair public exchangeA;
    IUniswapV2Pair public exchangeB;
    address routerA;
    address routerB;
    address token0;
    address token1;
    address pairAddress0;
    address pairAddress1;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;  

    address public _tokenPay;
    address public _tokenSwap;
    uint256 public _amountTokenPay;
    address public _sourceFactory;
    address public _targetFactory;
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

        /////////////////////////////////// swap logic here
        
        uint256 deadline = getDeadline();
        IERC20 TokenA = IERC20(token0);
        IERC20 TokenB = IERC20(token1);
        require(
            TokenA.approve(address(exchangeA), _amount),
            "Could not approve token0 sell"
        );
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

        uint[] memory tokenBought;
        tokenBought = IUniswapV2Router02(routerA).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this), // or address(this), and transfer the swapped token to msg.sender
            block.timestamp + 3
        );

        require(
            tokenBought > 0,
            "tokenBought must be gt 0"
        );

        require(
            TokenB.approve(address(exchangeB), tokenBought[0]),
            "Could not approve token1 sell"
        );

        address[] memory path1;

        if (token0 == WBNB || token1 == WBNB) {
            path = new address[](2);
            path[0] = token1;
            path[1] = token0;
        } else {
            path = new address[](3);
            path[0] = token1;
            path[1] = WBNB;
            path[2] = token0;
        }
        uint[] memory token1Bought;
        token1Bought= IUniswapV2Router02(routerB).swapExactTokensForTokens(
            tokenBought[0],
            0,
            path1,
            address(this), // or address(this), and transfer the swapped token to msg.sender
            block.timestamp + 3
        );

        
        require(
            token1Bought > 0,
            "tokenBought must be gt 0"
        );
        
        /////////////////////////////////// swap ends here

        uint256 totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    function rescueBNB(uint256 amount) external{
        owner.transfer(amount);
    }

	function getDeadline() internal view returns (uint256) {
			return now + 3000;
	}
    
    // This is the last function to call to execute arbitrage
    function executeArbi( address _tokenPay1, // source currency when we will get; example BNB
		address _tokenSwap1, // swapped currency with the source currency; example BUSD
		uint256 _amountTokenPay1, // example: BNB => 10 * 1e18
		address _sourceFactory1,
		address _targetFactory1,
		address _sourceRouter1,
		address _targetRouter1 ) public{
        
        // setting parameters
        _tokenPay = _tokenPay1;
        _tokenSwap = _tokenSwap1;
        _amountTokenPay = _amountTokenPay1;
        _sourceFactory = _sourceFactory1;
        _targetFactory = _targetFactory1;
        _sourceRouter = _sourceRouter1;
        _targetRouter = _targetRouter1;
        // end setting parameters

        if(_tokenPay==WBNB)
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
        ); 

        pairAddress0 = IUniswapV2Factory(_sourceFactory).getPair(_tokenPay, _tokenSwap);
        require(pairAddress0 != address(0), "first pair not available");
        pairAddress1 = IUniswapV2Factory(_targetFactory).getPair(_tokenPay, _tokenSwap);
        require(pairAddress0 != address(0), "second pair not available");


        exchangeA = IUniswapV2Pair(pairAddress0);
        exchangeB = IUniswapV2Pair(pairAddress1);


        routerA= _sourceRouter;
        routerB = _targetRouter;

        bytes memory data = "";

        ILendingPool lendingPool = ILendingPool(
        addressesProvider.getLendingPool()
        );


        // invoke a flashloan and receive a loan on this contract address 
        lendingPool.flashLoan(receiver, token0, _amountTokenPay, data);
    }

    
}
