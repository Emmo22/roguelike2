import os
import json
import random
import uuid
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS

app = Flask(__name__, static_folder="game")
CORS(app)


@app.after_request
def add_headers(response):
    response.headers["Cross-Origin-Embedder-Policy"] = "require-corp"
    response.headers["Cross-Origin-Opener-Policy"] = "same-origin"
    return response


@app.route("/")
@app.route("/<path:filename>")
def game_files(filename="index.html"):
    return send_from_directory("game", filename)

LEVELS_DIR = os.path.join(os.path.dirname(__file__), "levels")
os.makedirs(LEVELS_DIR, exist_ok=True)


@app.route("/upload_level", methods=["POST"])
def upload_level():
    data = request.get_json()
    if data is None:
        return jsonify({"error": "No JSON received"}), 400

    level_id = str(uuid.uuid4())
    path = os.path.join(LEVELS_DIR, f"{level_id}.json")
    with open(path, "w") as f:
        json.dump(data, f, indent="\t")

    print(f"Level saved: {level_id}")
    return jsonify({"id": level_id}), 200


@app.route("/get_game", methods=["GET"])
def get_game():
    return get_rooms_response(4)


@app.route("/get_rooms", methods=["GET"])
def get_rooms():
    count = request.args.get("count", default=3, type=int)
    return get_rooms_response(count)


def get_rooms_response(count):
    files = [f for f in os.listdir(LEVELS_DIR) if f.endswith(".json")]
    available = min(count, len(files))
    chosen = random.sample(files, available)
    levels = []
    for filename in chosen:
        with open(os.path.join(LEVELS_DIR, filename)) as f:
            levels.append(json.load(f))
    return jsonify(levels), 200


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
