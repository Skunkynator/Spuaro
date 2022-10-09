extends HTTPRequest
class_name LLRequest


signal auth_completed(success, user_id, session_token, identifier)
signal user_name_received(success, user_name)
signal score_received(success, score, rank)
signal leaderboard_received(success, leaderboard)

const json_header := "Content-Type: application/json"
const ll_url := "https://api.lootlocker.io/game/"


func authenticate_user(identifier : String) -> void:
	var url := ll_url + "v2/session/guest"
	var data := {
		"game_key": LootLocker.game_API_key,
		"game_version": "0.1",
		"development_mode": false,
	}
	
	if identifier != "":
		data.player_identifier = identifier
	var headers := [json_header]
	connect("request_completed", self, "_on_auth_completed", [], CONNECT_ONESHOT)
	request(url, headers, true, HTTPClient.METHOD_POST, to_json(data))


func get_user_name() -> void:
	var url := ll_url + "player/name"
	var headers := [json_header , "x-session-token: " + LootLocker.session_token]
	
	connect("request_completed", self, "_on_user_name_received", [], CONNECT_ONESHOT)
	request(url, headers)


func set_user_name(name : String) -> void:
	var data := { "name": name }
	var url := ll_url + "player/name"
	var headers := [json_header , "x-session-token: " + LootLocker.session_token]
	connect("request_completed", self, "_on_user_name_received", [], CONNECT_ONESHOT)
	request(url, headers, true, HTTPClient.METHOD_PATCH, to_json(data))


func upload_score(level : String, difficulty : String, score : int) -> void:
	var data := { "score": str(score) }
	var leaderboard_id := level.replace(" ","_") + "-" + difficulty
	var url := ll_url + "leaderboards/"+leaderboard_id+"/submit"
	var headers = [json_header, "x-session-token:" + LootLocker.session_token]
	
	connect("request_completed", self, "_on_score_received", [], CONNECT_ONESHOT)
	request(url, headers, true, HTTPClient.METHOD_POST, to_json(data))


func get_score(
		level : String,
		difficulty : String,
		user_id : String = LootLocker.user_id
) -> void:
	var leaderboard_id := level.replace(" ","_") + "-" + difficulty
	var url := ll_url + "leaderboards/" + leaderboard_id + "/member/"
	var headers := [json_header, "x-session-token: " + LootLocker.session_token]
	
	connect("request_completed", self, "_on_score_received", [], CONNECT_ONESHOT)
	request(url + user_id, headers)


func get_leaderboard_around(
		level : String,
		difficulty : String,
		radius : int
) -> void:
	get_score(level, difficulty)
	var score_info = yield(self, "score_received")
	var start := max(score_info[2] - radius, 1)
	get_leaderboard(level, difficulty, start-1, 2*radius+1)


func get_leaderboard(
		level : String,
		difficulty : String,
		start : int = 0,
		count : int = 10
) -> void:
	var leaderboard_id := level.replace(" ","_") + "-" + difficulty
	var url := ll_url + "leaderboards/" + leaderboard_id + "/list"
	url += "?count=" + str(count) + "&after=" + str(start)
	var headers := [json_header, "x-session-token:"+LootLocker.session_token]
	
	connect("request_completed", self, "_leaderboard_received", [], CONNECT_ONESHOT)
	request(url, headers)


func _on_auth_completed(
		result : int,
		response_code : int,
		headers : PoolStringArray,
		body : PoolByteArray
) -> void:
	var json = JSON.parse(body.get_string_from_utf8())
	var user_id : String
	var session_token : String
	var identifier : String
	var success := result == RESULT_SUCCESS and response_code / 100 == 2
	if success:
		user_id = str(json.result.player_id)
		identifier = json.result.player_identifier
		session_token = json.result.session_token
	emit_signal("auth_completed", success, user_id, session_token, identifier)


func _on_user_name_received(
		result : int,
		response_code : int,
		headers : PoolStringArray,
		body : PoolByteArray
) -> void:
	var json := JSON.parse(body.get_string_from_utf8())
	var usr_name : String
	var success := result == RESULT_SUCCESS and response_code / 100 == 2
	if success:
		usr_name = json.result.name
	emit_signal("user_name_received", success, usr_name)


func _on_score_received(
		result : int,
		response_code : int,
		headers : PoolStringArray,
		body : PoolByteArray
) -> void:
	var score : int
	var rank : int
	var success := result == RESULT_SUCCESS and response_code / 100 == 2
	if success:
		var json := JSON.parse(body.get_string_from_utf8())
		score = json.result.score
		rank = json.result.rank
	emit_signal("score_received", success, score, rank)


func _on_leaderboard_received(
		result : int,
		response_code : int,
		headers : PoolStringArray,
		body : PoolByteArray
) -> void:
	var json := JSON.parse(body.get_string_from_utf8())
	var leaderboard := []
	var success := result == RESULT_SUCCESS and response_code / 100 == 2
	if success:
		for i in json.result.items.size():
			leaderboard.append({
				"name": json.result.items[i].player.name,
				"score": json.result.items[i].score,
				"rank": json.result.items[i].rank
			})
	emit_signal("leaderboard_received", success, leaderboard)
