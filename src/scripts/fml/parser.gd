class_name FMLParser
extends RefCounted

# TODO: generalize this one day

const f = FMLTokenizer.TokenType.FUNC_NAME
const l_brac = FMLTokenizer.TokenType.LEFT_BRACKET
const r_brac = FMLTokenizer.TokenType.RIGHT_BRACKET
const s = FMLTokenizer.TokenType.STRING
const comma = FMLTokenizer.TokenType.COMMA

var parser: LALRParser
func _init():
  var grammars: Array[LALRParser.Grammar] = [
   LALRParser.Grammar.new(
     "S", ["F"],
     _create_start_node
   ),
   LALRParser.Grammar.new(
     "S", [LALRParser.EMPTY],
     func(_t): return _create_start_node(null)
   ),
   LALRParser.Grammar.new(
     "F", [f, l_brac, "A", r_brac],
     _create_func_node
   ),
   LALRParser.Grammar.new("A", [s, comma, "A"], func(t): return t[0] + t[2]),
   LALRParser.Grammar.new("A", ["F", comma, "A"], func(t): return t[0] + t[2]),
   LALRParser.Grammar.new("A", [s], func(t): return [_create_value_node(t)]),
   LALRParser.Grammar.new("A", ["F"], func(t): return [t[0]]),
   LALRParser.Grammar.new("A", [LALRParser.EMPTY], func(_t): pass ),
  ]
  parser = LALRParser.new(grammars, [f, l_brac, r_brac, s, comma])

func parse(tokens: Array[Tokenizer.Token]):
  return parser.parse(tokens)

func _create_start_node(func_node_return):
  var node = FMLNode.new(FMLNodeType.START)
  if func_node_return != null:
   # Get the first function because F returns an array in grammar
   node.value = func_node_return[0]
  return node

func _create_func_node(t: Array): # Godot does not support multiline lambda lol
  var node = FMLNode.new(FMLNodeType.FUNC_CALL)
  node.func_name = t[0]

  var arglist = t[2]
  if arglist == null:
   node.arglist = []
  else:
   node.arglist = arglist

  return node
func _create_value_node(t: Array):
  var node = FMLNode.new(FMLNodeType.VALUE)
  node.value = t[0]
  return node

enum FMLNodeType {FUNC_CALL, VALUE, START}
class FMLNode:
  var type: FMLNodeType
  var func_name: String
  var arglist: Array
  var value

  func _init(_type: FMLNodeType):
   type = _type
