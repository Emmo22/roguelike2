extends Control

const SAVE_PATH = "user://level.json"
const GAME_SCENE = "res://world/game.tscn"

# In a web export the game is served from the same host as the backend, so we
# use relative URLs. In the editor/desktop there is no host, so fall back to
# the local dev server.
static func server_base() -> String:
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("window.location.origin")
	return "http://127.0.0.1:5000"

@onready var upload_url: String = server_base() + "/upload_level"
@onready var get_rooms_url: String = server_base() + "/get_rooms?count=3"

@onready var start_button: Button = $Button
@onready var http_upload: HTTPRequest = $HTTPRequest
@onready var http_get: HTTPRequest = $HTTPGet


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	http_upload.request_completed.connect(_on_upload_completed)


func _on_start_pressed() -> void:
	start_button.disabled = true
	var scene = get_tree().current_scene
	var level_node: Node = scene.get_node("Level")
	var custom_walls: TileMapLayer = scene.get_node("Level/Room00/CustomWalls")

	var data = _build_data(custom_walls, level_node)
	_save_local(data)
	_upload(data)

	# Fetch 3 random rooms from the server for rooms 2-4.
	var others = await _fetch_rooms()

	print("[ItemSelect] fetched ", others.size(), " server rooms. Total session rooms: ", 1 + others.size())
	print("[ItemSelect] is_web=", OS.has_feature("web"), " upload_url=", upload_url, " get_rooms_url=", get_rooms_url)

	GameSession.start_session(data, others)
	LevelManager.load_new_level(GAME_SCENE, "", Vector2.ZERO)


func _fetch_rooms() -> Array:
	print("[ItemSelect] requesting rooms from: ", get_rooms_url)
	var err = http_get.request(get_rooms_url)
	if err != OK:
		push_warning("Could not start room request (err " + str(err) + "). Playing only your room.")
		return []
	var result = await http_get.request_completed
	# result = [result_code, response_code, headers, body]
	print("[ItemSelect] /get_rooms response: result=", result[0], " http_code=", result[1])
	if result[0] != HTTPRequest.RESULT_SUCCESS or result[1] != 200:
		push_warning("Could not fetch rooms from server (code " + str(result[1]) + "). Playing only your room.")
		return []

	var body_text = result[3].get_string_from_utf8()
	var parsed = JSON.parse_string(body_text)
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("Server returned unexpected room data. Body: " + body_text.left(200))
		return []
	return parsed


func _on_upload_completed(result: int, _code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		push_warning("Level upload failed - server may not be running.")


func _build_data(custom_walls: TileMapLayer, level_node: Node) -> Dictionary:
	var walls = []
	for cell in custom_walls.get_used_cells():
		var coords = custom_walls.get_cell_atlas_coords(cell)
		walls.append({ "x": cell.x, "y": cell.y, "tile": coords.x })

	var enemies = []
	for child in level_node.get_children():
		if child is Enemy:
			enemies.append({
				"x": child.global_position.x,
				"y": child.global_position.y,
				"scene": child.scene_file_path
			})

	return { "walls": walls, "enemies": enemies }


func _save_local(data: Dictionary) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file: " + str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("Level saved locally: ", ProjectSettings.globalize_path(SAVE_PATH))


func _upload(data: Dictionary) -> void:
	var body = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	http_upload.request(upload_url, headers, HTTPClient.METHOD_POST, body)
	print("Level uploaded to server.")
