//not working yet

type state is record
  value: int;
end;

function main (const dummy_int : int; const contractStorage : state) : (state) is
  block {
    const f : int -> int = function (const param : int) is block {
        skip
    } with 5
  } with (contractStorage);