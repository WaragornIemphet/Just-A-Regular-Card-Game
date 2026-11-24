extends BasePassive

# The combat engine will specifically look for this variable!
var can_act_from_reserve: bool = true

# Optional: Add a UI name so it shows up neatly in the [ SKILLS ] list
func _ready():
	name = "Indirect Fire"
