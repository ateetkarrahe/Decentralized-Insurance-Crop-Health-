// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedInsurance {
    enum InsuranceType { Crop, Health }
    enum ClaimStatus { None, Filed, Approved, Rejected }

    struct InsurancePolicy {
        InsuranceType policyType;
        uint256 premium;
        uint256 coverage;
        ClaimStatus claimStatus;
        bool isActive;
        uint256 createdAt;
        uint256 expiry;
    }

    mapping(address => InsurancePolicy) public policies;
    mapping(address => bool) public blacklisted;

    address public owner;

    uint256 public totalPoliciesIssued;
    uint256 public totalClaimsFiled;

    event PolicyPurchased(address indexed user, InsuranceType policyType, uint256 premium, uint256 coverage);
    event ClaimFiled(address indexed user, InsuranceType policyType);
    event ClaimApproved(address indexed user, uint256 payout);
    event ClaimRejected(address indexed user);
    event PolicyCanceled(address indexed user);
    event FundsWithdrawn(address indexed admin, uint256 amount);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event DonationReceived(address indexed donor, uint256 amount);
    event UserBlacklisted(address indexed user);
    event UserRemovedFromBlacklist(address indexed user);
    event PolicyReset(address indexed user);
    event PolicyExtended(address indexed user, uint256 newExpiry);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Purchase insurance policy
    function purchasePolicy(InsuranceType _type) external payable {
        require(msg.value > 0, "Premium must be greater than 0");
        require(!policies[msg.sender].isActive, "Existing policy active");
        require(!blacklisted[msg.sender], "User is blacklisted");

        uint256 coverage = msg.value * 5;
        uint256 duration = 30 days;

        policies[msg.sender] = InsurancePolicy({
            policyType: _type,
            premium: msg.value,
            coverage: coverage,
            claimStatus: ClaimStatus.None,
            isActive: true,
            createdAt: block.timestamp,
            expiry: block.timestamp + duration
        });

        totalPoliciesIssued++;

        emit PolicyPurchased(msg.sender, _type, msg.value, coverage);
    }

    // File an insurance claim
    function fileClaim() external {
        InsurancePolicy storage policy = policies[msg.sender];
        require(policy.isActive, "No active policy");
        require(policy.claimStatus == ClaimStatus.None, "Claim already filed");
        require(block.timestamp <= policy.expiry, "Policy expired");

        policy.claimStatus = ClaimStatus.Filed;
        totalClaimsFiled++;

        emit ClaimFiled(msg.sender, policy.policyType);
    }

    // Approve a claim and send payout
    function approveClaim(address user) external onlyOwner {
        InsurancePolicy storage policy = policies[user];
        require(policy.claimStatus == ClaimStatus.Filed, "Claim not filed");

        policy.claimStatus = ClaimStatus.Approved;
        policy.isActive = false;

        payable(user).transfer(policy.coverage);
        emit ClaimApproved(user, policy.coverage);
    }

    // Reject a claim
    function rejectClaim(address user) external onlyOwner {
        InsurancePolicy storage policy = policies[user];
        require(policy.claimStatus == ClaimStatus.Filed, "Claim not filed");

        policy.claimStatus = ClaimStatus.Rejected;

        emit ClaimRejected(user);
    }

    // Cancel a policy (user-initiated)
    function cancelPolicy() external {
        InsurancePolicy storage policy = policies[msg.sender];
        require(policy.isActive, "No active policy");
        require(policy.claimStatus == ClaimStatus.None, "Claim already filed");

        uint256 refund = policy.premium;
        delete policies[msg.sender];

        payable(msg.sender).transfer(refund);
        emit PolicyCanceled(msg.sender);
    }

    // Withdraw unallocated funds (only owner)
    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(amount);

        emit FundsWithdrawn(owner, amount);
    }

    // View a user's policy details
    function getPolicyDetails(address user) external view returns (
        InsuranceType, uint256, uint256, ClaimStatus, bool, uint256, uint256
    ) {
        InsurancePolicy memory policy = policies[user];
        return (
            policy.policyType,
            policy.premium,
            policy.coverage,
            policy.claimStatus,
            policy.isActive,
            policy.createdAt,
            policy.expiry
        );
    }

    // Check if a user has an active policy
    function hasActivePolicy(address user) external view returns (bool) {
        return policies[user].isActive;
    }

    // Get the contract's current balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Transfer contract ownership
    function updateOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // Allow donations to the contract fund
    function donate() external payable {
        require(msg.value > 0, "Donation must be more than 0");
        emit DonationReceived(msg.sender, msg.value);
    }

    // Extend policy duration
    function extendPolicy(uint256 extraDays) external payable {
        InsurancePolicy storage policy = policies[msg.sender];
        require(policy.isActive, "No active policy");

        uint256 requiredAmount = (policy.premium * extraDays) / 30;
        require(msg.value >= requiredAmount, "Insufficient payment for extension");

        policy.expiry += extraDays * 1 days;

        emit PolicyExtended(msg.sender, policy.expiry);
    }

    // Check if a user's policy is expired
    function isPolicyExpired(address user) public view returns (bool) {
        InsurancePolicy memory policy = policies[user];
        return policy.isActive && block.timestamp > policy.expiry;
    }

    // Blacklist a user
    function blacklistUser(address user) external onlyOwner {
        blacklisted[user] = true;
        emit UserBlacklisted(user);
    }

    // Remove a user from blacklist
    function removeBlacklist(address user) external onlyOwner {
        blacklisted[user] = false;
        emit UserRemovedFromBlacklist(user);
    }

    // Reset a user's policy (admin only)
    function resetPolicy(address user) external onlyOwner {
        require(policies[user].isActive, "No active policy to reset");
        delete policies[user];
        emit PolicyReset(user);
    }

    // Get total stats
    function getPlatformStats() external view returns (uint256 totalPolicies, uint256 totalClaims, uint256 contractBalance) {
        return (totalPoliciesIssued, totalClaimsFiled, address(this).balance);
    }
}

