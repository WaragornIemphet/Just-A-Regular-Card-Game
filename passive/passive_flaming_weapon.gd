extends BasePassive
class_name PassiveFlamingWeapon

func _ready():
	await get_tree().process_frame 
	
	if is_active:
		card.outgoing_damage_type = "burn"
		
