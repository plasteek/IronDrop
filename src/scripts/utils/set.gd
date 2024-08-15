class_name Set
extends RefCounted

# General purpose set object

var dict = {}

func add(item):
  if has(item):
   return
  dict[_get_key(item)] = item

func add_array(arr: Array):
  for item in arr:
   add(item)

func remove(item):
  dict.erase(_get_key(item))

func has(item) -> bool:
  return dict.has(_get_key(item))

func size() -> int:
  return dict.size()

func values() -> Array:
  return dict.values()

func _get_key(item) -> String:
  match typeof(item):
   TYPE_STRING:
     return item
   TYPE_INT:
     return str(item)
   TYPE_FLOAT:
     return str(item)
   _:
     return str(item.get_instance_id())
   
func equal(b: Set):
  if b.dict.size() != dict.size():
   return false
  for key in b.dict:
   if not key in dict:
     return false
  return true

func union(b: Set):
  add_array(b.values())

func clone():
  var new_set = Set.new()
  new_set.dict = dict.duplicate(false)
  return new_set

static func unique(arr: Array):
  var new_set = Set.new()
  new_set.add_array(arr)
  return new_set.values()

static func from_array(arr: Array):
  var new_set = Set.new()
  new_set.add_array(arr)
  return new_set
