class_name Stack
extends RefCounted

# Simple implementation of standard stack

var _stack: Array

func _init(initial=[]):
  _stack = initial

func push(item):
  _stack.push_back(item)

func pop():
  return _stack.pop_back()

func insert(item, from_top:=0):
  var pos = _stack.size() - from_top
  _stack.insert(pos, item)

func ordered_pop(count=1) -> Array: # Returns the pop in order
  var bound = _stack.size() - count
  var result = _stack.slice(bound)
  _stack = _stack.slice(0, bound)
  return result

func top():
  return _stack[_stack.size() - 1]

func size():
  return _stack.size()