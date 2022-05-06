pragma solidity ^0.5.0;

import "./base/FlashLoanReceiverBase.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";
import "./interfaces/ILendingPool.sol";

contract Flashloan is FlashLoanReceiverBase {

    address public receiver = address(this);
    address public constant BNB_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public owner;

    // properties for swapping
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    //  address private constant pancakeRouter = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;
    IUniswapV2Pair public exchangeA;
    IUniswapV2Pair public exchangeB;
    address routerA;
    address routerB;
    address token0;
    address token1;
    address pairAddress0;
    address pairAddress1;
    // end properties for swapping

    
    constructor() public {
            owner = msg.sender;
    }

    function flashloanBnb(uint256 _amount) external  {
        bytes memory data = "";

        ILendingPool lendingPool = ILendingPool(
            addressesProvider.getLendingPool()
        );
        // invoke a flashloan and receive a loan on this contract address
        lendingPool.flashLoan(receiver, BNB_ADDRESS, _amount, data);
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

        //
        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `_reserve` funds to payback the `_fee` !!
        //

        // IDefi app = IDefi(defi);
        // Todo: Deposit into defi smart contract
        // app.depositBNB.value(_amount)(_amount);
        
        // Todo: Withdraw from defi smart contract
        // app.withdraw(_amount);

        uint256 totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    function rescueBNB(uint256 amount) external{
        payable(owner).transfer(amount);
    }
}
