#!/bin/sh
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED='/usr/local/bin/gsed'
else
    SED='/usr/bin/sed'
fi

ligo dry-run ligo-contracts/SimpleSum.ligo --syntax pascaligo sum 0 "record
    value = 5;
end
" \
| $SED "s/record//g" \
| $SED "s/\[//g" \
| $SED "s/\]//g" \
| $SED "/^[[:space:]]*$/d" \
| $SED "s/^/\"/g" \
| $SED "s/->/\":/g" \
| $SED "s/\ //g" \
| $SED "s/\r/,\r/g" \
| $SED '$ s/..$//' \
| (echo "{" && cat)

echo "}"