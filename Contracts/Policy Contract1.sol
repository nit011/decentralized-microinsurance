//This contract demonstrates the implementation of policy creation, premium payment, claim submission, claim processing, and payout distribution. It also includes the integration with Chainlink Keepers to automate claim processing.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract AutomatedClaimsProcessing is ChainlinkClient, KeeperCompatibleInterface {
    uint256 private policyCounter;
    uint256 private claimCounter;
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

    constructor(address _oracle, string memory _jobId, uint256 _fee) {
        setChainlinkOracle(_oracle);
        jobId = stringToBytes32(_jobId);
        fee = _fee;
    }

    function registerPolicy(uint256 _expirationDate) external payable {
        require(msg.value > 0, "Premium amount must be greater than 0");

        uint256 newPolicyId = policyCounter;
        policies[newPolicyId] = Policy(msg.sender, msg.value, _expirationDate, true);

        emit PolicyRegistered(newPolicyId, msg.sender);

        policyCounter++;
    }

    function submitClaim(uint256 _policyId, uint256 _amount) external {
        require(policies[_policyId].isActive, "Invalid policy ID");
        require(msg.sender == policies[_policyId].policyholder, "Not the policyholder");
        require(!claims[_policyId].isProcessed, "Claim has already been processed");

        uint256 newClaimId = claimCounter;
        claims[newClaimId] = Claim(_policyId, msg.sender, _amount, false);

        emit ClaimSubmitted(newClaimId, _policyId, msg.sender);

        claimCounter++;
    }

    function processClaim(uint256 _claimId) external {
        require(claims[_claimId].isProcessed == false, "Claim has already been processed");

        Claim memory claim = claims[_claimId];

        // Implement our claim processing logic here
        // we can use Chainlink oracles to fetch external data for claim verification, such as accident reports or weather data

        // Placeholder action: Approve and process the claim by transferring the claim amount to the claimant
        payable(claim.claimant).transfer(claim.amount);
        claims[_claimId].isProcessed = true;

        emit ClaimProcessed(_claimId, claim.policyId, claim.claimant, claim.amount);
    }

    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        // Implement your own logic to determine if upkeep is needed
        //  we can check if there are any pending claims that need processing

        upkeepNeeded = false; // Set to true if upkeep is needed
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        // Implement our own logic for performing the automated claims processing
        // we can iterate over the pending claims and process them

        // Call processClaim() function for each pending claim
        // Make sure to set claim.isProcessed to true after processing

        
         for (uint256 claimId = 0; claimId < claimCounter; claimId++) {
            if (!claims[claimId].isProcessed) {
                processClaim(claimId);
            }
        }
    }

    function cancelPolicy(uint256 _policyId) external {
        require(policies[_policyId].isActive, "Invalid policy ID");
        require(msg.sender == policies[_policyId].policyholder, "Not the policyholder");

        policies[_policyId].isActive = false;
    }

    function withdrawFunds() external {
        // Implement our own logic to withdraw contract funds, if necessary
        //  we can restrict withdrawals to the contract owner

        // Placeholder action: Transfer all contract funds to the contract owner
        payable(msg.sender).transfer(address(this).balance);
    }

    // Helper function to convert string to bytes32
    function stringToBytes32(string memory _source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_source, 32))
        }
    }
}


