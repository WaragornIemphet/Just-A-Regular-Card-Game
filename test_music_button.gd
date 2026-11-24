extends Button

func _ready():
	# Connect the button press to play the sound
	pressed.connect(_on_test_button_pressed)
	text = "Test Music Bus"

func _on_test_button_pressed():
	# 1. Create a brand new audio player in the code
	var test_player = AudioStreamPlayer.new()
	
	# 2. CRUCIAL: Route it specifically to the "Music" bus!
	test_player.bus = "Music"
	
	# 3. Load a sound file from your project
	var test_sound = load("res://audio/strategy.mp3")
	test_player.stream = test_sound
	
	# 4. Add it to the scene and hit play
	add_child(test_player)
	test_player.play()
	
	# 5. Automatically delete the player when the song finishes so it doesn't leak memory
	test_player.finished.connect(test_player.queue_free)
	
	print("🎵 Playing test sound on the Music bus!")
