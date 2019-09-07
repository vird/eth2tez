Type = require 'type'
ast = require 'ast4gen'

class Context
  current_contract  : null
  contract_list     : []
  constructor:()->
    @contract_list = []

class SContract
  name              : ''
  var_list          : []
  function_list     : []
  current_function  : null
  constructor:()->
    @var_list = []
    @function_list = []

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
      
      when 'BinaryOperation'
        ret = new ast.Bin_op
        ret.op = ast_tree.operator
        ret.a = walk_exec ast_tree.leftExpression, ctx
        ret.b = walk_exec ast_tree.rightExpression, ctx
        ret
      
      # ###################################################################################################
      #    stmt
      # ###################################################################################################
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
        ret = new ast.Ret
        ret.t = walk_exec ast_tree.expression
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
        fn = ctx.current_function = new ast.Fn_decl
        # ctx.current_contract.function_list.push ctx.current_function
        ctx.current_contract.scope.list.push ctx.current_function
        fn.name = ast_tree.name
        arg_list = walk_param ast_tree.parameters, ctx
        ret_list = walk_param ast_tree.returnParameters, ctx
        if ret_list.length > 1
          throw new Error("ret_list.length > 1")
        
        fn.type =  new Type 'function'
        fn.type.nest_list.push ret_list[0]
        fn.type.nest_list.append arg_list
        for v in arg_list
          fn.type.arg_name_list.push v._name
        # ctx.stateMutability
        if ast_tree.modifiers.length
          throw new "ast_tree.modifiers not implemented"
        # TODO standard
        
        fn.scope = walk_exec ast_tree.body, ctx
        fn
        
      when "ContractDefinition"
        ctx.contract_list.push ctx.current_contract = new ast.Class_decl
        ctx.current_contract.name = ast_tree.name
        for node in ast_tree.nodes
          walk node, ctx
      else
        p ast_tree
        throw new Error("walk unknown nodeType '#{ast_tree.nodeType}'")
    return
  
  # first pass
  ctx = new Context
  for node in root.nodes
    walk node, ctx  
  
  pp ctx.current_contract
  
  return
