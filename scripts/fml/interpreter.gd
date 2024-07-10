class_name FMLInterpreter
extends RefCounted

# Naive implementation of generalized FMLInterpreter

var global_lookup: Map # Map<func str, function
var compiler: FMLCompiler

const START_NODE = FMLParser.FMLNodeType.START
const FUNC_CALL_NODE = FMLParser.FMLNodeType.FUNC_CALL
const VALUE_NODE = FMLParser.FMLNodeType.VALUE
const MAX_CALL_STACK = 1000

func _init(global_methods: Array[Function]=[]):
  global_lookup = _create_func_lookup(global_methods)
  compiler = FMLCompiler.new()

# Aliases for running the actual code
func eval(s: String, func_def: Array[Function]=[]):
  var compiled = compiler.compile(s)
  if compiled == null:
   push_error("Fail to evaluate")
   return null
  return _evaluate(compiled, func_def)

# https://medium.com/@ujjawalsinhacool16021998/easily-convert-recursive-solutions-to-non-recursive-alternatives-4fa6e1acf702
enum Eval {CALL, HANDLE} # For non-recusive call
func _evaluate(node: FMLParser.FMLNode, local_funcs: Array[Function]=[]):
  var local_lookup = _create_func_lookup(local_funcs)

  # Start evaluation
  var call_stack = Stack.new([[Eval.CALL, node]]) # Stack of nodes
  var return_stack = Stack.new()

  while call_stack.size() > 0:
   var stack_item = call_stack.pop()
   var stack_mode = stack_item[0]
   var current_node = stack_item[1]

   if call_stack.size() > MAX_CALL_STACK:
     push_error("Call stack sizse exceeded")
     return null

   if stack_mode == Eval.CALL:
     match (current_node.type):
      # Recusively _evaluate first
      # NOTE: you cannot call value nodes
      START_NODE:
        # This is probably a comment line
        var call_node = current_node.value
        if call_node == null:
         return
        call_stack.push([Eval.CALL, call_node])
      FUNC_CALL_NODE:
        var arglist = current_node.arglist

        call_stack.push([Eval.HANDLE, current_node])
        for argnode in arglist:
         match (argnode.type):
           FUNC_CALL_NODE:
            # Recusively call every function first
            call_stack.push([Eval.CALL, argnode])
           VALUE_NODE:
            # HACK: Push all argument for later use 
            return_stack.push(argnode.value)
     continue
   
   if stack_mode == Eval.HANDLE:
     # Construct the argument list after the recusive call
     var arglist = current_node.arglist
     var func_name = current_node.func_name
     # Prioritize local first
     var lookup_order: Array[Map] = [local_lookup, global_lookup]

     var target_function = _lookup(func_name, lookup_order)
     if target_function == null:
      push_error("ERROR: Function definition not found: {}".format([func_name], "{}"))
      return null

     var func_impl = target_function.impl
     var target_params = target_function.params

     # Get all the arguments
     var args = [] # Finalized args
     var total_arg = arglist.size()
     for i in range(0, total_arg):
      var argvalue = return_stack.pop()
      var param = target_params[i]

      if not _value_match_param_type(argvalue, param.type):
        push_error("Value {} does not match function signature at {} with type {}".format([
         argvalue, i, param._param_type_to_readable_text()
        ], "{}"))
        return null

      args.append(argvalue)

     # With or without arguments
     var result
     if total_arg <= 0:
      result = func_impl.call()
     else:
      result = func_impl.callv(args)
     return_stack.push(result)

  return return_stack.top()

func _value_match_param_type(value, target: ParamType):
  match (target):
   ParamType.STRING:
     return typeof(value) == TYPE_STRING
  return false

func _lookup(func_name, lookups):
  return Map.look_all(func_name, lookups)

func _create_func_lookup(funcs: Array[Function]):
  var new_map = Map.new()
  for method in funcs:
   new_map.set_value(method.func_name, method)
   for alias in method.aliases:
     new_map.set_value(method.alias, method)
  return new_map

class Function:
  var func_name: String
  var aliases: Array
  var params: Array

  var impl: Callable

  # _params = Array[ParamType], aliases = []
  func _init(name: String, func_implementation: Callable, _params: Array=[], _aliases=[]):
   func_name = name
   aliases = _aliases
   params = _params
   impl = func_implementation
   
  func str():
   var param_str = params.map(func(p): return p.str())
   return "{}({})".format([func_name, ", ".join(param_str)], "{}")

enum ParamType {
  STRING
}
class Param:
  var param_name: String
  var type: ParamType

  func _init(name: String, _type: ParamType):
   param_name = name
   type = _type
  func str():
   return "{}: {}".format([param_name, _param_type_to_readable_text(type)], "{}")
  func _param_type_to_readable_text(param: ParamType):
   match (param):
     ParamType.STRING:
      return "String"
     _:
      return "String"
