type state is record
  value: int;
end

function main (const parameter : int; const contractStorage : state) : state is
  begin
    const x : int = 5;
    const z : nat = abs(-5);
    const addr : address = ("tz1KqTpEZ7Yob7QbPE4Hy4Wo8fHG8LhKxZSx" : address);
    const str : string = "";
    // const b : bytes = 0x00;
  end with record
    value = contractStorage.value + 3;
  end