//This smart contract allows users to register policies, calculate premiums, handle policy expiration, submit claims, and process payouts.

// The Policy struct represents a policy with its associated details, and the Claim struct represents a claim with its relevant information.

//Users can register a policy by calling the registerPolicy function, passing the desired expiration date as a parameter and sending the premium amount as Ether. 

//The calculatePremium function can be used to retrieve the premium amount for a specific policy.

//The expirePolicy function allows policyholders to manually expire their policies after the expiration date has passed.

//Claims can be submitted using the submitClaim function, specifying the policy ID and the claim amount. 

//The processClaim function is used to approve a claim, and the distributePayout function is used to distribute the approved claim amount to the policyholder.

// this contract includes getter functions (getPolicy and getClaim) to retrieve policy and claim details based on their respective IDs.

//Events are emitted throughout the contract execution to notify external systems or applications about policy registrations, claim submissions, claim approvals, and claim payouts.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MicroinsuranceContract {
    
    struct Policy {
        address policyholder;
        uint256 premium;
        uint256 expirationDate;
        bool isActive;
    }
    
    struct Claim {
        uint256 claimAmount;
        bool isApproved;
        bool isPaid;
    }
    
    mapping(uint256 => Policy) private policies;
    mapping(uint256 => Claim) private claims;
    uint256 private policyCounter;
    uint256 private claimCounter;
    
    event PolicyRegistered(uint256 indexed policyId, address indexed policyholder);
    event ClaimSubmitted(uint256 indexed claimId, uint256 indexed policyId, uint256 claimAmount);
    event ClaimApproved(uint256 indexed claimId);
    event ClaimPaid(uint256 indexed claimId);
    
    modifier onlyActivePolicy(uint256 _policyId) {
        require(policies[_policyId].isActive, "Policy is not active");
        _;
    }
    
    modifier onlyPolicyholder(uint256 _policyId) {
        require(policies[_policyId].policyholder == msg.sender, "Not the policyholder");
        _;
    }
    
    function registerPolicy(uint256 _expirationDate) external payable {
        require(msg.value > 0, "Premium amount must be greater than 0");
        
        uint256 newPolicyId = policyCounter;
        policies[newPolicyId] = Policy(msg.sender, msg.value, _expirationDate, true);
        
        emit PolicyRegistered(newPolicyId, msg.sender);
        
        policyCounter++;
    }
    
    function calculatePremium(uint256 _policyId) external view returns (uint256) {
        require(policies[_policyId].isActive, "Policy is not active");
        return policies[_policyId].premium;
    }
    
    function expirePolicy(uint256 _policyId) external onlyPolicyholder(_policyId) {
        require(block.timestamp >= policies[_policyId].expirationDate, "Policy has not expired yet");
        policies[_policyId].isActive = false;
    }
    
    function submitClaim(uint256 _policyId, uint256 _claimAmount) external onlyActivePolicy(_policyId) {
        require(_claimAmount > 0, "Claim amount must be greater than 0");
        
        uint256 newClaimId = claimCounter;
        claims[newClaimId] = Claim(_claimAmount, false, false);
        
        emit ClaimSubmitted(newClaimId, _policyId, _claimAmount);
        
        claimCounter++;
    }
    
    function processClaim(uint256 _claimId) external {
        require(!claims[_claimId].isApproved, "Claim has already been approved");
        require(policies[_claimId].isActive, "Policy is not active");
        
        claims[_claimId].isApproved = true;
        
        emit ClaimApproved(_claimId);
    }
    
    function distributePayout(uint256 _claimId) external onlyActivePolicy(_claimId) {
        require(claims[_claimId].isApproved, "Claim has not been approved yet");
        require(!claims[_claimId].isPaid, "Claim has already been paid");
        
        claims[_claimId].isPaid = true;
        
        payable(policies[_claimId].policyholder).transfer(claims[_claimId].claimAmount);
        
        emit ClaimPaid(_claimId);
    }
    
    function getPolicy(uint256 _policyId) external view returns (address, uint256, uint256, bool) {
        return (
            policies[_policyId].policyholder,
            policies[_policyId].premium,
            policies[_policyId].expirationDate,
            policies[_policyId].isActive
        );
    }
    
    function getClaim(uint256 _claimId) external view returns (uint256, bool, bool) {
        return (
            claims[_claimId].claimAmount,
            claims[_claimId].isApproved,
            claims[_claimId].isPaid
        );
    }
}
