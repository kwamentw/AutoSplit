// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

//import Token
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import{SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import ownable
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// import uniswap interface
import {IUniswapV2Router01} from "./IUniswapV2Router01.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//for test purposes
import {console} from "forge-std/console.sol";

/**
 * @title Auto Split
 * @author 4b
 * @notice This is production code but meant for understanding the concept of rebalancing.
 */
contract AutoSplit is Ownable {

    using SafeERC20 for IERC20;

    //TokenA
    IERC20 tokenA;
    //TokenB
    IERC20 tokenB;
    //Router
    IUniswapV2Router01 router;
    uint256 constant TARGET_RATIO = 5e3; //50%
    uint256 constant rebalanceThreshold = 500; //5% deviation of thhe target triggers rebalance

    // emits when tokens are deposited
    event Deposited(address user, uint256 amountTknA, uint256 amountTknB);
    // emits when tokens are  withdrawn
    event Withdrawn(address receipient, uint256 amounttkA, uint256 anounttkB);
    // emits when tokens are swapped
    event Swapped(address fromtkn, address totkn, uint256 amount);
    // emits when tokens are rebalanced
    event Rebalanced( address tknA, address tknB);

    error InsufficientAmount(); //reverts when amount is insufficient

    /**
     * temo variables to be initialized to main variables 
     * @param _tokenA token A address
     * @param _tokenB token B address
     * @param _router router address
     */
    constructor(address _tokenA, address _tokenB, address _router) Ownable(msg.sender){
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        router = IUniswapV2Router01(_router);
    }

    /**
     * Deposits tokens into pool
     * @param amountA amount of token A
     * @param amountB amount of token B
     */
    function deposit(uint256 amountA, uint256 amountB) external onlyOwner{
        require(amountA != 0 || amountB != 0,"Stop fucking around there's nothing to deposit");
        
        if(amountA != 0 && amountB != 0){
            tokenA.safeTransferFrom(msg.sender, address(this), amountA);
            tokenB.safeTransferFrom(msg.sender, address(this), amountB);
        }else{
            if(amountA == 0){
                tokenB.safeTransferFrom(msg.sender, address(this), amountB);
            }else if ( amountB == 0){
                tokenA.safeTransferFrom(msg.sender, address(this), amountA);
            }
        }

        emit Deposited( msg.sender, amountA, amountB);

    }
    
    /**
     * Checks whether protocol needs rebalancing
     */
    function needRebalance() external view returns(bool) {
        uint256 balA = tokenA.balanceOf(address(this))/1e6;
        uint256 balB = tokenB.balanceOf(address(this))/1e18;

        console.log("balance of A: ", balA);
        console.log("balance of B: ", balB);

        uint256 totalBal =(balA + balB);
        console.log("Total balance: ", totalBal);

        uint256 currentRatio = totalBal == 0 ? 5e3 : balA * 1e4 / totalBal; //find a way to normalise the decimals of balA here too
        console.log("current ratio: ", currentRatio);

        if(currentRatio >  TARGET_RATIO + rebalanceThreshold || currentRatio < TARGET_RATIO - rebalanceThreshold){
            return true;
        }else{
            return false;
        }
    }

    /**
     * Rebalances the tokens in the pool
     */ 
    function rebalance() public returns (uint256[] memory retAmt){

        uint256 balanceA = tokenA.balanceOf(address(this));
        uint256 balanceB = tokenB.balanceOf(address(this));
        uint256 totalBalance = balanceA + balanceB;


        uint256 desiredBalanceA = (totalBalance * TARGET_RATIO ) / 1e4;
        uint256 desiredBalanceB = (totalBalance * TARGET_RATIO ) / 1e4;
        console.log("dbal: ",desiredBalanceA);

        if (balanceA > desiredBalanceA) {
            uint256 excessA = balanceA - desiredBalanceA;
            // swap(usdc, dai, excessUsdc);
            retAmt = _swap(address(tokenA), address(tokenB), (excessA)/2, 0);
        }else if (balanceB > desiredBalanceB) {
            uint256 excessB = balanceB - desiredBalanceB;
            // swap(dai, usdc, excessDai);
            retAmt = _swap(address(tokenB), address(tokenA), (excessB)/2, 0);
        }

         emit Rebalanced(address(tokenA), address(tokenB));
    }
     

    /**
     * Swaps from one token to another
     * @param fromtkn input token
     * @param totkn output token
     * @param amount amount to swap
     * @param amountMin minimum amount desired
     */
    function _swap(address fromtkn, address totkn, uint256 amount, uint256 amountMin) internal returns(uint256[] memory retAmt){
        address[] memory path = new address[](2);
        IERC20(fromtkn).approve(address(router), amount);

        path[0] = fromtkn;
        path[1] = totkn;
        uint256 balBef = IERC20(totkn).balanceOf(address(this));

        retAmt = IUniswapV2Router01(router).swapExactTokensForTokens(amount, amountMin, path, address(this), block.timestamp); //keeping dealine zero for now

        uint256 balAfter = IERC20(totkn).balanceOf(address(this));

        if(balAfter - balBef < amountMin || retAmt[1] != balAfter - balBef){
            revert InsufficientAmount();
        }

        emit Swapped(fromtkn, totkn, amount);
    }

    /**
     * Withdraws a specific amount of token A or/and B 
     * @param amountA amount of token A
     * @param amountB amount of token B
     */
    function withdraw(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA != 0 || amountB != 0,"Nothing to transfer");

        if(amountA != 0){
            if(amountB != 0){
                tokenA.safeTransfer(msg.sender, amountA);
                tokenB.safeTransfer(msg.sender, amountB);
            }else if(amountB == 0){
                tokenA.safeTransfer(msg.sender, amountA);
            }
        }else if(amountB != 0){
            tokenB.safeTransfer(msg.sender, amountB);
        }

        emit Withdrawn(msg.sender, amountA, amountB);
    }

    /**
     * Returns total balance of both tokens 
     * @return balA balance of token A
     * @return balB balance of token B
     */
    function getTotalBalances() public view returns(uint256 balA, uint256 balB){
        balA = tokenA.balanceOf(address(this));
        balB = tokenB.balanceOf(address(this));
    }

}