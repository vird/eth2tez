pragma solidity ^0.5.11;

contract Asserter {
  function asserter() public returns (uint yourMom) {
    uint y = 0;
    assert(y != 0);
    y = 1;
    return y;
  }
}