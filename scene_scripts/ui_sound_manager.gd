extends Node

var hover_player: AudioStreamPlayer
var click_player: AudioStreamPlayer

func _ready():
	hover_player = AudioStreamPlayer.new()
	hover_player.bus = "UI" # Routes through your new UI slider!
	hover_player.stream = load("res://audio/ui/buttonclick.wav") # <--- CHANGE THIS PATH
	add_child(hover_player)

	click_player = AudioStreamPlayer.new()
	click_player.bus = "UI" # Routes through your new UI slider!
	click_player.stream = load("res://audio/ui/buttonclickrelease.wav") # <--- CHANGE THIS PATH
	add_child(click_player)

	get_tree().node_added.connect(_on_node_added)
	
	_connect_buttons_recursive(get_tree().root)

func _on_node_added(node: Node):
	if node is BaseButton:
		_connect_button(node)

func _connect_buttons_recursive(node: Node):
	if node is BaseButton:
		_connect_button(node)
	for child in node.get_children():
		_connect_buttons_recursive(child)

func _connect_button(btn: BaseButton):
	if not btn.mouse_entered.is_connected(play_hover):
		btn.mouse_entered.connect(play_hover)
	
	if not btn.pressed.is_connected(play_click):
		btn.pressed.connect(play_click)

func play_hover():
	hover_player.pitch_scale = randf_range(0.95, 1.05)
	hover_player.play()

func play_click():
	click_player.pitch_scale = randf_range(0.95, 1.05)
	click_player.play()
