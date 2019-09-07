require 'fy/codegen'
module = @

@bin_op_name_map =
  ADD : '+'
  # SUB : '-'
  # MUL : '*'

@bin_op_name_cb_map = {}

class @Gen_context
  expand_hash : false
  in_class : false
  mk_nest : ()->
    t = new module.Gen_context
    t

translate_type = (type)->
  type = type.toString()
  switch type
    when 't_uint256'
      'int'
    else
      throw new Error("unknown solidity type '#{type}'")

@gen = gen = (ast, opt = {}, ctx = new module.Gen_context)->
  switch ast.constructor.name
    # ###################################################################################################
    #    expr
    # ###################################################################################################
    when "Var"
      ast.name
    
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
      
      ret = jl.pop()
      if 0 != ret.indexOf 'with'
        jl.push ret
        ret = ''
      """
      begin
        #{join_list jl, '  '}
      end #{ret}
      """
    
    when "Var_decl"
      """
      const x : int = 5
      """
    
    when "Ret"
      ret = gen ast.t, opt, ctx
      """
      with (#{ret})
      """
    
    when "Class_decl"
      # Õ¿ —¿ÃŒÃ ƒ≈À≈  À¿——Œ¬ ” Õ¿— ¡€“‹ Õ≈ ƒŒÀ∆ÕŒ
      gen ast.scope, opt, ctx
    
    when "Fn_decl"
      arg_jl = []
      for v,idx in ast.arg_name_list
        type = translate_type ast.type.nest_list[idx+1]
        arg_jl.push "const #{v} : #{type};"
      
      ret_type = translate_type ast.type.nest_list[0]
      body = gen ast.scope, opt, ctx
      """
      function #{ast.name} (#{arg_jl.join ''} const contractStorage : int) : (#{ret_type}) is
        #{make_tab body, '  '}
      """
      ###
      begin
          const x : int = 5;
        end with (x + 2)
      ###
    
    
    else
      if opt.next_gen?
        return opt.next_gen ast, opt, ctx
      ### !pragma coverage-skip-block ###
      perr ast
      throw new Error "unknown ast.constructor.name=#{ast.constructor.name}"
