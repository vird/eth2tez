#!/usr/bin/env iced
require 'fy'
ast_gen = require('./src/ast_gen')
translate = require('./src/translate')
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
translate res