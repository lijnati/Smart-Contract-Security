// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


contract OverflowVulnerable {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply;
        balances[msg.sender] = _initialSupply;
    }
    
    // VULNERABILITY #1: No overflow protection 
    function transfer(address to, uint256 amount) external {
        require(to != address(0), "Cannot transfer to zero address");
        
        unchecked {
            // VULNERABLE #2: Underflow possible if amount > balances[msg.sender]
            balances[msg.sender] -= amount;
            // VULNERABLE #3: Overflow possible
            balances[to] += amount;
        }
        
        emit Transfer(msg.sender, to, amount);
    }

    // VULNERABILITY #4: Batch transfer without proper checks
    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        
        uint256 totalAmount = 0;
        
        unchecked {
            // VULNERABLE #5: Overflow in totalAmount calculation
            for (uint256 i = 0; i < amounts.length; i++) {
                totalAmount += amounts[i];
            }
        }
        
        require(balances[msg.sender] >= totalAmount, "Insufficient balance");
        
        unchecked {
            balances[msg.sender] -= totalAmount;
            
            for (uint256 i = 0; i < recipients.length; i++) {
                // VULNERABLE #6: Overflow in recipient balance
                balances[recipients[i]] += amounts[i];
                emit Transfer(msg.sender, recipients[i], amounts[i]);
            }
        }
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}