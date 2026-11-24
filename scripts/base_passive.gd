extends Node
class_name BasePassive

# --- INSPECTOR VARIABLES ---
@export var passive_name: String = "Unnamed Passive"
@export var is_active: bool = true # A checkbox to easily turn it on/off in the editor

@onready var manager = get_parent()
@onready var card = manager.get_parent()

# ==========================================
# --- PASSIVE TRIGGERS (Virtual Functions) ---
# ==========================================
# These are empty by default. Your specific passive scripts will fill them in!

func on_turn_start():
	pass

func on_turn_end():
	pass

func on_take_damage(amount: int, damage_type: String, attacker: Node):
	pass

func on_attack(target: Node, damage: int):
	pass

func on_death():
	pass
