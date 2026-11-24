extends Node
class_name SynergyManager

@onready var manager = get_parent() # Hooks directly into your battlelogic to use the combat log!

# ==========================================
# --- TARGETING VALIDATION (Range & Rules) ---
# ==========================================
func can_target(attacker: Node, target: Node) -> bool:
	var a_tags = _get_lowercase_tags(attacker)
	var t_tags = _get_lowercase_tags(target)
	
	var a_melee = attacker.is_melee if "is_melee" in attacker else false
	var a_ranged = attacker.is_ranged if "is_ranged" in attacker else false
	
	# Exception: Orbital can ALWAYS attack Orbital, regardless of weapon type!
	if "orbital" in a_tags and "orbital" in t_tags:
		return true

	# --- MELEE RESTRICTIONS ---
	if a_melee:
		# Dimensional Melee CANNOT attack Naval
		if "dimensional" in a_tags and "naval" in t_tags:
			return false
			
		# Target is Naval Check
		if "naval" in t_tags:
			# Naval and Air Melee CAN hit Naval
			if "naval" in a_tags or "air" in a_tags:
				pass # Allowed!
			else:
				return false # Default: Ground Melee cannot hit Naval
				
		# Target is Air Check
		elif "air" in t_tags:
			# Air Melee CAN hit Air
			if "air" in a_tags:
				pass # Allowed!
			else:
				return false # Default: Ground/Naval Melee cannot hit Air

	# --- RANGED RESTRICTIONS ---
	if a_ranged:
		# Default: Standard Ranged cannot hit Orbital or Dimensional
		if "orbital" in t_tags or "dimensional" in t_tags:
			return false

	# If it passes all the blocks, the attack is legal!
	return true


func _get_lowercase_tags(card: Node) -> Array:
	var lower_tags = []
	if is_instance_valid(card) and "tags" in card:
		for t in card.tags:
			lower_tags.append(str(t).to_lower().strip_edges())
	return lower_tags

# ==========================================
# --- DAMAGE MULTIPLIERS ---
# ==========================================
func calculate_synergy_damage(attacker: Node, defender: Node, base_damage: int, damage_type: String) -> int:
	var final_damage = float(base_damage)
	
	# SAFELY GRAB TAGS
	var a_tags = _get_lowercase_tags(attacker)
	var d_tags = _get_lowercase_tags(defender)
	var a_ranged = false
	if is_instance_valid(attacker) and "is_ranged" in attacker:
		a_ranged = attacker.is_ranged
	
	
	
	# --- DAMAGE TYPE vs TAGS ---
	if damage_type == "pierce" and d_tags.has("armored"):
		final_damage *= 1.5
		manager.log_event("💥 SYNERGY: Armor-Piercing rounds shredded the Armored defenses!")
		
	if damage_type == "burn" and d_tags.has("humanoid"):
		final_damage *= 1.2
		manager.log_event("💥 SYNERGY: Fire burns soft target!")
		
	if damage_type == "burn" and d_tags.has("plant"):
		final_damage *= 10.0
		manager.log_event("💥 SYNERGY: Fire consumes the plantae!")
	
	# --- TAG vs TAG COMBAT ---
	if a_tags.has("anti-tank") and d_tags.has("mechanical"):
		final_damage *= 2.0
		manager.log_event("⚠️ SYNERGY: Anti-Tank weapon dealt 2x DMG to the Mechanical unit!")
	
	if a_tags.has("anti-tank") and d_tags.has("humanoid"):
		final_damage *= 0.5
		manager.log_event("⚠️ SYNERGY: It's not very effective!")
		
	if a_tags.has("artillery") and (d_tags.has("humanoid") or d_tags.has("infantry")):
		final_damage *= 1.5
		manager.log_event("⚠️ SYNERGY: It's very effective against soft targets!")

	if a_tags.has("naval") and d_tags.has("ground"):
		final_damage *= 1.2
		manager.log_event("🌊 SYNERGY: Naval bombardment gets +20% DMG against Ground!")

	if a_tags.has("naval") and d_tags.has("armored"):
		final_damage *= 0.8
		manager.log_event("🌊 SYNERGY: Naval bombardment gets -20% DMG against Armored!")
		
	# --- DEFENSIVE IMMUNITIES ---
	if damage_type == "poison" and d_tags.has("mechanical"):
		final_damage = 0
		manager.log_event("🛡️ RESIST: Mechanical units are completely immune to Poison!")

	if damage_type == "burn" and d_tags.has("mechanical"):
		final_damage *= 0.25
		manager.log_event("🛡️ RESIST: It's not very effective!")

	# Freeze Melt Logic
	if damage_type == "burn" and defender.debuffs != null and defender.debuffs.freeze_duration > 0:
		final_damage *= 0.5
		manager.log_event("❄️ SYNERGY: Melted!")
	# nanomachines son
	if is_instance_valid(defender) and "passives" in defender and defender.passives != null:
		for passiveNode in defender.passives.get_children():
			if passiveNode.has_method("modifyIncomingDamage"):
				final_damage = passiveNode.modifyIncomingDamage(final_damage, damage_type, attacker)
				
	# --- THE DAMAGE FLOOR ---
	if final_damage > 0.0:
		final_damage = max(1.0, final_damage)

	return int(final_damage)
