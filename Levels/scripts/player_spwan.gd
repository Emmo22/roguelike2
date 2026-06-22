extends Node2D


func _ready() -> void:
	visible = false
	PlayerManager.set_player_position.call_deferred(global_position)
