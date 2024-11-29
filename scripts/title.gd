extends Control

@onready var single_player_button: Button = $ButtonContainer/SinglePlayerButton
@onready var multiplayer_button: Button = $ButtonContainer/MultiplayerButton
@onready var team_battle_button: Button = $ButtonContainer/TeamBattleButton
@onready var ranked_button: Button = $ButtonContainer/RankedButton

func _ready():
	# Connect button signals
	single_player_button.pressed.connect(_on_single_player_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	team_battle_button.pressed.connect(_on_team_battle_pressed)
	ranked_button.pressed.connect(_on_ranked_pressed)
	
	# Initialize Steam if available
	if Engine.has_singleton("Steam"):
		var steam = Engine.get_singleton("Steam")
		if !steam.steamInit():
			print("Failed to initialize Steam")
			# Disable multiplayer-related buttons
			multiplayer_button.disabled = true
			team_battle_button.disabled = true
			ranked_button.disabled = true
	else:
		# If Steam singleton isn't available, disable multiplayer buttons
		multiplayer_button.disabled = true
		team_battle_button.disabled = true
		ranked_button.disabled = true

func _on_single_player_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_multiplayer_pressed():
	get_tree().change_scene_to_file("res://scenes/multiplayer_lobby.tscn")

func _on_team_battle_pressed():
	# To be implemented later
	pass

func _on_ranked_pressed():
	# To be implemented later
	pass
