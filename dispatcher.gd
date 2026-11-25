extends "res://scripts/cards.gd" 




func apply_skin(skin_id: int):
	if skin_id == 0:
		return
		
	elif skin_id == 1:
		texture = load("res://towers/skins/dispatcher2.png")
