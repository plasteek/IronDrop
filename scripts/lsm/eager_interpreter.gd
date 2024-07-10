class_name EagerInterpreter
extends RefCounted

# Naive implementation of eager interpreter

var prompt_builder: PromptBuilder
var current_func_defs: Array[FMLInterpreter.Function] = []
var logger: DebugLog
var llama: LlamaGD
var has_stopped = false

signal function_executed(executed_string: String)

func _init(_llama: LlamaGD, builder: PromptBuilder, enable_log=false):
  logger = DebugLog.new(enable_log)
  prompt_builder = builder

  llama = _llama
  llama.new_token_generated.connect(_interpret)

func prepare(defs: Array[FMLInterpreter.Function]):
  current_func_defs = defs
func reset():
  eager_window = ""
  current_func_defs = []
  has_stopped = false

  _detach_connected_listeners()

func cleanup():
  llama.new_token_generated.disconnect(_interpret)
  _detach_connected_listeners()

func stop():
  has_stopped = true

func _detach_connected_listeners():
  for conn in function_executed.get_connections():
   function_executed.disconnect(conn.callable)

var eager_window = ""
func _interpret(new_token: String):
  if has_stopped:
   return
  var executable = eager_window # Potentially invalid
  var is_comment = eager_window.begins_with("#")
  var finished_code_generation = new_token.contains("\n") or prompt_builder.is_stop_token(new_token)

  if finished_code_generation:
   logger.log("CODE: " + executable)
  if finished_code_generation and not is_comment:
   eager_window = ""

   logger.log("TRY RUN: " + executable)
   Globals.fmli.eval(executable, current_func_defs)
   function_executed.emit(executable)
   return

  if new_token.contains("\n"):
   eager_window = ""
   return
  eager_window += new_token
