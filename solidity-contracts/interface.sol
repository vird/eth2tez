pragma solidity ^0.5.11;

contract ERC20Interface {
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}