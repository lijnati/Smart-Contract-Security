// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/vulnerable/OverflowVulnerable.sol";
import "../contracts/exploits/OverflowAttacker.sol";
import "../contracts/fixed/OverflowFixed.sol";



contract OverflowTest is Test {
    OverflowVulnerable public vulnerableContract;
    OverflowAttacker public attacker;
    OverflowFixed public fixedContract;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public hacker = address(0x3);
    
    uint256 constant INITIAL_SUPPLY = 1000000 * 10**18;
    
    function setUp() public {
        vulnerableContract = new OverflowVulnerable(INITIAL_SUPPLY);
        fixedContract = new OverflowFixed(INITIAL_SUPPLY);
        
        // transfer some tokens to users for testing
        vulnerableContract.transfer(user1, 1000 * 10**18);
        vulnerableContract.transfer(user2, 2000 * 10**18);
        vulnerableContract.transfer(hacker, 100 * 10**18);
        
        fixedContract.transfer(user1, 1000 * 10**18);
        fixedContract.transfer(user2, 2000 * 10**18);
        fixedContract.transfer(hacker, 100 * 10**18);
        
        attacker = new OverflowAttacker(address(vulnerableContract));
        vulnerableContract.transfer(address(attacker), 50 * 10**18);
    }
    
    function testExploitUnderflow() public {
        uint256 initialBalance = vulnerableContract.balanceOf(address(attacker));
        console.log("Attacker initial balance:", initialBalance);
        
        // execute underflow attack
        vm.prank(hacker);
        attacker.underflowAttack();
        
        uint256 finalBalance = vulnerableContract.balanceOf(address(attacker));
        console.log("Attacker final balance:", finalBalance);
        
        // In vulnerable contract, underflow should give massive balance
        assertTrue(finalBalance > initialBalance, "Underflow attack should increase balance");
        
        // The balance should be close to type(uint256).max due to underflow
        assertTrue(finalBalance > type(uint256).max / 2, "Balance should be very large due to underflow");
    }
    
    function testExploitBatchOverflow() public {
        uint256 initialBalance = vulnerableContract.balanceOf(address(attacker));
        console.log("Attacker initial balance before batch attack:", initialBalance);
        
        vm.prank(hacker);
        attacker.batchOverflowAttack();
        
        uint256 finalBalance = vulnerableContract.balanceOf(address(attacker));
        console.log("Attacker final balance after batch attack:", finalBalance);
        
       
    }
    
    function testFixedContractPreventsUnderflow() public {
        uint256 initialBalance = fixedContract.balanceOf(hacker);
        
        // Try to transfer more than balance - should revert
        vm.prank(hacker);
        vm.expectRevert("Insufficient balance");
        fixedContract.transfer(user1, initialBalance + 1);
        
        // Balance should remain unchanged
        assertEq(fixedContract.balanceOf(hacker), initialBalance, "Balance should not change on failed transfer");
    }
    
    function testFixedContractBatchTransfer() public {
        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        
        recipients[0] = user1;
        recipients[1] = user2;
        amounts[0] = 10 * 10**18;
        amounts[1] = 20 * 10**18;
        
        uint256 initialBalance = fixedContract.balanceOf(hacker);
        uint256 totalAmount = amounts[0] + amounts[1];
        
        vm.prank(hacker);
        fixedContract.batchTransfer(recipients, amounts);
        
        assertEq(
            fixedContract.balanceOf(hacker), 
            initialBalance - totalAmount,
            "Sender balance should decrease by total amount"
        );
        
        assertEq(
            fixedContract.balanceOf(user1), 
            1000 * 10**18 + amounts[0],
            "Recipient 1 should receive correct amount"
        );
    }
    
    function testFixedContractOverflowProtection() public {
        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        
        recipients[0] = user1;
        recipients[1] = user2;
        
        // try to cause overflow in totalAmount
        amounts[0] = type(uint256).max - 100;
        amounts[1] = 200;
        
        vm.prank(hacker);
        vm.expectRevert(); // should revert due to overflow
        fixedContract.batchTransfer(recipients, amounts);
    }
    
    function testSafeTransfer() public {
        uint256 transferAmount = 10 * 10**18;
        uint256 initialBalance = fixedContract.balanceOf(hacker);
        
        vm.prank(hacker);
        bool success = fixedContract.safeTransfer(user1, transferAmount);
        
        assertTrue(success, "Safe transfer should succeed");
        assertEq(
            fixedContract.balanceOf(hacker), 
            initialBalance - transferAmount,
            "Balance should decrease"
        );
    }
    
    function testSafeTransferFailure() public {
        uint256 transferAmount = 1000 * 10**18; // More than hacker has
        
        vm.prank(hacker);
        bool success = fixedContract.safeTransfer(user1, transferAmount);
        
        assertFalse(success, "Safe transfer should fail for insufficient balance");
    }
    
    function testFuzzTransfer(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 50 * 10**18); // Within attacker's balance
        
        uint256 initialBalance = fixedContract.balanceOf(hacker);
        
        vm.prank(hacker);
        fixedContract.transfer(user1, amount);
        
        assertEq(
            fixedContract.balanceOf(hacker), 
            initialBalance - amount,
            "Balance should decrease by transfer amount"
        );
    }
    
    function testCanTransfer() public {
        assertTrue(
            fixedContract.canTransfer(hacker, user1, 50 * 10**18),
            "Should be able to transfer within balance"
        );
        
        assertFalse(
            fixedContract.canTransfer(hacker, user1, 200 * 10**18),
            "Should not be able to transfer more than balance"
        );
        
        assertFalse(
            fixedContract.canTransfer(hacker, address(0), 10 * 10**18),
            "Should not be able to transfer to zero address"
        );
    }
}