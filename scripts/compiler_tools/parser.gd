class_name LALRParser
extends RefCounted

# Class for implementing a LALR parser

# {Map<token, ParseAction>}
var parse_table := {}
var lookup: GrammarLookup

var start_grammar: Grammar
var aug_grammar: Grammar # Grammar augmented for parsing

var state_graph: StateGraph
var current_state_id := 0

var _grammars: Array[Grammar]
var _terminals: Set

var logger: DebugLog

const EMPTY = "$empty" # epsilon
const END = "$eof" # end of parsing

func _init(grammars: Array[Grammar], terminals: Array):
  logger = DebugLog.new(false)

  _grammars = grammars
  start_grammar = _grammars[0]
  if _grammars.size() < 1:
   push_error("empty _grammars")
   return

  _terminals = Set.new()
  _terminals.add_array(terminals)
  lookup = GrammarLookup.new(_grammars)
  state_graph = StateGraph.new()

  # Augment the grammar first
  var aug_sym := str(start_grammar.symbol) + "`"
  aug_grammar = Grammar.new(aug_sym, [start_grammar.symbol], func(): pass )
  aug_grammar.lookahead.add(END)

  # Construct DFA
  var start := AutomataState.new(current_state_id)
  start.grammars.add(aug_grammar)
  current_state_id += 1
  _make_dfa(start)

  # print(state_graph.get_graph())
  # state_graph.print()

  # Construct parsing table
  _make_parsing_table()

func _make_parsing_table():
  var graph = state_graph.get_graph()

  # Augmented grammar that is "completed parsing"
  var complete_aug = aug_grammar.clone()
  complete_aug.ptr = complete_aug.rule.size() - 1 # the end
  var complete_aug_hash = complete_aug.hash()

  for id in graph:
   var node = graph[id]
   var parse_map = Map.new() # Map<token, ParseAction>
   var transitions = node.transitions

   for token in transitions:
     if typeof(token) == typeof(EMPTY) and token == EMPTY: # Ignore epsilon tokens in the transition
      continue
     
     var target = transitions[token]
     if _terminals.has(token):
      parse_map.set_value(token, ParseAction.new(ParseActionType.SHIFT, target))
     else:
      parse_map.set_value(token, ParseAction.new(ParseActionType.GOTO, target))
  
   for grammar in node.grammars.values():
     # If grammar is empty, that means there MUST be a transition
     # to the epsilon state (which we ignore it the previous phase)
     # but in this case we want THIS state to immediately reduce it
     if _is_grammar_empty(grammar):
      var empty_grammar_id = lookup.get_grammar_id(grammar)
      for lookahead in grammar.lookahead.values():
        parse_map.set_value(lookahead, ParseAction.new(ParseActionType.REDUCE, empty_grammar_id))

     if not grammar.has_parsed():
      continue
     var g_hash = grammar.hash()

     # If the augmented grammar has reached end then we accept parsing result
     if complete_aug_hash == g_hash:
      parse_map.set_value(END, ParseAction.new(ParseActionType.ACCEPT, -1))
      continue
     
     var grammar_id = lookup.get_grammar_id(grammar)
     if grammar_id != null:
      for lookahead in grammar.lookahead.values():
        parse_map.set_value(lookahead, ParseAction.new(ParseActionType.REDUCE, grammar_id))

   parse_table[id] = parse_map

func _is_grammar_empty(g: Grammar):
  var rule = g.rule
  if rule.size() > 1:
   return false
  var token = rule[0]
  return typeof(token) == typeof(LALRParser.EMPTY) and token == LALRParser.EMPTY

func _make_dfa(start: AutomataState):
  # Get the state with all the current grammar
  # Append all additional production rules

  for grammar in start.grammars.values():
   # If the current token is empty, that means this function has parsed
   if grammar.current_token() == null:
     continue
   # Terminal does not have any other rule to append to
   if _terminals.has(grammar.current_token()):
     continue
   # Non-terminal
   var matched := _lookup_grammars(grammar.current_token())
   for g in matched.values():
     g.lookahead = grammar.lookahead_tokens()
     start.grammars.add(g)

  # Add node only when the augmentation is complete
  state_graph.add(start)

  # Collect all possible transitions
  var transitions := _group_grammar_by_current_token(start.grammars)

  # For each group, treat them like a new state
  for token in transitions:
   # Do not create state with only the epsilon grammar
   if typeof(token) == typeof(EMPTY) and token == EMPTY:
     continue

   var grammars = transitions[token]
   var state_grammars = grammars.filter(func(g): return not g.has_parsed())
   var state_grammar_set = GrammarSet.from_array(state_grammars)

   # Because the current token is 'consumed' 
   state_grammar_set.increment_grammar_pointers()

   # Check for nodes with similar grammar
   var similar_node = state_graph.find_node_with_grammar_set(state_grammar_set)
   if similar_node != null and similar_node.id != start.id:
     # Merge _grammars
     similar_node.grammars.union(state_grammar_set)
     start.transitions[token] = similar_node.id
     continue

   # If not available then add it
   var new_state = AutomataState.new(current_state_id)
   current_state_id += 1
   new_state.grammars = state_grammar_set
   
   # For each new state, recusively build them
   start.transitions[token] = new_state.id
   _make_dfa(new_state)

# Return Dictionary<src_token, grouped_grammars>
func _group_grammar_by_current_token(grammars: GrammarSet) -> Dictionary:
  var groups := {}
  for grammar in grammars.values():
   var curr_token = grammar.current_token()
   if curr_token == null:
     continue
   if not curr_token in groups:
     groups[curr_token] = []
   groups[curr_token].append(grammar)
  return groups

func _lookup_grammars(token) -> GrammarSet: # Array[Grammar]
  if _terminals.has(token):
   return GrammarSet.new()

  # Non-_terminals 
  var result = GrammarSet.new()
  var grammars = lookup.query(token)
  for grammar in grammars:
   # Skip same token
   var curr_token = grammar.current_token()
   if (typeof(curr_token) == typeof(token)) and curr_token == token:
     continue

   var new_grammar = grammar.clone()
   result.add(new_grammar)

   # Recursive decent
   var additional := _lookup_grammars(curr_token)
   for g_additional in additional.values():
     # Basically add the lookaheads ontop of previous lookahead
     var cloned = g_additional.clone()
     cloned.lookahead.union(new_grammar.lookahead_tokens())
     result.add(cloned)
  return result

func print_parse_table():
  for state in parse_table:
   print("NODE({})".format([state], "{}"))
   var transitions = parse_table[state]
   for token in transitions.keys():
     var action = transitions.get_value(token)
     var code_name = ""
     match (action.type):
      ParseActionType.SHIFT:
        code_name = "SHIFT"
      ParseActionType.REDUCE:
        code_name = "REDUCE"
      ParseActionType.GOTO:
        code_name = "GOTO"
      ParseActionType.ACCEPT:
        code_name = "ACCEPT"
     print("TRANSITION({}, {}({}))".format([token, code_name, action.target], "{}"))

class StateGraph:
  # Map<grammar_hash, node>
  var _node_map = Map.new()

  func add(node: AutomataState):
   var grammars := node.grammars
   var _hash = grammars.hash()

   # If node with similar grammar exists
   # Just merge the lookaheads
   if _node_map.has(_hash):
     var target_node = _node_map.get_value(_hash)
     for grammar in node.grammars.values():
      target_node.grammars.add(grammar)
     return

   # Add and cache
   _node_map.set_value(_hash, node)
  
  func print():
   for node in _node_map.values():
     print("NODE({}) ".format([node.id], "{}"), node.transitions)
     for grammar in node.grammars.values():
      print("GRAMMAR: ", grammar.str(), " ptr: ", grammar.ptr, " lookahead: ", grammar.lookahead.values())

  func find_node_with_grammar_set(gs: GrammarSet):
   return _node_map.get_value(gs.hash())
  func get_graph():
   var graph := {}
   for node in _node_map.values():
     graph[node.id] = node
   return graph

class Grammar:
  var symbol
  var rule: Array
  var callback: Callable

  var lookahead: Set
  var ptr: int = -1

  func _init(_symbol, _rule, action):
   rule = _rule
   symbol = _symbol
   callback = action
   lookahead = Set.new()
  func has_parsed():
   if ptr + 1 >= rule.size():
     return true
   return false

  func current_token():
   # When ptr is on last element we are done
   if ptr > (rule.size() - 1) - 1:
     return null
   return rule[ptr + 1]
  func lookahead_tokens() -> Set:
   # Lookahead can only be done if there are 2 elements after pointer
   # (the current and the lookahead)
   if ptr > (rule.size() - 1) - 2:
     return lookahead.clone()
   return Set.from_array([rule[ptr + 2]])

  func str():
   var tokens = "".join(rule)
   return symbol + "->" + tokens.insert(ptr + 1, "*")
  func hash():
   return "{}->{}@({})".format([symbol, "".join(rule), str(ptr)], "{}")
  func raw_hash():
   return "{}->{}".format([symbol, "".join(rule)], "{}")

  func clone() -> Grammar:
   var new_grammar = Grammar.new(symbol, rule, callback)
   new_grammar.ptr = ptr
   new_grammar.lookahead = lookahead
   return new_grammar

class AutomataState:
  var id: int
  var grammars: GrammarSet
  # Dict<"Symbol", "action"> (refer to start of file)
  var transitions: Dictionary

  func _init(_id: int):
   self.id = _id
   transitions = {}
   grammars = GrammarSet.new()
class GrammarLookup:
  var _map: Map
  var _id_map: Map
  var _grammars: Array[Grammar]

  func _init(grammars: Array[Grammar]):
   _id_map = Map.new()
   _grammars = grammars
   _map = Map.new() # Map<symbol_name, _grammars[]>

   for grammar in grammars:
     add(grammar)

  func add(grammar: Grammar):
   if not _map.has(grammar.symbol):
     _map.set_value(grammar.symbol, [])
   var arr = _map.get_value(grammar.symbol)
   if not _map.has(grammar.symbol):
     _map.set_value(grammar.symbol, [])
   arr.append(grammar)
   _map.set_value(grammar.symbol, arr)

   var g_hash = grammar.raw_hash()
   _id_map.set_value(g_hash, _id_map.size())
   
  func get_grammar_by_id(id: int):
   if id < 0 or id >= _grammars.size():
     return null
   return _grammars[id]
  func get_grammar_id(g: Grammar):
   return _id_map.get_value(g.raw_hash())

  func query(symbol) -> Array:
   var val = _map.get_value(symbol)
   if val == null:
     return []
   return val
class GrammarSet:
  var _grammars: Map # Map<grammar_hash, grammar>

  func _init():
   _grammars = Map.new()

  func add(g: Grammar) -> void:
   var _hash = g.hash()
   # If grammar exist we just merge the lookaheads
   if _grammars.has(_hash):
     var stored = _grammars.get_value(_hash)
     stored.lookahead.union(g.lookahead)
     return
   _grammars.set_value(_hash, g)
  func union(gs: GrammarSet):
   var target_grammar = gs._grammars
   # Merge all matching grammar lookaheads
   for g_hash in target_grammar.keys():
     var grammar = target_grammar.get_value(g_hash)
     # Sometimes it does not exist 
     if not _grammars.has(g_hash):
      add(grammar)
      continue
     # But if it does merge the lookaheads
     var stored = _grammars.get_value(g_hash)
     stored.lookahead.union(grammar.lookahead)
  func equal(b: GrammarSet):
   return self.hash() == b.hash()

  func values() -> Array:
   return _grammars.values()

  func hash() -> String:
   var _hash = []
   for g in _grammars.values():
     _hash.append(g.hash())
   # TODO: this is not efficient
   _hash.sort()
   return "".join(_hash)
  func clone():
   var new_set = GrammarSet.new()
   for g_hash in _grammars.keys():
     var grammar = _grammars[g_hash]
     new_set._grammar.set_value(g_hash, grammar.clone())

  func increment_grammar_pointers():
   for grammar in _grammars.values():
     grammar.ptr += 1

  static func from_array(arr: Array) -> GrammarSet:
   var new_set = GrammarSet.new()
   for grammar in arr:
     new_set.add(grammar.clone())
   return new_set

enum ParseActionType {SHIFT, REDUCE, GOTO, ACCEPT}
class ParseAction:
  var type: ParseActionType
  var target: int
  func _init(_type: ParseActionType, _target: int):
   type = _type
   target = _target

func parse(tokens: Array): # Array<Token>
  tokens.push_back(Tokenizer.Token.new(END, END)) # Push back EOF or something
  var state_stack = Stack.new([0])
  var symbols = Stack.new()

  var ptr = 0
  while ptr <= tokens.size():
   var token = tokens[ptr]

   # LOOKUP ACTION
   var current_state = state_stack.top()
   var actions = parse_table[current_state]
   var action = actions.get_value(token.type) # Get action for token

   logger.log(str(state_stack._stack) + " " + str(symbols._stack) + " " + token.text + " ")
   if action != null:
     logger.log(str(action.type) + " " + str(action.target))

   if action == null:
     push_error("Unexpected token: {}".format([token.text], "{}"))
     return null
   
   match (action.type):
     ParseActionType.SHIFT:
      symbols.push(token.text)
      state_stack.push(action.target) # Push next state
     ParseActionType.REDUCE:
      var grammar = lookup.get_grammar_by_id(action.target)
      var grammar_size = grammar.rule.size()
      var is_empty = _is_grammar_empty(grammar)

      # If handling epsilon, do not pop anything
      if is_empty:
        grammar_size = 0

      logger.log("REDUCE " + str(grammar_size) + " token to " + str(grammar.symbol))

      # Replace the symbol to the higher order symbol
      # (Also update the state accordingly)
      var popout = symbols.ordered_pop(grammar_size)
      state_stack.ordered_pop(grammar_size)

      # Let user handle the callback and push the result back
      var result = grammar.callback.call(popout)
      symbols.push(result)

      # Push the goto state of the current
      var new_state = state_stack.top()
      var new_actions = parse_table[new_state]
      var goto_action = new_actions.get_value(grammar.symbol)
      state_stack.push(goto_action.target)

      logger.log("AFTER REDUCE:")
      logger.log(str(popout) + " " + str(state_stack._stack) + " " + str(symbols._stack))
      # Do not continue to the next token yet
      continue

     ParseActionType.GOTO:
      state_stack.push(action.target) # Push next state only
     ParseActionType.ACCEPT: # Completed
      return symbols.top()
   # Next token~!
   ptr += 1

  push_error("Expected more token after: ", symbols.top())
  return null
