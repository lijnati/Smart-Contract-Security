// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OverflowFixed {
    using SafeMath for uint256;
    
    mapping(address => uint256) public balances;
    uint256 public totalSupply;
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply;
        balances[msg.sender] = _initialSupply;
    }
    
    // FIX 1: Proper balance checks and safe arithmetic
    function transfer(address to, uint256 amount) external {
        require(to != address(0), "Cannot transfer to zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // FIX: Use checked arithmetic (default in 0.8.19)
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
    }
    
    // FIX 2: Safe batch transfer with proper overflow checks
    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length > 0, "Empty arrays");
        require(recipients.length <= 100, "Too many recipients"); // Gas limit protection
        
        uint256 totalAmount = 0;
        
        // FIX: Check for overflow in totalAmount calculation
        for (uint256 i = 0; i < amounts.length; i++) {
            require(recipients[i] != address(0), "Cannot transfer to zero address");
            require(amounts[i] > 0, "Amount must be positive");
            
            // This will revert on overflow (checked arithmetic)
            totalAmount += amounts[i];
        }
        
        require(balances[msg.sender] >= totalAmount, "Insufficient balance");
        
        // Update sender balance first
        balances[msg.sender] -= totalAmount;
        
        // Then update recipient balances
        for (uint256 i = 0; i < recipients.length; i++) {
            balances[recipients[i]] += amounts[i];
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }
    }
    
    // FIX 3: Safe batch transfer with SafeMath (alternative approach)
    function safeBatchTransfer(address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length > 0, "Empty arrays");
        require(recipients.length <= 100, "Too many recipients");
        
        uint256 totalAmount = 0;
        
        for (uint256 i = 0; i < amounts.length; i++) {
            require(recipients[i] != address(0), "Cannot transfer to zero address");
            require(amounts[i] > 0, "Amount must be positive");
            
            // Using SafeMath for explicit overflow protection
            totalAmount = totalAmount.add(amounts[i]);
        }
        
        require(balances[msg.sender] >= totalAmount, "Insufficient balance");
        
        balances[msg.sender] = balances[msg.sender].sub(totalAmount);
        
        for (uint256 i = 0; i < recipients.length; i++) {
            balances[recipients[i]] = balances[recipients[i]].add(amounts[i]);
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }
    }
    
    // FIX 4: Additional safety functions
    function safeTransfer(address to, uint256 amount) external returns (bool) {
        if (to == address(0) || balances[msg.sender] < amount) {
            return false;
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    // Additional view function to check if transfer would succeed
    function canTransfer(address from, address to, uint256 amount) external view returns (bool) {
        return to != address(0) && balances[from] >= amount;
    }
}