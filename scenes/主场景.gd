extends Node2D

@onready var bg: Sprite2D = $bg
@onready var 当前钱数: Label = $当前钱数
@onready var 当前健康: Label = $当前健康
@onready var 当前天数: Label = $当前天数
@onready var 手机桌面页: Node2D = $手机桌面页
@onready var 拼好饭首页: Node2D = $拼好饭首页
@onready var 门: Node2D = $门
@onready var 黑屏: ColorRect = $黑屏
@onready var 手: Sprite2D = $手
@onready var 毒效果: ColorRect = $毒效果
@onready var 女主: Sprite2D = $女主
@onready var 全黑: ColorRect = $全黑
@onready var 取外卖前对话: Node2D = $取外卖前对话
@onready var 取餐对话框: Sprite2D = $取外卖前对话/对话框
@onready var 取餐头像: Sprite2D = $取外卖前对话/女主头像
@onready var 取餐文本: Label = $取外卖前对话/外卖到了Label
@onready var 取餐点击: Button = $取外卖前对话/点击继续
@onready var 健康值为0: CanvasLayer = $健康值为0
@onready var 黑屏说话: CanvasLayer = $黑屏说话

const 覆盖层 := ["拼好饭首页", "外卖详细页", "提交订单页", "订单进度页", "吃饭场景"]
const 第一天黑屏文案 := "唉 人为什么要吃饭 好饿……\n\n怎么这么快又到该吃饭的时候了。"
const 黑屏说话打字间隔 := 0.045
const 门铃占位 := preload("res://音乐音效/门铃.mp3")
const 取餐打字间隔 := 0.045
const 手图01 := preload("res://美术素材/手/hand01 2.png")
const 手图02 := preload("res://美术素材/手/hand02 2.png")
const 女主白天图 := [
	preload("res://美术素材/女主图片/261004房内1 1.png"),
	preload("res://美术素材/女主图片/261004房内3 1.png"),
]
const 女主图2 := preload("res://美术素材/女主图片/261004房内2 1.png")
const 女主图4 := preload("res://美术素材/女主图片/261004房内4 1.png")

var _进门过渡中 := false
var _门从全黑入场 := false
var _取餐对话中 := false
var _取餐打字中 := false
var _取餐可继续 := false
var _取餐打字令牌 := 0
var _取餐全文 := "嗯，外卖到了..."
var _门铃: AudioStreamPlayer
var _结局已触发 := false
var _黑屏说话打字令牌 := 0


func _ready() -> void:
	黑屏.hide()
	全黑.hide()
	手.hide()
	取外卖前对话.hide()
	健康值为0.hide()
	黑屏说话.hide()
	_取餐全文 = 取餐文本.text
	_门铃 = AudioStreamPlayer.new()
	add_child(_门铃)
	取餐点击.pressed.connect(_on_取餐点击)
	全局.数值已变化.connect(刷新数值)
	全局.页请求.connect(显示页)
	全局.进门过渡请求.connect(_on_进门过渡请求)
	全局.确认等待取餐请求.connect(_on_确认等待取餐)
	全局.手出现请求.connect(_on_手出现请求)
	刷新数值()
	await _播放新一天开场(false)


func 刷新数值() -> void:
	当前钱数.text = "￥ %.2f" % 全局.钱数
	var 实心 := clampi(全局.健康, 0, 5)
	当前健康.text = "健康 %s%s" % ["♥".repeat(实心), "♡".repeat(5 - 实心)]
	当前天数.text = 全局.当前时间文本()
	毒效果.visible = 全局.健康 < 3
	_更新顶栏可见()
	if 全局.健康 <= 0 and not _结局已触发:
		_结局已触发 = true
		健康值为0.开始结局()


func _更新顶栏可见() -> void:
	# 门/门外/吃饭场景隐藏顶栏；其余页面（含进游戏第一天）保持可见
	var 沉浸页 := 全局.当前页 in ["门", "门外场景", "吃饭场景"]
	当前钱数.visible = not 沉浸页
	当前健康.visible = not 沉浸页
	当前天数.visible = not 沉浸页


func 显示页(页名: String) -> void:
	手机桌面页.visible = not 全局.是否隐藏手机(页名)
	for 名 in 覆盖层:
		var 节点 := get_node_or_null(名)
		if 节点:
			节点.visible = 名 == 页名
	门.visible = 页名 == "门" or 页名 == "门外场景"
	match 页名:
		"外卖详细页":
			$外卖详细页.显示当前外卖()
		"提交订单页":
			$提交订单页.显示当前外卖()
		"订单进度页":
			$订单进度页.播放进度动画()
		"门":
			门.重置(_门从全黑入场)
			_门从全黑入场 = false
			全黑.hide()
		"门外场景":
			门.显示门外()
		"吃饭场景":
			$吃饭场景.显示当前外卖()
	刷新数值()


func _on_确认等待取餐() -> void:
	if _进门过渡中 or _取餐对话中:
		return
	_取餐对话中 = true
	_隐藏界面层()
	_门铃.stream = 门铃占位
	_门铃.play()
	await _门铃.finished
	if not is_inside_tree():
		return
	await _播放取外卖前对话()
	if not is_inside_tree():
		return
	_取餐对话中 = false
	await 播放进门过渡()
	女主.hide()
	_门从全黑入场 = true
	全局.打开页("门")


func _播放取外卖前对话() -> void:
	_取餐可继续 = false
	取外卖前对话.show()
	取餐对话框.show()
	取餐头像.show()
	await _播放取餐打字机(_取餐全文)
	if not is_inside_tree():
		return
	while not _取餐可继续:
		await get_tree().process_frame
		if not is_inside_tree():
			return
	取外卖前对话.hide()


func _播放取餐打字机(全文: String) -> void:
	_取餐打字令牌 += 1
	var 令牌 := _取餐打字令牌
	_取餐打字中 = true
	取餐文本.text = ""
	for i in 全文.length():
		if 令牌 != _取餐打字令牌 or not is_inside_tree():
			return
		取餐文本.text += 全文[i]
		await get_tree().create_timer(取餐打字间隔).timeout
	if 令牌 == _取餐打字令牌:
		_取餐打字中 = false


func _on_取餐点击() -> void:
	if _取餐打字中:
		_取餐打字令牌 += 1
		_取餐打字中 = false
		取餐文本.text = _取餐全文
		return
	_取餐可继续 = true


func _on_进门过渡请求() -> void:
	if _进门过渡中:
		return
	await 播放进门过渡()
	女主.hide()
	_门从全黑入场 = true
	全局.打开页("门")


func _on_手出现请求() -> void:
	if _进门过渡中:
		return
	await _播放新一天开场(true)


## 新一天开场：仅第一天黑屏说话 → bg 渐显 → 女主渐显 → 手动画
func _播放新一天开场(进入下一天: bool) -> void:
	var 是第一天 := not 进入下一天
	if 进入下一天:
		全局.进入下一天()
	全局.页历史.clear()
	全局.当前页 = "手机桌面页"

	_隐藏界面层()
	拼好饭首页.hide()
	手机桌面页.show()
	# 渐显前彻底藏起，避免黑屏说话淡出时露馅闪一下
	bg.modulate = Color(1, 1, 1, 0)
	bg.hide()
	女主.modulate = Color(1, 1, 1, 0)
	女主.hide()
	黑屏.color = Color(0, 0, 0, 1)
	黑屏.show()
	刷新数值()

	if 是第一天:
		await _播放第一天黑屏说话()
		if not is_inside_tree():
			return

	bg.modulate = Color(1, 1, 1, 0)
	bg.show()
	_随机白天女主(false)
	女主.modulate = Color(1, 1, 1, 0)
	女主.show()
	# 等一帧，确保以透明状态提交后再渐显
	await get_tree().process_frame
	if not is_inside_tree():
		return

	var tw := create_tween()
	tw.tween_property(bg, "modulate:a", 1.0, 1.0)
	await tw.finished
	if not is_inside_tree():
		return

	tw = create_tween()
	tw.tween_property(女主, "modulate:a", 1.0, 1.0)
	await tw.finished
	if not is_inside_tree():
		return

	await 手出现()
	if not is_inside_tree():
		return
	黑屏.hide()
	显示页("手机桌面页")


func _播放第一天黑屏说话() -> void:
	var 文案: Label = 黑屏说话.get_node("Label")
	var 底: ColorRect = 黑屏说话.get_node("ColorRect")
	var 头像: Sprite2D = 黑屏说话.get_node("Sprite2D")
	底.modulate = Color.WHITE
	头像.modulate = Color.WHITE
	文案.modulate = Color.WHITE
	文案.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92, 1))
	文案.text = ""
	黑屏说话.show()
	await _黑屏说话打字机(文案, 第一天黑屏文案)
	if not is_inside_tree():
		return
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(底, "modulate:a", 0.0, 0.8)
	tw.tween_property(头像, "modulate:a", 0.0, 0.8)
	tw.tween_property(文案, "modulate:a", 0.0, 0.8)
	await tw.finished
	if not is_inside_tree():
		return
	黑屏说话.hide()
	文案.text = ""


func _黑屏说话打字机(文案: Label, 全文: String) -> void:
	_黑屏说话打字令牌 += 1
	var 令牌 := _黑屏说话打字令牌
	文案.text = ""
	for i in 全文.length():
		if 令牌 != _黑屏说话打字令牌 or not is_inside_tree():
			return
		文案.text += 全文[i]
		await get_tree().create_timer(黑屏说话打字间隔).timeout


func _随机白天女主(立即显示: bool = true) -> void:
	女主.texture = 女主白天图[randi() % 女主白天图.size()]
	if 立即显示:
		女主.modulate = Color(1, 1, 1, 1)
		女主.show()


func _女主换图渐变(图: Texture2D) -> void:
	var tw := create_tween()
	tw.tween_property(女主, "modulate:a", 0.0, 0.45)
	await tw.finished
	if not is_inside_tree():
		return
	女主.texture = 图
	tw = create_tween()
	tw.tween_property(女主, "modulate:a", 1.0, 0.45)
	await tw.finished


func _隐藏界面层() -> void:
	for 名 in 覆盖层:
		var 节点 := get_node_or_null(名)
		if 节点:
			节点.hide()
	手机桌面页.hide()
	门.hide()


func 手出现() -> void:
	_进门过渡中 = true
	_隐藏界面层()
	# 新一天开场时黑屏已提前 show，手动画期间保持显示

	手.texture = 手图01
	手.modulate = Color(1, 1, 1, 0)
	手.show()

	# 进门过渡手部时间线的倒放：hand01 淡入→淡出→换 hand02→淡入
	var tw := create_tween()
	tw.tween_property(手, "modulate:a", 1.0, 0.3)
	tw.tween_property(手, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void:
		手.texture = 手图02
	)
	tw.tween_property(手, "modulate:a", 1.0, 0.2)
	await tw.finished

	# 停留在手图02；黑屏由新一天开场在结束后 hide
	手.texture = 手图02
	手.modulate = Color(1, 1, 1, 1)
	手.show()
	_进门过渡中 = false


func 播放进门过渡() -> void:
	_进门过渡中 = true
	_隐藏界面层()

	黑屏.show()
	手.texture = 手图02
	手.modulate = Color(1, 1, 1, 1)
	手.show()

	var tw := create_tween()
	tw.tween_property(手, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func() -> void:
		手.texture = 手图01
		黑屏.hide()
	)
	tw.tween_property(手, "modulate:a", 1.0, 0.25)
	tw.tween_property(手, "modulate:a", 0.0, 0.3)
	await tw.finished
	if not is_inside_tree():
		return

	手.hide()
	手.modulate = Color(1, 1, 1, 1)
	手.texture = 手图01

	# 手动画之后、门之前：女主房内2 → 房内4，再全黑
	女主.show()
	女主.modulate = Color(1, 1, 1, 1)
	await _女主换图渐变(女主图2)
	if not is_inside_tree():
		return
	await _女主换图渐变(女主图4)
	if not is_inside_tree():
		return

	全黑.color = Color(0, 0, 0, 0)
	全黑.show()
	tw = create_tween()
	tw.tween_property(全黑, "color:a", 1.0, 0.6)
	await tw.finished

	_进门过渡中 = false
