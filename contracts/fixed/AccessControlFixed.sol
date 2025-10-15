// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract AccessControlFixed is Ownable, AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    mapping(address => uint256) public balances;
    
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    constructor() {
        // FIX: Proper role setup
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }
    
    // FIX 1: Proper access control with onlyOwner modifier
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        super.transferOwnership(newOwner);
        
        // Transfer admin roles to new owner
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _grantRole(ADMIN_ROLE, newOwner);
        _grantRole(PAUSER_ROLE, newOwner);
        
        // Revoke from old owner
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _revokeRole(ADMIN_ROLE, msg.sender);
        _revokeRole(PAUSER_ROLE, msg.sender);
    }
    
    // FIX 2: Use msg.sender instead of tx.origin and proper role-based access
    function addAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(admin != address(0), "Admin cannot be zero address");
        _grantRole(ADMIN_ROLE, admin);
        emit AdminAdded(admin);
    }
    
    function removeAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(ADMIN_ROLE, admin);
        emit AdminRemoved(admin);
    }
    
    // FIX 3: Proper access control for pause functionality
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // FIX 4: Proper state-changing function (not marked as view)
    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Must deposit some ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // FIX 5: Internal function properly marked as internal
    function _internalFunction() internal pure returns (string memory) {
        return "This is properly internal!";
    }
    
    // Public wrapper if external access is needed
    function getInternalFunctionResult() external pure returns (string memory) {
        return _internalFunction();
    }
    
    function withdraw(uint256 amount) external whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        
        emit Withdrawal(msg.sender, amount);
    }
    
    // Additional security functions
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function isAdmin(address account) external view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }
    
    function isPauser(address account) external view returns (bool) {
        return hasRole(PAUSER_ROLE, account);
    }
    
    // Override required by Solidity for multiple inheritance
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(AccessControl) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}