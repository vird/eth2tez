#!/usr/bin/env iced
require 'fy'
if !(file = process.argv[2])
  p "usage ./test_translate.coffee <file.sol>"
  process.exit()

ast_gen             = require('./src/ast_gen')
solidity_to_ast4gen = require('./src/solidity_to_ast4gen')
type_inference      = require('./src/type_inference')
translate           = require('./src/translate')
fs = require 'fs'
  
solidity_ast = ast_gen fs.readFileSync file, 'utf-8'
ast = solidity_to_ast4gen solidity_ast
ast = type_inference.gen ast

p translate.gen ast