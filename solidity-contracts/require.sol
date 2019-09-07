pragma solidity ^0.5.11;

contract Requirer {
  function requirer() public returns (uint yourMom) {
    uint y = 0;
    require( (y != 0), "No way");
    y = 1;
    return y;
  }
}