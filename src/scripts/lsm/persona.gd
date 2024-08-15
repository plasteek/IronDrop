class_name Persona
extends Node

# Class containing only the personality descriptions

@export_category("Character Profile")
@export var persona_name := "Nana"
@export_multiline var attributes := "helpful, friendly, speaks in a anglo-saxon English dialog"
@export_multiline var profile := ""
@export_multiline var guidance := ""

@export_category("Character Context")
@export_multiline var goal: String = ""
@export_multiline var knowledge: String = ""