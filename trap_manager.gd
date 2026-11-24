extends Node
class_name TrapManager

@onready var manager = get_parent()

var player_traps_played_this_turn: int = 0
var enemy_traps_played_this_turn: int = 0

func reset_limits(is_player_turn: bool):
	if is_player_turn: player_traps_played_this_turn = 0
	else: enemy_traps_played_this_turn = 0

func can_play_trap(is_player: bool) -> bool:
	if is_player: return player_traps_played_this_turn < 1
	return enemy_traps_played_this_turn < 1

func execute_trap(trap_card: Node, target: Node, is_player: bool):
	if is_player: player_traps_played_this_turn += 1
	else: enemy_traps_played_this_turn += 1
		
	manager.log_event("⚡ SPELL ACTIVATED: " + trap_card.card_name.to_upper() + " ⚡")
	
	# --- VISUAL JUICE ---
	# Reveal the card and float it directly in the center of the screen
	trap_card.show()
	trap_card.z_index = 100
	var center_pos = trap_card.get_viewport_rect().size / 2
	
	if trap_card.has_method("move_to_anchor"):
		trap_card.move_to_anchor(center_pos)
	else:
		trap_card.global_position = center_pos
		
	if trap_card.has_method("buff_animation"): 
		trap_card.buff_animation()
		
	# --- EXECUTION ---
	if trap_card.ability_node != null:
		trap_card.ability_node.execute(trap_card, target, manager)
		
	# Dramatic pause for the spell to resolve, then send it to the shadow realm!
	await get_tree().create_timer(1.2).timeout
	trap_card.queue_free()
	
	if manager.has_node("HandManager"):
		manager.get_node("HandManager").update_player_hand()
