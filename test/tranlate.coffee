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
    type state is record
      value: int;
    end;
    function test (const contractStorage : state) : (state) is
      block {
        contractStorage.value := 1;
      } with (contractStorage);
    function main (const dummy_int : int; const contractStorage : state) : (state) is
      block {
        skip
      } with (contractStorage);
    """
    make_test text_i, text_o
  
  it 'if', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Ifer {
      uint public value;
      
      function ifer() public returns (uint yourMom) {
        uint x = 5;
        uint ret = 0;
        if (x == 5) {
          ret = value + x;
        }
        else  {
          ret = 0;
        }
        return ret;
      }
    }
    """
    text_o = """
    type state is record
      value: int;
    end;
    function ifer (const contractStorage : state) : (int * state) is
      block {
        const x : int = 5;
        const ret : int = 0;
        if ((x = 5)) then block {
          ret := (contractStorage.value + x);
        } else block {
          ret := 0;
        };
      } with (ret, contractStorage);
    function main (const dummy_int : int; const contractStorage : state) : (state) is
      block {
        skip
      } with (contractStorage);
    """
    make_test text_i, text_o
  
  it 'require', ()->
    text_i = """
    pragma solidity ^0.5.11;

    contract Forer {
      uint public value;
      
      function forer() public returns (uint yourMom) {
        uint y = 0;
        require(y == 0, "wtf");
        return y;
      }
    }
    """#"
    text_o = """
    type state is record
      value: int;
    end;
    function forer (const contractStorage : state) : (int * state) is
      block {
        const y : int = 0;
        if (!(y = 0)) begin
          fail("wtf");
        end;
      } with (y, contractStorage);
    function main (const dummy_int : int; const contractStorage : state) : (state) is
      block {
        skip
      } with (contractStorage);
    """
    make_test text_i, text_o
  
