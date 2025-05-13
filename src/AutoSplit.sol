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
    uint256 constant TARGET_RATIO = 50; //50%
    uint256 constant rebalanceThreshold = 5; //5% deviation of thhe target triggers rebalance

    // emits when tokens are deposited
    event Deposited(address user, uint256 amountTknA, uint256 amountTknB);
    // emits when tokens are  withdrawn
    event Withdrawn(address receipient, uint256 amounttkA, uint256 anounttkB);
    // emits when tokens are swapped
    event Swapped(address fromtkn, address totkn, uint256 amount);
    // emits when tokens are rebalanced
    event Rebalanced( address tknA, address tknB);

    error InsufficientAmount(); //reverts when amount is insufficient

    constructor(address _tokenA, address _tokenB, address _router) Ownable(msg.sender){
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        router = IUniswapV2Router01(_router);
    }

    //deposit
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


    // check rebalance from here if it needs rebalance then it is invoked from here 
    function needRebalance() external view returns(bool) {
        uint256 balA = tokenA.balanceOf(address(this));
        uint256 balB = tokenB.balanceOf(address(this));
        // decimals of token A
        uint256 decimalsA = ERC20(address(tokenA)).decimals();
        // decimals of token B
        uint256 decimalsB = ERC20(address(tokenB)).decimals();
        uint256 decDiff = decimalsA > decimalsB ? decimalsA - decimalsB : decimalsB - decimalsA;
        
        // balA = decimalsA > decimalsB ? balA : balA*decDiff;
        // balB = decimalsA > decimalsB ? balB*decDiff : balB;

        uint256 totalBal = decimalsA > decimalsB ? (balA + balB*decDiff) : (balA*decDiff + balB);

        uint256 currentRatio = totalBal == 0 ? 50 : balA * 100 / totalBal; //find a way to normalise the decimals of balA here too

        if(currentRatio >  TARGET_RATIO + rebalanceThreshold || currentRatio < TARGET_RATIO - rebalanceThreshold){
            return true;
        }else{
            return false;
        }
    }


    //rebalance
    //revisit the rebalance logic | the existing logic is not entirely correct | decimals checked left with the main logic
    /**
     * Rebalances the tokens in the pool
     */ 
    function rebalance() public returns (uint256[] memory retAmt){
        uint256 balA = tokenA.balanceOf(address(this));
        uint256 balB = tokenB.balanceOf(address(this));

        // decimals of token A
        uint256 decimalsA = ERC20(address(tokenA)).decimals();
        // decimals of token B
        uint256 decimalsB = ERC20(address(tokenB)).decimals();

        uint256 decDiff = decimalsA > decimalsB ? decimalsA - decimalsB : decimalsB - decimalsA;

         if(balA>balB){

            uint256 diff = decimalsA > decimalsB ? (balA - balB*decDiff) : (balA*decDiff - balB);
            require(diff != 0,"invalid amount");
            retAmt =_swap(address(tokenA), address(tokenB), diff,0);

         }else if( balB > balA){

            uint256 diff = decimalsB > decimalsA ? (balB - balA*decDiff) : (balB*decDiff - balA);
            require(diff != 0, "invalid amount");
            retAmt =_swap(address(tokenB), address(tokenA), diff,0);
         }

         emit Rebalanced(address(tokenA), address(tokenB));
    }
     
    //swap
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
    //withdraw
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

/**
 * Find the real value by multiplying the price
 * check the weights and rebalance
 * take into consideration decimals too
 * look at previous rebalance logics
 */

// new rebalance logic
// function rebalance() external {
//         uint256 balanceA = tokenA.balanceOf(pool);
//         uint256 balanceB = tokenB.balanceOf(pool);
//         uint256 totalBalance = balanceA + balanceB;

//         uint256 desiredBalanceA = (totalBalance * targetRatioA) / 100;
//         uint256 desiredBalanceB = (totalBalance * targetRatioB) / 100;

//         if (balanceA > desiredBalanceA) {
//             uint256 excessA = balanceA - desiredBalanceA;
//             _swapTokenAForTokenB(excessA);
//         } else if (balanceB > desiredBalanceB) {
//             uint256 excessB = balanceB - desiredBalanceB;
//             _swapTokenBForTokenA(excessB);
//         }
//     }