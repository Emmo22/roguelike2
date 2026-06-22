extends TextureRect

@export var this_scene : PackedScene
@export var tile : bool = false
@export var tile_id = 0
var object_cursor
var cursor_sprite



func _ready() -> void:
	object_cursor = get_tree().current_scene.get_node("Editor_Object")
	cursor_sprite = object_cursor.get_node("Sprite2D")
	connect("gui_input", _item_clicked)


func _item_clicked(event):
	if event is InputEventMouseButton:
		if !tile:
			if event.is_action_pressed("mb_left"):
				object_cursor.current_item = this_scene
				LevelManager.place_tile = false
				LevelManager.skip_next_click = true
				cursor_sprite.texture = texture
		else:
			if event.is_action_pressed("mb_left"):
				LevelManager.place_tile = true
				LevelManager.current_tile = tile_id
				LevelManager.skip_next_click = true
				cursor_sprite.texture = texture
			
			
