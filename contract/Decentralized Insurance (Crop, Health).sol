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

    event PolicyPurchased(address indexed user, InsuranceType policyType, uint256 premium, uint256 coverage);
    event ClaimFiled(address indexed user, InsuranceType policyType);

    // Purchase insurance policy
    function purchasePolicy(InsuranceType _type) external payable {
        require(msg.value > 0, "Premium must be greater than 0");
        require(!policies[msg.sender].isActive, "Existing policy active");

        uint256 coverage = msg.value * 5; // Simplified logic: coverage = 5x premium

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
}
