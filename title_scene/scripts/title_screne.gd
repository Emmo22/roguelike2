extends Node

const START_LEVEL : String = "res://world/world.tscn"
const LEVEL_EDITOR : String = "res://LevelEditor/LevelEditor.tscn"

@export var music : AudioStream
@export var button_focus_audio : AudioStream
@export var button_press_audio : AudioStream


@onready var button_tutorial: Button = $CanvasLayer/Control/Button_tutorial
@onready var button_builder: Button = $CanvasLayer/Control/Button_builder
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D




func _ready() -> void:
	# Re-apply the title state after LevelManager finishes loading us,
	# because load_new_level un-hides the player and un-pauses the tree.
	LevelManager.level_loaded.connect(enter_title_state)
	enter_title_state()
	setup_title_screne()


func enter_title_state() -> void:
	get_tree().paused = true
	PlayerManager.player.visible = false
	PlayerHud.visible = false


func setup_title_screne() -> void:
	button_tutorial.pressed.connect(start_tutorial)
	button_builder.pressed.connect(start_level_editor)

	button_tutorial.focus_entered.connect(play_audio.bind(button_focus_audio))
	button_builder.focus_entered.connect(play_audio.bind(button_focus_audio))
	


func start_tutorial() -> void:
	play_audio(button_press_audio)
	PlayerHud.visible = true
	LevelManager.load_new_level(START_LEVEL, "", Vector2.ZERO)


func start_level_editor() -> void:
	play_audio(button_press_audio)
	PlayerHud.visible = true
	LevelManager.load_new_level(LEVEL_EDITOR, "", Vector2.ZERO)



func play_audio(_a : AudioStream) -> void:
	audio_stream_player_2d.stream = _a
	audio_stream_player_2d.play()
	
