#!/usr/bin/env iced
require 'fy'
solc = require('solc')
input = {
    language: 'Solidity',
    sources: {
        'test.sol': {
            # content: 'contract C { function f() public { } }'
            content: """
            pragma solidity ^0.5.11;
            
            contract Summator {
              uint public value;
              
              function sum() public returns (uint yourMom) {
                uint x = 5;
                return value + x;
              }
            }
            """
        }
    },
    settings: {
        
        outputSelection: {
            '*': {
                '*': [ '*' ]
                '' : ['ast']
            }
        }
    }
}
output = JSON.parse(solc.compile(JSON.stringify(input)))

pp output.sources['test.sol'].ast
# pp output