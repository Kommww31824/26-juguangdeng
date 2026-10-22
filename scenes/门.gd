extends Node2D

enum 阶段 {
	无,
	走廊,
	头像,
	对话,
	选项,
}

@onready var 猫眼: Button = $猫眼
@onready var 底色: ColorRect = $ColorRect
@onready var 门图: Sprite2D = $Sprite2D
@onready var 门外层: ColorRect = $门外层
@onready var 门外走廊: Sprite2D = $门外层/门外走廊
@onready var 主角头像: Sprite2D = $门外层/主角头像
@onready var 对话框: ColorRect = $门外层/对话框
@onready var 对话文本: Label = $门外层/对话框/对话文本
@onready var 点击推进: Button = $门外层/点击推进
@onready var 拿外卖: Button = $门外层/拿外卖
@onready var 黑屏: ColorRect = $黑屏

const 打字间隔 := 0.045
const 打字音效列表 := [
	preload("res://音乐音效/cut_狸狸语-01-原声MP3.mp3"),
	preload("res://音乐音效/cut_狸狸语-02-原声MP3.mp3"),
]
## 每张门外走廊贴图对应一句猫眼对话
const 正常走廊池 := [
	{"图": preload("res://美术素材/鱼眼/正常鱼眼图片/261004门-1.png"), "话": "没啥可看的"},
	{"图": preload("res://美术素材/鱼眼/正常鱼眼图片/261004门-2.png"), "话": "外卖员急匆匆的走了，真是辛苦啊……"},
]
const 异常走廊池 := [
	{"图": preload("res://美术素材/鱼眼/异常鱼眼图片/261004门-3.png"), "话": "没啥可看的"},
	{"图": preload("res://美术素材/鱼眼/异常鱼眼图片/261004门-4.png"), "话": "外面好像脏脏的……"},
	{"图": preload("res://美术素材/鱼眼/异常鱼眼图片/261004门-5.png"), "话": "外卖小哥好像有点奇怪……"},
	{"图": preload("res://美术素材/鱼眼/异常鱼眼图片/261004门-6.png"), "话": "有点头晕……"},
]

var _阶段: 阶段 = 阶段.无
var _过渡中 := false
var _打字中 := false
var _打字令牌 := 0
var _全文 := ""
var _入场tween: Tween
var _打字音效: AudioStreamPlayer
var _打字音效令牌 := 0
var _打字音效开始 := 0


func _ready() -> void:
	_打字音效 = AudioStreamPlayer.new()
	add_child(_打字音效)
	猫眼.pressed.connect(_on_猫眼_pressed)
	猫眼.mouse_entered.connect(全局.使用查看鼠标)
	猫眼.mouse_exited.connect(_on_猫眼_mouse_exited)
	拿外卖.pressed.connect(_on_拿外卖_pressed)
	点击推进.pressed.connect(_on_点击推进_pressed)
	重置()


func 重置(从全黑: bool = false) -> void:
	_打字令牌 += 1
	_打字中 = false
	_停止打字音效()
	_过渡中 = false
	_阶段 = 阶段.无
	_全文 = ""
	门外层.hide()
	主角头像.hide()
	对话框.hide()
	对话文本.text = ""
	拿外卖.hide()
	点击推进.show()
	点击推进.disabled = false
	猫眼.hide()
	黑屏.hide()
	黑屏.color = Color(0, 0, 0, 1)
	全局.使用默认鼠标()
	_播放入场(从全黑)


func _播放入场(从全黑: bool = false) -> void:
	if _入场tween and _入场tween.is_valid():
		_入场tween.kill()
	底色.color.a = 1.0 if 从全黑 else 0.0
	底色.show()
	门图.modulate.a = 0.0
	门图.show()
	_入场tween = create_tween()
	if not 从全黑:
		_入场tween.tween_property(底色, "color:a", 1.0, 1.0)
	_入场tween.tween_property(门图, "modulate:a", 1.0, 1.0)
	_入场tween.tween_callback(func() -> void:
		猫眼.show()
	)


func 显示门外() -> void:
	猫眼.hide()
	主角头像.hide()
	对话框.hide()
	对话文本.text = ""
	拿外卖.hide()
	点击推进.show()
	点击推进.disabled = false
	门外层.modulate.a = 1.0
	门外层.show()
	_全文 = _随机门外走廊贴图()
	门外走廊.show()
	全局.使用查看鼠标()
	_阶段 = 阶段.走廊


func _随机门外走廊贴图() -> String:
	var 池: Array = 异常走廊池 if bool(全局.当前外卖.get("是否异常", false)) else 正常走廊池
	if 池.is_empty():
		return "没啥可看的"
	var 条: Dictionary = 池[randi() % 池.size()]
	门外走廊.texture = 条["图"]
	return str(条.get("话", "没啥可看的"))


func _on_猫眼_pressed() -> void:
	if _过渡中:
		return
	_过渡中 = true
	await _播放黑屏过渡()
	if not is_inside_tree():
		return
	_过渡中 = false


func _播放黑屏过渡() -> void:
	黑屏.color = Color(0, 0, 0, 1)
	黑屏.show()
	await get_tree().create_timer(0.25).timeout
	if not is_inside_tree():
		return
	# 先切到门外走廊，再把黑屏渐隐，形成“黑一下再渐显”
	全局.打开页("门外场景")
	var tw := create_tween()
	tw.tween_property(黑屏, "color:a", 0.0, 0.45)
	await tw.finished
	黑屏.hide()
	黑屏.color = Color(0, 0, 0, 1)


func _on_点击推进_pressed() -> void:
	if _过渡中:
		return
	match _阶段:
		阶段.走廊:
			_进入头像()
		阶段.头像:
			_进入对话()
		阶段.对话:
			if _打字中:
				_跳过打字()
			else:
				_进入选项()
		阶段.选项:
			pass


func _进入头像() -> void:
	主角头像.show()
	_阶段 = 阶段.头像


func _进入对话() -> void:
	对话框.show()
	_阶段 = 阶段.对话
	await _播放打字机(_全文)


func _进入选项() -> void:
	主角头像.hide()
	对话框.hide()
	对话文本.text = ""
	点击推进.hide()
	拿外卖.show()
	全局.使用拿外卖鼠标()
	_阶段 = 阶段.选项


func _播放打字机(全文: String) -> void:
	_打字令牌 += 1
	var 令牌 := _打字令牌
	_打字中 = true
	对话文本.text = ""
	_开始打字音效()
	for i in 全文.length():
		if 令牌 != _打字令牌 or not is_inside_tree():
			_停止打字音效()
			return
		对话文本.text += 全文[i]
		await get_tree().create_timer(打字间隔).timeout
	if 令牌 == _打字令牌:
		_打字中 = false
		_停止打字音效()


func _跳过打字() -> void:
	_打字令牌 += 1
	_打字中 = false
	对话文本.text = _全文
	_停止打字音效()


func _开始打字音效() -> void:
	_打字音效令牌 += 1
	_打字音效开始 = Time.get_ticks_msec()
	_打字音效.stream = 打字音效列表[randi() % 打字音效列表.size()]
	_打字音效.play()


func _停止打字音效() -> void:
	var 令牌 := _打字音效令牌
	var 已播 := (Time.get_ticks_msec() - _打字音效开始) / 1000.0
	if 已播 < 2.0:
		await get_tree().create_timer(2.0 - 已播).timeout
	if 令牌 != _打字音效令牌 or not is_inside_tree():
		return
	if _打字音效 and _打字音效.playing:
		_打字音效.stop()


func _on_猫眼_mouse_exited() -> void:
	if _阶段 == 阶段.无:
		全局.使用默认鼠标()


func _on_拿外卖_pressed() -> void:
	if _过渡中:
		return
	_过渡中 = true
	黑屏.color = Color(0, 0, 0, 1)
	黑屏.show()
	await get_tree().create_timer(0.25).timeout
	if not is_inside_tree():
		return
	# 切到吃饭场景；入场渐显由吃饭场景自己的黑屏完成
	全局.使用默认鼠标()
	全局.打开页("吃饭场景")
	_过渡中 = false
	黑屏.hide()
