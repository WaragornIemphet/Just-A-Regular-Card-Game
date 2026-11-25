extends Node
class_name PassiveManager

@onready var card = get_parent()


func trigger_turn_start():
	for passive in get_children():
		if passive is BasePassive and passive.is_active:
			passive.on_turn_start()

func trigger_turn_end():
	for passive in get_children():
		if passive is BasePassive and passive.is_active:
			passive.on_turn_end()

func trigger_take_damage(amount: int, damage_type: String, attacker: Node):
	for passive in get_children():
		if passive is BasePassive and passive.is_active:
			passive.on_take_damage(amount, damage_type, attacker)

func trigger_attack(target: Node, damage: int):
	for passive in get_children():
		if passive is BasePassive and passive.is_active:
			passive.on_attack(target, damage)

func trigger_death():
	for passive in get_children():
		if passive is BasePassive and passive.is_active:
			passive.on_death()
