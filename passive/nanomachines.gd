extends BasePassive

# --- PHASE 2 INSPECTOR SETTINGS ---
@export var phase2_texture: Texture2D
@export var transform_hp_threshold: int = 250 # <--- Easily change this in the Inspector!
var has_transformed: bool = false

# ==========================================
# 1. DAMAGE INTERCEPTION (Immunities & Resistances)
# ==========================================
func modifyIncomingDamage(baseDamage: int, damageType: String, attacker: Node) -> int:
	var aTags = []
	
	# Grab attacker tags safely if an attacker exists
	if is_instance_valid(attacker) and "tags" in attacker:
		for t in attacker.tags:
			aTags.append(str(t).to_lower().strip_edges())
			
	# 1. Magic, Holy, or Light bypasses Nanomachines completely
	if aTags.has("magic") or aTags.has("holy") or aTags.has("light"):
		return baseDamage
		
	var main_scene = card.get_tree().current_scene
		
	# 2. Armor Piercing weapons deal 50% damage
	if damageType == "pierce":
		if main_scene != null and main_scene.has_method("log_event"):
			main_scene.log_event(":shield: NANOMACHINES: Armor Piercing deals half damage!")
		return int(baseDamage * 0.5)
		
	# 3. Everything else (Normal, Physical, Poison, Burn, Splash) is completely blocked
	if main_scene != null and main_scene.has_method("log_event"):
		main_scene.log_event(":shield: NANOMACHINES, SON: Physical attacks can't hurt him!")
		
	return 0

# ... (modifyIncomingDamage stays exactly the same) ...

# ==========================================
# 2. PHASE 2 TRANSFORMATION
# ==========================================
func on_take_damage(_amount: int, _damage_type: String, _attacker: Node):
	# 1. If he already transformed once this match, do nothing!
	if has_transformed or not is_instance_valid(card):
		return
		
	# 2. Check if health dropped to the threshold (250) or below
	if card.health <= transform_hp_threshold:
		has_transformed = true # <--- Permanently locks the trigger!
		trigger_phase_two()


func trigger_phase_two():
	# 1. Swap Card Sprite Image
	if phase2_texture != null:
		card.texture = phase2_texture
		
	# 2. Double Attack Power (x2)
	card.attack_power *= 2
	
	# 3. Visual & UI Feedback
	card.show_floating_text("NANOMACHINES, SON! ATK x2", Color.RED)
	if card.has_method("buff_animation"):
		card.buff_animation()
		
	# 4. Log Event to Console
	var main_scene = card.get_tree().current_scene
	if main_scene != null and main_scene.has_method("log_event"):
		main_scene.log_event(":boom: ENRAGED! Senator Armstrong's Nanomachines harden! ATK doubled to " + str(card.attack_power) + "!")
