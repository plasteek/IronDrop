extends Node

# Simple file that contains a lot essential tool that needs to be run once at least

var fmli: FMLInterpreter # FML Interpreter
var current_scene = null

func _ready():
  fmli = FMLInterpreter.new()

  var root = get_tree().root
  current_scene = root.get_child(root.get_child_count() - 1)

func change_scene(path):
  # This function will usually be called from a signal callback,
  # or some other function in the current scene.
  # Deleting the current scene at this point is
  # a bad idea, because it may still be executing code.
  # This will result in a crash or unexpected behavior.

  # The solution is to defer the load to a later time, when
  # we can be sure that no code from the current scene is running:

  call_deferred("_change_scene", path)

func _change_scene(path):
  # It is now safe to remove the current scene.
  current_scene.free()

  # Load the new scene.
  var s = ResourceLoader.load(path)
  if s == null:
   push_error("Unable to load scene'{}'".format([path], "{}"))
   return

  # Instance the new scene.
  current_scene = s.instantiate()

  # Add it to the active scene, as child of root.
  get_tree().root.add_child(current_scene)

  # Optionally, to make it compatible with th
  get_tree().current_scene = current_scene
