extends Node2D
class_name Spawner


signal did_finish
enum Side {Left,Right,None}
export var note_scene : PackedScene
export var min_angle : float
export var max_angle : float
export(Side) var type
var finished := false
var spawn_done := false
var note_queue : Array


func spawn(notes : Array):
	var instance : Note
	for note in notes:
		if not note is Dictionary:
			note = {"time": note}
		note.spawn = (note.time - 4) / LevelController.bps
		# do further note type stuff like hold/spam here later
		if note.spawn > LevelController.time:
			yield(get_tree().create_timer(note.spawn - LevelController.time),"timeout")
		instance = note_scene.instance() as Note
		var angle = rand_range(min_angle,max_angle)
		instance.spawn(note.time / LevelController.bps, note.spawn, angle)
		add_child(instance)
		instance.connect("missed",self,"note_hit")
		note_queue.push_back(instance)
	spawn_done = true


func _input(event: InputEvent) -> void:
	var action := ""
	match type:
		Side.Left:
			action = "left"
		Side.Right:
			action = "right"
		_:
			action = "invalid"
	if event.is_action_pressed(action):
		if note_queue.size() > 0:
			note_hit(note_queue[0])


func note_hit(to_hit : Note) -> void:
	var hit_time : float = to_hit.hit - LevelController.time
	if hit_time > 0.180:
		return
	elif abs(hit_time) <= 0.045:
		emit_particle($PerfectParticles)
		LevelController.note_hit(LevelController.HitMode.Perfect)
	elif abs(hit_time) > 0.135:
		emit_particle($MissParticles)
		LevelController.note_hit(LevelController.HitMode.Miss)
	elif abs(hit_time) > 0.090:
		emit_particle($OkParticles)
		LevelController.note_hit(LevelController.HitMode.Ok)
	elif abs(hit_time) > 0.045:
		emit_particle($GoodParticles)
		LevelController.note_hit(LevelController.HitMode.Good)
	note_queue.pop_front()
	to_hit.queue_free()
	if note_queue.size() == 0 and spawn_done:
		finished = true
		emit_signal("did_finish")


func emit_particle(particles : CPUParticles2D) -> void:
	particles.emitting = true
	yield(get_tree().create_timer(0.05),"timeout")
	particles.emitting = false
