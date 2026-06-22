extends Node2D

var can_place = true
@onready var level: Level = $"../Level"
@onready var boden: TileMapLayer = $"../Level/Room00/Boden"
@onready var waende_base: TileMapLayer = $"../Level/Room00/Waende_base"
@onready var door: TileMapLayer = $"../Level/Room00/door"
@onready var custom_walls: TileMapLayer = $"../Level/Room00/CustomWalls"
@onready var cursor_sprite: Sprite2D = $Sprite2D

var current_item


func _ready() -> void:
	PlayerManager.player.set_physics_process(false)
	PlayerManager.player.visible = true
	PlayerHud.visible = false


func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()

	if LevelManager.skip_next_click and Input.is_action_just_pressed("mb_left"):
		LevelManager.skip_next_click = false
		return

	if Input.is_action_just_pressed("mb_right") and not LevelManager.place_tile:
		_try_delete_enemy()
	elif LevelManager.place_tile:
		_handle_wall_paint()
	elif current_item != null and can_place:
		if Input.is_action_just_pressed("mb_left"):
			if _is_on_floor():
				var new_item = current_item.instantiate()
				level.add_child(new_item)
				new_item.global_position = get_global_mouse_position()
				new_item.set_physics_process(false)
				new_item.get_node("EnemyStateMachine").process_mode = Node.PROCESS_MODE_DISABLED
				cursor_sprite.texture = null
				current_item = null


func _handle_wall_paint() -> void:
	var mouse_pos = get_global_mouse_position()
	var paint_cell = custom_walls.local_to_map(custom_walls.to_local(mouse_pos))

	if Input.is_action_just_pressed("mb_left"):
		if _is_on_floor():
			var below = paint_cell + Vector2i(0, 1)
			var is_above_ceiling = custom_walls.get_cell_atlas_coords(below) == Vector2i(4, 0)
			var is_on_ceiling = custom_walls.get_cell_atlas_coords(paint_cell) == Vector2i(4, 0)
			if is_above_ceiling or is_on_ceiling:
				custom_walls.set_cell(paint_cell, 0, Vector2i(4, 0))
			else:
				custom_walls.set_cell(paint_cell, 0, Vector2i(randi_range(0, 3), 0))
				_place_ceiling(paint_cell)

	elif Input.is_action_just_pressed("mb_right"):
		var above = paint_cell + Vector2i(0, -1)
		var below = paint_cell + Vector2i(0, 1)
		var is_ceiling = custom_walls.get_cell_atlas_coords(paint_cell) == Vector2i(4, 0)
		custom_walls.erase_cell(paint_cell)
		if is_ceiling:
			custom_walls.erase_cell(below)
			_enforce_ceiling(below + Vector2i(0, 1))
			_enforce_wall(above)
		else:
			if custom_walls.get_cell_atlas_coords(above) == Vector2i(4, 0):
				custom_walls.erase_cell(above)
			_enforce_wall(above + Vector2i(0, -1))


func _place_ceiling(wall_cell: Vector2i) -> void:
	var above = wall_cell + Vector2i(0, -1)
	custom_walls.set_cell(above, 0, Vector2i(4, 0))


func _enforce_ceiling(cell: Vector2i) -> void:
	var src = custom_walls.get_cell_source_id(cell)
	var coords = custom_walls.get_cell_atlas_coords(cell)
	if src == -1 or coords == Vector2i(4, 0):
		return
	var above = cell + Vector2i(0, -1)
	if custom_walls.get_cell_atlas_coords(above) != Vector2i(4, 0):
		custom_walls.set_cell(above, 0, Vector2i(4, 0))


func _enforce_wall(cell: Vector2i) -> void:
	if custom_walls.get_cell_atlas_coords(cell) != Vector2i(4, 0):
		return
	var below = cell + Vector2i(0, 1)
	if custom_walls.get_cell_source_id(below) == -1:
		custom_walls.set_cell(below, 0, Vector2i(randi_range(0, 3), 0))


func _try_delete_enemy() -> void:
	var mouse_pos = get_global_mouse_position()
	for child in level.get_children():
		if child is Enemy and child.global_position.distance_to(mouse_pos) < 32.0:
			child.queue_free()
			return


func _is_on_floor() -> bool:
	var mouse_pos = get_global_mouse_position()
	var boden_cell = boden.local_to_map(boden.to_local(mouse_pos))
	var wall_cell = waende_base.local_to_map(waende_base.to_local(mouse_pos))
	var door_cell = door.local_to_map(door.to_local(mouse_pos))
	return boden.get_cell_source_id(boden_cell) != -1 \
		and waende_base.get_cell_source_id(wall_cell) == -1 \
		and door.get_cell_source_id(door_cell) == -1
