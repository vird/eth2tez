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
        contractStorage.value := 1n;
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
      value: nat;
    end;
    
    function ifer (const contractStorage : state) : (nat * state) is
      block {
        const x : nat = 5n;
        const ret : nat = 0n;
        if (x = 5n) then block {
          ret := (contractStorage.value + x);
        } else block {
          ret := 0n;
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
      value: nat;
    end;
    
    function forer (const contractStorage : state) : (nat * state) is
      block {
        const y : nat = 0n;
        if (not (y = 0n)) then begin
          fail("wtf");
        end;
      } with (y, contractStorage);
    
    function main (const dummy_int : int; const contractStorage : state) : (state) is
      block {
        skip
      } with (contractStorage);
    """#"
    make_test text_i, text_o
  
  it 'uint ops', ()->
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
      
      function main (const dummy_int : int; const contractStorage : state) : (state) is
        block {
          skip
        } with (contractStorage);
    """
    make_test text_i, text_o
  
  it 'int ops', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      int public value;
      
      function forer() public returns (int yourMom) {
        int a = 0;
        int b = 0;
        int c = 0;
        c = -c;
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
        value: int;
      end;
      
      function forer (const contractStorage : state) : (int * state) is
        block {
          const a : int = 0;
          const b : int = 0;
          const c : int = 0;
          c := -(c);
          c := (a + b);
          c := (a - b);
          c := (a * b);
          c := (a / b);
          c := (a mod b);
          c := bitwise_and(a, b);
          c := bitwise_or(a, b);
          c := bitwise_xor(a, b);
        } with (c, contractStorage);
      
      function main (const dummy_int : int; const contractStorage : state) : (state) is
        block {
          skip
        } with (contractStorage);
    """
    make_test text_i, text_o
  it 'a[b]', ()->
    text_i = """
    pragma solidity ^0.5.11;

    contract Forer {
      mapping (address => uint) balances;
      
      function forer(address owner) public returns (uint yourMom) {
        return balances[owner];
      }
    }
    """#"
    text_o = """
    type state is record
      balances: map(address, nat);
    end;
    
    function forer (const owner : address; const contractStorage : state) : (nat * state) is
      block {
        skip
      } with ((case contractStorage.balances[owner] of | None -> 0n | Some(x) -> x end), contractStorage);
    
    function main (const dummy_int : int; const contractStorage : state) : (state) is
      block {
        skip
      } with (contractStorage);
    """
    make_test text_i, text_o
  it 'maps', ()->
    text_i = """
    pragma solidity ^0.5.11;

    contract Forer {
      mapping (address => int) balances;
      
      function forer(address owner) public returns (int yourMom) {
        balances[owner] += 1;
        return balances[owner];
      }
    }
    """#"
    text_o = """
      type state is record
        balances: map(address, int);
      end;
      
      function forer (const owner : address; const contractStorage : state) : (int * state) is
        block {
          const tmp_0 : map(address, int) = contractStorage.balances;
          tmp_0[owner] := ((case contractStorage.balances[owner] of | None -> 0 | Some(x) -> x end) + 1);
          contractStorage.balances := tmp_0;
        } with ((case contractStorage.balances[owner] of | None -> 0 | Some(x) -> x end), contractStorage);
      
      function main (const dummy_int : int; const contractStorage : state) : (state) is
        block {
          skip
        } with (contractStorage);
    """
    make_test text_i, text_o
  it 'while', ()->
    text_i = """
    pragma solidity ^0.5.11;

    contract Forer {
      mapping (address => int) balances;
      
      function forer(address owner) public returns (int yourMom) {
        int i = 0;
        while(i < 5) {
          i += 1;
        }
        return i;
      }
    }
    """#"
    text_o = """
    type state is record
      balances: map(address, int);
    end;
    
    function forer (const owner : address; const contractStorage : state) : (int * state) is
      block {
        const i : int = 0;
        while (i < 5) block {
          i := (i + 1);
        };
      } with (i, contractStorage);
    
    function main (const dummy_int : int; const contractStorage : state) : (state) is
      block {
        skip
      } with (contractStorage);
    """
    make_test text_i, text_o
  it 'for', ()->
    text_i = """
    pragma solidity ^0.5.11;

    contract Forer {
      mapping (address => int) balances;
      
      function forer(address owner) public returns (int yourMom) {
        int i = 0;
        for(i=2;i < 5;i+=10) {
          i += 1;
        }
        return i;
      }
    }
    """#"
    text_o = """
    type state is record
      balances: map(address, int);
    end;
    
    function forer (const owner : address; const contractStorage : state) : (int * state) is
      block {
        const i : int = 0;
        i := 2;
        while (i < 5) block {
          i := (i + 1);
          i := (i + 10);
        };
      } with (i, contractStorage);
    
    function main (const dummy_int : int; const contractStorage : state) : (state) is
      block {
        skip
      } with (contractStorage);
    """
    make_test text_i, text_o
  
