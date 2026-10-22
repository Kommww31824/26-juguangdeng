extends Node2D

signal 确认吃完
signal 请求播放评价(文本: String)

const 小菜评价 := {
	"面": "嗯……面还软着。",
	"豆腐": "豆腐吸饱了汤。",
	"鱼丸": "鱼丸倒是Q弹。",
	"青菜": "青菜有点老了……",
	"午餐肉": "午餐肉……还能吃。",
	"香肠": "这肠有点甜。",
}

@onready var 吃完了按钮: Button = $吃完了

var _剩余小菜 := 0
var _忙碌中 := false
var _评价完成 := false
var _可互动 := false


func _ready() -> void:
	吃完了按钮.hide()
	吃完了按钮.pressed.connect(_on_吃完了_pressed)
	_剩余小菜 = 0
	for 子 in get_children():
		if 子 is Area2D and 子.is_in_group("麻辣烫小菜"):
			_剩余小菜 += 1
			子.input_pickable = true
			子.monitoring = true
			子.monitorable = true


func 设置可互动(可以: bool) -> void:
	_可互动 = 可以
	for 子 in get_children():
		if 子 is Area2D and 子.is_in_group("麻辣烫小菜"):
			子.input_pickable = 可以


func _input(event: InputEvent) -> void:
	if not _可互动 or _忙碌中 or not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var 小菜 := _找命中小菜(get_global_mouse_position())
		if 小菜:
			get_viewport().set_input_as_handled()
			_吃掉小菜(小菜)
		#pass


func 评价播完() -> void:
	_评价完成 = true


func _找命中小菜(全局点: Vector2) -> Area2D:
	var 候选: Array[Area2D] = []
	for 子 in get_children():
		if not (子 is Area2D and 子.visible and 子.is_in_group("麻辣烫小菜")):
			continue
		if not 子.input_pickable:
			continue
		var 本地: Vector2 = 子.to_local(全局点)
		for 形节点 in 子.get_children():
			if 形节点 is CollisionPolygon2D and not 形节点.disabled:
				if Geometry2D.is_point_in_polygon(本地, 形节点.polygon):
					候选.append(子)
					break
	if 候选.is_empty():
		return null
	候选.sort_custom(func(a: Area2D, b: Area2D) -> bool: return a.z_index > b.z_index)
	return 候选[0]


func _吃掉小菜(小菜: Area2D) -> void:
	_忙碌中 = true
	小菜.input_pickable = false
	# 抬到其他小菜之上，但仍低于吃饭场景对话框（对话框 z=30，本节点 z=1）
	小菜.z_index = 6
	var tw := create_tween()
	tw.tween_property(小菜, "position", Vector2(0, -40), 0.35)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	if not is_inside_tree():
		return
	var 文本 := str(小菜评价.get(小菜.name, "……还能下咽。"))
	_评价完成 = false
	请求播放评价.emit(文本)
	while not _评价完成:
		await get_tree().process_frame
		if not is_inside_tree():
			return
	小菜.hide()
	_剩余小菜 = maxi(0, _剩余小菜 - 1)
	_忙碌中 = false
	if _剩余小菜 <= 0:
		吃完了按钮.show()


func _on_吃完了_pressed() -> void:
	确认吃完.emit()
