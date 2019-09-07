config = require './config'
require 'fy/codegen'
module = @

@bin_op_name_map =
  ADD : '+'
  # SUB : '-'
  # MUL : '*'
  ASSIGN : ':='

@bin_op_name_cb_map = {}

class @Gen_context
  fn_hash     : {}
  var_hash    : {}
  expand_hash : false
  in_fn       : false
  tmp_idx     : 0
  sink_list   : []
  
  constructor:()->
    @fn_hash    = {}
    @var_hash   = {}
    @sink_list  = []
  
  mk_nest : ()->
    t = new module.Gen_context
    t.var_hash = clone @var_hash
    t.fn_hash  = @fn_hash
    t

translate_type = (type)->
  type = type.toString()
  switch type
    when 't_uint256'
      'int'
    when config.storage
      config.storage
    else
      throw new Error("unknown solidity type '#{type}'")

type2default_value = (type)->
  switch type
    when 't_uint256'
      '0'
    else
      throw new Error("unknown solidity type '#{type}'")
    

@gen = (ast, opt = {})->
  ctx = new module.Gen_context
  for v in ast.list
    if v.constructor.name == 'Fn_decl_multiret'
      ctx.fn_hash[v.name] = v
  module._gen ast, opt, ctx

@_gen = gen = (ast, opt, ctx)->
  switch ast.constructor.name
    # ###################################################################################################
    #    expr
    # ###################################################################################################
    when "Var"
      if ctx.var_hash[ast.name] or ast.name == config.contractStorage
        ast.name
      else
        "#{config.contractStorage}.#{ast.name}"
    
    when 'Bin_op'
      _a = gen ast.a, opt, ctx
      _b = gen ast.b, opt, ctx
      if op = module.bin_op_name_map[ast.op]
        "(#{_a} #{op} #{_b})"
      else if cb = module.bin_op_name_cb_map[ast.op]
        cb(_a, _b)
      else
        throw new Error "Unknown/unimplemented bin_op #{ast.op}"
      
    when "Const"
      ast.val
    
    when "Fn_call"
      fn = gen ast.fn, opt, ctx
      arg_list = []
      for v in ast.arg_list
        arg_list.push gen v, opt, ctx
      
      fn_decl = ctx.fn_hash[fn]
      if !fn_decl
        "#{fn}(#{arg_list.join ', '}"
      else
        type_jl = []
        for v in fn_decl.type_o.nest_list
          type_jl.push translate_type v
        
        arg_list.push config.contractStorage
        tmp_var = "_tmp#{ctx.tmp_idx++}"
        ctx.sink_list.push "const #{tmp_var} : (#{type_jl.join ' * '}) = #{fn}(#{arg_list.join ', '})"
        tmp_var
      
    # ###################################################################################################
    #    stmt
    # ###################################################################################################
    when "Scope"
      jl = []
      append = (t)->
        if t and t[t.length - 1] != ";"
          t += ";"
        jl.push t if t != ''
        return
      for v in ast.list
        t = gen v, opt, ctx
        for sink in ctx.sink_list
          append sink
        ctx.sink_list.clear()
        append t
        
      
      ret = jl.pop() or ''
      if 0 != ret.indexOf 'with'
        jl.push ret
        ret = ''
      if ctx.in_fn
        body = ""
        if jl.length
          body = """
          block {
            #{join_list jl, '  '}
          }
          """
        else
          body = """
          block {
            skip
          }
          """
        """
        #{body} #{ret}
        """
      else
        join_list jl, ''
    
    when "Var_decl"
      ctx.var_hash[ast.name] = true
      if ast.assign_value
        val = gen ast.assign_value, opt, ctx
        """
        const #{ast.name} : #{translate_type ast.type} = #{val}
        """
      else
        """
        const #{ast.name} : #{translate_type ast.type} = #{type2default_value ast.type}
        """
    
    when "Ret_multi"
      jl = []
      for v in ast.t_list
        jl.push gen v, opt, ctx
      """
      with (#{jl.join ', '})
      """
    
    when "Class_decl"
      jl = []
      for v in ast.scope.list
        switch v.constructor.name
          when 'Var_decl'
            jl.push "#{v.name}: #{translate_type v.type};"
          else
            throw new Error("unimplemented v.constructor.name=#{v.constructor.name}")
      """
      type #{ast.name} is record
        #{join_list jl, '  '}
      end
      """
    
    when "Fn_decl_multiret"
      ctx.var_hash[ast.name] = true
      ctx = ctx.mk_nest()
      ctx.in_fn = true
      arg_jl = []
      for v,idx in ast.arg_name_list
        type = translate_type ast.type_i.nest_list[idx]
        arg_jl.push "const #{v} : #{type}"
      
      ret_jl = []
      for v in ast.type_o.nest_list
        type = translate_type v
        ret_jl.push "#{type}"
      
      body = gen ast.scope, opt, ctx
      """
      function #{ast.name} (#{arg_jl.join '; '}) : (#{ret_jl.join ' * '}) is
        #{make_tab body, '  '}
      """
    
    
    else
      if opt.next_gen?
        return opt.next_gen ast, opt, ctx
      ### !pragma coverage-skip-block ###
      perr ast
      throw new Error "unknown ast.constructor.name=#{ast.constructor.name}"
