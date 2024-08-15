class_name Computer
extends Node2D

signal message_sent(msg: String)
signal booted

@export var boot_timeout = 1500
@export var popupTimeout = 1000

var time: TimerCounter
var delay: Delay
var machine: StateMachine
var state_values: Map

var on_click_reply: Callable = func(): pass
var on_click_send: Callable = func(): pass

var has_received_message = false # For stringer

@onready var audio: AudioManager = $AudioManager

func _init():
  state_values = Map.new()

func _ready():
  delay = Delay.new(self)
  time = TimerCounter.new()

  const S = StateMachine.FSMState
  const T = StateMachine.FSMTransition
  machine = StateMachine.new([
   S.new("off", [
     T.new("start", func(): pass , "boot"),
   ], turn_off),

   S.new("boot", [
     T.new("write_message", func(): pass , "write_message"),
     T.new("lock", func(): pass , "locked"),
   ], boot_computer),

   S.new("locked", [
     T.new("write_message", func(): pass , "write_message"),
     T.new("wait_message", func(): pass , "wait_message"),
     T.new("new_message", view_message, "view_message"),
   ], lock_computer),

   S.new("wait_message", [
     T.new("new_message", view_message, "view_message"),
     T.new("lock", func(): pass , "locked"),
   ], wait_new_message),

   S.new("write_message", [
     T.new("new_message", view_message, "view_message"),
     T.new("view_message", view_message, "view_message"),
     T.new('wait_reply', func(): pass , "wait_message"),
     T.new("lock", func(): pass , "locked"),
   ], write_message),

   S.new("view_message", [
     T.new("new_message", view_message, "view_message"),
     T.new("write_message", func(): pass , "write_message"),
     T.new("lock", func(): pass , "locked"),
   ]),
  ])

func send_signal(s: String, params=[]):
  machine.send_signal(s, params)

# Internal state machine functions
func turn_off(): # Off
  _hide_screens()
  $PostProcessing/Scanline.hide()

func lock_computer():
  on_click_reply = func(): pass
  on_click_send = func(): pass
  audio.play("ding")
  $LockScreen.show()

func boot_computer(): # Boot
  _hide_screens()

  audio.play("boot")
  var track_len = audio.get_track_length_ms("boot")
  time.start("boot")
  
  await delay.wait(1000)
  $PostProcessing/Scanline.show()
  await delay.wait(2000)
  $BootScreen.show()

  var elapsed = time.stop("boot")
  var leftover = track_len - elapsed
  # Start early to prevent an empty period
  await delay.wait(leftover - 10)

  audio.play("static", {"persistent": true})

  await delay.wait(boot_timeout)
  booted.emit()

func write_message():
  _hide_screens()
  on_click_reply = func(): show_error("Already replying")
  on_click_send = func(): send_message()

  $InputScreen/UserInput.text = ""
  $InputScreen/UserInput.grab_focus()
  $InputScreen.show()
func send_message():
  var user_msg = $InputScreen/UserInput.text
  if user_msg == "":
   show_error("No Message")
   return

  await show_success("Message sent")
  message_sent.emit(user_msg)

  machine.send_signal("wait_reply")

func view_message(msg: String):
  _hide_screens()
  audio.play("chime")
  on_click_reply = func(): send_signal("write_message")
  on_click_send = func(): show_error("Invalid Action")
  $MessageScreen/Msg.text = msg
  $MessageScreen.show()

  if not has_received_message: # Add string
   has_received_message = true
   await delay.wait(300)
   audio.play('stinger')

func wait_new_message():
  _hide_screens()
  on_click_reply = func(): show_error("Waiting Reply")
  on_click_send = func(): show_error("Invalid Action")
  $WaitScreen.show()

func show_success(msg: String):
  audio.play("success")
  $Success/Label.text = msg
  $Success.show()
  await delay.wait(popupTimeout)
  $Success.hide()

func show_error(msg: String):
  audio.play("error")
  $Fail/Label.text = msg
  $Fail.show()
  await delay.wait(popupTimeout)
  $Fail.hide()

func _hide_screens():
  $LockScreen.hide()
  $BootScreen.hide()
  $WaitScreen.hide()
  $MessageScreen.hide()
  $InputScreen.hide()
  $Success.hide()
  $Fail.hide()

func _on_reply_btn_button_clicked():
  if on_click_reply != null:
   on_click_reply.call()

func _on_send_btn_button_clicked():
  if on_click_send != null:
   on_click_send.call()
