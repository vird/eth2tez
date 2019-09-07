#!/bin/sh

#USAGE: compile-ligo.sh <filename> 

ligo dry-run ligo-contracts/$1 --syntax pascaligo main 0 "record
    value = 5;
end
"