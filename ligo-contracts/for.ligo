type state is record
  value: int;
end;

function increase (const contractStorage : state) : (state) is
  block {
    contractStorage.value := 13;
  } with (contractStorage);

function main (const dummy_int : int; const contractStorage : state) : (state) is
  block {
    skip
  } with (contractStorage);