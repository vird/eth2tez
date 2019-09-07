#!/usr/bin/env iced
require 'fy'
ast_gen = require('./src/ast_gen')
solidity_to_ast4gen = require('./src/solidity_to_ast4gen')
translate = require('./src/translate')
solidity_ast = ast_gen """
  pragma solidity ^0.5.11;
  
  contract Summator {
    uint public value;
    
    function increase() public {
      value = 13;
    }
    function sum(uint a) public returns (uint yourMom) {
      uint x = 5;
      increase();
      return value + x;
    }
  }
  """
ast = solidity_to_ast4gen solidity_ast

p translate.gen ast