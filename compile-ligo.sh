#!/bin/sh

#USAGE: compile-ligo.sh <filename> 

ligo dry-run $1 --syntax pascaligo main 0 "record
    value = 5n;
end
"