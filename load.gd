extends Node


func _ready() -> void:
	pass


func load_menu():
	var menu := preload("res://menu/main.tscn") as PackedScene
	get_parent().add_child(menu.instance())
	queue_free()
