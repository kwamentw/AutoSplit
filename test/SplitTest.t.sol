// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AutoSplit} from "../src/AutoSplit.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Auto Split Test
 * @author 4b
 * @notice  A test script for AutoSplit
 */
contract SplitTest is Test{
    
    address tokenA = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //usdc
    address tokenB = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //Dai

    address routerr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    AutoSplit split; // contract to test

    function setUp() public{
        split = new AutoSplit(tokenA, tokenB, routerr);
    }

    /////////////////////// helper function //////////////////////////

    function depositOneSide(address token, uint256 amount) public {
        deal(token, address(this), amount + 10000e18);

        IERC20(token).approve(address(split), type(uint128).max);

        token == tokenB ? split.deposit(0,amount) : split.deposit(amount,0);

        uint256 splitBalTknB = IERC20(token).balanceOf(address(split));

        console2.log("token bal of contract", splitBalTknB);
    }

    ///////////////////// DEPOSIT TEST //////////////////////////

    function testDeposit() public{

        deal(tokenA, address(this), 10e18);
        deal(tokenB, address(this), 10e18);

        IERC20(tokenA).approve(address(split), 10e18);
        IERC20(tokenB).approve(address(split), 10e18);

        // vm.prank(address(this));
        split.deposit(10e18,10e18);

        uint256 splitBalTknA = IERC20(tokenA).balanceOf(address(split));
        uint256 splitBalTknB = IERC20(tokenB).balanceOf(address(split));

        assertEq(splitBalTknA, splitBalTknB);
        assertEq(splitBalTknB, 10e18);

        console2.log("tokenA bal of contract", splitBalTknA);
        console2.log("tokenB bal of contract", splitBalTknB);
    }

    function testDepositOneSide() public{
        deal(tokenB, address(this), 200e18);

        IERC20(tokenB).approve(address(split), 200e18);

        split.deposit(0,200e18);

        uint256 splitBalTknB = IERC20(tokenB).balanceOf(address(split));

        assertEq(splitBalTknB, 200e18);
        console2.log("tokenB bal of contract", splitBalTknB);
    }

    function testDepositOtherSide() public{
        depositOneSide(tokenA, 100e18);

        uint256 bal = IERC20(tokenA).balanceOf(address(split));
        assertEq(bal, 100e18);
    }

    ///////////////////////////// WITHDRAW TEST ///////////////////////////////

    function testWithdraw() public{

        depositOneSide(tokenA,100e18);
        uint256 balBefA = IERC20(tokenA).balanceOf(address(split));
        assertEq(balBefA, 100e18);

        depositOneSide(tokenB, 100e18);
        uint256 balBefB = IERC20(tokenB).balanceOf(address(split));
        assertEq(balBefB, 100e18);

        split.withdraw(100e18,100e18);
        uint256 balAftA = IERC20(tokenA).balanceOf(address(split));
        uint256 balAftB = IERC20(tokenB).balanceOf(address(split));

        assertEq(balAftA, balAftB); // All balances should zero out
        assertEq(balAftA, 0);

        uint256 senderBalA = IERC20(tokenA).balanceOf(address(this));
        uint256 senderBalB = IERC20(tokenB).balanceOf(address(this));
        assertEq(senderBalA, senderBalB);
        assertEq(senderBalA, 100e18);

    }

    function testWithdrawOneSide() public{
        depositOneSide(tokenA, 100e18);
        depositOneSide(tokenB, 100e18);

        split.withdraw(0,100e18);

        uint256 balA = IERC20(tokenA).balanceOf(address(this));
        uint256 balB = IERC20(tokenB).balanceOf(address(this));

        assertEq(balA, 0);
        assertEq(balB, 100e18);
        
        // checking the tokenA withdrawal

        split.withdraw(100e18,0);

        uint256 balA2 = IERC20(tokenA).balanceOf(address(this));

        assertEq(balA2, 100e18);
        assertGt(balA2, balA);
    }

    //////////////////////////////////// REBALANCE TEST ////////////////////////////

    function testNeedsRebalance() public{
        // deposit equal amounts in both tokens
        depositOneSide(tokenB, 20e18);
        depositOneSide(tokenA, 20e18);

        bool state1 = split.needRebalance();

        // deposit only one side of the pool
        depositOneSide(tokenA, 200e18);

        bool state2 = split.needRebalance();

        assertFalse(state1);
        assertTrue(state2);

        console2.log(state1);
        console2.log(state2);
    }

    function testRebalance() public {
        depositOneSide(tokenB, 100e18);
        depositOneSide(tokenA, 50e6);

        bool needReba = split.needRebalance();

        assertTrue(needReba);

        split.rebalance();

        needReba= split.needRebalance();

        (uint256 balA, uint256 balB) = split.getTotalBalances();

        console2.log("Bal of tokenA: ", balA);
        console2.log("Bal of tokenB: ", balB);

        if(needReba){
            split.rebalance();
        }else{
            assertFalse(needReba);
        }

        needReba= split.needRebalance();
    }
}