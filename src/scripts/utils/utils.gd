class_name Util
extends RefCounted

# Contains many utility function 

static func list_array(arr: Array, prefix=null):
  var result = ""

  for i in range(arr.size()):
   var value = str(arr[i])
   if prefix != null:
     result += "{}{}".format([prefix, value], "{}")
   else:
     result += "{}: {}".format([i, value], "{}")

   var is_last_element = i >= arr.size() - 1
   if not is_last_element:
     result += "\n"
  
  return result

static func stringify_array(arr: Array):
  return "[{}]".format([
   ", ".join(arr)
  ], "{}")

static func list_dictionary(dict: Dictionary):
  var result = ""

  var _iterated = 0
  for key in dict:
   _iterated += 1
   var value = str(dict[key])
   result += "{}: {}".format([key, value], "{}")

   var is_last_element = _iterated >= dict.size() - 1
   if not is_last_element:
     result += "\n"
  return result

static func get_func_name_from_string(s: String):
  var regex = RegEx.new()
  regex.compile("^(<func_name>\\w+)\\(.*\\)$")
  return regex.search(s).get_string("func_name")

static func limit_length(s: String, max_len:=100):
  if s.length() > max_len:
   return s.substr(0, max_len - 1) + "..."
  return s

static func empty():
  pass

static func list_states(states: Array, prefix=""):
  var list = ""
  for state_index in range(states.size()):
   var state = states[state_index]
   list += "{prefix}{key}: {value}".format({
     "prefix": prefix,
     "key": state.sname,
     "value": state.value
   })
   var is_last = state_index != states.size() - 1
   if is_last:
     list += "\n"

  return list

static func default(value, default_val=""):
  if value == "":
   return default_val
  return value

# Wraps values around
static func wrap(min_val: int, max_val: int, value: int):
  var value_range = max_val - min_val + 1

  if value < min_val: # Value smaller than range
   var offset = (value - min_val + 1) % value_range
   return max_val + offset
  if value > max_val: # Value bigger than range
   var offset = (value - max_val - 1) % value_range
   return min_val + offset

  return value
