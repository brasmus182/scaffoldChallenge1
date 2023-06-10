// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping (address => uint256) public balances;

  uint256 public constant threshold = 1 ether;

  uint256 public deadline = block.timestamp + 72 hours;
  bool public openForWithdrawal = false;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  } 

  event Stake(address, uint256);
  event Withdrawal(address, uint256);

  function stake() public payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }
  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

  function execute() public returns (uint256) {
    require(block.timestamp >= deadline, "Deadline not met");
    uint256 contractBalance = address(this).balance;
    if(contractBalance <= threshold) {
      openForWithdrawal = true;
    } else {
      exampleExternalContract.complete{value: address(this).balance}();
    }
  }
  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`


  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() public payable {
    require(openForWithdrawal, "Withdrawl is not available yet"); 
    uint256 amount = balances[msg.sender];
    require(amount > 0, "User balance is Zero");
    balances[msg.sender] = 0;
    (bool sent, ) = msg.sender.call{value: amount}("");
    require(sent, "Failed to send to address");
    emit Withdrawal(msg.sender, amount);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256){
    if(block.timestamp >= deadline) return 0;
    return deadline - block.timestamp;
  }

  // Add the `receive()` special function that receives eth and calls stake()

  function thresholdCrossed() public view returns (bool) {
    return address(this).balance >= threshold;
  }

  receive() external payable {
    stake();
  }

}
