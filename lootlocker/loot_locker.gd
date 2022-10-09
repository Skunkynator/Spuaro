extends Node

signal user_name_found

const identifier_file := "user://user.data"
var game_API_key := ""
var session_token := ""
var user_name := ""
var user_id := ""
var online := false
var authenticator : LLRequest


func _ready():
	reconnect()


func reconnect() -> void:
	var file := File.new()
	var identifier := ""
	if file.open(identifier_file, File.READ) == OK:
		identifier = file.get_as_text()
		file.close()
	authenticator = LLRequest.new()
	add_child(authenticator)
	authenticator.connect("auth_completed", self, "_authentication_completed", [], CONNECT_ONESHOT)
	authenticator.authenticate_user(identifier)


func save_identifier(identifier : String):
	var file := File.new()
	if not file.file_exists(identifier_file):
		file.open(identifier_file, File.WRITE)
		file.store_string(identifier)
		file.close()


func _authentication_completed(success : bool, user_id, session_token, identifier) -> void:
	if not success:
		return
	online = true
	self.user_id = user_id
	self.session_token = session_token
	save_identifier(identifier)
	authenticator.connect("user_name_received", self, "_name_request_completed")
	authenticator.get_user_name()


func _name_request_completed(success : bool, response_name : String) -> void:
	emit_signal("user_name_found",response_name)
	if success:
		user_name = response_name


func set_user_name(name : String):
	authenticator.set_user_name(name)
