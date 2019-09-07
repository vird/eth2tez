config = require './config'
require 'fy/codegen'
module = @

@bin_op_name_map =
  ADD : '+'
  # SUB : '-'
  # MUL : '*'

@bin_op_name_cb_map = {}

class @Gen_context
  var_hash : {}
  expand_hash : false
  in_fn : false
  constructor:()->
    @var_hash = {}
  
  mk_nest : ()->
    t = new module.Gen_context
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

@gen = gen = (ast, opt = {}, ctx = new module.Gen_context)->
  switch ast.constructor.name
    # ###################################################################################################
    #    expr
    # ###################################################################################################
    when "Var"
      if ctx.var_hash[ast.name]
        ast.name
      else
        "{config.contractStorage}.#{ast.name}"
    
    when 'Bin_op'
      _a = gen ast.a, opt, ctx
      _b = gen ast.b, opt, ctx
      if op = module.bin_op_name_map[ast.op]
        "(#{_a} #{op} #{_b})"
      else if cb = module.bin_op_name_cb_map[ast.op]
        cb(_a, _b)
      else
        throw new Error "Unknown/unimplemented bin_op #{ast.op}"
      
    # ###################################################################################################
    #    stmt
    # ###################################################################################################
    when "Scope"
      jl = []
      for v in ast.list
        t = gen v, opt, ctx
        if t and t[t.length - 1] != ";"
          t += ";"
        jl.push t if t != ''
      
      ret = jl.pop() or ''
      if 0 != ret.indexOf 'with'
        jl.push ret
        ret = ''
      if ctx.in_fn
        """
        begin
          #{join_list jl, '  '}
        end #{ret}
        """
      else
        join_list jl, ''
    
    when "Var_decl"
      ctx.var_hash[ast.name] = ast
      if ast.assign_value
        val = gen ast.assign_value, opt, ctx
        """
        const #{ast.name} : #{translate_type ast.type} = #{val}
        """
      else
        """
        const #{ast.name} : #{translate_type ast.type}
        """
    
    when "Const"
      ast.val
    
    when "Ret_multi"
      jl = []
      for v in ast.t_list
        jl.push gen v, opt, ctx
      """
      with (#{jl.join '; '})
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
      function #{ast.name} (#{arg_jl.join '; '}) : (#{ret_jl.join '; '}) is
        #{make_tab body, '  '}
      """
    
    
    else
      if opt.next_gen?
        return opt.next_gen ast, opt, ctx
      ### !pragma coverage-skip-block ###
      perr ast
      throw new Error "unknown ast.constructor.name=#{ast.constructor.name}"
