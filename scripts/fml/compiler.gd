class_name FMLCompiler
extends RefCounted

# Implementation of FML compiler

var parser = FMLParser.new()
var tokenizer = FMLTokenizer.new()

func compile(s: String):
  var tokens := tokenizer.tokenize(s)
  return parser.parse(tokens)