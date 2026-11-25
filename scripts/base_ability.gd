extends Node
class_name BaseAbility

@export var ability_name: String = "Unnamed Ability"
@export var is_one_time_use: bool = false # <--- THE NEW BOX!
@export var initial_cooldown: int = 0 
@export var max_cooldown: int = 3
@export var requires_target: bool = true
@export var is_free_action: bool = false

var current_cooldown: int = 0
var has_been_used: bool = false

func _ready():
	current_cooldown = initial_cooldown

func tick_cooldown():
	if current_cooldown > 0:
		current_cooldown -= 1
