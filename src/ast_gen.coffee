
module.exports = (code)->
  solc = require('solc')
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

  res = output.sources['test.sol'].ast
  if !res
    throw Error "!res"
  res
