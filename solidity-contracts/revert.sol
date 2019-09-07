pragma solidity ^0.5.11;

contract Reverter {
  function reverter() public returns (uint yourMom) {
    uint y = 0;
    if (y != 0) { revert("No way"); }
    y = 1;
    return y;
  }
}