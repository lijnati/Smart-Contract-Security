// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/vulnerable/AccessControlVulnerable.sol";
import "../contracts/exploits/AccessControlAttacker.sol";
import "../contracts/fixed/AccessControlFixed.sol";

contract AccessControlTest is Test {
    AccessControlVulnerable public vulnerableContract;
    AccessControlAttacker public attacker;
    AccessControlFixed public fixedContract;
    
    address public owner = address(0x1);
    address public user = address(0x2);
    address public hacker = address(0x3);
    
    function setUp() public {
        vm.prank(owner);
        vulnerableContract = new AccessControlVulnerable();
        
        vm.prank(owner);
        fixedContract = new AccessControlFixed();
        
        vm.deal(user, 10 ether);
        vm.deal(hacker, 5 ether);
        
        attacker = new AccessControlAttacker(address(vulnerableContract));
    }
    
    function testExploitOwnershipTheft() public {
        address originalOwner = vulnerableContract.owner();
        assertEq(originalOwner, owner, "Original owner should be set correctly");
        
        // Hacker steals ownership due to missing access control
        vm.prank(hacker);
        attacker.stealOwnership();
        
        assertTrue(attacker.isOwner(), "Attacker should have stolen ownership");
        assertEq(vulnerableContract.owner(), address(attacker), "Contract owner should be attacker");
    }
    
    function testExploitUnauthorizedPause() public {
        assertFalse(vulnerableContract.paused(), "Contract should not be paused initially");
        
        // missing access control
        vm.prank(hacker);
        attacker.unauthorizedPause();
        
        assertTrue(vulnerableContract.paused(), "Contract should be paused by unauthorized user");
    }
    
    function testExploitInternalFunctionCall() public {
        vm.prank(hacker);
        string memory result = attacker.callInternalFunction();
        
        assertEq(result, "This should be internal!", "Should be able to call internal function");
    }
    
    function testFixedContractOwnershipProtection() public {
        address originalOwner = fixedContract.owner();
        
        // try to steal ownership 
        vm.prank(hacker);
        vm.expectRevert("Ownable: caller is not the owner");
        fixedContract.transferOwnership(hacker);
        
        assertEq(fixedContract.owner(), originalOwner, "Owner should not change");
    }
    
    function testFixedContractProperOwnershipTransfer() public {
        address newOwner = address(0x4);
        
        vm.prank(owner);
        fixedContract.transferOwnership(newOwner);
        
        assertEq(fixedContract.owner(), newOwner, "Ownership should transfer correctly");
        assertTrue(fixedContract.isAdmin(newOwner), "New owner should have admin role");
    }
    
    function testFixedContractAdminManagement() public {
        // only owner can add admins
        vm.prank(hacker);
        vm.expectRevert();
        fixedContract.addAdmin(hacker);
        
        // owner can add admins
        vm.prank(owner);
        fixedContract.addAdmin(user);
        
        assertTrue(fixedContract.isAdmin(user), "User should be admin");
        
        // owner can remove admins
        vm.prank(owner);
        fixedContract.removeAdmin(user);
        
        assertFalse(fixedContract.isAdmin(user), "User should no longer be admin");
    }
    
    function testFixedContractPauseProtection() public {
        // only pauser role can pause
        vm.prank(hacker);
        vm.expectRevert();
        fixedContract.pause();

        // owner has pauser role by default
        vm.prank(owner);
        fixedContract.pause();
        
        assertTrue(fixedContract.paused(), "Contract should be paused");
        
        // only owner can unpause
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        fixedContract.unpause();
        
        vm.prank(owner);
        fixedContract.unpause();
        
        assertFalse(fixedContract.paused(), "Contract should be unpaused");
    }
    
    function testFixedContractDeposit() public {
        uint256 depositAmount = 1 ether;
        
        vm.prank(user);
        fixedContract.deposit{value: depositAmount}();
        
        assertEq(fixedContract.balances(user), depositAmount, "Balance should be updated");
    }
    
    function testFixedContractDepositWhenPaused() public {
        vm.prank(owner);
        fixedContract.pause();
        
        vm.prank(user);
        vm.expectRevert("Pausable: paused");
        fixedContract.deposit{value: 1 ether}();
    }
    
    function testFixedContractWithdrawal() public {
        uint256 depositAmount = 2 ether;
        uint256 withdrawAmount = 1 ether;
        
        // deposit first
        vm.prank(user);
        fixedContract.deposit{value: depositAmount}();
        
        uint256 initialEthBalance = user.balance;
        
        // withdraw
        vm.prank(user);
        fixedContract.withdraw(withdrawAmount);
        
        assertEq(
            fixedContract.balances(user), 
            depositAmount - withdrawAmount,
            "Contract balance should decrease"
        );
        
        assertEq(
            user.balance, 
            initialEthBalance + withdrawAmount,
            "User ETH balance should increase"
        );
    }
    
    function testFixedContractEmergencyWithdraw() public {
        // deposit some ETH
        vm.prank(user);
        fixedContract.deposit{value: 5 ether}();
        
        uint256 contractBalance = address(fixedContract).balance;
        uint256 ownerInitialBalance = owner.balance;
        
        // only owner can emergency withdraw
        vm.prank(hacker);
        vm.expectRevert("Ownable: caller is not the owner");
        fixedContract.emergencyWithdraw();
        
        vm.prank(owner);
        fixedContract.emergencyWithdraw();
        
        assertEq(address(fixedContract).balance, 0, "Contract should have no ETH");
        assertEq(owner.balance, ownerInitialBalance + contractBalance, "Owner should receive ETH");
    }
    
    function testRoleBasedAccess() public {
        bytes32 adminRole = fixedContract.ADMIN_ROLE();
        bytes32 pauserRole = fixedContract.PAUSER_ROLE();
        
        // owner has all roles initially
        assertTrue(fixedContract.hasRole(adminRole, owner), "Owner should have admin role");
        assertTrue(fixedContract.hasRole(pauserRole, owner), "Owner should have pauser role");
        
        // grant pauser role to user
        vm.prank(owner);
        fixedContract.grantRole(pauserRole, user);
        
        assertTrue(fixedContract.isPauser(user), "User should have pauser role");
        
        // user can now pause
        vm.prank(user);
        fixedContract.pause();
        
        assertTrue(fixedContract.paused(), "Contract should be paused by user");
    }
    
    function testFuzzDeposit(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 100 ether);
        vm.deal(user, amount);
        
        vm.prank(user);
        fixedContract.deposit{value: amount}();
        
        assertEq(fixedContract.balances(user), amount, "Balance should match deposit");
    }
}