
class @Gen_context
  expand_hash : false
  in_class : false
  mk_nest : ()->
    t = new module.Gen_context
    t

@gen = gen = (ast, opt = {}, ctx = new module.Gen_context)->
  switch ast.constructor.name
    when 'wtf'
      wtf
    else
      if opt.next_gen?
        return opt.next_gen ast, opt, ctx
      ### !pragma coverage-skip-block ###
      perr ast
      throw new Error "unknown ast.constructor.name=#{ast.constructor.name}"
