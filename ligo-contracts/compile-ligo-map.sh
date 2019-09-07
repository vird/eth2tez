#!/bin/sh

#USAGE: compile-ligo.sh <filename> 

ligo dry-run $1 --syntax pascaligo main 0 "map
1n -> record
        value = 50;
    end;
    2n -> record
        value = 133;
    end;
end
"