// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SBXToken is ERC20, Ownable, Pausable {
    address public treasury;
    address public governanceDAO;
    
    event TreasuryUpdated(address indexed newTreasury);
    event GovernanceUpdated(address indexed newGovernance);
    
    constructor(
        address _treasury,
        address _governanceDAO
    ) ERC20("Shibakery Exchange", "SBX") {
        require(_treasury != address(0), "Invalid treasury address");
        require(_governanceDAO != address(0), "Invalid governance address");
        
        treasury = _treasury;
        governanceDAO = _governanceDAO;
    }
    
    function mint(address to, uint256 amount) external {
        require(msg.sender == treasury || msg.sender == governanceDAO, "Unauthorized");
        _mint(to, amount);
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    function updateTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury address");
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }
    
    function updateGovernance(address newGovernance) external onlyOwner {
        require(newGovernance != address(0), "Invalid governance address");
        governanceDAO = newGovernance;
        emit GovernanceUpdated(newGovernance);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
