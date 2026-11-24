extends BasePassive
class_name PassiveApplyStatus

# --- INSPECTOR SETTINGS ---
@export_enum("poison", "burn", "curse", "corrosion", "stun", "freeze", "disabled", "bleed", "wet", "confusion", "blind", "shell shocked", "slow") var status_to_apply: String = "poison"

@export var duration: int = 2 
@export var potency: int = 1  # How much DMG it deals (or how much DEF corrosion shreds)

# ==========================================
func on_attack(target: Node, damage: int):
	if target.debuffs != null:
		if status_to_apply == "poison":
			target.debuffs.apply_poison(duration, potency)
		elif status_to_apply == "burn":
			target.debuffs.apply_burn(duration, potency)
		elif status_to_apply == "curse":
			target.debuffs.apply_curse(duration, potency)
		elif status_to_apply == "corrosion":
			# Corrosion doesn't use duration, it permanently shreds stats based on potency!
			target.debuffs.apply_corrosion(potency)
			
		# --- NEW CROWD CONTROL EFFECTS ---
		elif status_to_apply == "stun":
			target.debuffs.apply_stun(duration)
		elif status_to_apply == "freeze":
			target.debuffs.apply_freeze(duration)
		elif status_to_apply == "disabled":
			target.debuffs.apply_disabled(duration)
		elif status_to_apply == "wet":
			target.debuffs.apply_wet(duration)
		elif status_to_apply == "confusion":
			target.debuffs.apply_confusion(duration)
		elif status_to_apply == "bleed":
			target.debuffs.apply_bleed(duration)
		elif status_to_apply == "blind":
			target.debuffs.apply_blind(duration)
		elif status_to_apply == "slow":
			target.debuffs.apply_slow(duration, potency)
		elif status_to_apply == "shell shocked":
			target.debuffs.apply_shell_shocked(duration)
