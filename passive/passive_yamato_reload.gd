extends Node

var reload_turns_left: int = 0
@onready var card = get_parent().get_parent()

func trigger_attack(target, damage):
	
	reload_turns_left = 3

func trigger_turn_start():
	if reload_turns_left > 0:
		
		
		card.show_floating_text("Reloading... (" + str(reload_turns_left) + ")", Color.GRAY)
		
		
		card.exhaust() 
		
		
		reload_turns_left -= 1
