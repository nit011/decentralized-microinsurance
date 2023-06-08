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

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract AutomatedClaimsProcessing is ChainlinkClient, KeeperCompatibleInterface {
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    struct Policy {
        address policyholder;
        uint256 premium;
        uint256 expirationDate;
        bool isActive;
    }

    struct Claim {
        uint256 policyId;
        address claimant;
        uint256 amount;
        bool isProcessed;
    }

    mapping(uint256 => Policy) private policies;
    mapping(uint256 => Claim) private claims;

    event PolicyRegistered(uint256 indexed policyId, address indexed policyholder);
    event ClaimSubmitted(uint256 indexed claimId, uint256 indexed policyId, address indexed claimant);
    event ClaimProcessed(uint256 indexed claimId, uint256 indexed policyId, address indexed claimant, uint256 amount);

    constructor(address _oracle, bytes32 _jobId, uint256 _fee) {
        setChainlinkOracle(_oracle);
        jobId = _jobId;
        fee = _fee;
    }

    function registerPolicy(uint256 _expirationDate) external payable {
        require(msg.value > 0, "Premium amount must be greater than 0");

        uint256 newPolicyId = policies.length;
        policies[newPolicyId] = Policy(msg.sender, msg.value, _expirationDate, true);

        emit PolicyRegistered(newPolicyId, msg.sender);
    }

    function submitClaim(uint256 _policyId, uint256 _amount) external {
        require(policies[_policyId].isActive, "Invalid policy ID");
        require(msg.sender == policies[_policyId].policyholder, "Not the policyholder");
        require(!claims[_policyId].isProcessed, "Claim has already been processed");

        uint256 newClaimId = claims.length;
        claims[newClaimId] = Claim(_policyId, msg.sender, _amount, false);

        emit ClaimSubmitted(newClaimId, _policyId, msg.sender);
    }

    function processClaim(uint256 _claimId) external {
        require(claims[_claimId].isProcessed == false, "Claim has already been processed");

        Claim memory claim = claims[_claimId];

        // Implement our claim processing logic here

        // Placeholder action: Approve and process the claim by transferring the claim amount to the claimant
        payable(claim.claimant).transfer(claim.amount);
        claims[_claimId].isProcessed = true;

        emit ClaimProcessed(_claimId, claim.policyId, claim.claimant, claim.amount);
    }

    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        // Implement our own logic to determine if upkeep is needed
        //  we can check if there are any pending claims that need processing

        upkeepNeeded = false; // Set to true if upkeep is needed
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        // Implement our own logic for performing the automated claims processing
        //  we can iterate over the pending claims and process them

        // Call processClaim() function for each pending claim
        // Make sure to set claim.isProcessed to true after processing

        
         for (uint256 claimId = 0; claimId < claims.length; claimId++) {
            if (!claims[claimId].isProcessed) {
                processClaim(claimId);
            }
         }
    }
}
