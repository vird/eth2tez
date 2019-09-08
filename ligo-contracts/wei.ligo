type state is record
  value: nat;
end;
function sum (const contractStorage : state) : (nat * state) is
  block {
    const x : nat = 5;
  } with ((contractStorage.value + x), contractStorage);
function main (const dummy_int : nat; const contractStorage : state) : (state) is
  block {
    skip
  } with (contractStorage);
