#!/bin/sh

#USAGE: compile-ligo.sh <filename> 

ligo dry-run $1 --syntax pascaligo $2 0 "record
    minter = (\"tz1gSkRdKZiEyDXWArRSBLjpUaFr5ReLMy1w\": address);
    balances = ((map end) : map(address, int))
    end
"

# (\"tz1KqTpEZ7Yob7QbPE4Hy4Wo8fHG8LhKxZSx\" : address) -> 1n;