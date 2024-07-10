class_name Agent
extends Node

# Main agent node

signal initialized;

@export_category("Character Profile")
@export var persona: Persona = Persona.new()
@export var states: Array[State] = []

@export_category("Character Config")
@export var max_history = 7

@export_category("Language Model")
@export var llama: LlamaGD
@export var prompt_builder: PromptBuilder

@export_group("Few-shots Conditioning")
@export_file("*.json") var few_shot_file;

@export_group("Performance")
@export var batching_timeout := 150 # ms

@export_group("Debugging")
@export var verbose := false
@export var max_log_length := 100

var pending_events: Array[String] = []
var history: LimitedHistory

# Internals
var debounce: Debounce
var logger: DebugLog
var act_mutex: Mutex
var has_initialized = false;
var model_eos: String

var state_history: Array[AgentState] = []
var few_shot_prompt = ""

# For interpretation
var interpreter: EagerInterpreter
var interrupted = false
var processing_mutex: Mutex
var processing_thread: Thread
var block_next_gen = false

const MAX_INT_SIZE = 9223372036854775807
var m: StateMachine
var start_cache

func _ready():
  history = LimitedHistory.new(max_history)
  debounce = Debounce.create(self, batching_timeout)

  llama.new_token_generated.connect(_stop_generation_when_markup_end)
  llama.new_token_generated.connect(_stop_next_generation_adapter)

  _ensure_model_loaded()
  _init_few_shots_prompt();

  logger = DebugLog.new(verbose)
  act_mutex = Mutex.new()

  interpreter = EagerInterpreter.new(llama, prompt_builder, verbose)
  processing_mutex = Mutex.new()
  processing_thread = Thread.new()

  const S = StateMachine.FSMState
  const T = StateMachine.FSMTransition

  m = StateMachine.new([
   S.new("idle", [
     T.new("new_event", queue_event, "processing")
   ]),
   S.new("processing", [
     T.new("process_completed", clear_observed_events, "idle"),
     T.new("new_event", stop_processing, "interrupted"),
   ], process_events),
   S.new("interrupted", [
     T.new("new_event", queue_event),
     T.new("stop_completed", func(): pass , "processing"),
   ]),
  ])
  m.log_activity = true

# User function
func observe(event: String):
  m.send_signal("new_event", [event])
func stop():
  block_next_generation()
  interrupted = false # We don't consider this interruption
  interpreter.stop()

# State related
func queue_event(event: String):
  pending_events.append(event)

func stop_processing(new_event):
  block_next_generation()
  interrupted = true
  interpreter.stop()
  pending_events.append(new_event)

func process_events():
  processing_mutex.lock()
  interrupted = false
  unblock_next_generation()

  await _ensure_model_loaded()
  processing_thread.start(_process_events)

  await llama.generation_completed
  processing_thread.wait_to_finish()

  if interrupted:
   m.send_signal("stop_completed")
  else:
   m.send_signal("process_completed")
  processing_mutex.unlock()

func _process_events():
  var state = AgentState.capture(self)
  var prompt = prompt_builder.make(self, state)

  if start_cache == null:
   start_cache = await _get_start_prompt()
  llama.use_state(start_cache)

  logger.log("PROMPT: {}\nPROMPT_SIZE{}\n\n".format([prompt, llama.tokenize(prompt).size()], "{}"))

  # Interpret the code eagerly
  interpreter.prepare(state.function_impls)
  # Assume every action taken is also observation and not recent memories 
  interpreter.function_executed.connect(func(f): pending_events.push_back("Run function: {}".format([f], "{}")))
  llama.create_completion(prompt)
  interpreter.reset()

func clear_observed_events():
  if not interrupted:
   for event in pending_events:
     history.store(event)
   pending_events.clear()

func _get_start_prompt():
  var start_prompt = prompt_builder.embed_system_prompt(few_shot_prompt) + "\n"
  logger.log("FEW_SHOT:%s\nFEW_SHOT SIZE:%d\n" % [start_prompt, llama.tokenize(start_prompt).size()])

  var prompt_hash = (llama.model_path + start_prompt).hash()
  var cache_name = "start_prompt-{}.cache".format([prompt_hash], "{}")
  var cache_path = "./pcache/" + cache_name

  var cache: LlamaState
  if not FileAccess.file_exists(cache_path):
   logger.log("Few shots start_prompt does not exist. Creating.")
   cache = llama.create_state(start_prompt)
   LlamaStateFile.write_to_file(cache_path, cache)
  else:
   cache = LlamaStateFile.read_from_file(cache_path, llama)
  return cache

func _ensure_model_loaded():
  if not llama.is_model_loaded() and not llama.is_loading_model():
   llama.load_model()
   await llama.model_loaded
   model_eos = llama.get_model_eos()
   return
  
  if not llama.is_model_loaded() and llama.is_loading_model():
   await llama.model_loaded

func _init_few_shots_prompt():
  if few_shot_file == "" or few_shot_file == null:
   return
  
  if not FileAccess.file_exists(few_shot_file):
   push_error("Cannot find few shot file")
   return

  var file = FileAccess.open(few_shot_file, FileAccess.READ)
  var few_shot_examples = FewShotExamplesParser.parse(file.get_as_text())
  few_shot_prompt = prompt_builder.make_few_shots_prompt(few_shot_examples)

func _trim_text(s: String):
  var trim_size = MAX_INT_SIZE if max_log_length <= 0 else max_log_length
  return Util.limit_length(s, trim_size)

func _stop_generation_when_markup_end(new_token: String):
  if prompt_builder.is_stop_token(new_token):
   llama.stop_generation()
  
func block_next_generation():
  block_next_gen = true
func unblock_next_generation():
  block_next_gen = false

func _stop_next_generation_adapter(_token: String):
  if block_next_gen:
   llama.stop_generation()
