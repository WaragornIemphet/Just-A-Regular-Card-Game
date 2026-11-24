extends Node
class_name DebuffManager

@onready var card = get_parent()

# --- DEBUFF MEMORIES ---
var taunt_duration: int = 0
var taunted_by: Node = null

var poison_duration: int = 0  
var poison_damage: int = 0    

var burn_duration: int = 0    
var burn_damage: int = 0      

var curse_duration: int = 0   
var curse_potency: int = 0    

var corrosion_stacks: int = 0 

# --- CROWD CONTROL TIMERS ---
var stun_duration: int = 0
var freeze_duration: int = 0
var disabled_duration: int = 0

# --- NEW UNIQUE STATUSES ---
var wet_duration: int = 0
var bleed_stacks: int = 0
var bleed_duration: int = 0
var confusion_duration: int = 0
var blind_duration: int = 0
var slow_duration: int = 0

# --- VISUAL UI ---
var status_label: Label

func _ready():
	status_label = Label.new()
	status_label.position = Vector2(-100, -150) 
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size = Vector2(200, 50)
	
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 12) 
	status_label.add_theme_font_size_override("font_size", 72) 
	
	# Uses the deferred call so it doesn't crash on boot!
	card.call_deferred("add_child", status_label)
	update_status_ui()

# ==========================================
# --- REFRESHING THE VISUALS ---
# ==========================================
func update_status_ui():
	if status_label == null: return
	
	var ui_text = ""
	# Elements
	if taunt_duration > 0: ui_text += "💢" + str(taunt_duration) + " "
	if burn_duration > 0: ui_text += "🔥" + str(burn_duration) + " "
	if poison_duration > 0: ui_text += "☠️" + str(poison_duration) + " "
	if curse_duration > 0: ui_text += "👁️" + str(curse_duration) + " "
	if corrosion_stacks > 0: ui_text += "🧪" + str(corrosion_stacks) + " "
	
	# Crowd Control
	if stun_duration > 0: ui_text += "💫" + str(stun_duration) + " "
	if freeze_duration > 0: ui_text += "❄️" + str(freeze_duration) + " "
	if disabled_duration > 0: ui_text += "🚫" + str(disabled_duration) + " "
	
	# New Statuses
	if wet_duration > 0: ui_text += "💦" + str(wet_duration) + " "
	if bleed_stacks > 0: ui_text += "🩸" + str(bleed_stacks) + " "
	if confusion_duration > 0: ui_text += "🌀" + str(confusion_duration) + " "
	if blind_duration > 0: ui_text += "🕶️" + str(blind_duration) + " "
	if slow_duration > 0: ui_text += "🐢" + str(slow_duration) + " "
	
	status_label.text = ui_text

# ==========================================
# --- APPLYING DEBUFFS & IMMUNITIES ---
# ==========================================
func apply_taunt(duration: int, caster: Node):
	if ("debuff_immune" in card and card.debuff_immune) or ("immune_to_taunt" in card and card.immune_to_taunt):
		card.show_floating_text("Immune!", Color.GRAY)
		return
	taunt_duration = max(taunt_duration, duration)
	taunted_by = caster
	if card.has_method("buff_animation"): card.buff_animation()
	card.show_floating_text("TAUNTED!", Color.MAGENTA)
	update_status_ui()

func apply_poison(duration: int, damage: int):
	if ("debuff_immune" in card and card.debuff_immune) or ("immune_to_poison" in card and card.immune_to_poison): return
	poison_duration = max(poison_duration, duration) 
	poison_damage = max(poison_damage, damage)
	if card.has_method("buff_animation"): card.buff_animation()
	card.show_floating_text("POISONED!", Color.PURPLE)
	update_status_ui()

func apply_burn(duration: int, damage: int):
	if ("debuff_immune" in card and card.debuff_immune) or ("immune_to_burn" in card and card.immune_to_burn): return
	
	# ---> WET CHECK: CANNOT BE IGNITED <---
	if wet_duration > 0:
		card.show_floating_text("Too Wet to Burn!", Color.BLUE)
		return
		
	burn_duration = max(burn_duration, duration)
	burn_damage = max(burn_damage, damage)
	if card.has_method("buff_animation"): card.buff_animation()
	card.show_floating_text("BURNED!", Color.ORANGE)
	update_status_ui()

func apply_curse(duration: int, potency: int):
	if ("debuff_immune" in card and card.debuff_immune) or ("immune_to_curse" in card and card.immune_to_curse): return
	curse_duration = max(curse_duration, duration)
	curse_potency = max(curse_potency, potency)
	if card.has_method("buff_animation"): card.buff_animation()
	card.show_floating_text("CURSED!", Color.DARK_GRAY)
	update_status_ui()

func apply_corrosion(amount: int):
	if "debuff_immune" in card and card.debuff_immune: return
	corrosion_stacks += amount
	if card.has_method("buff_animation"): card.buff_animation()
	card.show_floating_text("-DEF CORROSION!", Color.DARK_GREEN)
	
	if card.stats != null:
		card.defense = max(0, card.defense - amount)
		card.max_defense = max(0, card.max_defense - amount)
	update_status_ui()

func apply_stun(duration: int):
	if ("debuff_immune" in card and card.debuff_immune) or ("immune_to_stun" in card and card.immune_to_stun): return
	stun_duration = max(stun_duration, duration)
	card.show_floating_text("STUNNED!", Color.YELLOW)
	update_status_ui()

func apply_freeze(duration: int):
	if ("debuff_immune" in card and card.debuff_immune) or ("immune_to_freeze" in card and card.immune_to_freeze): return
	freeze_duration = max(freeze_duration, duration)
	card.show_floating_text("FROZEN!", Color.CYAN)
	update_status_ui()

func apply_disabled(duration: int):
	if ("debuff_immune" in card and card.debuff_immune) or ("immune_to_disbale" in card and card.immune_to_disable): return
	if card.has_method("update_disabled_visuals"):
		card.update_disabled_visuals()
	disabled_duration = max(disabled_duration, duration)
	card.show_floating_text("DISABLED!", Color.BLACK)
	
	update_status_ui()

# ==========================================
# --- NEW UNIQUE STATUS APPLICATIONS ---
# ==========================================
func apply_wet(duration: int):
	if ("debuff_immune" in card and card.debuff_immune) or ("immune_to_wet" in card and card.immune_to_wet): return
	wet_duration = max(wet_duration, duration)
	
	# Extinguish any existing fires immediately!
	if burn_duration > 0:
		burn_duration = 0
		burn_damage = 0
		card.show_floating_text("Extinguished!", Color.LIGHT_BLUE)
	else:
		card.show_floating_text("SOAKED!", Color.BLUE)
		
	if card.has_method("buff_animation"): card.buff_animation()
	update_status_ui()

func apply_bleed(stacks_to_add: int = 1):
	if ("debuff_immune" in card and card.debuff_immune) or ("immune_to_bleed" in card and card.immune_to_bleed): return
	bleed_stacks += stacks_to_add
	bleed_duration = 5 # Bleed strictly lasts 5 turns from the most recent application
	card.show_floating_text("BLEED STACK!", Color.RED)
	if card.has_method("buff_animation"): card.buff_animation()
	update_status_ui()
	
func heal_clears_bleed():
	if bleed_stacks > 0:
		bleed_stacks = 0
		bleed_duration = 0
		card.show_floating_text("Bleed Stopped", Color.GREEN)
		update_status_ui()

func apply_confusion(duration: int):
	if ("debuff_immune" in card and card.debuff_immune) or ("immune_to_confusion" in card and card.immune_to_confusion): return
	confusion_duration = max(confusion_duration, duration)
	card.show_floating_text("CONFUSED!", Color.DEEP_PINK)
	if card.has_method("buff_animation"): card.buff_animation()
	update_status_ui()

func apply_blind(duration: int):
	if ("debuff_immune" in card and card.debuff_immune) or ("immune_to_blind" in card and card.immune_to_blind): return
	blind_duration = max(blind_duration, duration)
	card.show_floating_text("BLINDED!", Color.DARK_SLATE_GRAY)
	update_status_ui()
	
func apply_slow(duration: int):
	if ("debuff_immune" in card and card.debuff_immune) or ("immune_to_slow" in card and card.immune_to_slow): return
	slow_duration = max(slow_duration, duration)
	card.show_floating_text("SLOWED!", Color.BROWN)
	update_status_ui()

func apply_shell_shocked(battle_manager: Node2D):
	if "debuff_immune" in card and card.debuff_immune: return
	card.show_floating_text("SHELL SHOCKED!", Color.GRAY)
	
	var is_hybrid = "is_hybrid" in card and card.is_hybrid
	
	if is_hybrid:
		# Hybrid Cards retreat to hand instantly
		card.row = card.Row.HAND
		card.current_slot = "hand" if card.is_player_card else "eh"
		if not card.is_player_card:
			card.hide()
			if battle_manager.has_method("update_ai_hand_visuals"):
				battle_manager.update_ai_hand_visuals()
		else:
			if battle_manager.has_node("HandManager"):
				battle_manager.get_node("HandManager").update_player_hand()
	else:
		# Standard Cards are forcibly swapped to the reserve
		var target_reserve = "pr1" if card.is_player_card else "er1"
		var occupant = battle_manager.get_card_in_slot(target_reserve)
		
		if occupant != null:
			battle_manager.swap_cards(card, occupant)
		else:
			card.current_slot = target_reserve
			card.row = card.Row.RESERVE
			var anchor = battle_manager.get_node("Board").get_node_or_null(target_reserve)
			if anchor:
				if card.has_method("move_to_anchor"):
					card.move_to_anchor(anchor.global_position)
				else:
					card.global_position = anchor.global_position

# ==========================================
# --- TICKING DEBUFFS (Start of Turn) ---
# ==========================================
func tick_debuffs():
	# 1. TAUNT
	if taunt_duration > 0:
		taunt_duration -= 1
		if taunt_duration <= 0:
			clear_taunt()
			card.show_floating_text("Taunt Faded", Color.GRAY)
			
	# 2. POISON 
	if poison_duration > 0:
		card.show_floating_text("Poison Tick", Color.PURPLE)
		card.take_damage(poison_damage, "poison", null)
		poison_duration -= 1
		if poison_duration <= 0: poison_damage = 0
		
	# 3. BURN 
	if burn_duration > 0:
		card.show_floating_text("🔥 Burn!", Color.ORANGE)
		card.take_damage(burn_damage, "burn", null)
		burn_duration -= 1
		if burn_duration <= 0: burn_damage = 0
		
	# 4. CURSE
	if curse_duration > 0:
		curse_duration -= 1
		if curse_duration <= 0:
			curse_potency = 0
			card.show_floating_text("Curse Lifted", Color.GRAY)
			
	# 5. STUN & FREEZE
	if stun_duration > 0:
		stun_duration -= 1
		if stun_duration <= 0: card.show_floating_text("Stun Lifted", Color.GRAY)
		
	if freeze_duration > 0:
		freeze_duration -= 1
		if freeze_duration <= 0: card.show_floating_text("Thawed Out", Color.GRAY)
		
	# 6. DISABLED
	if disabled_duration > 0:
		disabled_duration -= 1
		if disabled_duration <= 0:
			card.show_floating_text("Re-Activated!", Color.WHITE)
			if card.has_method("update_disabled_visuals"): card.update_disabled_visuals()
			
	# 7. WET
	if wet_duration > 0:
		wet_duration -= 1
		if wet_duration <= 0: card.show_floating_text("Dried Off", Color.GRAY)

	# 8. BLEED
	if bleed_duration > 0:
		bleed_duration -= 1
		if bleed_duration <= 0:
			bleed_stacks = 0
			card.show_floating_text("Bleed Stopped", Color.GRAY)

	# 9. CONFUSION, BLIND, SLOW
	if confusion_duration > 0:
		confusion_duration -= 1
		if confusion_duration <= 0: card.show_floating_text("Regained Senses", Color.GRAY)

	if blind_duration > 0:
		blind_duration -= 1
		if blind_duration <= 0: card.show_floating_text("Vision Restored", Color.GRAY)
		
	if slow_duration > 0:
		slow_duration -= 1
		if slow_duration <= 0: card.show_floating_text("Speed Normal", Color.GRAY)
				
	update_status_ui()

# ==========================================
# --- UTILITIES ---
# ==========================================
func clear_taunt():
	taunt_duration = 0
	taunted_by = null
	update_status_ui()
	
func is_taunted() -> bool:
	return taunt_duration > 0
	
func get_taunter() -> Node:
	return taunted_by

func is_stunned() -> bool:
	return stun_duration > 0 or freeze_duration > 0 or disabled_duration > 0
	
func is_frozen() -> bool:
	return freeze_duration > 0

func is_disabled() -> bool:
	return disabled_duration > 0
	
func is_wet() -> bool:
	return wet_duration > 0
	
func is_blind() -> bool:
	return blind_duration > 0
	
func is_slowed() -> bool:
	return slow_duration > 0
	
func is_confused() -> bool:
	return confusion_duration > 0
