// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


contract AccessControlVulnerable {
    address public owner;
    mapping(address => bool) public admins;
    mapping(address => uint256) public balances;
    bool public paused;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    
    constructor() {
        owner = msg.sender;
    }
    
    // VULNERABILITY #1 : Missing access control modifier
    function transferOwnership(address newOwner) external {
       
        require(newOwner != address(0), "New owner cannot be zero address");
        
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    // VULNERABILITY #2 : Weak access control check
    function addAdmin(address admin) external {
        // VULNERABLE: Uses tx.origin instead of msg.sender
        require(tx.origin == owner, "Only owner can add admins");
        admins[admin] = true;
        emit AdminAdded(admin);
    }
    
    function removeAdmin(address admin) external {
        require(msg.sender == owner, "Only owner can remove admins");
        admins[admin] = false;
        emit AdminRemoved(admin);
    }
    
    // VULNERABILITY #3: Missing proper access control
    function emergencyPause() external {
        // Should check if caller is owner or admin
        paused = true;
    }
    
    function unpause() external {
        require(msg.sender == owner, "Only owner can unpause");
        paused = false;
    }
    
    // VULNERABILITY #4: State-changing function marked as view
    function deposit() external payable view {
        // VULNERABLE: This should modify state but is marked as view
        // balances[msg.sender] += msg.value; // This would cause compilation error
    }
    
    // VULNERABILITY #5: Public function that should be internal
    function _internalFunction() public pure returns (string memory) {
        return "This should be internal!";
    }
    
    function withdraw(uint256 amount) external {
        require(!paused, "Contract is paused");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}