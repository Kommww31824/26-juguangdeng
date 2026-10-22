extends Node2D

@onready var color_rect: ColorRect = $ColorRect
@onready var button: Button = $Button
@onready var label: Label = $Label

@export_file("*.tscn") var next_scene: String = "res://scenes/next_scene.tscn"


func _ready() -> void:
	label.text = name


func _on_button_mouse_entered() -> void:
	pass


func _on_button_mouse_exited() -> void:
	pass


func _on_button_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.1)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_tween_finished)


func _on_tween_finished() -> void:
	读app名字()


func 拼好饭app() -> void:
	全局.食反需要开屏 = true
	全局.打开页("拼好饭首页")


func 读app名字() -> void:
	if name == "食反":
		拼好饭app()
