// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Transact__INSUFFICIENT_FUNDS();
error Transact__INVALID_BURN_AMT();
error Transact__INVALID_SWAP_AMT();

contract Transact is ERC20, Ownable {
    mapping(address => uint256) public addressToAmtDeposited;

    // Exchange rates (1 token = exchangeRate usdc, 1 token = exchangeRate usdt)
    uint256 public exchangeRate = 100;

    address public usdcToken;
    address public usdtToken;


    event deposited(
        address indexed depositor,
        uint256 indexed amountDeposited
    );

    event burnt(
        address indexed burner,
        uint256 amountBurnt
    );

    event swapped(
        address indexed swapper,
        uint256 amountSwapped
    );
    

    constructor(
        string memory _name,
        string memory _symbol,
        address _usdcToken,
        address _usdtToken
    ) ERC20(_name, _symbol) {
        usdcToken = _usdcToken;
        usdtToken = _usdtToken;
    }

    function deposit(uint256 usdcAmount, uint256 ethAmount, uint256 arbAmount) external {
        // We're going to assume 1 usdc, eth and arb can mint 1 token
        if(usdcAmount <= 0 && ethAmount <= 0 && arbAmount <= 0){
            revert Transact__INSUFFICIENT_FUNDS();
        }

        uint256 totalDepositAmount = usdcAmount + ethAmount + arbAmount;

        // Mint the token to the depositor
        _mint(msg.sender, totalDepositAmount);

        // Update deposited amounts for the user
        addressToAmtDeposited[msg.sender] += totalDepositAmount;
        emit deposited(msg.sender, totalDepositAmount);

        // These conditionals allow transfer of either eth,usdc or arb from the depositor to the contract depending on which was deposited
        if (usdcAmount > 0) {
            require(IERC20(usdcToken).transferFrom(msg.sender, address(this), usdcAmount), "USDC transfer failed");
        }

        if (ethAmount > 0) {
            payable(address(this)).transfer(ethAmount);
        }

        if (arbAmount > 0) {
            // Perform ARB transfer logic here
            // Example: Transfer ARB from msg.sender to address(this)
        }
    }

    function burn(uint256 amount) external {
        if(amount < 0 || amount > addressToAmtDeposited[msg.sender]){
            revert Transact__INVALID_BURN_AMT();
        }

        // Burn the token from the user
        _burn(msg.sender, amount);

        // Update deposited amounts for the user
        addressToAmtDeposited[msg.sender] -= amount;
        emit burnt(msg.sender, amount);
    }

    function swap(uint256 amount, bool forUSDC) external {
        if(amount < 0 || amount > addressToAmtDeposited[msg.sender]){
            revert Transact__INVALID_SWAP_AMT();
        }

        // Calculate the equivalent amount based on the exchange rate
        uint256 equivalentAmount = amount * exchangeRate;

        // Transfer USDC or USDT to the user
        address recipient = forUSDC ? usdcToken : usdtToken;
        require(IERC20(recipient).transfer(msg.sender, equivalentAmount), "Swap failed");

        // Burn the swapped tokens
        _burn(msg.sender, amount);

        // Update deposited amounts for the user
        addressToAmtDeposited[msg.sender] -= amount;
        emit swapped(msg.sender, equivalentAmount);
    }

    function updateExchangeRate(uint256 newRate) external onlyOwner {
        exchangeRate = newRate;
    }

    // GETTERS
}