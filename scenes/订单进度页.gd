extends Node2D

@onready var 进度条: Sprite2D = $进度条
@onready var button: Button = $Button

var _进度tween: Tween


func 播放进度动画() -> void:
	button.disabled = false
	button.hide()
	var mat := 进度条.material as ShaderMaterial
	if mat == null:
		return
	if _进度tween and _进度tween.is_valid():
		_进度tween.kill()
	mat.set_shader_parameter("progress", 0.0)
	_进度tween = create_tween()
	_进度tween.tween_property(mat, "shader_parameter/progress", 1.0, 2.0)
	_进度tween.finished.connect(_进度动画结束)
	
func _进度动画结束() -> void:
	button.show()


func _on_button_pressed() -> void:
	button.disabled = true
	全局.请求确认等待取餐()
