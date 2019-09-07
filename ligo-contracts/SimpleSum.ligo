type store is record
  value: int ;
end

function sum (const parameter : int; const contractStorage : store) : store is
  begin
    const x : int = 5;
  end with record
    value = contractStorage.value + 3;
  end
