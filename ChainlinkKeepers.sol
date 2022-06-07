//SPDX-License-Identifier: MIT
pragma solidity >=0.6.7;

import "@chainlink/contracts/src/v0.6/interfaces/KeeperCompatibleInterface.sol";

contract Subsidy is KeeperCompatibleInterface {
    address payable private owner;              //Owner of the contract
    address payable public beneficiary;         //Payments will be made to this address
    address payable private pendingBeneficiary; //Store the beneficiary here until approved by owner
    uint256 public immutable interval;          //Time interval between payments
    uint256 private immutable amount;           //Amount to be paid to beneficiary
    uint256 public lastTimeStamp;               //Last payment time

    /* ---------- Modifiers ---------- */
    modifier restricted() {
        require(msg.sender == owner);
        _;
    }

    modifier hasBeneficiary() {
        require(beneficiary != address(0));
        _;
    }

    modifier hasPendingBeneficiary() {
        require(pendingBeneficiary != address(0));
        _;
    }

    modifier noPendingBeneficiary() {
        require(pendingBeneficiary == address(0));
        _;
    }

    constructor(uint256 updateInterval, uint256 subsidy) public {
        owner = msg.sender;
        interval = updateInterval;
        amount = subsidy;
        lastTimeStamp = block.timestamp;
    }

    //Check contract balance
    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    //Owner can withdraw everything
    function withdraw() public restricted {
        owner.transfer(address(this).balance);
    }

    //Register as pending beneficiary
    function registerBeneficiary() public noPendingBeneficiary {
        pendingBeneficiary = msg.sender;
    }

    //Approve pending beneficiary. Must be called by owner.
    function approveBeneficiary() public restricted hasPendingBeneficiary {
        beneficiary = pendingBeneficiary;
        pendingBeneficiary = address(0);
    }

    //Deposit amount to be paid as subsidy
    function depositSubsidy() public payable restricted {}

    //Called by Chainlink Keepers to check if work needs to be done
    function checkUpkeep(
        bytes calldata /*checkData */
    ) external override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (beneficiary != address(0)) && (block.timestamp - lastTimeStamp) > interval;
    }

    //Called by Chainlink Keepers to handle work
    function performUpkeep(bytes calldata) external override {
        lastTimeStamp = block.timestamp;
        require(address(this).balance > amount);
        beneficiary.transfer(amount);
    }
}