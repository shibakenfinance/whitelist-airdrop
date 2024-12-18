// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WhitelistAirdrop is Ownable, ReentrancyGuard {
    IERC20 public token;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public hasClaimed;
    uint256 public airdropAmount;
    bool public isAirdropActive;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    event TokensClaimed(address indexed account, uint256 amount);

    constructor(address _token, uint256 _airdropAmount) {
        token = IERC20(_token);
        airdropAmount = _airdropAmount;
        isAirdropActive = false;
    }

    function addToWhitelist(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
            emit AddedToWhitelist(accounts[i]);
        }
    }

    function removeFromWhitelist(address account) external onlyOwner {
        whitelist[account] = false;
        emit RemovedFromWhitelist(account);
    }

    function setAirdropActive(bool _isActive) external onlyOwner {
        isAirdropActive = _isActive;
    }

    function claim() external nonReentrant {
        require(isAirdropActive, "Airdrop is not active");
        require(whitelist[msg.sender], "Address not whitelisted");
        require(!hasClaimed[msg.sender], "Already claimed");
        require(token.balanceOf(address(this)) >= airdropAmount, "Insufficient tokens");

        hasClaimed[msg.sender] = true;
        require(token.transfer(msg.sender, airdropAmount), "Transfer failed");
        
        emit TokensClaimed(msg.sender, airdropAmount);
    }

    function withdrawTokens() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner(), balance), "Transfer failed");
    }
}
