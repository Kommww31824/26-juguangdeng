extends Button


func _ready() -> void:
	if icon == null and text.is_empty():
		text = ""
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	全局.返回上一级()
