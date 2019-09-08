assert = require 'assert'
ast_gen             = require('../src/ast_gen')
solidity_to_ast4gen = require('../src/solidity_to_ast4gen')
type_inference      = require('../src/type_inference')
translate           = require('../src/translate')

make_test = (text_i, text_o_expected)->
  solidity_ast = ast_gen text_i, silent:true
  ast = solidity_to_ast4gen solidity_ast
  ast = type_inference.gen ast
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
      value: nat;
    end;
    
    function test (const contractStorage : state) : (state) is
      block {
        contractStorage.value := 1;
      } with (contractStorage);
    
    function main (const dummy_int : nat; const contractStorage : state) : (state) is
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
      value: nat;
    end;
    
    function ifer (const contractStorage : state) : (nat * state) is
      block {
        const x : nat = 5n;
        const ret : nat = 0n;
        if (x = 5) then block {
          ret := (contractStorage.value + x);
        } else block {
          ret := 0;
        };
      } with (ret, contractStorage);
    
    function main (const dummy_int : nat; const contractStorage : state) : (state) is
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
      value: nat;
    end;
    
    function forer (const contractStorage : state) : (nat * state) is
      block {
        const y : nat = 0n;
        if (not (y = 0n)) begin
          fail("wtf");
        end;
      } with (y, contractStorage);
    
    function main (const dummy_int : nat; const contractStorage : state) : (state) is
      block {
        skip
      } with (contractStorage);
    """#"
    make_test text_i, text_o
  
  it 'int ops', ()->
    text_i = """
    pragma solidity ^0.5.11;

    contract Forer {
      uint public value;
      
      function forer() public returns (uint yourMom) {
        uint a = 0;
        uint b = 0;
        uint c = 0;
        c = a + b;
        c = a - b;
        c = a * b;
        c = a / b;
        c = a % b;
        c = a & b;
        c = a | b;
        c = a ^ b;
        return c;
      }
    }
    """#"
    text_o = """
      type state is record
        value: nat;
      end;
      
      function forer (const contractStorage : state) : (nat * state) is
        block {
          const a : nat = 0n;
          const b : nat = 0n;
          const c : nat = 0n;
          c := (a + b);
          c := (a - b);
          c := (a * b);
          c := (a / b);
          c := (a mod b);
          c := bitwise_and(a, b);
          c := bitwise_or(a, b);
          c := bitwise_xor(a, b);
        } with (c, contractStorage);
      
      function main (const dummy_int : nat; const contractStorage : state) : (state) is
        block {
          skip
        } with (contractStorage);
    """
    make_test text_i, text_o
  
