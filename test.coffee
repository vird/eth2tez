#!/usr/bin/env iced
require 'fy'
ast_gen = require('./src/ast_gen')
res = ast_gen """
  pragma solidity ^0.5.11;
  
  contract Summator {
    uint public value;
    
    function sum() public returns (uint yourMom) {
      uint x = 5;
      return value + x;
    }
  }
  """
pp res