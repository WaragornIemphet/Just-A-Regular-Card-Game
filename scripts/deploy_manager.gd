extends Node

signal card_deployed(card, target_slot)

var deploy_overlays: Node2D

func show_deploy_options(card, board_node: Node):
	hide_deploy_options() # Clear any old ones first
	
	if not is_instance_valid(card) or card.row != card.Row.HAND: return
	if "is_trap" in card and card.is_trap: return # Traps are cast, not placed
	
	if deploy_overlays == null:
		deploy_overlays = Node2D.new()
		deploy_overlays.z_index = 50
		board_node.add_child(deploy_overlays)

	var empty_frontline = ["pf1", "pf2", "pf3", "pf4"]
	var empty_hybrid = ["phy1", "phy2"]
	var empty_reserve = ["pr1"]
	var pt_occupied = false
	
	var all_cards = get_tree().get_nodes_in_group("cards")
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion() and c.is_player_card and c.row != c.Row.HAND:
			empty_frontline.erase(c.current_slot)
			empty_hybrid.erase(c.current_slot)
			empty_reserve.erase(c.current_slot)
			if c.current_slot == "pt": pt_occupied = true
				
	var valid_slots = []
	var slot_color = Color.WHITE
	
	if "is_hybrid" in card and card.is_hybrid:
		valid_slots = empty_hybrid
		slot_color = Color(0.2, 0.6, 1.0) # Blue
	elif "is_tower" in card and card.is_tower:
		if not pt_occupied:
			valid_slots = ["pt"]
			slot_color = Color.WHITE
	else:
		valid_slots = empty_frontline.duplicate()
		if "is_summon" in card and card.is_summon:
			slot_color = Color.GRAY
		else:
			slot_color = Color.WHITE
			
		if empty_frontline.size() == 0 and empty_reserve.size() > 0:
			valid_slots = empty_reserve.duplicate()
			slot_color = Color.YELLOW

	for slot_name in valid_slots:
		var anchor = board_node.get_node_or_null(slot_name)
		if anchor != null:
			var btn = Button.new()
			btn.size = Vector2(110, 150) 
			
			btn.global_position = anchor.global_position - (btn.size / 2.0)
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0)
			style.border_width_left = 6
			style.border_width_right = 6
			style.border_width_top = 6
			style.border_width_bottom = 6
			style.border_color = slot_color
			
			var hover_style = style.duplicate()
			hover_style.bg_color = slot_color
			hover_style.bg_color.a = 0.2 # Slight fill when hovering
			
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", hover_style)
			btn.add_theme_stylebox_override("pressed", hover_style)
			
			btn.pressed.connect(_on_deploy_slot_clicked.bind(card, slot_name))
			deploy_overlays.add_child(btn)

func hide_deploy_options():
	if deploy_overlays != null:
		for child in deploy_overlays.get_children():
			child.queue_free()

func _on_deploy_slot_clicked(card, target_slot):
	hide_deploy_options()
	card_deployed.emit(card, target_slot)
