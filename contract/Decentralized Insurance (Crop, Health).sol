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
    }

    mapping(address => InsurancePolicy) public policies;
    address public owner;

    event PolicyPurchased(address indexed user, InsuranceType policyType, uint256 premium, uint256 coverage);
    event ClaimFiled(address indexed user, InsuranceType policyType);
    event ClaimApproved(address indexed user, uint256 payout);
    event ClaimRejected(address indexed user);
    event PolicyCanceled(address indexed user);
    event FundsWithdrawn(address indexed admin, uint256 amount);

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

        uint256 coverage = msg.value * 5;

        policies[msg.sender] = InsurancePolicy({
            policyType: _type,
            premium: msg.value,
            coverage: coverage,
            claimStatus: ClaimStatus.None,
            isActive: true
        });

        emit PolicyPurchased(msg.sender, _type, msg.value, coverage);
    }

    // File an insurance claim
    function fileClaim() external {
        InsurancePolicy storage policy = policies[msg.sender];
        require(policy.isActive, "No active policy");
        require(policy.claimStatus == ClaimStatus.None, "Claim already filed");

        policy.claimStatus = ClaimStatus.Filed;

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
}
