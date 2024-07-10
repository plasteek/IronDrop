class_name Map
extends RefCounted

var dict = {}

func set_value(key, item):
  dict[str(key)] = item

func delete(key):
  dict.erase(str(key))

func get_value(key):
  var _key = str(key)
  if not has(_key):
   return null
  return dict[_key]

func has(key):
  return dict.has(str(key))

func size():
  return dict.size()

func keys():
  return dict.keys()

func values():
  return dict.values()

func get_dict():
  return dict

func clone():
  var new_map = Map.new()
  new_map.dict = dict.duplicate(false)
  return new_map

# Look at all map and search for a match
static func look_all(key, arr: Array[Map]):
  var result = null
  for map in arr:
   var query = map.get_value(key)
   if query != null:
     result = query
     break

  return result