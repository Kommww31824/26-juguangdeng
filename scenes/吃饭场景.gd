extends Node2D

enum 阶段 {
	无,
	桌垫,
	饭,
	头像,
	对话,
	选项,
	健康提示,
	结算,
	日期卡,
}

@onready var 桌垫板: Sprite2D = $桌垫板
@onready var 饭占位: Sprite2D = $饭占位
@onready var 主角头像: Sprite2D = $主角头像
@onready var 对话框: ColorRect = $对话框
@onready var 对话文本: Label = $对话框/对话文本
@onready var 点击推进: Button = $点击推进
@onready var 吃外卖: Button = $吃外卖
@onready var 麻辣烫选项: VBoxContainer = $麻辣烫选项
@onready var 黑屏: ColorRect = $黑屏
@onready var 日期文字: Label = $黑屏/日期文字
@onready var 结算页: Node2D = $结算页

const 打字间隔 := 0.045
const 打字音效列表 := [
	preload("res://音乐音效/cut_狸狸语-01-原声MP3.mp3"),
	preload("res://音乐音效/cut_狸狸语-02-原声MP3.mp3"),
]
const 麻辣烫场景 := preload("res://scenes/吃饭场景麻辣烫.tscn")

var _阶段: 阶段 = 阶段.无
var _过渡中 := false
var _打字中 := false
var _打字令牌 := 0
var _全文 := ""
var _打字音效: AudioStreamPlayer
var _打字音效令牌 := 0
var _打字音效开始 := 0
var _麻辣烫: Node2D
var _麻辣烫演出中 := false
var _进食已选择 := false


func _ready() -> void:
	_打字音效 = AudioStreamPlayer.new()
	add_child(_打字音效)
	吃外卖.pressed.connect(_on_吃外卖_pressed)
	点击推进.pressed.connect(_on_点击推进_pressed)
	$麻辣烫选项/不吃了.pressed.connect(_on_不吃了_pressed)
	$麻辣烫选项/算了吃吧.pressed.connect(_on_算了吃吧_pressed)
	结算页.确认继续.connect(_on_结算确认继续)
	_重置界面()


func _重置界面() -> void:
	_打字令牌 += 1
	_打字中 = false
	_停止打字音效()
	_过渡中 = false
	_阶段 = 阶段.无
	_清理麻辣烫()
	饭占位.hide()
	主角头像.hide()
	对话框.hide()
	对话文本.text = ""
	吃外卖.hide()
	麻辣烫选项.hide()
	_进食已选择 = false
	#健康提示层.hide()
	结算页.hide()
	点击推进.show()
	点击推进.disabled = false
	桌垫板.show()
	日期文字.hide()
	日期文字.modulate.a = 0.0
	黑屏.hide()
	黑屏.color = Color(0, 0, 0, 1)


func 显示当前外卖() -> void:
	_打字令牌 += 1
	_打字中 = false
	_停止打字音效()
	_过渡中 = true
	_全文 = str(全局.当前外卖.get("吃饭提示", "吃完了。"))
	_清理麻辣烫()
	_更新饭占位图()
	饭占位.hide()
	主角头像.hide()
	对话框.hide()
	对话文本.text = ""
	吃外卖.hide()
	麻辣烫选项.hide()
	_进食已选择 = false
	#健康提示层.hide()
	结算页.hide()
	日期文字.hide()
	日期文字.modulate.a = 0.0
	点击推进.show()
	点击推进.disabled = false
	桌垫板.show()
	if _是麻辣烫():
		_摆上麻辣烫()
	全局.使用吃饭鼠标()
	_阶段 = 阶段.桌垫
	黑屏.color = Color(0, 0, 0, 1)
	黑屏.show()
	await get_tree().create_timer(0.15).timeout
	if not is_inside_tree():
		return
	var tw := create_tween()
	tw.tween_property(黑屏, "color:a", 0.0, 0.45)
	await tw.finished
	黑屏.hide()
	黑屏.color = Color(0, 0, 0, 1)
	_过渡中 = false


func _on_点击推进_pressed() -> void:
	if _过渡中:
		return
	match _阶段:
		阶段.桌垫:
			_进入饭()
		阶段.饭:
			_进入头像()
		阶段.头像:
			_进入对话()
		阶段.对话:
			if _打字中:
				_跳过打字()
			else:
				_进入选项()
		阶段.健康提示:
			_显示结算页()
		阶段.结算:
			pass
		阶段.日期卡:
			_确认进入下一天()
		阶段.选项:
			pass


func _进入饭() -> void:
	if _是麻辣烫():
		# 麻辣烫碗已在进场时摆好；其他外卖这里显示饭占位
		pass
	else:
		_更新饭占位图()
		饭占位.show()
	_进入进食选择()


func _更新饭占位图() -> void:
	var 图 := 外卖数据终版.读图片(全局.当前外卖)
	if 图:
		饭占位.texture = 图


func _进入进食选择() -> void:
	_进食已选择 = false
	点击推进.hide()
	麻辣烫选项.hide()
	_阶段 = 阶段.饭
	var 提示 := _全文.strip_edges()
	if 提示.is_empty():
		主角头像.hide()
		对话框.hide()
		对话文本.text = ""
	else:
		主角头像.show()
		对话框.show()
		await _播放打字机(提示)
		if not is_inside_tree():
			return
	$麻辣烫选项/不吃了.visible = 全局.剩余拒绝次数 > 0
	麻辣烫选项.show()


func _on_不吃了_pressed() -> void:
	if _进食已选择 or 全局.剩余拒绝次数 <= 0:
		return
	_进食已选择 = true
	麻辣烫选项.hide()
	全局.登记拒绝进食()
	await _播放打字机("不吃了")
	if not is_inside_tree():
		return
	await get_tree().create_timer(0.6).timeout
	_显示结算页()


func _on_算了吃吧_pressed() -> void:
	if _进食已选择:
		return
	_进食已选择 = true
	麻辣烫选项.hide()
	主角头像.hide()
	对话框.hide()
	对话文本.text = ""
	if _是麻辣烫():
		_开始麻辣烫演出()
	else:
		# 提示已在选择前播过，直接进入「吃外卖」
		_进入选项()


func _是麻辣烫() -> bool:
	var 饭 := 全局.当前外卖
	return "麻辣烫" in str(饭.get("图片", "")) or "麻辣烫" in str(饭.get("名字", ""))


func _摆上麻辣烫() -> void:
	if _麻辣烫 and is_instance_valid(_麻辣烫):
		_麻辣烫.设置可互动(false)
		return
	饭占位.hide()
	_麻辣烫 = 麻辣烫场景.instantiate()
	add_child(_麻辣烫)
	_麻辣烫.position = Vector2(960, 540)
	_麻辣烫.确认吃完.connect(_on_麻辣烫确认吃完)
	_麻辣烫.请求播放评价.connect(_on_麻辣烫请求评价)
	_麻辣烫.设置可互动(false)


func _开始麻辣烫演出() -> void:
	_摆上麻辣烫()
	饭占位.hide()
	点击推进.hide()
	_麻辣烫演出中 = true
	_麻辣烫.设置可互动(true)
	_阶段 = 阶段.饭


func _清理麻辣烫() -> void:
	_麻辣烫演出中 = false
	主角头像.hide()
	对话框.hide()
	对话文本.text = ""
	if _麻辣烫 and is_instance_valid(_麻辣烫):
		_麻辣烫.queue_free()
	_麻辣烫 = null


func _on_麻辣烫请求评价(文本: String) -> void:
	主角头像.show()
	对话框.show()
	await _播放打字机(文本)
	if not is_inside_tree():
		return
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	主角头像.hide()
	对话框.hide()
	对话文本.text = ""
	if _麻辣烫 and is_instance_valid(_麻辣烫):
		_麻辣烫.评价播完()


func _on_麻辣烫确认吃完() -> void:
	_清理麻辣烫()
	_on_吃外卖_pressed()


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
	吃外卖.show()
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


func _on_吃外卖_pressed() -> void:
	if _过渡中:
		return
	吃外卖.hide()
	await _播放最后说()
	if not is_inside_tree():
		return
	全局.结算用餐()
	if bool(全局.当前外卖.get("是否异常", false)):
		#健康提示层.show()
		点击推进.show()
		_阶段 = 阶段.健康提示
	else:
		_显示结算页()


func _播放最后说() -> void:
	var 最后 := str(全局.当前外卖.get("女主文本最后说", "")).strip_edges()
	if 最后.is_empty():
		return
	主角头像.show()
	对话框.show()
	_全文 = 最后
	await _播放打字机(最后)
	if not is_inside_tree():
		return
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	主角头像.hide()
	对话框.hide()
	对话文本.text = ""


func _显示结算页() -> void:
	_过渡中 = true
	#健康提示层.hide()
	吃外卖.hide()
	麻辣烫选项.hide()
	主角头像.hide()
	对话框.hide()
	点击推进.hide()
	_清理麻辣烫()
	结算页.显示结算()
	_阶段 = 阶段.结算
	_过渡中 = false


func _on_结算确认继续() -> void:
	if _阶段 != 阶段.结算:
		return
	_显示日期卡()


func _显示日期卡() -> void:
	_过渡中 = true
	#健康提示层.hide()
	吃外卖.hide()
	主角头像.hide()
	对话框.hide()
	结算页.hide()
	点击推进.show()
	日期文字.text = 全局.下一天时间文本()
	日期文字.modulate.a = 0.0
	日期文字.show()
	黑屏.color = Color(0, 0, 0, 1)
	黑屏.show()
	var tw := create_tween()
	tw.tween_property(日期文字, "modulate:a", 1.0, 0.8)
	await tw.finished
	if not is_inside_tree():
		return
	_阶段 = 阶段.日期卡
	_过渡中 = false


func _确认进入下一天() -> void:
	if _过渡中:
		return
	_过渡中 = true
	全局.使用默认鼠标()
	# 与第一天进游戏相同：先播手出现并停留在手图02，再进入下一天打开拼好饭
	全局.请求手出现()
	_过渡中 = false
