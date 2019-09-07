
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

  if output.errors.length
    perr output.errors
    throw Error "solc compiler error"

  res = output.sources['test.sol'].ast
  if !res
    throw Error "!res"
  res
