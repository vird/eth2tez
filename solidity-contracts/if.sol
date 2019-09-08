pragma solidity ^0.5.11;

contract Ifer {
  uint public value;
  
  function ifer() public returns (uint) {
    uint x = 6;

    if (x == 5) {
        x += 1;
    }
    else {
        x -= 1;
    }

    return x;
  }
}
