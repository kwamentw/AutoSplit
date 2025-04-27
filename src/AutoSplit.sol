// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

//import Token
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import ownable
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// import uniswap interface
import {IUniswapV2Router01} from "./IUniswapV2Router01.sol";

contract AutoSplit is Ownable {
    //TokenA
    IERC20 tokenA;
    //TokenB
    IERC20 tokenB;
    //Router
    IUniswapV2Router01 router;

    constructor(address _tokenA, address _tokenB, address _router) Ownable(msg.sender){
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        router = IUniswapV2Router01(_router);
    }

    //deposit
    function deposit(uint256 amountA, uint256 amountB) external onlyOwner{

    }

    // check rebalance from here if it needs rebalance then it is invoked from here 
    function needRebalance() external returns(bool) {}
    //rebalance
    function rebalance() internal {}
    //swap
    function _swap() internal {}
    //withdraw
    function withdraw() public onlyOwner {}

}