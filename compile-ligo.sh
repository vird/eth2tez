#!/bin/sh
ligo dry-run ligo-contracts/statechange.ligo --syntax pascaligo sum 0 "record
    value = 5;
end
"