type state is record
  value: int ;

  function increase (const this : state) : state is
    begin
        this.value := 13;
    end with this;
end

function sum (const parameter : int; const this : state) : state is
  begin
    const x : nat = 0n;
    x := x + 1n;
    this := increase(this);
  end with this
