type state is record
    value : int;
end
type map_state is map(nat, state);

function main (const parameter: int ; const map_state : map_state) : map_state is
  block {skip} with map_state