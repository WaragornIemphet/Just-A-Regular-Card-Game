extends Node
class_name ModeManager

@export var base_mode_name: String = "Base Form"
@export var alternate_modes: Array[CardModeData] = []

var current_index: int = 0
var original_stats_saved: bool = false
var mode_cooldowns: Array[int] = [] # Tracks current CD for ALL modes
var initialized: bool = false

var orig_is_melee: bool
var orig_is_ranged: bool
var orig_has_depth_charge: bool
var orig_can_attack: bool

var orig_is_ground: bool
var orig_is_air: bool
var orig_is_naval: bool
var orig_is_sub_naval: bool
var orig_is_orbital: bool
var orig_is_anti_air: bool
var orig_is_sam: bool

var orig_attack_power: int
var orig_crit_chance: int
var orig_crit_multiplier: float
var orig_attack_times: int
var orig_max_attack_cooldown: int # <--- NEW
var orig_burst_count: int
var orig_burst_delay: float

var orig_base_ignore_def: bool
var orig_splash_damage: bool
var orig_outgoing_damage_type: String
var orig_attack_vfx: String
var orig_attack_sfx: Array[AudioStream]

func _init_cooldowns(total_modes: int):
	if not initialized:
		mode_cooldowns.resize(total_modes)
		mode_cooldowns.fill(0)
		initialized = true

func cycle_mode(card: Node2D) -> int:
	if alternate_modes.size() == 0: return 1
	_init_cooldowns(alternate_modes.size() + 1)

	if not original_stats_saved:
		orig_is_melee = card.is_melee
		orig_is_ranged = card.is_ranged
		if "has_depth_charge" in card: orig_has_depth_charge = card.has_depth_charge
		if "can_attack" in card: orig_can_attack = card.can_attack
		
		orig_is_ground = card.is_ground
		orig_is_air = card.is_air
		orig_is_naval = card.is_naval
		orig_is_sub_naval = card.is_sub_naval
		orig_is_orbital = card.is_orbital
		orig_is_anti_air = card.is_anti_air
		orig_is_sam = card.is_sam
		
		orig_attack_power = card.attack_power
		orig_crit_chance = card.crit_chance
		orig_crit_multiplier = card.crit_multiplier
		
		orig_attack_times = card.attack_times
		if "max_attack_cooldown" in card: orig_max_attack_cooldown = card.max_attack_cooldown # <--- NEW
		if "burst_count" in card: orig_burst_count = card.burst_count
		if "burst_delay" in card: orig_burst_delay = card.burst_delay
		
		if "base_ignore_def" in card: orig_base_ignore_def = card.base_ignore_def
		if "splash_damage" in card: orig_splash_damage = card.splash_damage
		if "outgoing_damage_type" in card: orig_outgoing_damage_type = card.outgoing_damage_type
		
		if "attack_vfx" in card: orig_attack_vfx = card.attack_vfx
		if "attack_sfx" in card: orig_attack_sfx = card.attack_sfx
		
		original_stats_saved = true

	mode_cooldowns[current_index] = card.current_attack_cooldown

	current_index = (current_index + 1) % (alternate_modes.size() + 1)

	if current_index == 0:
		card.is_melee = orig_is_melee
		card.is_ranged = orig_is_ranged
		if "has_depth_charge" in card: card.has_depth_charge = orig_has_depth_charge
		if "can_attack" in card: card.can_attack = orig_can_attack
		
		card.is_ground = orig_is_ground
		card.is_air = orig_is_air
		card.is_naval = orig_is_naval
		card.is_sub_naval = orig_is_sub_naval
		card.is_orbital = orig_is_orbital
		card.is_anti_air = orig_is_anti_air
		card.is_sam = orig_is_sam
		
		card.attack_power = orig_attack_power
		card.crit_chance = orig_crit_chance
		card.crit_multiplier = orig_crit_multiplier
		
		card.attack_times = orig_attack_times
		if "max_attack_cooldown" in card: card.max_attack_cooldown = orig_max_attack_cooldown # <--- NEW
		if "burst_count" in card: card.burst_count = orig_burst_count
		if "burst_delay" in card: card.burst_delay = orig_burst_delay
		
		if "base_ignore_def" in card: card.base_ignore_def = orig_base_ignore_def
		if "splash_damage" in card: card.splash_damage = orig_splash_damage
		if "outgoing_damage_type" in card: card.outgoing_damage_type = orig_outgoing_damage_type
		
		if "attack_vfx" in card: card.attack_vfx = orig_attack_vfx
		if "attack_sfx" in card: card.attack_sfx = orig_attack_sfx
	else:
		var cur = alternate_modes[current_index - 1]
		
		card.is_melee = cur.is_melee
		card.is_ranged = cur.is_ranged
		if "has_depth_charge" in card: card.has_depth_charge = cur.has_depth_charge
		if "can_attack" in card: card.can_attack = cur.can_attack
		
		card.is_ground = cur.is_ground
		card.is_air = cur.is_air
		card.is_naval = cur.is_naval
		card.is_sub_naval = cur.is_sub_naval
		card.is_orbital = cur.is_orbital
		card.is_anti_air = cur.is_anti_air
		card.is_sam = cur.is_sam
		
		card.attack_power = cur.attack_power
		card.crit_chance = cur.crit_chance
		card.crit_multiplier = cur.crit_multiplier
		
		card.attack_times = cur.attack_times
		if "max_attack_cooldown" in card: card.max_attack_cooldown = cur.max_attack_cooldown # <--- NEW
		if "burst_count" in card: card.burst_count = cur.burst_count
		if "burst_delay" in card: card.burst_delay = cur.burst_delay
		
		if "base_ignore_def" in card: card.base_ignore_def = cur.base_ignore_def
		if "splash_damage" in card: card.splash_damage = cur.splash_damage
		if "outgoing_damage_type" in card: card.outgoing_damage_type = cur.outgoing_damage_type
		
		if "attack_vfx" in card: card.attack_vfx = cur.attack_vfx
		if "attack_sfx" in card: card.attack_sfx = cur.attack_sfx

	card.current_attack_cooldown = mode_cooldowns[current_index]

	return current_index + 1

func tick_hidden_cooldowns():
	if not initialized: return
	for i in range(mode_cooldowns.size()):
		if i != current_index: # The active mode is ticked by cards.gd natively
			if mode_cooldowns[i] > 0:
				mode_cooldowns[i] -= 1
				
@export_group("Advanced Mechanics")
@export var exhaust_only_after_all_modes: bool = false
var modes_attacked_this_turn: Array[int] = []

func mark_current_mode_used():
	if not current_index in modes_attacked_this_turn:
		modes_attacked_this_turn.append(current_index)

func has_used_all_modes() -> bool:
	return modes_attacked_this_turn.size() >= (alternate_modes.size() + 1)

func reset_modes_used():
	modes_attacked_this_turn.clear()
