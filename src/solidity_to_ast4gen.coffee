config = require './config'
Type = require 'type'
ast = require './ast'

bin_op_map =
  '+' : 'ADD'

class Context
  current_contract  : null
  contract_list     : []
  constructor:()->
    @contract_list = []

module.exports = (root)->
  
  walk_param = (ast_tree, ctx)->
    switch ast_tree.nodeType
      when 'ParameterList'
        ret = []
        for v in ast_tree.parameters
          ret.append walk_param v, ctx
        ret
      when 'VariableDeclaration'
        if ast_tree.value
          throw new Error("ast_tree.value not implemented")
        ret = []
        t = new Type ast_tree.typeDescriptions.typeIdentifier
        # HACK INJECT
        t._name = ast_tree.name
        ret.push t
        ret
      else
        p ast_tree
        throw new Error("walk_param unknown nodeType '#{ast_tree.nodeType}'")
    
  
  walk_exec = (ast_tree, ctx)->
    switch ast_tree.nodeType
      # ###################################################################################################
      #    expr
      # ###################################################################################################
      when 'Identifier'
        ret = new ast.Var
        ret.name = ast_tree.name
        ret.type = new Type ast_tree.typeDescriptions.typeIdentifier
        ret
      
      when 'Literal'
        ret = new ast.Const
        ret.type  = new Type ast_tree.kind
        ret.val   = ast_tree.value
        ret
      
      when 'Assignment'
        ret = new ast.Bin_op
        ret.op = 'ASSIGN'
        if !ret.op
          throw new Error("unknown bin_op #{ast_tree.operator}")
        ret.a = walk_exec ast_tree.leftHandSide, ctx
        ret.b = walk_exec ast_tree.rightHandSide, ctx
        ret
      
      when 'BinaryOperation'
        ret = new ast.Bin_op
        ret.op = bin_op_map[ast_tree.operator]
        if !ret.op
          throw new Error("unknown bin_op #{ast_tree.operator}")
        ret.a = walk_exec ast_tree.leftExpression, ctx
        ret.b = walk_exec ast_tree.rightExpression, ctx
        ret
      
      when 'FunctionCall'
        ret = new ast.Fn_call
        ret.fn = new ast.Var
        ret.fn.name = ast_tree.expression.name
        
        for v in ast_tree.arguments
          ret.arg_list.push walk_exec v, ctx
        ret
      
      # ###################################################################################################
      #    stmt
      # ###################################################################################################
      when 'ExpressionStatement'
        walk_exec ast_tree.expression, ctx
      
      when 'VariableDeclarationStatement'
        if ast_tree.declarations.length != 1
          throw new Error("ast_tree.declarations.length != 1")
        decl = ast_tree.declarations[0]
        if decl.value
          throw new Error("decl.value not implemented")
        
        ret = new ast.Var_decl
        ret.name = decl.name
        ret.type = new Type decl.typeDescriptions.typeIdentifier
        ret.assign_value = walk_exec ast_tree.initialValue, ctx
        ret
      
      when "Block"
        ret = new ast.Scope
        for node in ast_tree.statements
          ret.list.push walk_exec node, ctx
        ret
      
      # ###################################################################################################
      #    control flow
      # ###################################################################################################
      when 'Return'
        ret = new ast.Ret_multi
        ret.t_list.push walk_exec ast_tree.expression
        ret
      
      else
        p ast_tree
        throw new Error("walk_exec unknown nodeType '#{ast_tree.nodeType}'")
    
  
  walk = (ast_tree, ctx)->
    switch ast_tree.nodeType
      when "PragmaDirective"
        name = ast_tree.literals[0]
        if name == 'solidity'
          return
        throw new Error("unknown pragma '#{name}'")
      when "VariableDeclaration"
        if ast_tree.value
          throw new Error("ast_tree.value not implemented")
        # ctx.current_contract.var_list.push 
        ret = new ast.Var_decl
        ret.name = ast_tree.name
        ret.type = new Type ast_tree.typeDescriptions.typeIdentifier
        # ast_tree.typeName
        # storage : ast_tree.storageLocation
        # state   : ast_tree.stateVariable
        # visibility   : ast_tree.visibility
        ret
        
      when "FunctionDefinition"
        # fn = ctx.current_function = new SFunction
        fn = ctx.current_function = new ast.Fn_decl_multiret
        # ctx.current_contract.function_list.push ctx.current_function
        # ctx.current_contract.scope.list.push ctx.current_function
        fn.name = ast_tree.name
        
        fn.type_i =  new Type 'function'
        fn.type_o =  new Type 'function'
        
        fn.type_i.nest_list = walk_param ast_tree.parameters, ctx
        fn.type_o.nest_list = walk_param ast_tree.returnParameters, ctx
        
        for v in fn.type_i.nest_list
          fn.arg_name_list.push v._name
        # ctx.stateMutability
        if ast_tree.modifiers.length
          throw new "ast_tree.modifiers not implemented"
        
        fn.scope = walk_exec ast_tree.body, ctx
        fn
        
      when "ContractDefinition"
        ctx.contract_list.push ctx.current_contract = new ast.Class_decl
        ctx.current_contract.name = ast_tree.name
        for node in ast_tree.nodes
          ctx.current_contract.scope.list.push walk node, ctx
        null
      else
        p ast_tree
        throw new Error("walk unknown nodeType '#{ast_tree.nodeType}'")
    
  
  # first pass
  ctx = new Context
  for node in root.nodes
    walk node, ctx  
  
  # stub. Select first function
  storage_decl = new ast.Class_decl
  storage_decl.name = 'store'
  fn_list = []
  
  for contract in ctx.contract_list
    for node in contract.scope.list
      switch node.constructor.name
        when 'Var_decl'
          storage_decl.scope.list.push node
        when 'Fn_decl_multiret'
          # TODO add this function as type to storage
          
          fn_list.push node
          node.arg_name_list.push config.contractStorage
          node.type_i.nest_list.push new Type config.storage
          node.type_o.nest_list.push new Type config.storage
          
          last = node.scope.list.last()
          t = new ast.Var
          t.name = config.contractStorage
          if last.constructor.name == 'Ret_multi'
            last.t_list.push t
          else
            node.scope.list.push last = new ast.Ret_multi
            last.t_list.push t
        else
          throw new Error("bad type node.constructor.name=#{node.constructor.name}")
  ret = new ast.Scope
  ret.list.push storage_decl
  ret.list.append fn_list
  
  main_fn = new ast.Fn_decl_multiret
  main_fn.name = 'main'
  main_fn.arg_name_list.push config.contractStorage
  main_fn.type_i = new Type "function<#{config.storage}>"
  main_fn.type_o = new Type "function<#{config.storage}>"
  main_fn.scope  = new ast.Scope
  
  # TODO
  main_fn.scope.list.push tmp = new ast.Ret_multi
  tmp.t_list.push t = new ast.Var
  t.name = config.contractStorage
  
  ret.list.push main_fn
  
  ret
