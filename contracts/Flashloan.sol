pragma solidity ^0.5.0;

import "./base/FlashLoanReceiverBase.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";
import "./interfaces/ILendingPool.sol";
import "./WBNB.sol";

contract Flashloan is FlashLoanReceiverBase {

    address public receiver = address(this);
    address public constant BNB_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    WBNB wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    mapping (address => uint)                       public  balanceOf;

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

        WrapBNB();
        
        UnwrapBNB(_amount);

        uint256 totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }



    function WrapBNB() public payable{

       require(msg.value>0, "no value for deposit ");
       require(address(this).balance >0, "no money ");
        wbnb.deposit.value(msg.value)(); //wrap BNB to WBNB
    }


    function UnwrapBNB(uint _amount) public payable{

        require(_amount>0, "no amount for withdraw ");
        wbnb.withdraw(_amount); //unwrap WBNB to BNB
    }

}