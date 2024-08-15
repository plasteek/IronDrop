class_name LimitedHistory
extends RefCounted

# Keeps and stores n most recent items and discard old ones

var _max_size = -1;
var _mem_queue = []

func _init(recency=6):
  _max_size = recency;

func get_entries():
  return _mem_queue

func store(item):
  _allocate_space()
  _mem_queue.append(item)

func _allocate_space():
  if _mem_queue.size() >= _max_size and _max_size > - 1:
   _trim_memory()
   # Allocate one more space
   _mem_queue.pop_front()

func _trim_memory():
  while _mem_queue.size() > _max_size and _max_size > - 1:
   _mem_queue.pop_front()
