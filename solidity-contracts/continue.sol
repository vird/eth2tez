pragma solidity ^0.5.11;

contract Continuer {
  uint public value;
  
  function continuer() public returns (uint yourMom) {
    uint y = 0;
    while (y != 2) {
        y += 1;
        if (y==0){
            continue;
        }
    }
    return y;
  }
}