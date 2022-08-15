extends Node

signal user_name_found
signal score_submitted
signal got_score
signal got_leaderboard

const identifier_file := "user://user.data"
var game_API_key := ""
var session_token := ""
var user_name := ""
var user_id := ""

# HTTP Request node can only handle one call per node
var auth_http = HTTPRequest.new()
var get_leaderboard_http = HTTPRequest.new()
var set_score_http = HTTPRequest.new()
var get_score_http = HTTPRequest.new()
var set_name_http = HTTPRequest.new()
var get_name_http = HTTPRequest.new()


func _ready():
	# Check if a player profile has been saved
	var file = File.new()
	var user_id = ""
	if file.open(identifier_file, File.READ) == OK:
		user_id = file.get_as_text()
		file.close()
	if user_id.length() < 8:
		user_id = null
	
	authenticate_user(user_id)


func authenticate_user(identifier) -> void:
	# Make a dictionary with our data
	var data := { "game_key": game_API_key, "game_version": "0.1", "development_mode": true }
	
	# If identifier is given, add it to data
	if identifier is String:
		data.player_identifier = identifier
	
	# Add 'Content-Type' header:
	var headers = ["Content-Type: application/json"]
	
	# Create a HTTPRequest node for authentication
	auth_http = HTTPRequest.new()
	add_child(auth_http)
	auth_http.connect("request_completed", self, "_on_authentication_request_completed")
	# Send request
	auth_http.request("https://api.lootlocker.io/game/v2/session/guest", headers, true, HTTPClient.METHOD_POST, to_json(data))


func _on_authentication_request_completed(result, response_code, headers, body) -> void:
	var json = JSON.parse(body.get_string_from_utf8())
	user_id = str(json.result.player_id)
	
	# Save identifier in case it doesn't exist
	var file = File.new()
	file.open(identifier_file, File.WRITE)
	file.store_string(json.result.player_identifier)
	file.close()
	
	# Save session token to variable
	session_token = json.result.session_token
	auth_http.queue_free()
	#  Query the user name that the server has attached to our ID
	_get_user_name()


func _get_user_name() -> void:
	var url = "https://api.lootlocker.io/game/player/name"
	var headers = ["Content-Type: application/json", "x-session-token:"+session_token]
	
	# Create a request node for getting the user name
	get_name_http = HTTPRequest.new()
	add_child(get_name_http)
	get_name_http.connect("request_completed", self, "_on_get_user_name_request_completed")
	# Send request
	get_name_http.request(url, headers, true, HTTPClient.METHOD_GET, "")


func _on_get_user_name_request_completed(result, response_code, headers, body) -> void:
	var json = JSON.parse(body.get_string_from_utf8())
	user_name = json.result.name
	get_name_http.queue_free()
	# Inform the game that we got a user name back
	emit_signal("user_name_found", user_name)


func set_user_name(name : String) -> void:
	var data = { "name": name }
	var url =  "https://api.lootlocker.io/game/player/name"
	var headers = ["Content-Type: application/json", "x-session-token:"+session_token]
	
	# Create a request node
	set_name_http = HTTPRequest.new()
	add_child(set_name_http)
	set_name_http.connect("request_completed", self, "_on_set_user_name_request_completed")
	# Send request
	set_name_http.request(url, headers, true, HTTPClient.METHOD_PATCH, to_json(data))


func _on_set_user_name_request_completed(result, response_code, headers, body) -> void:
	var json = JSON.parse(body.get_string_from_utf8())
	set_name_http.queue_free()


func upload_score(level : String, difficulty : String, score : int) -> void:
	var data := { "score": str(score) }
	var leaderboard_id := level.replace(" ","_") + "-" + difficulty
	var url := "https://api.lootlocker.io/game/leaderboards/"+leaderboard_id+"/submit"
	var headers = ["Content-Type: application/json", "x-session-token:"+session_token]
	
	set_score_http = HTTPRequest.new()
	add_child(set_score_http)
	set_score_http.connect("request_completed", self, "_on_upload_score_request_completed")
	# Send request
	set_score_http.request(url, headers, true, HTTPClient.METHOD_POST, to_json(data))


func _on_upload_score_request_completed(result, response_code, headers, body) -> void:
	var json = JSON.parse(body.get_string_from_utf8())
	var data := { "score": json.result.score, "rank": json.result.rank }
	set_score_http.queue_free()
	emit_signal("score_submitted", data)


func get_score(level : String, difficulty : String) -> void:
	var data := { "score": "0" }
	var leaderboard_id := level.replace(" ","_") + "-" + difficulty
	var url := "https://api.lootlocker.io/game/leaderboards/"+leaderboard_id+"/submit"
	var headers = ["Content-Type: application/json", "x-session-token:"+session_token]
	
	get_score_http = HTTPRequest.new()
	add_child(get_score_http)
	get_score_http.connect("request_completed", self, "_on_get_score_request_completed")
	# Send request
	get_score_http.request(url, headers, true, HTTPClient.METHOD_POST, to_json(data))


func _on_get_score_request_completed(result, response_code, headers, body) -> void:
	var json = JSON.parse(body.get_string_from_utf8())
	var data := { "score": json.result.score, "rank": json.result.rank }
	get_score_http.queue_free()
	emit_signal("got_score", data)


func get_leaderboard_top_10(level : String, difficulty : String) -> void:
	_get_leaderboard(level, difficulty, 0, 10)


func get_leaderboard_range(level : String, difficulty : String, from : int, to : int) -> void:
	_get_leaderboard(level, difficulty, from-1, to)


func get_leaderboard_around(level : String, difficulty : String, radius : int) -> void:
	get_score(level, difficulty)
	var score_info = yield(self, "got_score")
	var start = max(score_info.rank - radius, 0)
	_get_leaderboard(level, difficulty, start-1, 2*radius+1)


func _get_leaderboard(level : String, difficulty : String, start : int, count : int) -> void:
	var leaderboard_id := level.replace(" ","_") + "-" + difficulty
	var url := "https://api.lootlocker.io/game/leaderboards/"+leaderboard_id+"/list?count="+str(count)+"&after="+str(start)
	var headers = ["Content-Type: application/json", "x-session-token:"+session_token]
	
	# Create a request node for getting the leaderboard data
	get_leaderboard_http = HTTPRequest.new()
	add_child(get_leaderboard_http)
	get_leaderboard_http.connect("request_completed", self, "_on_leaderboard_request_completed")
	# Send request
	get_leaderboard_http.request(url, headers, true, HTTPClient.METHOD_GET, "")


func _on_leaderboard_request_completed(result, response_code, headers, body) -> void:
	var json = JSON.parse(body.get_string_from_utf8())
	
	# Filter leaderboard data into what we need
	var leaderboard := []
	for i in json.result.items.size():
		leaderboard.append({
			"name": json.result.items[i].player.name,
			"score": json.result.items[i].score,
			"rank": json.result.items[i].rank
		})
	
	get_leaderboard_http.queue_free()
	emit_signal("got_leaderboard", leaderboard)
