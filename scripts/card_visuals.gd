extends Node
class_name CardVisuals

@onready var card = get_parent()

var home_position: Vector2 = Vector2.ZERO
var hover_tween: Tween
var base_z_index: int = 0
var popup_queue_offset: int = 0

func move_to_anchor(target_pos: Vector2):
	home_position = target_pos
	
	if card.row == card.Row.HAND and not card.is_hovered:
		var move_tween = create_tween()
		move_tween.tween_property(card, "global_position", target_pos, 0.2).set_trans(Tween.TRANS_SINE)
	else:
		if hover_tween:
			hover_tween.kill() 
		card.global_position = target_pos
		
	if card.row != card.Row.HAND:
		card.z_index = 0 

func hover_enter_anim():
	card.z_index = 10 
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(card, "global_position:y", home_position.y - 120, 0.15).set_trans(Tween.TRANS_SINE)

func hover_exit_anim():
	card.z_index = base_z_index 
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(card, "global_position:y", home_position.y, 0.15).set_trans(Tween.TRANS_SINE)
	

func show_floating_text(msg: String, text_color: Color):
	var label = Label.new()
	label.text = msg
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", 100) 
	label.add_theme_constant_override("outline_size", 16) 
	
	card.add_child(label)
	
	var y_start_offset = 0
	var y_float_distance = 0
	var stack_dir = 1 
	
	if card.is_player_card:
		y_start_offset = -60
		y_float_distance = -100
		stack_dir = -1 
	else:
		y_start_offset = 20
		y_float_distance = 100
		stack_dir = 1 
		
	var stack_shift = popup_queue_offset * 70 * stack_dir
	popup_queue_offset += 1
	
	get_tree().create_timer(0.4).timeout.connect(func():
		popup_queue_offset = max(0, popup_queue_offset - 1)
	)
		
	label.global_position = card.global_position + Vector2(-50, y_start_offset + stack_shift) 
	label.z_index = 100 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y + y_float_distance, 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_LINEAR)
	tween.chain().tween_callback(label.queue_free)

func shake_animation():
	var tween = create_tween()
	var orig_x = card.global_position.x
	tween.tween_property(card, "global_position:x", orig_x - 12, 0.04)
	tween.tween_property(card, "global_position:x", orig_x + 12, 0.04)
	tween.tween_property(card, "global_position:x", orig_x - 8, 0.04)
	tween.tween_property(card, "global_position:x", orig_x + 8, 0.04)
	tween.tween_property(card, "global_position:x", orig_x, 0.04)

func attack_bump(target_pos: Vector2):
	var dir = (target_pos - card.global_position).normalized()
	var bump_pos = card.global_position + (dir * 40)
	
	var tween = create_tween()
	tween.tween_property(card, "global_position", bump_pos, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(card, "global_position", home_position, 0.2).set_trans(Tween.TRANS_SINE)

func buff_animation():
	var tween = create_tween()
	tween.tween_property(card, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.15)
	tween.tween_property(card, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)

func death_animation():
	card.remove_from_group("cards")
	card.set_process_input(false)
	
	show_floating_text("DEFEATED", Color(0.3, 0.3, 0.3)) 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(card, "self_modulate", Color(0.0, 0.0, 0.0, 0.0), 0.8) 
	tween.tween_property(card, "scale", Vector2(0.6, 0.6), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(card, "global_position:y", card.global_position.y + 40, 0.8)
	tween.chain().tween_callback(card.queue_free)
