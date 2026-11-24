extends BaseAbility

@export var attack_boost: int = 20

func execute(user_card, target_card, manager) -> bool:
	# Safety check in case it gets clicked anyway
	if has_been_used:
		manager.log_event(user_card.card_name + "'s " + ability_name + " has already been used!")
		return false
		
	if current_cooldown > 0:
		manager.log_event(ability_name + " is on cooldown for " + str(current_cooldown) + " turns!")
		return false

	# --- USE THE HELPER FUNCTION! ---
	user_card.buff_attack(attack_boost) 
	
	manager.log_event("🔥 OVERCLOCK! " + user_card.card_name + " power surges!")
	
	current_cooldown = max_cooldown
	
	# --- ONE-TIME USE TRIGGER ---
	if is_one_time_use:
		has_been_used = true
		
	return true
