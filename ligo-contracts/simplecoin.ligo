type balance_type is map(address, nat);

type state is record
  minter: address;
  balances: balance_type;
end;

type MintArgs is record
    owner: address;
    reserved__amount: nat;

type Send is record
    owner: address;
    reserved__amount: nat;

type QueryBalanceArgs is record
    owner: address;

type action is
| Constructor
| Mint of (address * nat)
| Send of (address * nat)
| QueryBalance of (address)

function set_ (const balls : balance_type ; const key : address ; const amt : nat) : balance_type is block {
    balls[key] := amt;
} with balls;

function constructor (const this : state) : (state) is
  block {
    this.minter := sender;
  } with (this);

function mint (const owner : address; const reserved__amount : nat; const this : state) : (state) is
  block {
    // if (sender = this.minter) then block {

      const b : balance_type = this.balances;
      b[owner] := (get_force(owner, this.balances) + reserved__amount);
      this.balances := b;

    // skip
    // } else block {
    //   skip
    // };
  } with (this);

function send (const receiver : address; const reserved__amount : nat; const this : state) : (state) is
  block {
    if (get_force(sender, this.balances) >= reserved__amount) then block {
    //   this.balances[sender] := (get_force(sender, this.balances) - reserved__amount);
    skip
    } else block {
      skip
    };
  } with (this);

function queryBalance (const addr : address; const this : state) : (nat * state) is
  block {
    skip
  } with (get_force(addr, this.balances), this);

function main (const param : action; const this : state) : (state) is
  block {
      skip
  } with  case param of
    | Constructor -> constructor(state)
    | Mint(params) -> mint(params.owner, params.reserved__amount, state)
    | Send(params) -> send(params.receiver, params.reserved__amount, state)
    | QueryBalance(params) -> queryBalance(params.address, state)
    end;
