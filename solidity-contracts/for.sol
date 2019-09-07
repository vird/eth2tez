pragma solidity ^0.5.11;

contract Forer {
  uint public value;
  
  function forer() public returns (uint yourMom) {
    uint y = 0;
    for (uint i=0; i<5; i++) {
        y += 1;
    }
    return y;
  }
}
