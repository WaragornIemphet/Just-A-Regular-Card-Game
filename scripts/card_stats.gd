extends Node
class_name CardStats

@onready var card = get_parent()

@export var max_health: int = 5
@export var health: int = 5
@export var attack_power: int = 2
@export var defense: int = 0

@export_range(0, 100) var crit_chance: int = 0 
@export var crit_multiplier: float = 2.0 
@export var attack_times: int = 1
@export var base_ignore_def: bool = false 
@export var splash_damage: bool = false

func take_damage(amount: int, damage_type: String = "normal", attacker: Node = null) -> bool:
	if card.debuffs != null and card.debuffs.is_disabled():
		print(card.name, " is Disabled! Attack bounced.")
		return false
		
	var incoming_damage = amount
	
	if card.debuffs != null and card.debuffs.is_frozen():
		incoming_damage *= 2
		card.visuals.show_floating_text("Shatter! x2", Color.CYAN)

	if damage_type == "normal" and card.evasion > 0 and (randi() % 100) < card.evasion:
		card.visuals.show_floating_text("Evaded!", Color.LIGHT_GRAY)
		return false 
		
	if damage_type != "burn" and card.parry_stacks > 0:
		card.parry_stacks -= 1
		card.visuals.show_floating_text("Parried!", Color.YELLOW)
		if attacker != null:
			attacker.exhaust()
			if attacker.has_method("show_floating_text"):
				attacker.show_floating_text("Stunned!", Color.GRAY)
		return false 
		
	if damage_type != "poison" and card.block_stacks > 0:
		card.block_stacks -= 1
		card.visuals.show_floating_text("Blocked!", Color.BLUE)
		return false 
	
	var main_scene = card.get_tree().current_scene
		
	
	
	if "is_tower" in card and card.is_tower:
		card.tower_hp -= 1
		card.visuals.show_floating_text("-1 THP", Color.MAGENTA)
		
		if main_scene != null:
			main_scene.log_event("🏛️ The Tower takes a hit! Remaining THP: " + str(card.tower_hp))
			
			if card.tower_hp <= 0:
				if main_scene.has_method("trigger_game_over"):
					main_scene.trigger_game_over(not card.is_player_card)
					
		return true

	card.visuals.shake_animation()
	
	if incoming_damage == 0:
		card.visuals.show_floating_text("0", Color.GRAY)
		if card.passives != null:
			card.passives.trigger_take_damage(0, damage_type, attacker)
		return true
	
	if damage_type == "poison" or damage_type == "pierce":
		card.health -= incoming_damage
		card.visuals.show_floating_text("-" + str(incoming_damage), Color.PURPLE)
		print(card.name, " took ", incoming_damage, " POISON damage directly to HP!")
		
	else:
		if card.defense > 0:
			if damage_type == "burn":
				var enhanced_burn = incoming_damage * 5
				if enhanced_burn <= card.defense:
					card.defense -= enhanced_burn
					card.visuals.show_floating_text("Melt! -" + str(enhanced_burn), Color.ORANGE)
					incoming_damage = 0
				else:
					var leftover_enhanced = enhanced_burn - card.defense
					card.defense = 0
					card.visuals.show_floating_text("Shield Melted!", Color.ORANGE)
					incoming_damage = int(ceil(leftover_enhanced / 5.0))
			else:
				if incoming_damage <= card.defense:
					card.defense -= incoming_damage
					card.visuals.show_floating_text("Absorb!", Color(0.2, 0.6, 1.0))
					incoming_damage = 0 
				else:
					var broken_amount = card.defense
					incoming_damage -= card.defense 
					card.defense = 0
					card.visuals.show_floating_text("Break! -" + str(broken_amount), Color.ORANGE)
					
		if incoming_damage > 0:
			card.health -= incoming_damage
			if damage_type == "burn":
				card.visuals.show_floating_text("-" + str(incoming_damage), Color.CORAL)
			else:
				card.visuals.show_floating_text("-" + str(incoming_damage), Color.RED)
	
	
	if card.passives != null:
		card.passives.trigger_take_damage(incoming_damage, damage_type, attacker)
			
	if card.health <= 0:
		print(card.name, " was defeated!")
		card.card_died.emit(card.current_slot, card.is_player_card) 
		card.visuals.death_animation()
		
	return true
	
func heal(amount: int):
	var total_heal = amount + card.extra_heal
	
	card.health += total_heal
	card.visuals.show_floating_text("+" + str(total_heal), Color.GREEN)
	print(card.name, " healed for ", total_heal, "! Health: ", card.health)


func buff_attack(amount: int):
	attack_power += amount
	card.visuals.buff_animation()
	card.visuals.show_floating_text("+" + str(amount) + " ATK", Color(1.0, 0.6, 0.0))

func buff_defense(amount: int):
	defense += amount
	card.visuals.buff_animation()
	card.visuals.show_floating_text("+" + str(amount) + " DEF", Color.CYAN)
