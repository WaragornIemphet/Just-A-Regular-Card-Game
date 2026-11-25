extends Button

func _ready():
	pressed.connect(_on_test_button_pressed)
	text = "Test Music Bus"

func _on_test_button_pressed():
	var test_player = AudioStreamPlayer.new()
	
	test_player.bus = "Music"
	
	var test_sound = load("res://audio/strategy.mp3")
	test_player.stream = test_sound
	
	add_child(test_player)
	test_player.play()
	
	test_player.finished.connect(test_player.queue_free)
	
	print("🎵 Playing test sound on the Music bus!")
