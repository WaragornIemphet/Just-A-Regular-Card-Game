extends Node

var hover_player: AudioStreamPlayer
var click_player: AudioStreamPlayer

func _ready():
	# 1. Create the Hover Sound Player
	hover_player = AudioStreamPlayer.new()
	hover_player.bus = "UI" # Routes through your new UI slider!
	hover_player.stream = load("res://audio/ui/buttonclick.wav") # <--- CHANGE THIS PATH
	add_child(hover_player)

	# 2. Create the Click Sound Player
	click_player = AudioStreamPlayer.new()
	click_player.bus = "UI" # Routes through your new UI slider!
	click_player.stream = load("res://audio/ui/buttonclickrelease.wav") # <--- CHANGE THIS PATH
	add_child(click_player)

	# 3. Tell Godot to run a function every time ANY node is added to the game
	get_tree().node_added.connect(_on_node_added)
	
	# 4. Catch any buttons that already exist when the game boots up
	_connect_buttons_recursive(get_tree().root)

# ==========================================
# AUTOMATIC WIRING
# ==========================================
func _on_node_added(node: Node):
	# If the new thing spawning is a Button (or TextureButton), wire it!
	if node is BaseButton:
		_connect_button(node)

func _connect_buttons_recursive(node: Node):
	if node is BaseButton:
		_connect_button(node)
	for child in node.get_children():
		_connect_buttons_recursive(child)

func _connect_button(btn: BaseButton):
	# Safely connect the hover and click signals without duplicating them
	if not btn.mouse_entered.is_connected(play_hover):
		btn.mouse_entered.connect(play_hover)
	
	if not btn.pressed.is_connected(play_click):
		btn.pressed.connect(play_click)

# ==========================================
# SOUND PLAYBACK
# ==========================================
func play_hover():
	# Optional logic: Add a tiny pitch variation so repeating hovers sound natural
	hover_player.pitch_scale = randf_range(0.95, 1.05)
	hover_player.play()

func play_click():
	click_player.pitch_scale = randf_range(0.95, 1.05)
	click_player.play()
