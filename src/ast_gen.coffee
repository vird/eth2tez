
require 'fy'
solc = require 'solc'

module.exports = (code)->
  input = {
      language: 'Solidity',
      sources: {
          'test.sol': {
              content: code
          }
      },
      settings: {
          
          outputSelection: {
              '*': {
                  '*': [ '*' ]
                  '' : ['ast']
              }
          }
      }
  }
  output = JSON.parse(solc.compile(JSON.stringify(input)))

  is_ok = true
  for error in output.errors
    if error.type == 'Warning'
      p "WARNING", error
      continue
    is_ok = false
    perr error
  
  if !is_ok
    throw Error "solc compiler error"

  res = output.sources['test.sol'].ast
  if !res
    throw Error "!res"
  res
