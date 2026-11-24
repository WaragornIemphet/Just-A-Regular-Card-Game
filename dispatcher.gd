extends "res://scripts/cards.gd" 



# DISPATCHER SKIN SYSTEM

func apply_skin(skin_id: int):
	# 0 is the default
	if skin_id == 0:
		return
		
	# Skin 1
	elif skin_id == 1:
		texture = load("res://towers/skins/dispatcher2.png")
