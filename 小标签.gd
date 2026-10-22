@tool
extends NinePatchRect

## 文字左右离圆角的空白
const 左右留白 := 10.0
const 最小高度 := 15.0

var _上次文本 := ""


func _ready() -> void:
	_适应文字()


func _process(_delta: float) -> void:
	var 标签 := get_node_or_null("Label") as Label
	if 标签 == null or 标签.text == _上次文本:
		return
	if _适应文字():
		_上次文本 = 标签.text


func 设置文本(文本: String) -> void:
	$Label.text = 文本
	_上次文本 = ""
	_适应文字()


func 设置序号颜色(序号: int) -> void:
	var 文字色 := Color(0.49803922, 0.49803922, 0.49803922, 1)
	if 序号 == 0:
		self_modulate = Color.html("FF7A7A")
		文字色 = Color.html("FF0000")
	elif 序号 == 1:
		self_modulate = Color.html("D0FFD8")
		文字色 = Color.html("46E931")
	else:
		self_modulate = Color.WHITE
	$Label.add_theme_color_override("font_color", 文字色)


func _适应文字() -> bool:
	var 标签 := get_node_or_null("Label") as Label
	if 标签 == null:
		return false
	var 字大小 := 标签.get_minimum_size()
	if 字大小.x <= 0.0:
		return false
	var 新大小 := Vector2(字大小.x + 左右留白 * 2.0, maxf(字大小.y, 最小高度) - 3.0)
	custom_minimum_size = 新大小
	size = 新大小
	# 只改尺寸，不改 position：左上角固定，向右长，避免盖住旁边控件
	_上次文本 = 标签.text
	return true
