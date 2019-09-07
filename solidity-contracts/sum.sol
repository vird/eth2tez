pragma solidity ^0.5.11;

contract Summator {
  uint public value = 2;
  
  function sum() public returns (uint yourMom) {
    uint x = 5;
    return value + x;
  }
}
