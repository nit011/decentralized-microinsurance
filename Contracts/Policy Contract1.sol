//PolicyContract handles policy creation, premium payment, policy claims, and payouts.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract PolicyContract {
    struct Policy {
        address user;
        uint256 premium;
        uint256 coverage;
        uint256 expirationDate;
        bool isClaimed;
        bool isActive;
    }


    mapping(address => Policy) public policies;

    event PolicyCreated(address indexed user, uint256 premium, uint256 coverage, uint256 expirationDate);
    event PremiumPaid(address indexed user, uint256 premiumAmount);
    event PolicyClaimed(address indexed user, uint256 claimAmount);
    event Payout(address indexed user, uint256 payoutAmount);

    modifier onlyActivePolicy(address _user) {
        require(policies[_user].isActive, "Policy is not active");
        _;
    }

    modifier onlyUnclaimedPolicy(address _user) {
        require(!policies[_user].isClaimed, "Policy has already been claimed");
        _;
    }

    function createPolicy(uint256 _premium, uint256 _coverage, uint256 _expirationDate) external {
        require(_premium > 0, "Premium amount must be greater than zero");
        require(_expirationDate > block.timestamp, "Expiration date must be in the future");
        require(!policies[msg.sender].isActive, "User already has an existing policy");

        Policy storage policy = policies[msg.sender];
        policy.user = msg.sender;
        policy.premium = _premium;
        policy.coverage = _coverage;
        policy.expirationDate = _expirationDate;
        policy.isClaimed = false;
        policy.isActive = true;

        emit PolicyCreated(msg.sender, _premium, _coverage, _expirationDate);
    }

    function payPremium() external payable onlyActivePolicy(msg.sender) {
        require(msg.value == policies[msg.sender].premium, "Incorrect premium amount");

        emit PremiumPaid(msg.sender, msg.value);
    }

    function claimPolicy() external onlyActivePolicy(msg.sender) onlyUnclaimedPolicy(msg.sender) {
        require(policies[msg.sender].expirationDate < block.timestamp, "Policy has not expired yet");

        uint256 claimAmount = policies[msg.sender].coverage;

        policies[msg.sender].isClaimed = true;

        emit PolicyClaimed(msg.sender, claimAmount);
    }

    function payout(address payable _user, uint256 _amount) external onlyActivePolicy(_user) {
        require(policies[_user].isClaimed, "Policy has not been claimed yet");
        require(_amount <= policies[_user].coverage, "Payout amount exceeds coverage");

        policies[_user].isActive = false;

        _user.transfer(_amount);

        emit Payout(_user, _amount);
    }
}
