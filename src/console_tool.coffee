#!/usr/bin/env iced
### !pragma coverage-skip-block ###
require 'fy'
argv = require('minimist') process.argv.slice(2)

if !(file = argv._[0])
  p "usage eth2tez <file.sol>"
  p " -o output file (detault out.ligo)"
  process.exit()
output_file = argv.o or 'out.ligo'

if !(file = argv._[0])
  p "usage eth2tez <file.sol>"
  process.exit()

ast_gen             = require('./ast_gen')
solidity_to_ast4gen = require('./solidity_to_ast4gen')
type_inference      = require('./type_inference')
translate           = require('./translate')
fs = require 'fs'
  
solidity_ast = ast_gen fs.readFileSync file, 'utf-8'
ast = solidity_to_ast4gen solidity_ast
ast = type_inference.gen ast

res = translate.gen ast
fs.writeFileSync output_file, res