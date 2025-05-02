// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AutoSplit} from "../src/AutoSplit.sol";
import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract SplitTest is Test{
    address tokenA = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //usdc
    address tokenB = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //Dai
    address routerr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    AutoSplit split;

    function setUp() public{
        split = new AutoSplit(tokenA, tokenB, routerr);
    }

    function testDeposit() public{

        deal(tokenA, address(this), 10e18);
        deal(tokenB, address(this), 10e18);

        IERC20(tokenA).approve(address(split), 10e18);
        IERC20(tokenB).approve(address(split), 10e18);

        // vm.prank(address(this));
        split.deposit(10e18,10e18);
    }
}