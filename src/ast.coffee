ast = require 'ast4gen'
for k,v of ast
  @[k] = v

class @Fn_decl_multiret
  is_closure : false
  name    : ''
  type_i  : null
  type_o  : null
  arg_name_list  : []
  scope   : null
  line    : 0
  pos     : 0
  constructor:()->
    @arg_name_list = []

class @Ret_multi
  t_list : []
  
  constructor:()->
    @t_list = []

