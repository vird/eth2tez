assert = require 'assert'
ast_gen             = require('../src/ast_gen')
solidity_to_ast4gen = require('../src/solidity_to_ast4gen')
translate           = require('../src/translate')

make_test = (text_i, text_o_expected)->
  solidity_ast = ast_gen text_i, silent:true
  ast = solidity_to_ast4gen solidity_ast
  text_o_real = translate.gen ast
  text_o_expected = text_o_expected.trim()
  text_o_real     = text_o_real.trim()
  assert.strictEqual text_o_expected, text_o_real


describe 'translate section', ()->
  it 'empty', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Summator {
      uint public value;
      
      function test() public {
        value = 1;
      }
    }
    """
    text_o = """
    type store is record
      value: int;
    end;
    function test (const contractStorage : storage) : (storage) is
      block {
        (contractStorage.value := 1);
      } with (contractStorage);
    function main (const contractStorage : storage) : (storage) is
      block {
        skip
      } with (contractStorage);
    """
    make_test text_i, text_o
  
