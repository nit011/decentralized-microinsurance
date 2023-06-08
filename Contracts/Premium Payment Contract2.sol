//PremiumPaymentContract allows users to pay their premiums. 
//It keeps track of the premium amount paid for each policy contract.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract PremiumPaymentContract {
    mapping(address => uint256) public premiums;

    event PremiumPaid(address indexed user, uint256 premiumAmount);

    function payPremium(address _policyContract) external payable {
        require(msg.value > 0, "Premium amount must be greater than zero");

        premiums[_policyContract] += msg.value;

        emit PremiumPaid(msg.sender, msg.value);
    }

    function getPremiumBalance(address _policyContract) external view returns (uint256) {
        return premiums[_policyContract];
    }
}
