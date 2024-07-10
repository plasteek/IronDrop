extends Node2D

@export var money_count = 0; # unit dollar
@onready var label: Label = $Label

func _ready():
  # make label update consistent
  update_label()

func set_money(amount: int):
  money_count = amount
  update_label()

func add(amount: int):
  money_count += amount
  update_label()

func double():
  money_count *= 2
  update_label()

func reset():
  money_count = 0
  update_label()

func update_label():
  label.text = "$" + str(money_count)
