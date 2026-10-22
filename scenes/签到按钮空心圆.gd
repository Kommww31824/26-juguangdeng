extends Button

@onready var 黄色空心圆下图: Sprite2D = $"../../签到按钮/黄色空心圆下图"
@onready var 黄色空心圆下图2: Sprite2D = $"../../签到按钮/黄色空心圆下图2"
@onready var 黄色空心圆下图3: Sprite2D = $"../../签到按钮/黄色空心圆下图3"
@onready var 黄色空心圆下图4: Sprite2D = $"../../签到按钮/黄色空心圆下图4"
@onready var 黄色空心圆下图5: Sprite2D = $"../../签到按钮/黄色空心圆下图5"
@onready var 黄色空心圆下图6: Sprite2D = $"../../签到按钮/黄色空心圆下图6"
@onready var 黄色空心圆下图7: Sprite2D = $"../../签到按钮/黄色空心圆下图7"

const 已签图标 := preload("res://美术素材/Vector.png")
const 未签图标 := preload("res://美术素材/Group 4506_2.png")
const 漏签图标 := preload("res://美术素材/Ellipse 13.png")

## 1 = 14 号 … 7 = 20 号（对应签到按钮 1–7）
@export var 日序号: int = 1


func _ready() -> void:
	日序号 = _从节点名解析日序号()
	全局.签到已变化.connect(刷新显示)
	刷新显示()


func _从节点名解析日序号() -> int:
	match name:
		"签到按钮空心圆":
			return 1
		"签到按钮空心圆2":
			return 2
		"签到按钮空心圆3":
			return 3
		"签到按钮空心圆4":
			return 4
		"签到按钮空心圆5":
			return 5
		"签到按钮空心圆6":
			return 6
		"签到按钮空心圆7":
			return 7
		_:
			return 1


func _下图() -> Sprite2D:
	match 日序号:
		1:
			return 黄色空心圆下图
		2:
			return 黄色空心圆下图2
		3:
			return 黄色空心圆下图3
		4:
			return 黄色空心圆下图4
		5:
			return 黄色空心圆下图5
		6:
			return 黄色空心圆下图6
		7:
			return 黄色空心圆下图7
		_:
			return 黄色空心圆下图


func 刷新显示() -> void:
	var 状态 := 全局.取签到状态(日序号)
	var 下图 := _下图()
	match 状态:
		全局.签到_已签:
			icon = 已签图标
			if 下图:
				下图.show()
		全局.签到_漏签:
			icon = 漏签图标
			if 下图:
				下图.hide()
		_:
			icon = 未签图标
			if 下图:
				下图.hide()
	disabled = not 全局.能否签到(日序号)


func _on_pressed() -> void:
	if not 全局.执行签到(日序号):
		return
	刷新显示()
