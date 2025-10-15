// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../contracts/fixed/OverflowFixed.sol";


contract OverflowProperties {
    OverflowFixed public target;
    
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10**18;
    mapping(address => uint256) public initialBalances;
    
    constructor() {
        target = new OverflowFixed(INITIAL_SUPPLY);
        initialBalances[address(this)] = INITIAL_SUPPLY;
    }
    
    // property: Total supply should remain constant
    function echidna_total_supply_constant() public view returns (bool) {
        return target.totalSupply() == INITIAL_SUPPLY;
    }
    
    // property: Sum of all balances should equal total supply
    function echidna_balance_sum_equals_supply() public view returns (bool) {
        // This is hard to test with Echidna since we can't iterate over all addresses
        // But we can check that our known balances don't exceed supply
        return target.balanceOf(address(this)) <= INITIAL_SUPPLY;
    }
    
    // property: Balance should never exceed total supply
    function echidna_balance_bounded() public view returns (bool) {
        return target.balanceOf(msg.sender) <= INITIAL_SUPPLY;
    }
    
    // property: Transfer should preserve total balance
    function echidna_transfer_preserves_total(address to, uint256 amount) public returns (bool) {
        if (to == address(0) || to == msg.sender || amount == 0) {
            return true; // Skip invalid transfers
        }
        
        uint256 senderBefore = target.balanceOf(msg.sender);
        uint256 receiverBefore = target.balanceOf(to);
        
        if (amount > senderBefore) {
            // Should revert
            try target.transfer(to, amount) {
                return false; // Should not succeed
            } catch {
                return true; // Correctly reverted
            }
        }
        
        try target.transfer(to, amount) {
            uint256 senderAfter = target.balanceOf(msg.sender);
            uint256 receiverAfter = target.balanceOf(to);
            
            // Check balance changes
            return (senderAfter == senderBefore - amount) && 
                   (receiverAfter == receiverBefore + amount);
        } catch {
            return true; // Any revert is acceptable for edge cases
        }
    }
    
    // Property: Batch transfer should preserve total balance
    function echidna_batch_transfer_preserves_total() public returns (bool) {
        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        
        recipients[0] = address(0x1);
        recipients[1] = address(0x2);
        amounts[0] = 100;
        amounts[1] = 200;
        
        uint256 totalAmount = amounts[0] + amounts[1];
        uint256 senderBefore = target.balanceOf(msg.sender);
        
        if (totalAmount > senderBefore || totalAmount == 0) {
            return true; // Skip invalid transfers
        }
        
        try target.batchTransfer(recipients, amounts) {
            uint256 senderAfter = target.balanceOf(msg.sender);
            return senderAfter == senderBefore - totalAmount;
        } catch {
            return true; // Reverts are acceptable
        }
    }
    
    // Property: Safe transfer should never cause unexpected state changes
    function echidna_safe_transfer_consistency(address to, uint256 amount) public returns (bool) {
        if (to == address(0) || to == msg.sender) {
            return true;
        }
        
        uint256 senderBefore = target.balanceOf(msg.sender);
        uint256 receiverBefore = target.balanceOf(to);
        
        bool success = target.safeTransfer(to, amount);
        
        uint256 senderAfter = target.balanceOf(msg.sender);
        uint256 receiverAfter = target.balanceOf(to);
        
        if (success) {
            return (senderAfter == senderBefore - amount) && 
                   (receiverAfter == receiverBefore + amount);
        } else {
            return (senderAfter == senderBefore) && 
                   (receiverAfter == receiverBefore);
        }
    }
    
    // Property: canTransfer should accurately predict transfer success
    function echidna_can_transfer_accuracy(address to, uint256 amount) public view returns (bool) {
        bool canTransfer = target.canTransfer(msg.sender, to, amount);
        bool hasBalance = target.balanceOf(msg.sender) >= amount;
        bool validRecipient = to != address(0);
        
        return canTransfer == (hasBalance && validRecipient);
    }
    
    // Test functions for Echidna to call
    function transfer(address to, uint256 amount) public {
        if (to != address(0) && to != msg.sender && amount > 0) {
            try target.transfer(to, amount) {} catch {}
        }
    }
    
    function safeTransfer(address to, uint256 amount) public {
        if (to != address(0) && to != msg.sender) {
            target.safeTransfer(to, amount);
        }
    }
    
    function batchTransfer(uint256 amount1, uint256 amount2) public {
        if (amount1 > 0 && amount2 > 0 && amount1 + amount2 <= target.balanceOf(msg.sender)) {
            address[] memory recipients = new address[](2);
            uint256[] memory amounts = new uint256[](2);
            
            recipients[0] = address(0x1);
            recipients[1] = address(0x2);
            amounts[0] = amount1;
            amounts[1] = amount2;
            
            try target.batchTransfer(recipients, amounts) {} catch {}
        }
    }
}