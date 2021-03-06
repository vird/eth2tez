config = require './config'
Type   = require('type')
mod_ast= require('./ast')
require 'fy/codegen'
module = @

translate_type = (type)->
  switch type.main
    when 't_bool'
      'bool'
    when 't_uint256'
      'nat'
    when 't_int256'
      'int'
    when 't_address'
      'address'
    when 't_string_memory_ptr'
      'string'
    when 't_bytes_memory_ptr'
      'bytes'
    when config.storage
      config.storage
    when 'map'
      key   = translate_type type.nest_list[0]
      value = translate_type type.nest_list[1]
      "map(#{key}, #{value})"
    else
      throw new Error("unknown solidity type '#{type}'")

type2default_value = (type)->
  switch type.toString()
    when 't_bool'
      'false'
    when 't_uint256'
      '0n'
    when 't_int256'
      '0'
    when 't_address'
      '0'
    when 't_string_memory_ptr'
      '""'
    else
      throw new Error("unknown solidity type '#{type}'")

@bin_op_name_map =
  ADD : '+'
  # SUB : '-'
  MUL : '*'
  DIV : '/'
  MOD : 'mod'
  
  
  EQ : '='
  NE : '=/='
  GT : '>'
  LT : '<'
  GTE: '>='
  LTE: '<='
  
  
  BOOL_AND: 'and'
  BOOL_OR : 'or'

@bin_op_name_cb_map =
  ASSIGN  : (a, b)-> "#{a} := #{b}"
  BIT_AND : (a, b)-> "bitwise_and(#{a}, #{b})"
  BIT_OR  : (a, b)-> "bitwise_or(#{a}, #{b})"
  BIT_XOR : (a, b)-> "bitwise_xor(#{a}, #{b})"
  
  ASS_ADD : (a, b)-> "#{a} := #{a} + #{b}"
  ASS_SUB : (a, b)-> "#{a} := #{a} - #{b}"
  ASS_MUL : (a, b)-> "#{a} := #{a} * #{b}"
  ASS_DIV : (a, b)-> "#{a} := #{a} / #{b}"
  INDEX_ACCESS : (a, b, ctx, ast)->
    ret = if ctx.lvalue
      "#{a}[#{b}]"
    else
      val = type2default_value ast.type
      "(case #{a}[#{b}] of | None -> #{val} | Some(x) -> x end)"
      # "get_force(#{b}, #{a})"
  # nat - nat edge case
  SUB : (a, b, ctx, ast)->
    if ast.a.type.main == 't_uint256' and ast.b.type.main == 't_uint256'
      "abs(#{a} - #{b})"
    else
      "(#{a} - #{b})"

@un_op_name_cb_map =
  MINUS   : (a)->"-(#{a})"
  PLUS    : (a)->"+(#{a})"
  BIT_NOT : (a)->"not (#{a})"

smart_bracket = (t)->
  if t[0] == '(' and t[t.length-1] == ')'
    t
  else
    "(#{t})"


class @Gen_context
  fn_hash     : {}
  var_hash    : {}
  expand_hash : false
  in_fn       : false
  tmp_idx     : 0
  sink_list   : []
  lvalue      : false
  trim_expr   : ''
  
  constructor:()->
    @fn_hash    = {}
    @var_hash   = {}
    @sink_list  = []
  
  mk_nest : ()->
    t = new module.Gen_context
    t.var_hash = clone @var_hash
    t.fn_hash  = @fn_hash
    t

reserved_hash =
  sender : true
  source : true
  amount : true
  now    : true

var_name_trans = (name)->
  if reserved_hash[name]
    "reserved__#{name}"
  else
    name

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
      name = var_name_trans ast.name
      if ctx.var_hash[name] or name == config.contractStorage
        name
      else
        "#{config.contractStorage}.#{name}"
    
    when 'Bin_op'
      ctx_lvalue = ctx.mk_nest()
      is_assign = 0 == ast.op.indexOf 'ASS'
      if is_assign
        ctx_lvalue.lvalue = true
      _a = gen ast.a, opt, ctx_lvalue
      _b = gen ast.b, opt, ctx
      if is_assign
        # HACK for maps
        if ast.a.constructor.name == 'Bin_op' and ast.a.op == 'INDEX_ACCESS'
          if ast.a.a.type.main == 'map'
            tmp_var = "tmp_#{ctx.tmp_idx++}"
            ctx_lvalue.var_hash[tmp_var] = true
            tmp_type = translate_type ast.a.a.type
            _proxy_a = gen ast.a.a, opt, ctx_lvalue
            ctx.sink_list.push "const #{tmp_var} : #{tmp_type} = #{_proxy_a}"
            
            craft_a = new mod_ast.Bin_op
            craft_a.op = 'INDEX_ACCESS'
            craft_a.a = tmp_a = new mod_ast.Var
            tmp_a.type = ast.a.a.type
            tmp_a.name = tmp_var
            
            craft_a.b = ast.a.b
            craft_a.type = ast.type
            _craft_a = gen craft_a, opt, ctx_lvalue
            
            ctx.sink_list.push if op = module.bin_op_name_map[ast.op]
              "(#{_craft_a} #{op} #{_b})"
            else if cb = module.bin_op_name_cb_map[ast.op]
              cb(_craft_a, _b, ctx, ast)
            else
              throw new Error "Unknown/unimplemented bin_op #{ast.op}"
            _a = _proxy_a
            _b = tmp_var
      
      ret = if op = module.bin_op_name_map[ast.op]
        "(#{_a} #{op} #{_b})"
      else if cb = module.bin_op_name_cb_map[ast.op]
        cb(_a, _b, ctx, ast)
      else
        throw new Error "Unknown/unimplemented bin_op #{ast.op}"
      
      ret
    
    when "Un_op"
      if cb = module.un_op_name_cb_map[ast.op]
        cb gen(ast.a, opt, ctx), ctx
      else
        throw new Error "Unknown/unimplemented un_op #{ast.op}"
    
    when "Const"
      switch ast.type.main
        when "t_uint256"
          "#{ast.val}n"
        when 'string'
          JSON.stringify ast.val
        else
          ast.val
    
    when "Field_access"
      t = gen ast.t, opt, ctx
      ret = "#{t}.#{ast.name}"
      # HOOK
      if ret == 'contractStorage.msg.sender'
        ret = 'sender'
      ret
    
    when "Fn_call"
      fn = gen ast.fn, opt, ctx
      arg_list = []
      for v in ast.arg_list
        arg_list.push gen v, opt, ctx
      
      # HACK  
      if fn == "#{config.contractStorage}.require"
        arg_list[0]
        failtext = arg_list[1] or ""
        return """
          if (not #{smart_bracket arg_list[0]}) then begin
            fail(#{failtext});
          end
          """
      
      fn_decl = ctx.fn_hash[fn]
      if !fn_decl
        "#{fn}(#{arg_list.join ', '}"
      else
        type_jl = []
        for v in fn_decl.type_o.nest_list
          type_jl.push translate_type v
        
        arg_list.push config.contractStorage
        tmp_var = "tmp_#{ctx.tmp_idx++}"
        ctx.sink_list.push "const #{tmp_var} : (#{type_jl.join ' * '}) = #{fn}(#{arg_list.join ', '})"
        ctx.sink_list.push "#{config.contractStorage} := #{tmp_var}.1"
        ctx.trim_expr = tmp_var
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
        if ctx.trim_expr == t
          ctx.trim_expr = ''
          continue
        append t
        
      
      ret = jl.pop() or ''
      if 0 != ret.indexOf 'with'
        jl.push ret
        ret = ''
      jl = jl.filter (t)-> t != ''
      if ctx.in_fn and !ast._phantom # HACK
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
        ret = " #{ret}" if ret
        """
        #{body}#{ret}
        """
      else
        join_list jl, ''
    
    when "Var_decl"
      name = var_name_trans ast.name
      
      ctx.var_hash[name] = true
      type = translate_type ast.type
      if ast.assign_value
        val = gen ast.assign_value, opt, ctx
        """
        const #{name} : #{type} = #{val}
        """
      else
        """
        const #{name} : #{type} = #{type2default_value ast.type}
        """
    
    when "Ret_multi"
      jl = []
      for v in ast.t_list
        jl.push gen v, opt, ctx
      """
      with (#{jl.join ', '})
      """
    
    when "If"
      cond = gen ast.cond, opt, ctx
      t    = gen ast.t, opt, ctx
      f    = gen ast.f, opt, ctx
      """
      if #{smart_bracket cond} then #{t} else #{f};
      """
    
    when "While"
      cond = gen ast.cond, opt, ctx
      scope= gen ast.scope, opt, ctx
      """
      while #{smart_bracket cond} #{scope};
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
        v = var_name_trans v
        ctx.var_hash[v] = true
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
