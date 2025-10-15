// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/vulnerable/ReentrancyVulnerable.sol";
import "../contracts/exploits/ReentrancyAttacker.sol";
import "../contracts/fixed/ReentrancyFixed.sol";

contract ReentrancyTest is Test {
    ReentrancyVulnerable public vulnerableContract;
    ReentrancyAttacker public attacker;
    ReentrancyFixed public fixedContract;
    
    address public victim1 = address(0x1);
    address public victim2 = address(0x2);
    address public hacker = address(0x3);
    
    function setUp() public {
        vulnerableContract = new ReentrancyVulnerable();
        fixedContract = new ReentrancyFixed();
        
        // Fund victims
        vm.deal(victim1, 10 ether);
        vm.deal(victim2, 10 ether);
        vm.deal(hacker, 5 ether);
        
        // victims deposit into vulnerable contract
        vm.prank(victim1);
        vulnerableContract.deposit{value: 5 ether}();
        
        vm.prank(victim2);
        vulnerableContract.deposit{value: 3 ether}();
    }
    
    function testExploitReentrancy() public {
        uint256 initialContractBalance = vulnerableContract.getContractBalance();
        console.log("Initial contract balance:", initialContractBalance);
        
        // deploy attacker contract
        vm.prank(hacker);
        attacker = new ReentrancyAttacker(address(vulnerableContract));
        
        uint256 attackAmount = 1 ether;
        uint256 hackerInitialBalance = hacker.balance;
        
        // execute attack
        vm.prank(hacker);
        attacker.attack{value: attackAmount}();
        
        uint256 finalContractBalance = vulnerableContract.getContractBalance();
        uint256 attackerBalance = attacker.getBalance();
        
        console.log("Final contract balance:", finalContractBalance);
        console.log("Attacker contract balance:", attackerBalance);
        console.log("Stolen amount:", attackerBalance - attackAmount);
        
        // verify attack succeeded
        assertTrue(attackerBalance > attackAmount, "Attack should have stolen funds");
        assertTrue(finalContractBalance < initialContractBalance, "Contract should have lost funds");
        
        // withdraw stolen funds
        vm.prank(hacker);
        attacker.withdrawStolen();
        
        uint256 hackerFinalBalance = hacker.balance;
        console.log("Hacker profit:", hackerFinalBalance - hackerInitialBalance);
        
        assertTrue(hackerFinalBalance > hackerInitialBalance, "Hacker should have profited");
    }
    
    function testFixedContractPreventsReentrancy() public {
        // fund fixed contract
        vm.prank(victim1);
        fixedContract.deposit{value: 5 ether}();
        
        // try to create attacker for fixed contract (this should fail)
        vm.prank(hacker);
        
        
        uint256 initialBalance = fixedContract.getBalance(victim1);
        
        // normal withdrawal should work
        vm.prank(victim1);
        fixedContract.withdraw(1 ether);
        
        uint256 finalBalance = fixedContract.getBalance(victim1);
        assertEq(finalBalance, initialBalance - 1 ether, "Normal withdrawal should work");
    }
    
    function testPullPaymentPattern() public {
        vm.prank(victim1);
        fixedContract.deposit{value: 5 ether}();
        
        uint256 withdrawAmount = 2 ether;
        
        // request withdrawal
        vm.prank(victim1);
        fixedContract.requestWithdrawal(withdrawAmount);
        
        assertEq(
            fixedContract.getPendingWithdrawal(victim1), 
            withdrawAmount, 
            "Pending withdrawal should be recorded"
        );
        
        uint256 initialEthBalance = victim1.balance;
        
        // complete withdrawal
        vm.prank(victim1);
        fixedContract.completePendingWithdrawal();
        
        assertEq(
            fixedContract.getPendingWithdrawal(victim1), 
            0, 
            "Pending withdrawal should be cleared"
        );
        
        assertEq(
            victim1.balance, 
            initialEthBalance + withdrawAmount, 
            "Victim should receive ETH"
        );
    }
    
    function testFuzzWithdrawal(uint256 depositAmount, uint256 withdrawAmount) public {
        vm.assume(depositAmount > 0 && depositAmount <= 100 ether);
        vm.assume(withdrawAmount <= depositAmount);
        
        vm.deal(victim1, depositAmount);
        
        vm.prank(victim1);
        fixedContract.deposit{value: depositAmount}();
        
        if (withdrawAmount > 0) {
            vm.prank(victim1);
            fixedContract.withdraw(withdrawAmount);
            
            assertEq(
                fixedContract.getBalance(victim1), 
                depositAmount - withdrawAmount,
                "Balance should be updated correctly"
            );
        }
    }
}