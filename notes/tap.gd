extends Node2D
class_name Note


signal missed
var start : float
var hit : float
var start_pos : Vector2

func spawn(hit_time : float, spawn_time : float, rotation : float):
	start = spawn_time
	hit = hit_time
	start_pos = Vector2(sin(rotation),cos(rotation)) * 1000
	position = start_pos


func _process(_delta: float) -> void:
	var cur : float = (LevelController.time - start) / (hit - start)
	cur = 1 - cur + 0.1 * cur
	if LevelController.time > hit + 0.180:
		emit_signal("missed",self)
	position = start_pos * max(cur, 0)
