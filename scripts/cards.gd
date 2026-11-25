extends Sprite2D
class_name BaseCard

signal card_clicked(clicked_card, click_type)
signal hover_started(card) 
signal hover_ended(card)   
signal card_died(slot_name, is_player)


enum Row { FRONTLINE, RESERVE, HAND, HYBRID }

@export var tags: Array[String] = []
@export var card_name: String = "Character Name"
@export var base_mode_name: String = "Base Form"
@export var is_player_card: bool = true
@export var row: Row = Row.FRONTLINE
@export var can_swap: bool = false
@export var current_slot: String = "" 
var max_health: int

@export_group("Card Types")
@export var is_tower: bool = false
@export var tower_hp: int = 10 
@export var is_hybrid: bool = false
@export var is_summon: bool = false
@export var is_trap: bool = false

@export_group("Combat Range")
@export var is_melee: bool = false
@export var is_ranged: bool = false
@export var has_depth_charge: bool = false
@export var can_attack: bool = true

@export_group("Domain & Roles")
@export var is_ground: bool = false
@export var is_air: bool = false
@export var is_naval: bool = false
@export var is_sub_naval: bool = false
@export var is_orbital: bool = false
@export var is_anti_air: bool = false
@export var is_sam: bool = false

@export_group("Base ATK mods")
@export var attack_power: int = 2
@export var health: int = 5
@export var defense: int = 0
@export_range(0, 100) var crit_chance: int = 0 
@export var crit_multiplier: float = 2.0 
@export var max_defense: int = 0



@export_group("Infinite Stats")
@export var inf_health: bool = false
@export var inf_attack: bool = false
@export var inf_defense: bool = false

@export_group("DEF Stats")
@export var block_stacks: int = 0         
@export var parry_stacks: int = 0         
@export var extra_heal: int = 0           
@export_range(0, 100) var evasion: int = 0 

@export_group("Visual Effects")
@export_enum("None", "Judgement Cut", "Explosion", "Gunfire", "Melee Hit","Shadow", "Light", "Fire", "Freeze","Brimstone") var attack_vfx: String = "None"

@export_group("Audio")
@export var attack_sfx: Array[AudioStream] = []

@export_group("Boss Settings")
@export var is_boss: bool = false
@export var boss_theme: AudioStream

@export_group("Attack Times & Burst")
@export var attack_times: int = 1
@export var burst_count: int = 1
@export var burst_delay: float = 0.2
@export var max_attack_cooldown: int = 0
var current_attack_cooldown: int = 0     
var cd_overlay: ColorRect                

@export_group("Attack ETC.")
@export var base_ignore_def: bool = false 
@export var splash_damage: bool = false
@export var outgoing_damage_type: String = "normal"
@export var debuff_immune: bool = false

@export_group("Specific Immunities")
@export var immune_to_stun: bool = false
@export var immune_to_freeze: bool = false
@export var immune_to_burn: bool = false
@export var immune_to_poison: bool = false
@export var immune_to_curse: bool = false
@export var immune_to_taunt: bool = false
@export var immune_to_wet: bool = false
@export var immune_to_bleed: bool = false
@export var immune_to_confusion: bool = false
@export var immune_to_blind: bool = false
@export var immune_to_slow: bool = false
@export var immune_to_disable: bool = false

var attacks_performed: int = 0
var original_can_swap: bool = false
var has_acted: bool = false 
var is_hovered: bool = false 
var click_cooldown_active: bool = false

var base_z_index: int:
	get: return visuals.base_z_index if visuals != null else 0
	set(value): if visuals != null: visuals.base_z_index = value
	
var debuffs: Node
@onready var ability_node = get_node_or_null("Ability")
var passives: Node

var stats: Node
var visuals: Node

func _ready():
	stats = CardStats.new()
	stats.name = "CardStats"
	add_child(stats)
	
	visuals = CardVisuals.new()
	visuals.name = "CardVisuals"
	add_child(visuals)
	
	debuffs = get_node_or_null("DebuffManager")
	if debuffs == null:
		debuffs = DebuffManager.new()
		debuffs.name = "DebuffManager"
		add_child(debuffs)
		
	passives = get_node_or_null("PassiveManager")
	if passives == null:
		passives = PassiveManager.new()
		passives.name = "PassiveManager"
		add_child(passives)

	if not can_attack: attack_times = 0
	
	cd_overlay = ColorRect.new()
	cd_overlay.color = Color(0, 0, 0, 0.75) # Deep black, slightly transparent
	cd_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cd_overlay.z_index = 5 # Make sure it sits above the card art
	add_child(cd_overlay)
	cd_overlay.hide()

func move_to_anchor(target_pos: Vector2):
	visuals.move_to_anchor(target_pos)
	if row == Row.RESERVE:
		can_swap = true 
	elif row == Row.FRONTLINE or row == Row.HYBRID:
		can_swap = original_can_swap 

func show_floating_text(msg: String, color: Color):
	visuals.show_floating_text(msg, color)
	
	if "Evaded" in msg or "Miss" in msg:
		if passives != null:
			var mih = passives.get_node_or_null("PassiveMadeInHeaven")
			if mih != null and mih.has_method("play_evade_animation"):
				mih.play_evade_animation()

func buff_animation():
	if visuals: visuals.buff_animation()

func attack_bump(target_pos: Vector2):
	visuals.attack_bump(target_pos)

func take_damage(amount: int, damage_type: String = "normal", attacker: Node = null) -> bool:
	
	if inf_health:
		show_floating_text("INFINITY", Color.GRAY)
		return false 

	var final_amount = amount
	
	if inf_defense:
		final_amount = 0
		show_floating_text("BLOCKED", Color.SLATE_GRAY)
	
	if debuffs != null and "bleed_stacks" in debuffs and debuffs.bleed_stacks > 0:
		var bleed_bonus = (debuffs.bleed_stacks * 10)
		final_amount += bleed_bonus
		if debuffs.has_method("apply_bleed"): debuffs.apply_bleed(1) 
			
	if damage_type == "emotional":
		var prev_health = tower_hp if is_tower else health
		if is_tower:
			tower_hp = max(1, tower_hp - final_amount)
			var actual_dmg = prev_health - tower_hp
			show_floating_text("-" + str(actual_dmg) + " EMOTIONAL DMG", Color.DEEP_PINK)
		else:
			health = max(1, health - final_amount)
			var actual_dmg = prev_health - health
			show_floating_text("-" + str(actual_dmg) + " EMOTIONAL DMG", Color.DEEP_PINK)
		buff_animation() 
		return true 
		
	var hit_landed = false
	if stats: 
		hit_landed = stats.take_damage(final_amount, damage_type, attacker)
		
	if hit_landed and passives != null and passives.has_method("trigger_take_damage"):
		passives.trigger_take_damage(final_amount, damage_type, attacker)
		
	return hit_landed
	
func heal(amount: int):
	if debuffs != null and debuffs.has_method("heal_clears_bleed"): debuffs.heal_clears_bleed()
	if stats: stats.heal(amount)

func buff_attack(amount: int):
	attack_power += amount
	show_floating_text("+" + str(amount) + " ATK", Color.RED)
	if has_method("buff_animation"): buff_animation()
		
func buff_defense(amount: int):
	if stats: stats.buff_defense(amount)

func exhaust():
	has_acted = true
	modulate = Color(0.4, 0.4, 0.4, 1.0)

func reset_action():
	if debuffs != null and debuffs.is_disabled():
		has_acted = true 
		modulate = Color(0.0, 0.0, 0.0, 1.0) 
		return

	var is_cc_locked = false
	if debuffs != null and (debuffs.stun_duration > 0 or debuffs.freeze_duration > 0):
		is_cc_locked = true

	has_acted = false
	attacks_performed = 0 
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	var mode_manager = get_node_or_null("ModeManager")
	if mode_manager != null and mode_manager.has_method("reset_modes_used"):
		mode_manager.reset_modes_used()
		
	
	if max_defense > 0 and defense < max_defense:
		var restored = max_defense - defense
		defense = max_defense
		show_floating_text("+" + str(restored) + " Shield", Color.CYAN)

	if is_cc_locked: exhaust() 
		
func _process(_delta):
	var local_pos = get_local_mouse_position()
	var currently_hovering = get_rect().has_point(local_pos)
	
	if currently_hovering and not is_hovered:
		is_hovered = true
		hover_started.emit(self)
		if row == Row.HAND: visuals.hover_enter_anim()
			
	elif not currently_hovering and is_hovered:
		is_hovered = false
		hover_ended.emit(self)
		if row == Row.HAND: visuals.hover_exit_anim()
		
	if max_attack_cooldown > 0 and current_attack_cooldown > 0:
		cd_overlay.show()
		var tex_size = texture.get_size() if texture != null else Vector2(500, 700)
		
		var pct = float(current_attack_cooldown) / float(max_attack_cooldown)
		
		cd_overlay.size = Vector2(tex_size.x, tex_size.y * pct)
		cd_overlay.position = Vector2(-tex_size.x / 2.0, (tex_size.y / 2.0) - cd_overlay.size.y)
	else:
		cd_overlay.hide()

func _input(event):
	if debuffs != null and debuffs.is_disabled(): return 
		
	if event is InputEventMouseButton and event.pressed:
		if get_rect().has_point(get_local_mouse_position()):
			if click_cooldown_active: return 
			click_cooldown_active = true
			
			if event.button_index == MOUSE_BUTTON_LEFT: card_clicked.emit(self, "left")
			elif event.button_index == MOUSE_BUTTON_RIGHT: card_clicked.emit(self, "right")
				
			await get_tree().create_timer(0.2).timeout
			click_cooldown_active = false
			
func update_disabled_visuals():
	if debuffs != null and debuffs.is_disabled(): modulate = Color(0.0, 0.0, 0.0, 1.0) 
	else: modulate = Color(0.4, 0.4, 0.4, 1.0) if has_acted else Color(1.0, 1.0, 1.0, 1.0)

func process_round_tick():
	if row == Row.HAND:
		return 
	if row == Row.FRONTLINE or row == Row.RESERVE or row == Row.HYBRID:
		if ability_node != null and ability_node.current_cooldown > 0:
			ability_node.current_cooldown -= 1
			
		if current_attack_cooldown > 0:
			current_attack_cooldown -= 1
			
		var mode_manager = get_node_or_null("ModeManager")
		if mode_manager and mode_manager.has_method("tick_hidden_cooldowns"):
			mode_manager.tick_hidden_cooldowns()
			
		if debuffs != null and debuffs.has_method("tick_debuffs"):
			debuffs.tick_debuffs()
