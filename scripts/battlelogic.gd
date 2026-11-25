extends Node2D

enum Turn { PLAYER, ENEMY }
var current_turn: Turn = Turn.PLAYER
var selected_card: Sprite2D = null

var max_actions_per_turn: int = 6
var actions_left: int = 6
var has_swapped_this_turn: bool = false
var is_targeting_ability: bool = false
var draws_left_this_turn: int = 0

var is_setup_phase: bool = true
var player_went_first: bool = false
var is_game_over: bool = false
var current_round: int = 0
var sub_turn_count: int = 0

@onready var ui_panel = $UI/Panel
@onready var ui_name = $UI/Panel/ScrollContainer/VBoxContainer/NameLabel
@onready var ui_stats = $UI/Panel/ScrollContainer/VBoxContainer/StatsLabel
@onready var ui_desc = $UI/Panel/ScrollContainer/VBoxContainer/DescLabel
@onready var btn_ability = $UI/Panel/AbilityButton
@onready var btn_deploy = $UI/Panel/DeployButton
@onready var ai_hand_visuals = $UI/AIHandVisuals

@onready var btn_draw = $UI/DrawButton
@onready var btn_end_turn = $UI/EndTurnButton 

@onready var ui_turn_label = $UI/ConsolePanel/VBoxContainer/TurnLabel
@onready var ui_console = $UI/ConsolePanel/VBoxContainer/LogText
@onready var hover_tooltip = $UI/HoverTooltip
@onready var ui_console_input = $UI.get_node_or_null("ConsolePanel/VBoxContainer/ConsoleInput")

@onready var ui_game_over = $UI.get_node_or_null("GameOverPanel")
@onready var ui_result_label = $UI.get_node_or_null("GameOverPanel/ResultLabel")
@onready var btn_restart = $UI.get_node_or_null("GameOverPanel/RestartButton")
@onready var btn_main_menu = $UI.get_node_or_null("GameOverPanel/BtnMainMenu")

@onready var master_slider = %MasterSlider
@onready var ui_slider = %UISlider
@onready var sfx_slider = %SFXSlider
@onready var music_slider = %MusicSlider

@onready var master_value = %MasterValue
@onready var ui_value = %UIValue
@onready var sfx_value = %SFXValue
@onready var music_value = %MusicValue

@onready var top_left_buttons = $UI/TopLeftButtons
@onready var btn_chat = $UI/TopLeftButtons/BtnChat
@onready var btn_settings = $UI/TopLeftButtons/BtnSettings
@onready var settings_overlay = %SettingsOverlay
@onready var btn_resume = %BtnResume
@onready var btn_return_main = %BtnReturnMain

var bus_master: int
var bus_ui: int
var bus_sfx: int
var bus_music: int

var boss_music_player: AudioStreamPlayer
var current_playing_theme: AudioStream = null

var hovered_card: Sprite2D = null

func _ready():
	ui_panel.hide()
	hover_tooltip.hide() 
	
	btn_ability.pressed.connect(_on_ability_button_pressed)
	btn_draw.pressed.connect(_on_draw_button_pressed) 
	btn_end_turn.pressed.connect(_on_end_turn_pressed) 
	btn_deploy.pressed.connect(_on_deploy_pressed) 
	
	if ui_game_over:
		ui_game_over.hide()
		if btn_restart: btn_restart.pressed.connect(_on_restart_pressed)
		if btn_main_menu: btn_main_menu.pressed.connect(_on_main_menu_pressed)
	
	bus_master = AudioServer.get_bus_index("Master")
	bus_ui = AudioServer.get_bus_index("UI")
	bus_sfx = AudioServer.get_bus_index("SFX")
	bus_music = AudioServer.get_bus_index("Music")
	
	boss_music_player = AudioStreamPlayer.new()
	boss_music_player.bus = "Music" 
	add_child(boss_music_player)
	
	var music_timer = Timer.new()
	music_timer.wait_time = 1.0
	music_timer.autostart = true
	music_timer.timeout.connect(evaluate_boss_music)
	add_child(music_timer)
	
	if master_slider:
		_setup_slider(master_slider, bus_master, master_value)
		_setup_slider(ui_slider, bus_ui, ui_value)
		_setup_slider(sfx_slider, bus_sfx, sfx_value)
		_setup_slider(music_slider, bus_music, music_value)
		
		master_slider.value_changed.connect(_on_volume_changed.bind(bus_master, master_value))
		ui_slider.value_changed.connect(_on_volume_changed.bind(bus_ui, ui_value))
		sfx_slider.value_changed.connect(_on_volume_changed.bind(bus_sfx, sfx_value))
		music_slider.value_changed.connect(_on_volume_changed.bind(bus_music, music_value))

	btn_chat.pressed.connect(_on_chat_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	
	if settings_overlay:
		settings_overlay.hide()
		if btn_resume: btn_resume.pressed.connect(_on_resume_pressed)
		if btn_return_main: btn_return_main.pressed.connect(_on_return_main_pressed)
	
	var all_cards = get_tree().get_nodes_in_group("cards")
	for card in all_cards:
		_connect_card_signals(card)
		if card.current_slot != "":
			var anchor = $Board.get_node_or_null(card.current_slot)
			if anchor != null:
				card.move_to_anchor(anchor.global_position)
				
	print("--- DRAWING STARTING HAND ---")
	for i in range(5):
		draw_player_card()
	
	if has_node("EnemyAI"):
		$EnemyAI.initial_draw() 
		
	var deploy_manager = get_node_or_null("DeployManager")
	if deploy_manager:
		deploy_manager.card_deployed.connect(_on_card_deployed_by_manager)
	
	if ui_console_input:
		ui_console_input.text_submitted.connect(_on_console_input_submitted)
	
	start_setup_phase()
	
func _connect_card_signals(card):
	if not card.card_clicked.is_connected(_on_card_clicked): card.card_clicked.connect(_on_card_clicked)
	if not card.hover_started.is_connected(_on_card_hover_started): card.hover_started.connect(_on_card_hover_started) 
	if not card.hover_ended.is_connected(_on_card_hover_ended): card.hover_ended.connect(_on_card_hover_ended)    
	if not card.card_died.is_connected(_on_card_died): card.card_died.connect(_on_card_died) 

func start_setup_phase():
	ui_turn_label.text = "--- SETUP PHASE ---"
	log_event("\n>>> TACTICAL DEPLOYMENT PHASE <<<")
	log_event("Deploy your hand and swap units to counter the AI's formation.")
	log_event("Click 'End Turn' when you are ready to begin Round 1.")
	
	is_setup_phase = true
	current_turn = Turn.PLAYER
	draws_left_this_turn = 0
	btn_draw.disabled = true
	btn_draw.text = "Draw (0)"
	btn_end_turn.disabled = false
	actions_left = 0

func _on_end_turn_pressed():
	if current_turn != Turn.PLAYER or is_game_over: return

	var empty_frontline = get_empty_board_slot(true)
	var empty_reserve = get_empty_board_slot(false)
	
	if empty_frontline != "" or empty_reserve != "":
		var has_standard_unit_in_hand = false
		var all_cards = get_tree().get_nodes_in_group("cards")
		for c in all_cards:
			if is_instance_valid(c) and not c.is_queued_for_deletion():
				if c.is_player_card and c.row == c.Row.HAND:
					var is_trap = "is_trap" in c and c.is_trap
					var is_hybrid = "is_hybrid" in c and c.is_hybrid
					if not is_trap and not is_hybrid:
						has_standard_unit_in_hand = true
						break
						
		if has_standard_unit_in_hand:
			log_event("❌ Cannot end turn! You must deploy units to your empty Frontline/Reserve slots.")
			return 

	if is_setup_phase:
		is_setup_phase = false
		current_round = 1
		sub_turn_count = 0 
		cancel_selection()
		log_event("\n🎲 Rolling for the first turn...")
		
		if randi() % 2 == 0:
			log_event("🪙 YOU won! Player goes first.")
			player_went_first = true
			start_player_turn(true)
		else:
			log_event("🪙 AI won! Enemy goes first.")
			player_went_first = false
			start_enemy_turn(true)
		return
		
	print("Player ended their turn!")
	actions_left = 0
	cancel_selection()
	start_enemy_turn()
	
func start_player_turn(is_first_turn_of_match: bool = false):
	if is_game_over: return
	
	if not is_first_turn_of_match:
		tick_team_cards(Turn.ENEMY)
	
	if not is_first_turn_of_match:
		sub_turn_count += 1
		if sub_turn_count >= 2:
			current_round += 1
			sub_turn_count = 0
			
	ui_turn_label.text = "--- ROUND %d : PLAYER ---" % current_round
	log_event("\n>>> PLAYER TURN START <<<")
	
	current_turn = Turn.PLAYER
	if has_node("TrapManager"): $TrapManager.reset_limits(true)
	has_swapped_this_turn = false
	
	
	if current_round == 1 and player_went_first:
		log_event("⚠️ Player goes first! Skipping opening draw.")
		draws_left_this_turn = 0
		btn_draw.disabled = true
	else:
		draws_left_this_turn = 4
		btn_draw.disabled = false
		
	btn_draw.text = "Draw (" + str(draws_left_this_turn) + ")"
	btn_end_turn.disabled = false 
	
	var alive_players = 0
	var all_cards = get_tree().get_nodes_in_group("cards")
	
	for card in all_cards:
		if is_instance_valid(card) and not card.is_queued_for_deletion():
			if card.is_player_card:
				card.reset_action()
				
				var provides_action = (card.row == card.Row.FRONTLINE) or is_artillery(card) or ("is_tower" in card and card.is_tower) or (card.row == card.Row.HYBRID)
				if provides_action and not (card.debuffs != null and card.debuffs.is_disabled()):
					if card.debuffs != null and card.debuffs.is_slowed():
						log_event("🐢 " + card.card_name + " is slowed! No AP generated.")
					else:
						alive_players += 1
					
	actions_left = min(max_actions_per_turn, alive_players)
	print("--- PLAYER'S TURN (", actions_left, " Actions) ---")
	reset_highlights()

func start_enemy_turn(is_first_turn_of_match: bool = false):
	if is_game_over: return
	
	if not is_first_turn_of_match:
		tick_team_cards(Turn.PLAYER)
	
	if not is_first_turn_of_match:
		sub_turn_count += 1
		if sub_turn_count >= 2:
			current_round += 1
			sub_turn_count = 0
			
	var display_round = current_round
	if display_round == 0: display_round = 1
		
	ui_turn_label.text = "--- ROUND %d : ENEMY ---" % display_round
	log_event("\n>>> ENEMY TURN START <<<")
	
	current_turn = Turn.ENEMY
	if has_node("TrapManager"): $TrapManager.reset_limits(false)
	cancel_selection()
	btn_draw.disabled = true 
	btn_draw.text = "Draw (0)"
	btn_end_turn.disabled = true 
	
	var all_cards = get_tree().get_nodes_in_group("cards")
	for card in all_cards:
		if is_instance_valid(card) and not card.is_queued_for_deletion():
			if not card.is_player_card:
				card.reset_action()
	
	if has_node("EnemyAI"):
		$EnemyAI.execute_turn()

func check_auto_end_turn():
	if is_setup_phase or is_game_over: return
	
	if actions_left <= 0 or not has_available_moves(Turn.PLAYER):
		var empty_frontline = get_empty_board_slot(true)
		var empty_reserve = get_empty_board_slot(false)
		
		if empty_frontline != "" or empty_reserve != "":
			var all_cards = get_tree().get_nodes_in_group("cards")
			for c in all_cards:
				if is_instance_valid(c) and not c.is_queued_for_deletion():
					if c.is_player_card and c.row == c.Row.HAND:
						var is_trap = "is_trap" in c and c.is_trap
						var is_hybrid = "is_hybrid" in c and c.is_hybrid
						if not is_trap and not is_hybrid:
							return 
							
		start_enemy_turn()

func _on_card_died(dead_slot: String, is_player: bool):
	if "pf" in dead_slot or "ef" in dead_slot:
		var reserve_slot = "pr1" if is_player else "er1"
		var reserve_card = get_card_in_slot(reserve_slot)
		if reserve_card != null:
			reserve_card.current_slot = dead_slot
			reserve_card.row = reserve_card.Row.FRONTLINE
			var anchor = $Board.get_node_or_null(dead_slot)
			if anchor: reserve_card.move_to_anchor(anchor.global_position)
			
	check_match_status()
	evaluate_boss_music()
	reset_highlights()

func _on_draw_button_pressed():
	if is_setup_phase: return
	if current_turn != Turn.PLAYER or draws_left_this_turn <= 0: return
		
	var current_hand_size = 0
	var all_cards = get_tree().get_nodes_in_group("cards")
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			if c.is_player_card and c.row == c.Row.HAND:
				current_hand_size += 1
				
	if current_hand_size >= 6:
		var can_deploy = get_empty_board_slot(true) != "" or get_empty_board_slot(false) != "" or get_empty_hybrid_slot(true) != ""
		if can_deploy: log_event("⚠️ Hand is full! Deploy cards to make room for your remaining draws.")
		else: log_event("❌ Hand AND Board are full! You cannot draw any more cards.")
		return
		
	var cards_drawn_now = 0
	var deck_empty = false
	
	while draws_left_this_turn > 0 and current_hand_size < 6:
		var success = draw_player_card()
		if success:
			draws_left_this_turn -= 1
			cards_drawn_now += 1
			current_hand_size += 1
		else:
			deck_empty = true
			break
			
	if cards_drawn_now > 0:
		log_event("🃏 Drew " + str(cards_drawn_now) + " cards! (" + str(draws_left_this_turn) + " draws left this turn)")
		
	if deck_empty and current_hand_size < 6:
		log_event("⚠️ Global Deck is empty! No more cards remain.")
		
	btn_draw.text = "Draw (" + str(draws_left_this_turn) + ")"
	if draws_left_this_turn <= 0: btn_draw.disabled = true

func draw_player_card() -> bool:
	var current_hand_size = 0
	var all_cards = get_tree().get_nodes_in_group("cards")
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion() and c.is_player_card and c.row == c.Row.HAND:
			current_hand_size += 1
	if current_hand_size >= 6: return false

	var drawn_card_scene = null
	if has_node("DeckManager"): drawn_card_scene = $DeckManager.draw_card()
	if drawn_card_scene == null: return false
		
	var new_card = drawn_card_scene.instantiate()
	new_card.is_player_card = true 
	new_card.row = new_card.Row.HAND 
	new_card.current_slot = "hand" 
		
	add_child(new_card)
	new_card.global_position = Vector2(1000, 500) 
	
	_connect_card_signals(new_card)
	log_event("Drew " + new_card.card_name + "!")
	
	if has_node("HandManager"): $HandManager.update_player_hand()
	return true

func _on_deploy_pressed():
	if selected_card == null: return
		
	if btn_deploy.text == "Cast Spell":
		var trap_manager = get_node_or_null("TrapManager")
		if trap_manager and not trap_manager.can_play_trap(true):
			log_event("❌ You can only play 1 Spell/Trap per turn!")
			return
			
		var needs_target = false
		if selected_card.ability_node != null and "requires_target" in selected_card.ability_node:
			needs_target = selected_card.ability_node.requires_target
			
		if needs_target:
			is_targeting_ability = true
			btn_deploy.text = "🎯"
			log_event("🎯 Select a target for " + selected_card.card_name + "!")
			highlight_selection(selected_card) 
			return 
		else:
			if trap_manager: trap_manager.execute_trap(selected_card, null, true)
			cancel_selection()
			return
			
	elif btn_deploy.text == "Retreat":
		var current_hand_size = 0
		var all_cards = get_tree().get_nodes_in_group("cards")
		for c in all_cards:
			if is_instance_valid(c) and not c.is_queued_for_deletion() and c.is_player_card and c.row == c.Row.HAND:
				current_hand_size += 1
					
		if current_hand_size >= 6:
			log_event("❌ Hand is full! Cannot retreat.")
			return
			
		log_event("🏃 " + selected_card.card_name + " retreated to Hand.")
		selected_card.row = selected_card.Row.HAND
		selected_card.current_slot = "hand"
		selected_card.reset_action() 
		
		cancel_selection()
		if has_node("HandManager"): $HandManager.update_player_hand()
		check_auto_end_turn()

	elif selected_card.row == selected_card.Row.FRONTLINE and selected_card.has_node("ModeManager"):
		if selected_card.has_acted:
			log_event("❌ " + selected_card.card_name + " has already acted this turn!")
			return
		
		var mode_node = selected_card.get_node("ModeManager")
		mode_node.cycle_mode(selected_card)
		
		var mode_name_str = "Unknown Mode"
		
		if mode_node.current_index == 0:
			mode_name_str = selected_card.base_mode_name
		else:
			var alt_index = mode_node.current_index - 1
			if alt_index >= 0 and alt_index < mode_node.alternate_modes.size():
				var current_mode_data = mode_node.alternate_modes[alt_index]
				if "mode_name" in current_mode_data and current_mode_data.mode_name != "":
					mode_name_str = current_mode_data.mode_name
					
		selected_card.show_floating_text("🔄 " + mode_name_str, Color.CYAN)
		if selected_card.has_method("buff_animation"): selected_card.buff_animation()
		
		update_ui(selected_card) 
		log_event("🔄 " + selected_card.card_name + " shifted to " + mode_name_str + "!")
			
func _process(_delta):
	if hovered_card != null: hover_tooltip.global_position = get_viewport().get_mouse_position() + Vector2(15, -40)

func _on_card_hover_started(card):
	hovered_card = card
	if card.row == card.Row.HAND:
		hover_tooltip.hide() 
		preview_ui(card)     
	else:
		if "is_tower" in card and card.is_tower: hover_tooltip.text = "%s | THP: %d" % [card.card_name, card.tower_hp]
		else: hover_tooltip.text = "%s | HP: %d" % [card.card_name, card.health]
		hover_tooltip.show()

func _on_card_hover_ended(card):
	if hovered_card == card:
		hovered_card = null
		hover_tooltip.hide()
		if selected_card != null: update_ui(selected_card)
		else: ui_panel.hide()

func preview_ui(card):
	ui_panel.show()
	
	var final_name = card.card_name
	var mode_node = card.get_node_or_null("ModeManager")
	if mode_node != null and mode_node.alternate_modes.size() > 0:
		var current_m_name = card.base_mode_name
		if mode_node.current_index > 0:
			var alt_index = mode_node.current_index - 1
			if alt_index >= 0 and alt_index < mode_node.alternate_modes.size():
				var current_mode_data = mode_node.alternate_modes[alt_index]
				if "mode_name" in current_mode_data and current_mode_data.mode_name != "":
					current_m_name = current_mode_data.mode_name
					
		if "exhaust_only_after_all_modes" in mode_node and mode_node.exhaust_only_after_all_modes:
			if mode_node.current_index in mode_node.modes_attacked_this_turn:
				current_m_name += " ⛔"
				
		final_name += " [" + current_m_name + "]"
		
	ui_name.text = final_name
	
	if "is_tower" in card and card.is_tower: ui_stats.text = "THP: %d | ATK: %d | DEF: %d" % [card.tower_hp, card.attack_power, card.defense]
	else: ui_stats.text = "HP: %d | ATK: %d | DEF: %d" % [card.health, card.attack_power, card.defense]
	update_desc_label(card) 
	btn_ability.hide()
	btn_deploy.hide()

func update_ui(card):
	ui_panel.show()
	
	var final_name = card.card_name
	var mode_node = card.get_node_or_null("ModeManager")
	if mode_node != null and mode_node.alternate_modes.size() > 0:
		var current_m_name = card.base_mode_name
		if mode_node.current_index > 0:
			var alt_index = mode_node.current_index - 1
			if alt_index >= 0 and alt_index < mode_node.alternate_modes.size():
				var current_mode_data = mode_node.alternate_modes[alt_index]
				if "mode_name" in current_mode_data and current_mode_data.mode_name != "":
					current_m_name = current_mode_data.mode_name
		final_name += " [" + current_m_name + "]"
		
	ui_name.text = final_name
	
	var atk_str = str(card.attack_power)
	if "current_attack_cooldown" in card and card.current_attack_cooldown > 0:
		atk_str += " (⏳" + str(card.current_attack_cooldown) + ")"

	if "is_tower" in card and card.is_tower: ui_stats.text = "THP: %d | ATK: %s | DEF: %d" % [card.tower_hp, atk_str, card.defense]
	else: ui_stats.text = "HP: %d | ATK: %s | DEF: %d" % [card.health, atk_str, card.defense]
	
	update_desc_label(card)
	btn_ability.hide()
	btn_deploy.hide()
	
	if card.is_player_card:
		if card.row == card.Row.HAND:
			if "is_trap" in card and card.is_trap:
				btn_deploy.text = "Cast Spell"
				btn_deploy.show()
				
		elif card.row == card.Row.RESERVE and not ("is_tower" in card and card.is_tower):
			if card.debuffs != null and card.debuffs.is_wet(): pass 
			else:
				btn_deploy.text = "Retreat"
				btn_deploy.show()
				
		elif card.row == card.Row.FRONTLINE:
			if mode_node != null and mode_node.alternate_modes.size() > 0:
				
				var next_index = (mode_node.current_index + 1) % (mode_node.alternate_modes.size() + 1)
				var m_name = "Unknown Mode"
				
				if next_index == 0:
					m_name = card.base_mode_name
				else:
					var alt_index = next_index - 1
					if alt_index >= 0 and alt_index < mode_node.alternate_modes.size():
						var next_mode_data = mode_node.alternate_modes[alt_index]
						if "mode_name" in next_mode_data and next_mode_data.mode_name != "":
							m_name = next_mode_data.mode_name
				
				var mode_text = m_name
				
				var next_cd = 0
				if "mode_cooldowns" in mode_node and mode_node.mode_cooldowns.size() > next_index:
					next_cd = mode_node.mode_cooldowns[next_index]
					
				if next_cd > 0:
					mode_text += " ⏳" + str(next_cd)
					
				if "exhaust_only_after_all_modes" in mode_node and mode_node.exhaust_only_after_all_modes:
					if next_index in mode_node.modes_attacked_this_turn:
						mode_text += " ⛔"
					
				btn_deploy.text = mode_text
				btn_deploy.show()
			
		var can_act_here = (card.row == card.Row.FRONTLINE) or ("is_tower" in card and card.is_tower) or (card.row == card.Row.HYBRID)
		if card.passives != null:
			for p in card.passives.get_children():
				if "can_act_from_reserve" in p and p.can_act_from_reserve: can_act_here = true
					
		if can_act_here and not card.has_acted and not is_setup_phase:
			if card.ability_node != null:
				btn_ability.show()
				if card.debuffs != null and card.debuffs.is_taunted():
					btn_ability.text = "💢" 
					btn_ability.disabled = true
					btn_ability.modulate = Color.MAGENTA
				elif "has_been_used" in card.ability_node and card.ability_node.has_been_used:
					btn_ability.text = "⛔" 
					btn_ability.disabled = true
					btn_ability.modulate = Color.WHITE
				elif card.ability_node.current_cooldown > 0:
					btn_ability.text = str(card.ability_node.current_cooldown)
					btn_ability.disabled = true
					btn_ability.modulate = Color.WHITE
				else:
					btn_ability.text = "📟" 
					btn_ability.disabled = false
					btn_ability.modulate = Color.WHITE
					
func _on_ability_button_pressed():
	if selected_card != null and selected_card.ability_node != null:
		var needs_target = true
		if "requires_target" in selected_card.ability_node: needs_target = selected_card.ability_node.requires_target
			
		if not needs_target:
			var is_free = false
			if "is_free_action" in selected_card.ability_node: 
				is_free = selected_card.ability_node.is_free_action
			
			selected_card.ability_node.execute(selected_card, null, self)
			
			update_ui(selected_card) 
			
			if not is_free:
				selected_card.exhaust()
				cancel_selection()
				actions_left -= 1
				check_auto_end_turn()
		else:
			is_targeting_ability = true
			btn_ability.text = "🎯"
			highlight_selection(selected_card)
			
func _on_card_clicked(card, click_type):
	if click_type == "right":
		update_ui(card)
		return

	if current_turn != Turn.PLAYER or is_game_over: return 

	if selected_card == null:
		if card.is_player_card and card.has_acted and card.row != card.Row.HAND:
			print(card.name, " has already acted this turn!")
			return
		selected_card = card
		highlight_selection(card)
		update_ui(card) 
		
		if card.row == card.Row.HAND:
			var dm = get_node_or_null("DeployManager")
			if dm: dm.show_deploy_options(card, $Board)
			
	else:
		if card == selected_card:
			cancel_selection()
			return
			
		elif not selected_card.is_player_card:
			reset_highlights()
			selected_card = card
			highlight_selection(card)
			update_ui(card)
			return

		elif card.is_player_card:
			if selected_card.row == card.Row.HAND or card.row == card.Row.HAND:
				reset_highlights()
				selected_card = card
				highlight_selection(card)
				update_ui(card)
				return
				
			if selected_card.row != card.row: 
				if has_swapped_this_turn:
					print("Rule: You can only swap once per turn!")
					return
				if not selected_card.can_swap and not card.can_swap:
					print("Action blocked: Neither character has swap permission!")
					return
					
				var s_is_tower = "is_tower" in selected_card and selected_card.is_tower
				var c_is_tower = "is_tower" in card and card.is_tower
				if s_is_tower or c_is_tower:
					log_event("❌ Action blocked: Towers are immovable structures and cannot swap positions!")
					cancel_selection()
					return
					
				if selected_card.row == selected_card.Row.HYBRID or card.row == card.Row.HYBRID:
					log_event("❌ Action blocked: Hybrid Units are anchored to their slots and cannot swap!")
					cancel_selection()
					return
					
				var s_wet = selected_card.debuffs != null and selected_card.debuffs.is_wet()
				var c_wet = card.debuffs != null and card.debuffs.is_wet()
				if s_wet or c_wet:
					log_event("❌ Action blocked: Wet units slip and cannot swap/retreat!")
					cancel_selection()
					return

				swap_cards(selected_card, card)
				cancel_selection()
				return
			else:
				reset_highlights()
				selected_card = card
				highlight_selection(card)
				update_ui(card)
				is_targeting_ability = false
				return

		elif not card.is_player_card:
			var m_node = selected_card.get_node_or_null("ModeManager")
			if m_node != null and "exhaust_only_after_all_modes" in m_node and m_node.exhaust_only_after_all_modes:
				if m_node.current_index in m_node.modes_attacked_this_turn:
					log_event("❌ " + selected_card.card_name + " already fired in this stance! Shift modes to attack again.")
					cancel_selection()
					return
					
			if not _can_attack_target_silently(selected_card, card):
				if is_setup_phase: log_event("❌ Cannot attack during Setup Phase! Deploy your units.")
				elif selected_card.has_acted or (selected_card.debuffs != null and (selected_card.debuffs.is_disabled() or selected_card.debuffs.stun_duration > 0 or selected_card.debuffs.freeze_duration > 0)):
					log_event("❌ " + selected_card.card_name + " is incapacitated and cannot attack!")
				elif selected_card.debuffs != null and selected_card.debuffs.is_blind():
					log_event("❌ " + selected_card.card_name + " is BLINDED and cannot target enemies!")
					
				elif "current_attack_cooldown" in selected_card and selected_card.current_attack_cooldown > 0:
					log_event("⏳ " + selected_card.card_name + "'s attack is on cooldown for " + str(selected_card.current_attack_cooldown) + " turns!")
					
				elif not can_target_domain(selected_card, card):
					log_event("❌ Action blocked: Target is outside of this unit's combat domain or terrain reach!")
				elif selected_card.debuffs != null and selected_card.debuffs.is_taunted():
					var taunter = selected_card.debuffs.get_taunter()
					if taunter and taunter.row == taunter.Row.FRONTLINE and card != taunter:
						log_event("❌ ACTION BLOCKED: " + selected_card.card_name + " is TAUNTED! You must attack " + taunter.card_name + "!")
				else:
					var is_tower = "is_tower" in card and card.is_tower
					if is_tower: log_event("🛡️ ACTION BLOCKED: The Tower is protected by active defenders!")
					else: log_event("❌ Action blocked: Target is out of range!")
					
				cancel_selection()
				return

			if selected_card.debuffs != null and selected_card.debuffs.is_confused():
				log_event("🌀 " + selected_card.card_name + " is CONFUSED!")
				var board_targets = []
				var all_c = get_tree().get_nodes_in_group("cards")
				for c in all_c:
					if is_instance_valid(c) and not c.is_queued_for_deletion() and c.row != c.Row.HAND and c != selected_card:
						board_targets.append(c)
						
				if board_targets.size() > 0:
					card = board_targets.pick_random() 
					log_event("🌀 They wildly target " + card.card_name + "!")

			if is_targeting_ability:
				if "is_trap" in selected_card and selected_card.is_trap:
					var trap_manager = get_node_or_null("TrapManager")
					if trap_manager: trap_manager.execute_trap(selected_card, card, true)
				else:
					var is_free = false
					if "is_free_action" in selected_card.ability_node:
						is_free = selected_card.ability_node.is_free_action
						
					selected_card.ability_node.execute(selected_card, card, self)
					
					if not is_free:
						selected_card.exhaust() 
						actions_left -= 1
					
				cancel_selection()
				check_auto_end_turn()
			else:
				if selected_card.attack_times <= 0:
					log_event("❌ " + selected_card.card_name + " cannot perform basic attacks!")
					cancel_selection()
					return

				var bursts = 1
				if "burst_count" in selected_card: bursts = selected_card.burst_count
				var b_delay = 0.2
				if "burst_delay" in selected_card: b_delay = selected_card.burst_delay
				
				if "is_tower" in card and card.is_tower:
					bursts = 1
					
				play_attack_sound(selected_card)
				
				var attacker = selected_card
				var target = card
				
				for b_idx in range(bursts):
					if not is_instance_valid(attacker) or attacker.is_queued_for_deletion(): break
					if not is_instance_valid(target) or target.is_queued_for_deletion(): break

					var raw_damage = attacker.attack_power
					var is_crit = (randi() % 100) < attacker.crit_chance
					if is_crit:
						raw_damage = int(raw_damage * attacker.crit_multiplier)
					
					var final_damage_type = attacker.outgoing_damage_type
					if attacker.base_ignore_def and final_damage_type == "normal": final_damage_type = "pierce" 

					var terrain_hit_chance = calculate_terrain_hit_chance(attacker, target)
					var is_miss = (randi() % 100) >= terrain_hit_chance
					
					var main_target_dmg = raw_damage
					
					if is_miss:
						main_target_dmg = -1
					else:
						var synergy_manager = get_node_or_null("SynergyManager")
						if synergy_manager != null:
							main_target_dmg = synergy_manager.calculate_synergy_damage(attacker, target, raw_damage, final_damage_type)

					attacker.attack_bump(target.global_position)
					
					if "attack_vfx" in attacker and attacker.attack_vfx != "None":
						var vfx_manager = get_node_or_null("VFXManager")
						if vfx_manager:
							vfx_manager.play_vfx(attacker.attack_vfx, target.global_position)
					
					await get_tree().create_timer(0.1).timeout
					
					if not is_instance_valid(attacker) or attacker.is_queued_for_deletion(): break
					if not is_instance_valid(target) or target.is_queued_for_deletion(): break
					
					if main_target_dmg >= 0:
						if is_crit:
							log_event("⚡ CRITICAL HIT! " + attacker.card_name + " strikes for " + str(main_target_dmg) + " DMG!")
							target.show_floating_text("CRIT!", Color.YELLOW)
						else:
							log_event("⚔️ " + attacker.card_name + " attacks for " + str(main_target_dmg) + " DMG.")

						var hit_landed = target.take_damage(main_target_dmg, final_damage_type, attacker)	
						
						var force_chain = attacker.passives != null and attacker.passives.has_node("PassiveMadeInHeaven")
						if (hit_landed or force_chain) and attacker.passives != null:
							attacker.passives.trigger_attack(target, main_target_dmg)
							
						if "splash_damage" in attacker and attacker.splash_damage:
							var slot = target.current_slot 
							if slot.length() >= 3:
								var prefix = slot.substr(0, 2) 
								var num = int(slot.substr(2, 1)) 
								
								var adj1 = get_card_in_slot(prefix + str(num - 1))
								if adj1: 
									var splash_dmg1 = raw_damage
									var splash_chance1 = calculate_terrain_hit_chance(attacker, adj1)
									
									if (randi() % 100) >= splash_chance1:
										log_event("💨 Splash MISSED " + adj1.card_name + "!")
										adj1.show_floating_text("Miss!", Color.GRAY)
									else:
										var synergy_manager = get_node_or_null("SynergyManager")
										if synergy_manager != null:
											splash_dmg1 = synergy_manager.calculate_synergy_damage(attacker, adj1, raw_damage, final_damage_type)
										if splash_dmg1 >= 0:
											log_event("💥 Splash hit " + adj1.card_name + " for " + str(splash_dmg1) + " DMG!")
											adj1.take_damage(splash_dmg1, final_damage_type, attacker)
										
								var adj2 = get_card_in_slot(prefix + str(num + 1))
								if adj2: 
									var splash_dmg2 = raw_damage
									var splash_chance2 = calculate_terrain_hit_chance(attacker, adj2)
									
									if (randi() % 100) >= splash_chance2:
										log_event("💨 Splash MISSED " + adj2.card_name + "!")
										adj2.show_floating_text("Miss!", Color.GRAY)
									else:
										var synergy_manager = get_node_or_null("SynergyManager")
										if synergy_manager != null:
											splash_dmg2 = synergy_manager.calculate_synergy_damage(attacker, adj2, raw_damage, final_damage_type)
										if splash_dmg2 >= 0:
											log_event("💥 Splash hit " + adj2.card_name + " for " + str(splash_dmg2) + " DMG!")
											adj2.take_damage(splash_dmg2, final_damage_type, attacker)
					else:
						log_event("💨 " + attacker.card_name + "'s attack MISSED " + target.card_name + "!")
						target.show_floating_text("Miss!", Color.GRAY)
					
					if b_idx < bursts - 1:
						await get_tree().create_timer(b_delay).timeout

				if is_instance_valid(attacker):
					attacker.attacks_performed += 1
				
				var enemies_alive = 0
				var all_cards = get_tree().get_nodes_in_group("cards")
				for c in all_cards:
					if is_instance_valid(c) and not c.is_queued_for_deletion():
						if not c.is_player_card and (c.row == c.Row.FRONTLINE or c.row == c.Row.HYBRID) and not (c.debuffs != null and c.debuffs.is_disabled()):
							enemies_alive += 1
				
				var is_interrupted = not is_instance_valid(attacker) or attacker.is_queued_for_deletion() or attacker.has_acted
				
				var hit_a_tower = false
				if is_instance_valid(target) and "is_tower" in target and target.is_tower: hit_a_tower = true
				
				if is_interrupted or attacker.attacks_performed >= attacker.attack_times or enemies_alive == 0 or hit_a_tower:
					if is_instance_valid(attacker) and not attacker.is_queued_for_deletion():
						
						if "max_attack_cooldown" in attacker and attacker.max_attack_cooldown > 0:
							attacker.current_attack_cooldown = attacker.max_attack_cooldown

						if hit_a_tower and attacker.attacks_performed < attacker.attack_times:
							log_event("⚠️ Combo ended early: Towers can only be struck once per action!")
						elif is_interrupted and attacker.attacks_performed < attacker.attack_times: 
							log_event("⚠️ Combo broken! " + attacker.card_name + " was incapacitated!")
						elif enemies_alive == 0 and attacker.attacks_performed < attacker.attack_times: 
							print("Combo ended early: No targets remaining!")
							
						var attacker_mode = attacker.get_node_or_null("ModeManager")
						if attacker_mode != null and "exhaust_only_after_all_modes" in attacker_mode and attacker_mode.exhaust_only_after_all_modes:
							attacker_mode.mark_current_mode_used()
							
							if attacker_mode.has_used_all_modes():
								if not attacker.has_acted: attacker.exhaust() 
							else:
								attacker.attacks_performed = 0 
								attacker.modulate = Color(1.0, 1.0, 1.0, 1.0) 
								log_event("🔄 " + attacker.card_name + " is ready to fire again in a different mode!")
						else:
							if not attacker.has_acted: attacker.exhaust() 
							
					cancel_selection()
					actions_left -= 1 
				else:
					var hits_left = attacker.attack_times - attacker.attacks_performed
					print(attacker.card_name, " can attack ", hits_left, " more times!")
			
			check_auto_end_turn()
			
func check_match_status():
	await get_tree().create_timer(0.5).timeout
	var player_cards_alive = 0
	var enemy_cards_alive = 0
	
	var all_cards = get_tree().get_nodes_in_group("cards")
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			if c.is_player_card: player_cards_alive += 1
			else: enemy_cards_alive += 1
				
	if player_cards_alive == 0: trigger_game_over(false)
	elif enemy_cards_alive == 0: trigger_game_over(true)

func trigger_game_over(player_won: bool):
	if is_game_over: return
	is_game_over = true
	if ui_game_over: ui_game_over.show()
	
	if player_won:
		if ui_result_label:
			ui_result_label.text = "VICTORY!"
			ui_result_label.modulate = Color.GREEN
		log_event("\n🏆 >>> ENEMY FORCES ELIMINATED. YOU WIN! <<< 🏆")
	else:
		if ui_result_label:
			ui_result_label.text = "DEFEAT!"
			ui_result_label.modulate = Color.RED
		log_event("\n💀 >>> YOUR FORCES WERE WIPED OUT. GAME OVER. <<< 💀")
		
	btn_draw.disabled = true
	btn_end_turn.disabled = true
	current_turn = Turn.ENEMY 

func _on_restart_pressed():
	is_game_over = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	is_game_over = false
	get_tree().change_scene_to_file("res://main_menu.tscn")

func cancel_selection():
	reset_highlights()
	
	var dm = get_node_or_null("DeployManager")
	if dm: dm.hide_deploy_options()
	
	selected_card = null
	ui_panel.hide()
	is_targeting_ability = false
	btn_ability.text = "⏳"

func swap_cards(card1, card2):
	var temp_row = card1.row
	card1.row = card2.row
	card2.row = temp_row
	
	var temp_slot = card1.current_slot
	card1.current_slot = card2.current_slot
	card2.current_slot = temp_slot
	
	var anchor1 = $Board.get_node_or_null(card1.current_slot)
	if anchor1 != null: card1.move_to_anchor(anchor1.global_position) 
		
	var anchor2 = $Board.get_node_or_null(card2.current_slot)
	if anchor2 != null: card2.move_to_anchor(anchor2.global_position) 
	
	has_swapped_this_turn = true
	print("SWAP: ", card1.name, " and ", card2.name, " traded slots!")

func reset_highlights():
	var all_cards = get_tree().get_nodes_in_group("cards")
	for c in all_cards:
		if is_instance_valid(c):
			if not c.has_acted: c.modulate = Color(1.0, 1.0, 1.0, 1.0) 
			else: c.modulate = Color(0.4, 0.4, 0.4, 1.0) 
			
			var outline = c.get_node_or_null("ReadyOutline")
			if outline == null:
				outline = ReferenceRect.new()
				outline.name = "ReadyOutline"
				outline.border_color = Color.YELLOW
				outline.border_width = 3.0
				outline.editor_only = false
				outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
				outline.size = c.get_rect().size
				outline.position = c.get_rect().position
				c.add_child(outline)
				
			var ability_ready = false
			if c.is_player_card and not c.has_acted and not is_setup_phase:
				var can_act_here = (c.row == c.Row.FRONTLINE) or ("is_tower" in c and c.is_tower) or (c.row == c.Row.HYBRID)
				if c.passives != null:
					for p in c.passives.get_children():
						if "can_act_from_reserve" in p and p.can_act_from_reserve: can_act_here = true
						
				if can_act_here and c.ability_node != null:
					if not c.ability_node.has_been_used and c.ability_node.current_cooldown <= 0:
						ability_ready = true
						if c.debuffs != null and c.debuffs.is_taunted(): ability_ready = false
						
			outline.visible = ability_ready

func highlight_selection(chosen_card):
	reset_highlights()
	chosen_card.modulate = Color(1.0, 1.0, 1.0, 0.5) 
	
	var all_cards = get_tree().get_nodes_in_group("cards")
	for c in all_cards:
		if is_instance_valid(c) and c != chosen_card:
			if is_targeting_ability:
				pass 
			elif chosen_card.is_player_card:
				if c.is_player_card:
					if chosen_card.row == c.Row.HAND or c.row == c.Row.HAND: continue
					var can_swap = true
					if not chosen_card.can_swap and not c.can_swap: can_swap = false
					if ("is_tower" in chosen_card and chosen_card.is_tower) or ("is_tower" in c and c.is_tower): can_swap = false
					if chosen_card.row == chosen_card.Row.HYBRID or c.row == c.Row.HYBRID: can_swap = false
					if (chosen_card.debuffs != null and chosen_card.debuffs.is_wet()) or (c.debuffs != null and c.debuffs.is_wet()): can_swap = false
					
					if not can_swap: c.modulate = Color(0.2, 0.2, 0.2, 1.0)
				else:
					if not _can_attack_target_silently(chosen_card, c):
						c.modulate = Color(0.2, 0.2, 0.2, 1.0)

func _can_attack_target_silently(attacker, target) -> bool:
	if is_setup_phase: return false
	if attacker.has_acted: return false
	if attacker.row == attacker.Row.HAND: return false
	if attacker.debuffs != null and (attacker.debuffs.is_disabled() or attacker.debuffs.stun_duration > 0 or attacker.debuffs.freeze_duration > 0): return false
	if attacker.debuffs != null and attacker.debuffs.is_blind(): return false
	if attacker.debuffs != null and attacker.debuffs.is_confused(): return true
	
	if "current_attack_cooldown" in attacker and attacker.current_attack_cooldown > 0: return false

	if not can_target_domain(attacker, target): return false
	
	var attacker_can_indirect_fire = false
	if "is_tower" in attacker and attacker.is_tower: attacker_can_indirect_fire = true 
	if "is_orbital" in attacker and attacker.is_orbital and "is_ranged" in attacker and attacker.is_ranged: attacker_can_indirect_fire = true
	if attacker.passives != null:
		for p in attacker.passives.get_children():
			if "can_act_from_reserve" in p and p.can_act_from_reserve: attacker_can_indirect_fire = true
			
	if not attacker_can_indirect_fire:
		var target_is_tower = "is_tower" in target and target.is_tower
		if attacker.row == attacker.Row.RESERVE or (target.row == target.Row.RESERVE and not target_is_tower): return false
		
	if "is_tower" in target and target.is_tower:
		var active_enemy_defenders = 0
		var all_cards_check = get_tree().get_nodes_in_group("cards")
		for c in all_cards_check:
			if is_instance_valid(c) and not c.is_queued_for_deletion():
				if not c.is_player_card and c.current_slot in ["ef1", "ef2", "ef3", "ef4", "er1", "ehy1", "ehy2"]:
					var c_is_tower = "is_tower" in c and c.is_tower
					var c_is_trap = "is_trap" in c and c.is_trap
					var is_alive = true
					if "health" in c and c.health <= 0: is_alive = false
					if not c_is_tower and not c_is_trap and is_alive:
						active_enemy_defenders += 1
		if active_enemy_defenders > 1: return false
		
	if attacker.debuffs != null and attacker.debuffs.is_taunted():
		var taunter = attacker.debuffs.get_taunter()
		if is_instance_valid(taunter) and taunter.row == taunter.Row.FRONTLINE:
			if target != taunter: return false
			
	return true

func can_target_domain(attacker, defender) -> bool:
	if "is_orbital" in attacker and attacker.is_orbital and "is_ranged" in attacker and attacker.is_ranged: return true
	var attacker_has_indirect = false
	if attacker.passives != null:
		for p in attacker.passives.get_children():
			if "indirect_fire" in p and p.indirect_fire: attacker_has_indirect = true

	if "is_sub_naval" in defender and defender.is_sub_naval:
		var can_hit_sub = false
		if "is_sub_naval" in attacker and attacker.is_sub_naval: can_hit_sub = true
		if "has_depth_charge" in attacker and attacker.has_depth_charge: can_hit_sub = true
		if not can_hit_sub: return false

	if "is_sub_naval" in attacker and attacker.is_sub_naval:
		if not ("is_naval" in defender and defender.is_naval) and not ("is_sub_naval" in defender and defender.is_sub_naval) and not attacker_has_indirect:
			return false

	if "is_sam" in attacker and attacker.is_sam:
		var can_hit = false
		if "is_air" in defender and defender.is_air: can_hit = true
		if "is_orbital" in defender and defender.is_orbital: can_hit = true
		if not can_hit: return false
		
	if "is_melee" in attacker and attacker.is_melee:
		if "is_orbital" in attacker and attacker.is_orbital: return true
		if "is_air" in attacker and attacker.is_air:
			if "is_orbital" in defender and defender.is_orbital: return false
			return true
			
		var terrain_match = false
		if ("is_ground" in attacker and attacker.is_ground) and ("is_ground" in defender and defender.is_ground): terrain_match = true
		if ("is_naval" in attacker and attacker.is_naval) and ("is_naval" in defender and defender.is_naval): terrain_match = true
		if ("is_sub_naval" in attacker and attacker.is_sub_naval) and ("is_sub_naval" in defender and defender.is_sub_naval): terrain_match = true
		
		if ("is_sub_naval" in defender and defender.is_sub_naval) and ("has_depth_charge" in attacker and attacker.has_depth_charge):
			terrain_match = true
			
		if not terrain_match: return false
		
	return true

func calculate_terrain_hit_chance(attacker, defender) -> int:
	var hit_chance = 100
	if "is_air" in defender and defender.is_air:
		if "is_ground" in attacker and attacker.is_ground and "is_ranged" in attacker and attacker.is_ranged:
			if "is_sam" in attacker and attacker.is_sam: hit_chance = 100
			elif "is_anti_air" in attacker and attacker.is_anti_air: hit_chance = 80
			else: hit_chance = 20
		elif "is_naval" in attacker and attacker.is_naval and "is_ranged" in attacker and attacker.is_ranged:
			hit_chance = 50
	return hit_chance

func has_available_moves(team: Turn) -> bool:
	var all_cards = get_tree().get_nodes_in_group("cards")
	for card in all_cards:
		if is_instance_valid(card) and not card.is_queued_for_deletion():
			var is_my_team = (team == Turn.PLAYER and card.is_player_card) or (team == Turn.ENEMY and not card.is_player_card)
			
			if is_my_team:
				var can_act_here = (card.row == card.Row.FRONTLINE) or is_artillery(card) or ("is_tower" in card and card.is_tower) or (card.row == card.Row.HYBRID)
				var is_incapacitated = false
				if card.debuffs != null:
					if card.debuffs.is_disabled() or card.debuffs.stun_duration > 0 or card.debuffs.freeze_duration > 0: is_incapacitated = true
						
				if can_act_here and not card.has_acted and not is_incapacitated:
					var can_basic_attack = card.attack_times > 0
					if card.debuffs != null and card.debuffs.is_blind(): can_basic_attack = false
						
					var can_use_ability = false
					if card.ability_node != null:
						var used = false
						if "has_been_used" in card.ability_node: used = card.ability_node.has_been_used
						var cd = 0
						if "current_cooldown" in card.ability_node: cd = card.ability_node.current_cooldown
						if not used and cd <= 0: can_use_ability = true
							
					if can_basic_attack or can_use_ability: return true
	return false

func is_artillery(card_node) -> bool:
	if card_node.passives != null:
		for p in card_node.passives.get_children():
			if "can_act_from_reserve" in p and p.can_act_from_reserve: return true
	return false

func get_empty_board_slot(is_frontline: bool) -> String:
	var possible_slots = ["pf1", "pf2", "pf3", "pf4"] if is_frontline else ["pr1"]
	var filled_slots = []
	var all_cards = get_tree().get_nodes_in_group("cards")
	for card in all_cards:
		if is_instance_valid(card) and not card.is_queued_for_deletion() and card.is_player_card and card.row != card.Row.HAND:
			filled_slots.append(card.current_slot)
	for slot in possible_slots:
		if not slot in filled_slots: return slot
	return ""

func get_empty_hybrid_slot(is_player: bool) -> String:
	var possible_slots = ["phy1", "phy2"] if is_player else ["ehy1", "ehy2"]
	var filled_slots = []
	var all_cards = get_tree().get_nodes_in_group("cards")
	for card in all_cards:
		if is_instance_valid(card) and not card.is_queued_for_deletion() and card.is_player_card == is_player and card.row == card.Row.HYBRID:
			filled_slots.append(card.current_slot)
	for slot in possible_slots:
		if not slot in filled_slots: return slot
	return ""

func log_event(new_text: String):
	print(new_text) 
	if ui_console != null: ui_console.append_text(new_text + "\n")
		
func update_desc_label(card):
	var extra_text = ""
	if "tags" in card and card.tags.size() > 0:
		var joined_tags = ", ".join(card.tags)
		extra_text += "🏷️ [ " + joined_tags + " ]\n\n"
	
	if card.attack_times > 1: extra_text += "🗡️ Actions: %d\n" % card.attack_times
	if "burst_count" in card and card.burst_count > 1: extra_text += "🔫 Burst: %d hits\n" % card.burst_count
	if "splash_damage" in card and card.splash_damage: extra_text += " 💥 AOE\n"
	if "base_ignore_def" in card and card.base_ignore_def: extra_text += " 🛡️ Pierce DEF\n"
	if "crit_chance" in card and card.crit_chance > 0: extra_text += " Crit: %d%%\n" % card.crit_chance
	if "evasion" in card and card.evasion > 0: extra_text += " EVAS: %d%%\n" % card.evasion
	if "block_stacks" in card and card.block_stacks > 0: extra_text += " Block: %d\n" % card.block_stacks
	if "parry_stacks" in card and card.parry_stacks > 0: extra_text += " Parry: %d\n" % card.parry_stacks
	if "extra_heal" in card and card.extra_heal > 0: extra_text += " Extra Heal: +%d\n" % card.extra_heal
	
	if "debuff_immune" in card and card.debuff_immune: extra_text += " [Immune to CC & Debuffs]\n"
	else:
		if "immune_to_stun" in card and card.immune_to_stun: extra_text += " [Immune to Stun]\n"
		if "immune_to_freeze" in card and card.immune_to_freeze: extra_text += " [Immune to Freeze]\n"
		if "immune_to_burn" in card and card.immune_to_burn: extra_text += " [Immune to Burn]\n"
		if "immune_to_poison" in card and card.immune_to_poison: extra_text += " [Immune to Poison]\n"
		if "immune_to_curse" in card and card.immune_to_curse: extra_text += " [Immune to Curse]\n"
		if "immune_to_taunt" in card and card.immune_to_taunt: extra_text += " [Immune to Taunt]\n"
		if "immune_to_wet" in card and card.immune_to_wet: extra_text += " [Immune to Wet]\n"
		if "immune_to_bleed" in card and card.immune_to_bleed: extra_text += " [Immune to Bleed]\n"
		if "immune_to_confusion" in card and card.immune_to_confusion: extra_text += " [Immune to Confusion]\n"
		if "immune_to_blind" in card and card.immune_to_blind: extra_text += " [Immune to Blind]\n"
		if "immune_to_slow" in card and card.immune_to_slow: extra_text += " [Immune to Slow]\n"

	var skillset_text = ""
	if card.passives != null and card.passives.get_child_count() > 0:
		for p in card.passives.get_children():
			var p_name = p.name.replace("Passive", "").strip_edges()
			if "status_to_apply" in p: p_name += " [" + str(p.status_to_apply).to_upper() + "]"
			skillset_text += "Passive: " + p_name + "\n"
			
	if card.ability_node != null:
		var a_name = card.ability_node.name
		if "ability_name" in card.ability_node and card.ability_node.ability_name != "": a_name = card.ability_node.ability_name
		if "has_been_used" in card.ability_node and card.ability_node.has_been_used: skillset_text += "🌟 Ability: %s (Used)\n" % a_name
		elif card.ability_node.current_cooldown > 0: skillset_text += "⏳ Ability: %s (CD: %d)\n" % [a_name, card.ability_node.current_cooldown]
		else: skillset_text += "🌟 Ability: %s (Ready!)\n" % a_name
			
	if skillset_text != "": extra_text += "\n[ SKILLS ]\n" + skillset_text

	if card.debuffs != null:
		var active_statuses = ""
		if card.debuffs.taunt_duration > 0: active_statuses += "💢 Taunted (%d) \n" % card.debuffs.taunt_duration
		if card.debuffs.burn_duration > 0: active_statuses += "🔥 Burned (%d) \n" % card.debuffs.burn_duration
		if card.debuffs.poison_duration > 0: active_statuses += "☠️ Poisoned (%d) \n" % card.debuffs.poison_duration
		if card.debuffs.curse_duration > 0: active_statuses += "👁️ Cursed (%d) \n" % card.debuffs.curse_duration
		if card.debuffs.corrosion_stacks > 0: active_statuses += "🧪 Corroded (-%d DEF) \n" % card.debuffs.corrosion_stacks
		if card.debuffs.stun_duration > 0: active_statuses += "💫 Stunned (%d) \n" % card.debuffs.stun_duration
		if card.debuffs.freeze_duration > 0: active_statuses += "❄️ Frozen (%d) \n" % card.debuffs.freeze_duration
		if card.debuffs.disabled_duration > 0: active_statuses += "🚫 Disabled (%d) \n" % card.debuffs.disabled_duration
		
		if card.debuffs.wet_duration > 0: active_statuses += "💦 Wet (%d) \n" % card.debuffs.wet_duration
		if card.debuffs.bleed_duration > 0: active_statuses += "🩸 Bleeding (%d Stacks) \n" % card.debuffs.bleed_stacks
		if card.debuffs.confusion_duration > 0: active_statuses += "🌀 Confused (%d) \n" % card.debuffs.confusion_duration
		if card.debuffs.blind_duration > 0: active_statuses += "🕶️ Blinded (%d) \n" % card.debuffs.blind_duration
		if card.debuffs.slow_duration > 0: active_statuses += "🐢 Slowed (%d) \n" % card.debuffs.slow_duration
		
		if active_statuses != "": extra_text += "\n[ ACTIVE STATUS ]\n" + active_statuses
			
	if extra_text == "":
		ui_desc.text = ""
		ui_desc.hide()
	else:
		ui_desc.text = extra_text
		ui_desc.show()

func get_card_in_slot(slot: String):
	var all_cards = get_tree().get_nodes_in_group("cards")
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			if c.current_slot == slot: return c
	return null

func update_ai_hand_visuals():
	if ai_hand_visuals == null: return
	for child in ai_hand_visuals.get_children(): child.queue_free()
		
	var hidden_count = 0
	var all_cards = get_tree().get_nodes_in_group("cards")
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			if not c.is_player_card and c.current_slot == "eh": hidden_count += 1
				
	for i in range(hidden_count):
		var dummy_card = TextureRect.new() 
		dummy_card.custom_minimum_size = Vector2(60, 80)
		dummy_card.texture = load("res://images/jarcg.png") 
		dummy_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dummy_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ai_hand_visuals.add_child(dummy_card)
		
func tick_team_cards(team: Turn):
	var all_cards = get_tree().get_nodes_in_group("cards")
	for card in all_cards:
		if is_instance_valid(card) and not card.is_queued_for_deletion():
			var is_my_team = (team == Turn.PLAYER and card.is_player_card) or (team == Turn.ENEMY and not card.is_player_card)
			
			if is_my_team:
				if card.has_method("process_round_tick"):
					card.process_round_tick()
					

func _on_chat_pressed():
	var console = $UI.get_node_or_null("ConsolePanel")
	if console:
		console.visible = !console.visible

func _on_settings_pressed():
	if settings_overlay: settings_overlay.show()
	if top_left_buttons: top_left_buttons.hide()

func _on_resume_pressed():
	if settings_overlay: settings_overlay.hide()
	if top_left_buttons: top_left_buttons.show()

func _on_return_main_pressed():
	is_game_over = true
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _setup_slider(slider: HSlider, bus_index: int, value_label: Label):
	var current_db = AudioServer.get_bus_volume_db(bus_index)
	var linear_val = db_to_linear(current_db)
	slider.value = linear_val
	if value_label: value_label.text = str(int(linear_val * 100))

func _on_volume_changed(value: float, bus_index: int, value_label: Label):
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_index, db)
	AudioServer.set_bus_mute(bus_index, value <= 0.001)
	if value_label: value_label.text = str(int(value * 100))

func play_attack_sound(attacker):
	if "attack_sfx" in attacker and attacker.attack_sfx.size() > 0:
		var random_sfx = attacker.attack_sfx.pick_random()
		if random_sfx != null:
			var sfx_player = AudioStreamPlayer.new()
			sfx_player.bus = "SFX"
			sfx_player.stream = random_sfx
			sfx_player.pitch_scale = randf_range(0.95, 1.05)
			add_child(sfx_player)
			sfx_player.play()
			sfx_player.finished.connect(sfx_player.queue_free)

func evaluate_boss_music():
	if is_game_over: return
	
	var all_cards = get_tree().get_nodes_in_group("cards")
	var highest_power = -1
	var best_boss_theme: AudioStream = null
	var winning_boss_name = ""

	var akashiro_overriding = false
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			if "card_name" in c and c.card_name.to_lower().contains("akashiro"):
				if c.has_node("Ability") and c.get_node("Ability").has_method("is_judgment_active"):
					if c.get_node("Ability").is_judgment_active():
						akashiro_overriding = true
						break

	if akashiro_overriding:
		pass
	else:
		for c in all_cards:
			if is_instance_valid(c) and not c.is_queued_for_deletion():
				if "card_name" in c and c.card_name.contains("Bank"):
					if c.passives != null and c.passives.has_node("PassiveMadeInHeaven") and c.boss_theme != null:
						best_boss_theme = c.boss_theme
						winning_boss_name = c.card_name
						highest_power = 999999 # Forces him to be the absolute highest priority!
						break

		if highest_power != 999999:
			for c in all_cards:
				if is_instance_valid(c) and not c.is_queued_for_deletion():
					if c.row != c.Row.HAND and c.current_slot != "":
						if "is_boss" in c and c.is_boss and c.boss_theme != null:
							var current_hp = c.tower_hp if ("is_tower" in c and c.is_tower) else c.health
							var total_power = c.attack_power + current_hp + c.defense
							
							if total_power > highest_power:
								highest_power = total_power
								best_boss_theme = c.boss_theme
								winning_boss_name = c.card_name

	if best_boss_theme != current_playing_theme:
		current_playing_theme = best_boss_theme
		if best_boss_theme == null:
			boss_music_player.stop()
		else:
			boss_music_player.stream = best_boss_theme
			boss_music_player.play()
			log_event("🎵 " + winning_boss_name + " is overpowering the battlefield! Playing Boss theme.")

func _on_card_deployed_by_manager(card, target_slot):
	if is_instance_valid(card) and card.row == card.Row.HAND:
		card.current_slot = target_slot
		
		if "hy" in target_slot: card.row = card.Row.HYBRID
		elif "r" in target_slot: card.row = card.Row.RESERVE
		else: card.row = card.Row.FRONTLINE
		
		var anchor = $Board.get_node_or_null(target_slot)
		if anchor: card.move_to_anchor(anchor.global_position)
		
		log_event("Deployed " + card.card_name + " to " + target_slot)
		
		var gives_ap = (card.row == card.Row.FRONTLINE) or (card.row == card.Row.HYBRID) or is_artillery(card) or ("is_tower" in card and card.is_tower)
		if gives_ap and actions_left < max_actions_per_turn and not is_setup_phase:
			if card.debuffs != null and card.debuffs.is_slowed():
				pass
			else:
				actions_left += 1
				print("Gained 1 Action Point! (Total AP: ", actions_left, ")")
		
		cancel_selection()
		if has_node("HandManager"): $HandManager.update_player_hand()
		check_auto_end_turn()
		
		

func _on_console_input_submitted(new_text: String):
	if ui_console_input: ui_console_input.clear()
	
	if new_text.begins_with("/"):
		var admin = get_node_or_null("AdminConsole")
		if admin:
			admin.process_command(new_text)
		else:
			log_event("❌ ERROR: AdminConsole module is missing from the scene!")
