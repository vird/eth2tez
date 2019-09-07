pragma solidity ^0.5.11;

contract Coin {
    address minter;
    mapping (address => uint) balances;

    constructor() public {
        minter = msg.sender;
    }
    function mint(address owner, uint amount) public {
        if (msg.sender == minter) {
            balances[owner] += amount;
        }
    }
    function send(address receiver, uint amount) public {
        if (balances[msg.sender] >= amount) {
            balances[msg.sender] -= amount;
            balances[receiver] += amount;
        }
    }
    function queryBalance(address addr) public view returns (uint balance) {
        return balances[addr];
    }
}