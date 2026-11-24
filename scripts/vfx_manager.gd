extends Node

# Central router for EVERY visual effect in the game!
func play_vfx(vfx_name: String, target_pos: Vector2):
	match vfx_name:
		"Judgement Cut":
			_spawn_normal_judgement_cut(target_pos)
		"Explosion":
			_spawn_explosion(target_pos)
		"Gunfire":
			_spawn_gunfire_impact(target_pos)
		"Melee Hit":
			_spawn_melee_hit(target_pos)
		"Shadow":
			_spawn_shadow(target_pos)
		"Light":
			_spawn_light(target_pos)
		"Fire":
			_spawn_fire(target_pos)
		"Freeze":
			_spawn_freeze(target_pos)
		"Brimstone":
			_spawn_brimstone(target_pos)

# ==========================================
# 1. PROCEDURAL JUDGEMENT CUT
# ==========================================
func _spawn_normal_judgement_cut(target_pos: Vector2):
	var vfx_node = Node2D.new()
	vfx_node.z_index = 60 
	
	var scene_root = get_tree().current_scene
	if scene_root: scene_root.add_child(vfx_node)
	else: return

	# THE DARK SPHERE
	var void_circle = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.08, 0.85)
	style.corner_radius_top_left = 100
	style.corner_radius_top_right = 100
	style.corner_radius_bottom_left = 100
	style.corner_radius_bottom_right = 100
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.6, 1.0, 0.6)
	style.border_blend = true

	void_circle.add_theme_stylebox_override("panel", style)
	void_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	void_circle.size = Vector2(0, 0)
	void_circle.position = target_pos
	vfx_node.add_child(void_circle)

	var sphere_size = 110 
	var t = get_tree().create_tween()
	t.tween_property(void_circle, "size", Vector2(sphere_size, sphere_size), 0.05)
	t.parallel().tween_property(void_circle, "position", target_pos - Vector2(sphere_size / 2.0, sphere_size / 2.0), 0.05)

	# THE INNER SLASHES
	for i in range(8):
		var slash = ColorRect.new()
		slash.color = Color(1.0, 1.0, 1.0, 0.95) if (randi() % 3 == 0) else Color(0.3, 0.8, 1.0, 0.85)
		slash.size = Vector2(randf_range(60, 100), randf_range(2, 4))
		slash.position = target_pos - (slash.size / 2) + Vector2(randf_range(-25, 25), randf_range(-25, 25))
		slash.rotation = randf_range(0, TAU)
		slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vfx_node.add_child(slash)

		var slash_t = get_tree().create_tween()
		slash_t.tween_property(slash, "color", Color(1, 1, 1, 0), 0.15).set_delay(randf_range(0.0, 0.05))

	await get_tree().create_timer(0.15).timeout

	# THE LOCAL SHATTER
	style.bg_color = Color(1.0, 1.0, 1.0, 0.9)
	style.border_color = Color(1, 1, 1, 0)
	
	for i in range(6):
		var shard = Polygon2D.new()
		shard.color = Color(0.7, 0.9, 1.0, 0.8) 
		var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		shard.polygon = PackedVector2Array([
			target_pos + offset,
			target_pos + offset + Vector2(randf_range(10, 35), randf_range(-20, 20)),
			target_pos + offset + Vector2(randf_range(-20, 20), randf_range(10, 35))
		])
		vfx_node.add_child(shard)
		
		var shard_t = get_tree().create_tween()
		shard_t.set_parallel(true)
		var dir = (shard.polygon[0] - target_pos).normalized()
		if dir == Vector2.ZERO: dir = Vector2.UP
		
		shard_t.tween_property(shard, "position", dir * randf_range(40, 100), 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		shard_t.tween_property(shard, "rotation", randf_range(-1.5, 1.5), 0.2)
		shard_t.tween_property(shard, "color", Color(1, 1, 1, 0), 0.2)

	var t_end = get_tree().create_tween()
	t_end.tween_property(void_circle, "modulate", Color(1, 1, 1, 0), 0.15)
	
	await get_tree().create_timer(0.2).timeout
	vfx_node.queue_free()

# ==========================================
# 2. PROCEDURAL EXPLOSION
# ==========================================
func _spawn_explosion(target_pos: Vector2):
	var vfx_node = Node2D.new()
	vfx_node.z_index = 65
	var scene_root = get_tree().current_scene
	if scene_root: scene_root.add_child(vfx_node)
	else: return

	# Main Fireball (Expands, shifts from orange to dark grey smoke)
	var fireball = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.4, 0.0, 0.95) # Bright Orange
	style.corner_radius_top_left = 100
	style.corner_radius_top_right = 100
	style.corner_radius_bottom_left = 100
	style.corner_radius_bottom_right = 100
	fireball.add_theme_stylebox_override("panel", style)
	fireball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	fireball.size = Vector2(10, 10)
	fireball.position = target_pos - Vector2(5, 5)
	vfx_node.add_child(fireball)

	var t = get_tree().create_tween()
	t.set_parallel(true)
	var exp_size = 120
	t.tween_property(fireball, "size", Vector2(exp_size, exp_size), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(fireball, "position", target_pos - Vector2(exp_size/2.0, exp_size/2.0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(style, "bg_color", Color(0.15, 0.15, 0.15, 0.8), 0.3) # Shifts to smoke
	t.chain().tween_property(fireball, "modulate", Color(1, 1, 1, 0), 0.3) # Fades out

	# Sparks/Embers flying out
	for i in range(12):
		var spark = ColorRect.new()
		spark.color = Color(1.0, 0.8, 0.1, 1.0)
		spark.size = Vector2(5, 5)
		spark.position = target_pos
		vfx_node.add_child(spark)

		var spark_t = get_tree().create_tween()
		spark_t.set_parallel(true)
		var angle = randf_range(0, TAU)
		var dir = Vector2(cos(angle), sin(angle))
		var dist = randf_range(60, 120)
		spark_t.tween_property(spark, "position", target_pos + dir * dist, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		spark_t.tween_property(spark, "color", Color(1, 0, 0, 0), 0.35)

	await get_tree().create_timer(0.6).timeout
	vfx_node.queue_free()

# ==========================================
# 3. PROCEDURAL GUNFIRE / BULLET IMPACT
# ==========================================
func _spawn_gunfire_impact(target_pos: Vector2):
	var vfx_node = Node2D.new()
	vfx_node.z_index = 65
	var scene_root = get_tree().current_scene
	if scene_root: scene_root.add_child(vfx_node)
	else: return

	# Flash of the bullet hitting the armor
	var flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 0.8, 1.0) # Bright pale yellow
	flash.size = Vector2(30, 30)
	flash.position = target_pos - Vector2(15, 15)
	flash.rotation = randf_range(0, TAU)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vfx_node.add_child(flash)

	var t = get_tree().create_tween()
	t.set_parallel(true)
	t.tween_property(flash, "scale", Vector2(0.1, 0.1), 0.1)
	t.tween_property(flash, "color", Color(1.0, 0.5, 0.0, 0.0), 0.1)

	# Tiny ricochet sparks
	for i in range(4):
		var spark = ColorRect.new()
		spark.color = Color(1.0, 0.9, 0.4, 1.0)
		spark.size = Vector2(12, 3)
		spark.position = target_pos
		spark.rotation = randf_range(0, TAU)
		vfx_node.add_child(spark)

		var spark_t = get_tree().create_tween()
		spark_t.set_parallel(true)
		var dir = Vector2(cos(spark.rotation), sin(spark.rotation))
		spark_t.tween_property(spark, "position", target_pos + dir * randf_range(20, 40), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		spark_t.tween_property(spark, "color", Color(1, 0.4, 0, 0), 0.15)

	await get_tree().create_timer(0.2).timeout
	vfx_node.queue_free()

# ==========================================
# 4. PROCEDURAL MELEE NORMAL HIT
# ==========================================
func _spawn_melee_hit(target_pos: Vector2):
	var vfx_node = Node2D.new()
	vfx_node.z_index = 65
	var scene_root = get_tree().current_scene
	if scene_root: scene_root.add_child(vfx_node)
	else: return

	# Create a sharp "X" shape out of two slashes
	for i in range(2):
		var slash = ColorRect.new()
		slash.color = Color(1.0, 1.0, 1.0, 0.95)
		slash.size = Vector2(100, 4)
		slash.position = target_pos - Vector2(50, 2)
		slash.pivot_offset = Vector2(50, 2)
		slash.rotation = randf_range(-0.8, -0.4) if i == 0 else randf_range(0.4, 0.8)
		slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vfx_node.add_child(slash)

		var t = get_tree().create_tween()
		t.set_parallel(true)
		t.tween_property(slash, "scale:x", 1.4, 0.15)
		t.tween_property(slash, "scale:y", 0.1, 0.15)
		t.tween_property(slash, "color", Color(1, 1, 1, 0), 0.15)

	# A quick spherical impact burst in the center
	var burst = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.8)
	style.corner_radius_top_left = 50
	style.corner_radius_top_right = 50
	style.corner_radius_bottom_left = 50
	style.corner_radius_bottom_right = 50
	burst.add_theme_stylebox_override("panel", style)
	burst.size = Vector2(20, 20)
	burst.position = target_pos - Vector2(10, 10)
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vfx_node.add_child(burst)

	var t2 = get_tree().create_tween()
	t2.set_parallel(true)
	t2.tween_property(burst, "size", Vector2(60, 60), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t2.tween_property(burst, "position", target_pos - Vector2(30, 30), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t2.tween_property(style, "bg_color", Color(1, 1, 1, 0), 0.15)

	await get_tree().create_timer(0.2).timeout
	vfx_node.queue_free()

# ==========================================
# 5. PROCEDURAL SHADOW / DARKNESS
# ==========================================
func _spawn_shadow(target_pos: Vector2):
	var vfx_node = Node2D.new()
	vfx_node.z_index = 65
	var scene_root = get_tree().current_scene
	if scene_root: scene_root.add_child(vfx_node)
	else: return

	# Expanding pool of darkness
	var abyss = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.0, 0.2, 0.9) # Deep Void Purple
	style.corner_radius_top_left = 100
	style.corner_radius_top_right = 100
	style.corner_radius_bottom_left = 100
	style.corner_radius_bottom_right = 100
	abyss.add_theme_stylebox_override("panel", style)
	abyss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	abyss.size = Vector2(10, 10)
	abyss.position = target_pos - Vector2(5, 5)
	vfx_node.add_child(abyss)

	var t = get_tree().create_tween()
	t.set_parallel(true)
	var exp_size = 90
	t.tween_property(abyss, "size", Vector2(exp_size, exp_size), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(abyss, "position", target_pos - Vector2(exp_size/2.0, exp_size/2.0), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.chain().tween_property(abyss, "modulate", Color(1, 1, 1, 0), 0.4)

	# Erratic black particles pulling inwards, then exploding out
	for i in range(8):
		var dark_matter = ColorRect.new()
		dark_matter.color = Color(0.0, 0.0, 0.0, 0.8)
		dark_matter.size = Vector2(8, 8)
		
		# Start slightly offset
		var angle = randf_range(0, TAU)
		var dir = Vector2(cos(angle), sin(angle))
		dark_matter.position = target_pos + dir * 20
		dark_matter.rotation = randf_range(0, TAU)
		vfx_node.add_child(dark_matter)

		var dm_t = get_tree().create_tween()
		dm_t.set_parallel(true)
		dm_t.tween_property(dark_matter, "position", target_pos + dir * randf_range(50, 90), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		dm_t.tween_property(dark_matter, "rotation", randf_range(-3, 3), 0.5)
		dm_t.tween_property(dark_matter, "color", Color(0, 0, 0, 0), 0.5)

	await get_tree().create_timer(0.7).timeout
	vfx_node.queue_free()

# ==========================================
# 6. PROCEDURAL LIGHT / HOLY
# ==========================================
func _spawn_light(target_pos: Vector2):
	var vfx_node = Node2D.new()
	vfx_node.z_index = 65
	var scene_root = get_tree().current_scene
	if scene_root: scene_root.add_child(vfx_node)
	else: return

	# The Holy Cross (Vertical and Horizontal Beams)
	for i in range(2):
		var beam = ColorRect.new()
		beam.color = Color(1.0, 0.95, 0.6, 1.0) # Blinding Gold/White
		beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if i == 0: # Vertical
			beam.size = Vector2(6, 200)
			beam.position = target_pos - Vector2(3, 100)
			beam.pivot_offset = Vector2(3, 100)
		else: # Horizontal
			beam.size = Vector2(200, 6)
			beam.position = target_pos - Vector2(100, 3)
			beam.pivot_offset = Vector2(100, 3)
			
		vfx_node.add_child(beam)

		var t = get_tree().create_tween()
		t.set_parallel(true)
		if i == 0: t.tween_property(beam, "scale:x", 0.0, 0.4)
		else: t.tween_property(beam, "scale:y", 0.0, 0.4)
		t.tween_property(beam, "color", Color(1.0, 0.8, 0.0, 0.0), 0.4)

	# A blinding center flash
	var flash = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	style.corner_radius_top_left = 100
	style.corner_radius_top_right = 100
	style.corner_radius_bottom_left = 100
	style.corner_radius_bottom_right = 100
	flash.add_theme_stylebox_override("panel", style)
	flash.size = Vector2(10, 10)
	flash.position = target_pos - Vector2(5, 5)
	vfx_node.add_child(flash)
	
	var flash_t = get_tree().create_tween()
	flash_t.set_parallel(true)
	flash_t.tween_property(flash, "size", Vector2(150, 150), 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	flash_t.tween_property(flash, "position", target_pos - Vector2(75, 75), 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	flash_t.tween_property(style, "bg_color", Color(1.0, 0.9, 0.2, 0.0), 0.3)

	await get_tree().create_timer(0.4).timeout
	vfx_node.queue_free()

# ==========================================
# 7. PROCEDURAL FIRE
# ==========================================
func _spawn_fire(target_pos: Vector2):
	var vfx_node = Node2D.new()
	vfx_node.z_index = 65
	var scene_root = get_tree().current_scene
	if scene_root: scene_root.add_child(vfx_node)
	else: return

	# Drifting flames rising upwards
	for i in range(7):
		var flame = Panel.new()
		var style = StyleBoxFlat.new()
		
		# Mix of Red, Orange, and Yellow
		var fire_colors = [Color(1.0, 0.2, 0.0, 0.9), Color(1.0, 0.5, 0.0, 0.9), Color(1.0, 0.8, 0.1, 0.9)]
		style.bg_color = fire_colors.pick_random()
		style.corner_radius_top_left = 50
		style.corner_radius_top_right = 50
		style.corner_radius_bottom_left = 50
		style.corner_radius_bottom_right = 50
		flame.add_theme_stylebox_override("panel", style)
		flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var f_size = randf_range(20, 50)
		flame.size = Vector2(f_size, f_size)
		
		# Spawn slightly randomly around target
		var offset = Vector2(randf_range(-25, 25), randf_range(-10, 20))
		flame.position = target_pos + offset - Vector2(f_size/2.0, f_size/2.0)
		vfx_node.add_child(flame)

		var t = get_tree().create_tween()
		t.set_parallel(true)
		
		# Flames drift UP and shrink
		var drift_up = randf_range(40, 80)
		t.tween_property(flame, "position:y", flame.position.y - drift_up, 0.4).set_delay(randf_range(0.0, 0.1))
		t.tween_property(flame, "size", Vector2(5, 5), 0.4).set_delay(randf_range(0.0, 0.1))
		
		# Adjust position while shrinking to keep it centered
		t.tween_property(flame, "position:x", flame.position.x + (f_size/2.0), 0.4).set_delay(randf_range(0.0, 0.1))
		t.tween_property(style, "bg_color", Color(0.2, 0.2, 0.2, 0.0), 0.4).set_delay(randf_range(0.0, 0.1))

	await get_tree().create_timer(0.6).timeout
	vfx_node.queue_free()

# ==========================================
# 8. PROCEDURAL FREEZE / ICE
# ==========================================
func _spawn_freeze(target_pos: Vector2):
	var vfx_node = Node2D.new()
	vfx_node.z_index = 65
	var scene_root = get_tree().current_scene
	if scene_root: scene_root.add_child(vfx_node)
	else: return

	# Cyan Frost Aura
	var frost = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.4, 0.9, 1.0, 0.6)
	style.corner_radius_top_left = 100
	style.corner_radius_top_right = 100
	style.corner_radius_bottom_left = 100
	style.corner_radius_bottom_right = 100
	frost.add_theme_stylebox_override("panel", style)
	frost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frost.size = Vector2(80, 80)
	frost.position = target_pos - Vector2(40, 40)
	vfx_node.add_child(frost)
	
	var frost_t = get_tree().create_tween()
	frost_t.tween_property(style, "bg_color", Color(0.8, 1.0, 1.0, 0.0), 0.4)

	# Jagged Ice Spikes erupting outwards
	for i in range(5):
		var spike = Polygon2D.new()
		spike.color = Color(0.7, 0.95, 1.0, 0.9)
		
		# Draw a sharp crystalline triangle
		spike.polygon = PackedVector2Array([
			Vector2(0, -10), # Left base
			Vector2(0, 10),  # Right base
			Vector2(randf_range(40, 70), 0) # Sharp tip pointing right
		])
		
		spike.position = target_pos
		# Rotate outward evenly like a starburst
		spike.rotation = (TAU / 5) * i + randf_range(-0.2, 0.2)
		vfx_node.add_child(spike)
		
		var spike_t = get_tree().create_tween()
		spike_t.set_parallel(true)
		var dir = Vector2(cos(spike.rotation), sin(spike.rotation))
		
		# Spikes slide out then dissolve
		spike_t.tween_property(spike, "position", target_pos + dir * 15, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		spike_t.tween_property(spike, "color", Color(1.0, 1.0, 1.0, 0.0), 0.2).set_delay(0.2)

	await get_tree().create_timer(0.5).timeout
	vfx_node.queue_free()

# ==========================================
# 9. PROCEDURAL BRIMSTONE FIRE
# ==========================================
func _spawn_brimstone(target_pos: Vector2):
	var vfx_node = Node2D.new()
	vfx_node.z_index = 65
	var scene_root = get_tree().current_scene
	if scene_root: scene_root.add_child(vfx_node)
	else: return

	# The Calamitas Core (Pitch Black inner circle, Thick Crimson red border)
	var core = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.0, 0.0, 1.0) # Near Black
	style.border_color = Color(0.9, 0.0, 0.1, 1.0) # Blood Red
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 6
	style.corner_radius_top_left = 100
	style.corner_radius_top_right = 100
	style.corner_radius_bottom_left = 100
	style.corner_radius_bottom_right = 100
	core.add_theme_stylebox_override("panel", style)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	core.size = Vector2(20, 20)
	core.position = target_pos - Vector2(10, 10)
	vfx_node.add_child(core)

	var core_t = get_tree().create_tween()
	core_t.set_parallel(true)
	var max_size = 130
	# Violently expands
	core_t.tween_property(core, "size", Vector2(max_size, max_size), 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	core_t.tween_property(core, "position", target_pos - Vector2(max_size/2.0, max_size/2.0), 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	# Shrinks back into nothingness
	core_t.chain().tween_property(core, "size", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	core_t.chain().tween_property(core, "position", target_pos, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	core_t.chain().tween_property(style, "border_color", Color(1.0, 0.5, 0.0, 0.0), 0.2) # Flashes to orange as it dies

	# Jagged Brimstone Embers (Red/Orange/Black squares spinning out)
	for i in range(14):
		var ember = ColorRect.new()
		var r = randi() % 3
		if r == 0: ember.color = Color(0.8, 0.0, 0.1, 1.0) # Crimson
		elif r == 1: ember.color = Color(1.0, 0.4, 0.0, 1.0) # Orange
		else: ember.color = Color(0.1, 0.0, 0.0, 0.9) # Black/Charcoal
		
		ember.size = Vector2(randf_range(6, 12), randf_range(6, 12))
		ember.position = target_pos - (ember.size / 2.0)
		ember.rotation = randf_range(0, TAU)
		vfx_node.add_child(ember)

		var ember_t = get_tree().create_tween()
		ember_t.set_parallel(true)
		var angle = randf_range(0, TAU)
		var dir = Vector2(cos(angle), sin(angle))
		var dist = randf_range(70, 140)
		
		# Embers fly out erratically
		ember_t.tween_property(ember, "position", target_pos + dir * dist, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		ember_t.tween_property(ember, "rotation", randf_range(-5, 5), 0.4)
		ember_t.tween_property(ember, "scale", Vector2(0.1, 0.1), 0.4).set_delay(0.1)
		ember_t.tween_property(ember, "color", Color(0, 0, 0, 0), 0.4)

	await get_tree().create_timer(0.6).timeout
	vfx_node.queue_free()
