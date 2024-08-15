extends Node2D

@export var min_pod = 2
@export var max_pod = 5

@export var conversation_timeout = 30000
@export var money_increase = 250
@export var player_money_goal = 1000
@export var initial_money = 0
@export var personas: Array[Persona] = []

var delay: Delay
var game: StateMachine

@onready var computer = $Computer
@onready var announcer = $Announcer
@onready var selector = $PodSelector
@onready var counter = $Counter
@onready var drop_scene = $DropScene

# NPC STATE TO MANIPULATE
@onready var agent: Agent = $NPC/Agent
@onready var npc_computer_state = $NPC/NPCState/ComputerState
@onready var npc_selector_state = $NPC/NPCState/PodSelectorState
@onready var npc_money_state = $NPC/NPCState/MoneyState
@onready var audio = $AudioManager

func _ready():
  audio.play("spotlight")
  counter.set_money(initial_money)
  computer.message_sent.connect(handle_outgoing_message)
  delay = Delay.new(self)

  # Setup adversary
  agent.persona = personas.pick_random()
  print("OPPONENT: ", agent.persona.persona_name)

  const S = StateMachine.FSMState
  const T = StateMachine.FSMTransition

  game = StateMachine.new([
   S.new("intro", [
     T.new("begin_game", func(): pass , "setup")
   ]),
   S.new("setup", [
     T.new("announce_role", func(): pass , "role_announcement")
   ], game_setup),
   S.new("role_announcement", [
     T.new("conversation_timeout", func(): pass , "pod_selection")
   ], announce_role),
   S.new("pod_selection", [
     T.new("reset", func(): pass , "setup")
   ], select_pod),
  ])

  await game_intro()
  game.send_signal('begin_game') # Start game

func game_intro():
  audio.play("ambience", {"persistent": true})
  await delay.wait(2000)
  computer.send_signal("start")

  await computer.booted
  computer.send_signal("lock")

  await delay.wait(1000)
  await announcer.announce("Reach ${} to win".format([player_money_goal], "{}"))
  await announcer.announce("${} added to your balance per turn".format([money_increase], "{}"))

  await announcer.announce("You will take turn being inside a pod")
  await announcer.announce("If enemy selects your pod. Gameover.")
  await announcer.announce("If you don't have enough money. Gameover.")

  await announcer.announce("Some will try to kill you.")
  await announcer.announce("Some will try to befriend you.")
  await announcer.announce("Becareful.")

  await announcer.announce("GAME STARTS NOW.")
  agent.observe('Game Master: "There is a computer in front of you. Use that to communicate with your opponent"')
  agent.observe('Game Master: "Your computer is now connected to your opponent"')

# Gameplay Variables
enum Selector {PLAYER, AI}
var num_of_pods: int
var current_selector = null
var pod_containing_target: int

func game_setup():
  num_of_pods = randi_range(min_pod, max_pod)
  pod_containing_target = randi_range(1, num_of_pods)

  # Just assume one chose a random
  if current_selector == null:
   current_selector = Selector.AI # Default to user first

  if current_selector == Selector.PLAYER: # If player, we flip the one who decides
   current_selector = Selector.AI
  else:
   current_selector = Selector.PLAYER

  game.send_signal("announce_role")

func announce_role():
  var conv_timeout_seconds := int(conversation_timeout / 1000.0)

  if current_selector == Selector.PLAYER:
   await announcer.announce("Your turn to select a pod")
   agent.observe("Game Master: Your turn to be in a pod. You will be in pod {} from {} pods.".format([pod_containing_target, num_of_pods], "{}"), )
  else:
   await announcer.announce("Your turn to be placed in a pod".format([pod_containing_target, num_of_pods], "{}"), )
   await announcer.announce("Your pod is {} out of {}".format([pod_containing_target, num_of_pods], "{}"), )
   agent.observe("Game Master: Your turn to select pod. Find out where your opponent pod is.".format([conv_timeout_seconds], "{}"))
  
  await announcer.announce("{} seconds to interact with opponent".format([conv_timeout_seconds], "{}"))
  agent.observe("Game Master: {} seconds to interact with opponent".format([conv_timeout_seconds], "{}"))

  computer.send_signal("write_message")
  await delay.wait(conversation_timeout)

  agent.stop()
  computer.send_signal("lock")

  await announcer.announce("Time's up")
  agent.history.store("Game Master: Time is up") # Silent add

  await delay.wait(1000)

  game.send_signal("conversation_timeout")

func select_pod():
  if current_selector == Selector.AI:
   computer.audio.pause_persistent_audios()
   npc_computer_state.disable_computer();

   drop_scene.show()
   await delay.wait(2000)
   drop_scene.start()

   npc_selector_state.choose_from(num_of_pods)
   agent.observe("Game Master: 'Opponent in a pod. Please select a pod'")
   var chosen_pod = await npc_selector_state.pod_chosen

   if chosen_pod == pod_containing_target: # Player death
     await drop_scene.drop()
     Globals.change_scene("res://scenes/main_menu.tscn")

   await drop_scene.safe()
   await delay.wait(2000)

   if await check_goal():
     Globals.change_scene("res://scenes/victory.tscn")
     return

   drop_scene.hide()
   drop_scene.reset()
   audio.play("spotlight")

   agent.observe("Game Master: Opponent survived")
   npc_computer_state.enable_computer();
   computer.audio.resume_persistent_audios()
  else:
   await announcer.announce("Opponent in pod.")
   selector.select_from(num_of_pods)

   var chosen_pod = await selector.pod_chosen
   if chosen_pod == pod_containing_target:
     counter.double()

     await delay.wait(500)
     await announcer.announce("Dead")
     await delay.wait(1000)

     if counter.money_count < player_money_goal: # Player and NPC lost
      await announcer.announce("Unfortunate.")

      drop_scene.show() # Simulate drop scene
      drop_scene.start()
      await drop_scene.drop()
      Globals.change_scene("res://scenes/main_menu.tscn")

     await announcer.announce("Winner") # Player selfish win
     Globals.change_scene("res://scenes/victory.tscn")
     return

   # Game has not reached the end
   await announcer.announce("Survived")
   if await check_goal():
     Globals.change_scene("res://scenes/victory.tscn")
     return

   agent.observe("Opponent selected pod {}. Your pod was {}".format([chosen_pod, pod_containing_target], "{}"))
  game.send_signal("reset")

func check_goal() -> bool:
  counter.add(money_increase)
  npc_money_state.value += money_increase
  if counter.money_count >= player_money_goal: # Both NPC and player win
   await announcer.announce("How interesting...")
   return true
  return false

func handle_outgoing_message(msg: String):
  agent.observe("Computer displays '{}'".format([msg], "{}"))
