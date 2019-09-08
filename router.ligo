#include "out.ligo"

function main (const param : int; const this : state) : state is
  block {
      this := constructor(this);
      this := mint(sender, 130, this);

      const receiver : address = ("tz1TRqDFsVpGnfBMHjiKHid84YV18xqvCL44" : address);

      this := send(receiver, 50, this);
  } with this ;
