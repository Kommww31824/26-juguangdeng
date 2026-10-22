extends Node2D

@onready var 黑屏: ColorRect = $黑屏

var _正在进入 := false


func _on_button_pressed() -> void:
	if _正在进入:
		return
	_正在进入 = true
	$Button.disabled = true
	黑屏.color = Color(0, 0, 0, 0)
	黑屏.show()
	var tw := create_tween()
	tw.tween_property(黑屏, "color:a", 1.0, 1.0)
	await tw.finished
	if not is_inside_tree():
		return
	get_tree().change_scene_to_packed(load("res://scenes/主场景.tscn"))
