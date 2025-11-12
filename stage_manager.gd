extends Node

var current_stage: int = 1
var total_stages: int = 3

func get_stage_path(stage: int) -> String:
	return "res://scenes/Game%d.tscn" % stage

func load_next_stage():
	current_stage += 1
	if current_stage > total_stages:
		get_tree().change_scene_to_file("res://scenes/Menu/victory_menu.tscn")
	else:
		get_tree().change_scene_to_file(get_stage_path(current_stage))

func restart_stage():
	get_tree().change_scene_to_file(get_stage_path(current_stage))

func load_stage(stage: int):
	current_stage = stage
	get_tree().change_scene_to_file(get_stage_path(stage))
