// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title VotingPower
 * @dev Manages voting power based on staked tokens, expertise, and infrastructure contribution
 */
contract VotingPower is Ownable, ReentrancyGuard {
    IERC20 public sbxToken;
    
    // Staking and lock data
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public lockEndTime;
    mapping(address => uint256) public votingPower;
    
    // Expertise and contribution tracking
    mapping(address => bool) public isExpert;
    mapping(address => uint256) public infrastructureContribution;
    
    // Time lock tiers (in days) and their multipliers (x100 for precision)
    uint256 constant public MIN_LOCK_DAYS = 7;
    uint256 constant public MULTIPLIER_PRECISION = 100;
    uint256 constant public EXPERT_MULTIPLIER = 150; // 1.5x for experts
    uint256 constant public MAX_INFRA_MULTIPLIER = 300; // Up to 3x for infrastructure
    
    struct LockTier {
        uint256 days;
        uint256 multiplier;
    }
    
    LockTier[] public lockTiers;
    
    event Staked(address indexed user, uint256 amount, uint256 lockDays);
    event Unstaked(address indexed user, uint256 amount);
    event VotingPowerUpdated(address indexed user, uint256 newVotingPower);
    event ExpertStatusUpdated(address indexed user, bool isExpert);
    event InfrastructureContributionUpdated(address indexed user, uint256 amount);
    
    constructor(address _sbxToken) {
        sbxToken = IERC20(_sbxToken);
        
        // Initialize lock tiers
        lockTiers.push(LockTier({days: 7, multiplier: 100}));    // 1x for 7 days
        lockTiers.push(LockTier({days: 30, multiplier: 150}));   // 1.5x for 30 days
        lockTiers.push(LockTier({days: 90, multiplier: 200}));   // 2x for 90 days
        lockTiers.push(LockTier({days: 180, multiplier: 300}));  // 3x for 180 days
        lockTiers.push(LockTier({days: 365, multiplier: 500}));  // 5x for 365 days
    }
    
    function stake(uint256 amount, uint256 lockDays) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        require(lockDays >= MIN_LOCK_DAYS, "Lock too short");
        
        // Transfer tokens to contract
        require(sbxToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        // Update staking data
        stakedBalance[msg.sender] += amount;
        lockEndTime[msg.sender] = block.timestamp + (lockDays * 1 days);
        
        // Calculate and update voting power
        _updateVotingPower(msg.sender);
        
        emit Staked(msg.sender, amount, lockDays);
    }
    
    function unstake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot unstake 0");
        require(stakedBalance[msg.sender] >= amount, "Insufficient balance");
        require(block.timestamp >= lockEndTime[msg.sender], "Still locked");
        
        // Update staking data
        stakedBalance[msg.sender] -= amount;
        
        // Transfer tokens back to user
        require(sbxToken.transfer(msg.sender, amount), "Transfer failed");
        
        // Update voting power
        _updateVotingPower(msg.sender);
        
        emit Unstaked(msg.sender, amount);
    }
    
    function getVotingPower(address user) external view returns (uint256) {
        return votingPower[user];
    }
    
    function getLockTierMultiplier(uint256 lockDays) public view returns (uint256) {
        uint256 multiplier = lockTiers[0].multiplier; // Default to minimum multiplier
        
        for (uint256 i = 0; i < lockTiers.length; i++) {
            if (lockDays >= lockTiers[i].days) {
                multiplier = lockTiers[i].multiplier;
            } else {
                break;
            }
        }
        
        return multiplier;
    }
    
    function _updateVotingPower(address user) internal {
        uint256 stakedAmount = stakedBalance[user];
        if (stakedAmount == 0) {
            votingPower[user] = 0;
            emit VotingPowerUpdated(user, 0);
            return;
        }
        
        // Calculate days until lock expires
        uint256 daysLocked = 0;
        if (lockEndTime[user] > block.timestamp) {
            daysLocked = (lockEndTime[user] - block.timestamp) / 1 days;
        }
        
        // Get base multiplier based on lock time
        uint256 multiplier = getLockTierMultiplier(daysLocked);
        
        // Apply expert multiplier if applicable
        if (isExpert[user]) {
            multiplier = (multiplier * EXPERT_MULTIPLIER) / MULTIPLIER_PRECISION;
        }
        
        // Apply infrastructure contribution multiplier
        uint256 infraMultiplier = (infrastructureContribution[user] * MAX_INFRA_MULTIPLIER) / MULTIPLIER_PRECISION;
        if (infraMultiplier > MAX_INFRA_MULTIPLIER) {
            infraMultiplier = MAX_INFRA_MULTIPLIER;
        }
        multiplier += infraMultiplier;
        
        // Calculate final voting power: stake * multiplier / precision
        uint256 newVotingPower = (stakedAmount * multiplier) / MULTIPLIER_PRECISION;
        votingPower[user] = newVotingPower;
        
        emit VotingPowerUpdated(user, newVotingPower);
    }
    
    // Admin functions
    function setExpertStatus(address user, bool status) external onlyOwner {
        isExpert[user] = status;
        _updateVotingPower(user);
        emit ExpertStatusUpdated(user, status);
    }
    
    function updateInfrastructureContribution(address user, uint256 amount) external onlyOwner {
        infrastructureContribution[user] = amount;
        _updateVotingPower(user);
        emit InfrastructureContributionUpdated(user, amount);
    }
    
    function addLockTier(uint256 days_, uint256 multiplier) external onlyOwner {
        require(days_ > lockTiers[lockTiers.length - 1].days, "Invalid days");
        require(multiplier > lockTiers[lockTiers.length - 1].multiplier, "Invalid multiplier");
        
        lockTiers.push(LockTier({
            days: days_,
            multiplier: multiplier
        }));
    }
}
