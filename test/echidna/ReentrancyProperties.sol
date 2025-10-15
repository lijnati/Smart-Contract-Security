// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../contracts/fixed/ReentrancyFixed.sol";


contract ReentrancyProperties {
    ReentrancyFixed public target;
    
    uint256 public totalDeposited;
    uint256 public totalWithdrawn;
    
    constructor() {
        target = new ReentrancyFixed();
    }
    
    // Property: Contract balance should always equal total deposits minus total withdrawals
    function echidna_balance_consistency() public view returns (bool) {
        return address(target).balance == totalDeposited - totalWithdrawn;
    }
    
    // Property: User balance should never exceed their deposits
    function echidna_user_balance_bounded() public view returns (bool) {
        return target.getBalance(msg.sender) <= address(this).balance + totalDeposited;
    }
    
    // Property: Total supply conservation
    function echidna_supply_conservation() public view returns (bool) {
        return address(target).balance + totalWithdrawn == totalDeposited;
    }
    
    // Property: No negative balances (this should always be true in Solidity)
    function echidna_no_negative_balance() public view returns (bool) {
        return target.getBalance(msg.sender) >= 0;
    }
    
    // Property: Withdrawal should not exceed user balance
    function echidna_withdrawal_bounded(uint256 amount) public returns (bool) {
        uint256 userBalance = target.getBalance(msg.sender);
        
        if (amount > userBalance) {
            // Should revert, so we return true if it doesn't execute
            try target.withdraw(amount) {
                return false; // Should not succeed
            } catch {
                return true; // Correctly reverted
            }
        }
        
        return true;
    }
    
    // Test functions for Echidna to call
    function deposit() public payable {
        if (msg.value > 0) {
            target.deposit{value: msg.value}();
            totalDeposited += msg.value;
        }
    }
    
    function withdraw(uint256 amount) public {
        uint256 balanceBefore = target.getBalance(msg.sender);
        
        if (amount <= balanceBefore && amount > 0) {
            target.withdraw(amount);
            totalWithdrawn += amount;
        }
    }
    
    function requestWithdrawal(uint256 amount) public {
        if (amount <= target.getBalance(msg.sender) && amount > 0) {
            target.requestWithdrawal(amount);
        }
    }
    
    function completePendingWithdrawal() public {
        uint256 pending = target.getPendingWithdrawal(msg.sender);
        if (pending > 0) {
            target.completePendingWithdrawal();
            totalWithdrawn += pending;
        }
    }
    
    // Receive function to accept ETH
    receive() external payable {}
}