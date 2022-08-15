extends Node


enum HitMode {Perfect,Good,Ok,Miss}
var time : float
var bps : float
var score : int
var combo : int
var level : Dictionary
var player : AudioStreamPlayer
var left_bh := preload("res://gameplay/black_hole_left.tscn").instance() as Spawner
var right_bh := preload("res://gameplay/black_hole_right.tscn").instance() as Spawner
var game_ui : Control = preload("res://gameplay/game_ui.tscn").instance()
var finish_screen : PackedScene = preload("res://menu/level_finished.tscn")


func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)


func _process(_delta: float) -> void:
	if level:
		time = player.get_playback_position() - level.start


func open_level(level_path : String, song_path : String) -> void:
	var file := File.new()
	if file.open(level_path,File.READ):
		file.close()
		return
	level = str2var(file.get_as_text())
	file.close()
	
	if file.open(song_path,File.READ):
		file.close()
		return
	var audio_stream := AudioStreamOGGVorbis.new()
	audio_stream.data = file.get_buffer(file.get_len())
	file.close()
	
	play_level(audio_stream)


func play_level(audio : AudioStream = null) -> void:
	score = 0
	combo = 0
	if not level.start:
		level.start = 0.0
	bps = level.bpm / 60.0
	if audio:
		player.stream = audio
	player.play(level.start)
	player.volume_db = 0.0
	add_child(left_bh)
	add_child(right_bh)
	add_child(game_ui)
	game_ui.update_ui()
	left_bh.spawn(level.lnotes)
	right_bh.spawn(level.rnotes)
	yield(left_bh,"did_finish")
	if not right_bh.finished:
		yield(right_bh,"did_finish")
	var tween := create_tween()
	tween.tween_property(player,"volume_db",-50.0,4).set_trans(Tween.TRANS_EXPO)
	
	yield(get_tree().create_timer(4),"timeout")
	finish_level()


func finish_level():
	player.stop()
	get_parent().add_child(finish_screen.instance())
	remove_child(left_bh)
	remove_child(right_bh)


func note_hit(mode):
	if mode == HitMode.Miss:
		combo = 0
	else:
		combo += 1
	match mode:
		HitMode.Perfect:
			score += 100
		HitMode.Good:
			score += 80
		HitMode.Ok:
			score += 50
	game_ui.update_ui()
