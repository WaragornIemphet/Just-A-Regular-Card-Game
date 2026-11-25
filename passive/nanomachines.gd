extends BasePassive

@export var phase2_texture: Texture2D
@export var transform_hp_threshold: int = 250 # <--- Easily change this in the Inspector!
var has_transformed: bool = false

func modifyIncomingDamage(baseDamage: int, damageType: String, attacker: Node) -> int:
	var aTags = []
	
	if is_instance_valid(attacker) and "tags" in attacker:
		for t in attacker.tags:
			aTags.append(str(t).to_lower().strip_edges())
			
	if aTags.has("magic") or aTags.has("holy") or aTags.has("light"):
		return baseDamage
		
	var main_scene = card.get_tree().current_scene
		
	if damageType == "pierce":
		if main_scene != null and main_scene.has_method("log_event"):
			main_scene.log_event(":shield: NANOMACHINES: Armor Piercing deals half damage!")
		return int(baseDamage * 0.5)
		
	if main_scene != null and main_scene.has_method("log_event"):
		main_scene.log_event(":shield: NANOMACHINES, SON: Physical attacks can't hurt him!")
		
	return 0


func on_take_damage(_amount: int, _damage_type: String, _attacker: Node):
	if has_transformed or not is_instance_valid(card):
		return
		
	if card.health <= transform_hp_threshold:
		has_transformed = true # <--- Permanently locks the trigger!
		trigger_phase_two()


func trigger_phase_two():
	if phase2_texture != null:
		card.texture = phase2_texture
		
	card.attack_power *= 2
	
	card.show_floating_text("NANOMACHINES, SON! ATK x2", Color.RED)
	if card.has_method("buff_animation"):
		card.buff_animation()
		
	var main_scene = card.get_tree().current_scene
	if main_scene != null and main_scene.has_method("log_event"):
		main_scene.log_event(":boom: ENRAGED! Senator Armstrong's Nanomachines harden! ATK doubled to " + str(card.attack_power) + "!")
