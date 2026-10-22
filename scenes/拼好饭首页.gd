extends Node2D

@onready var v_box_container: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var 退出键: Node = $"退出键"
@onready var 开屏: Node2D = $开屏
@onready var 优惠券: Button = $优惠券
@onready var 签到: Control = $ScrollContainer/VBoxContainer/签到
@onready var 签到文本: Label = $ScrollContainer/VBoxContainer/签到/签到按钮/签到文本
@onready var 抽奖页面: Node2D = $抽奖页面
@onready var 转盘: Sprite2D = $抽奖页面/转盘
@onready var 点击抽奖按钮: Button = $抽奖页面/点击抽奖按钮

const 按钮场景 := preload("res://scenes/拼好饭首页按钮.tscn")
const 开屏时长 := 1.5
const 优惠券下移 := 50.0
const 优惠券动画时长 := 0.45
## 与转盘贴图一致：自顶部起逆时针五格
const 转盘奖品 := ["好饭免单", "好饭7折券", "好饭5折券", "神秘大礼", "没中"]

var _开屏令牌 := 0
var _优惠券基准位置 := Vector2.ZERO
var _优惠券tween: Tween
var _优惠券已展示 := false
var _优惠券已使用 := false
var _抽奖中 := false


func _ready() -> void:
	_优惠券基准位置 = 优惠券.position
	优惠券.hide()
	优惠券.modulate.a = 0.0
	优惠券.pressed.connect(_on_优惠券_pressed)
	点击抽奖按钮.pressed.connect(_on_点击抽奖按钮_pressed)
	抽奖页面.hide()
	全局.日已刷新.connect(刷新菜单)
	全局.数值已变化.connect(_检查优惠券)
	全局.签到已变化.connect(_刷新签到文本)
	刷新菜单()
	_刷新签到文本()
	visibility_changed.connect(_on_visibility_changed)
	显示首页内容()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# 测试：Q + P + B 载入全部正常+异常外卖（按数字id排序）
		if Input.is_key_pressed(KEY_Q) and Input.is_key_pressed(KEY_P) and Input.is_key_pressed(KEY_B):
			_测试载入全部外卖()
			get_viewport().set_input_as_handled()
		# 测试：P + O 弹出抽奖页
		elif Input.is_key_pressed(KEY_P) and Input.is_key_pressed(KEY_O):
			_测试打开抽奖页()
			get_viewport().set_input_as_handled()
		# 测试：M + P 在列表最上方插入麻辣烫
		elif Input.is_key_pressed(KEY_M) and Input.is_key_pressed(KEY_P):
			_测试插入麻辣烫()
			get_viewport().set_input_as_handled()


func _测试载入全部外卖() -> void:
	var 全部: Array = []
	for 饭 in 外卖数据终版.正常饭:
		全部.append(外卖数据终版.复制一份(饭))
	for 饭 in 外卖数据终版.异常饭:
		全部.append(外卖数据终版.复制一份(饭))
	全部.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("数字id", 0)) < int(b.get("数字id", 0))
	)
	全局.今日菜单 = 全部
	刷新菜单()
	scroll_container.scroll_vertical = 0


func _测试打开抽奖页() -> void:
	全局.七天抽奖已完成 = false
	_抽奖中 = false
	点击抽奖按钮.disabled = false
	转盘.rotation = 0.0
	抽奖页面.show()


func _测试插入麻辣烫() -> void:
	var 源: Dictionary = {}
	for 饭 in 外卖数据终版.正常饭:
		if "麻辣烫" in str(饭.get("图片", "")) or "麻辣烫" in str(饭.get("名字", "")):
			源 = 饭
			break
	if 源.is_empty():
		return
	var 饭 := 外卖数据终版.复制一份(源)
	全局.今日菜单.insert(0, 饭)
	var 按钮 := 按钮场景.instantiate()
	v_box_container.add_child(按钮)
	v_box_container.move_child(按钮, _菜单插入位置())
	按钮.配置(饭)
	scroll_container.scroll_vertical = 0


func _刷新签到文本() -> void:
	签到文本.text = "已连续签到%d天" % 全局.连续签到天数()
	_检查抽奖页面()


func _检查抽奖页面() -> void:
	if 全局.可否七天抽奖():
		抽奖页面.show()
	elif 全局.七天抽奖已完成:
		抽奖页面.hide()


func _on_点击抽奖按钮_pressed() -> void:
	if _抽奖中 or not 抽奖页面.visible:
		return
	_抽奖中 = true
	点击抽奖按钮.disabled = true
	var 结果索引 := randi() % 转盘奖品.size()
	var 扇区角 := TAU / float(转盘奖品.size())
	var 目标角 := 结果索引 * 扇区角
	var 当前 := fmod(转盘.rotation, TAU)
	if 当前 < 0.0:
		当前 += TAU
	var 补角 := 目标角 - 当前
	if 补角 < 0.0:
		补角 += TAU
	var 终角 := 转盘.rotation + float(randi_range(5, 8)) * TAU + 补角
	var tw := create_tween()
	tw.tween_property(转盘, "rotation", 终角, 4.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	if not is_inside_tree():
		return
	var 奖品 := str(转盘奖品[结果索引])
	全局.发放抽奖奖品(奖品)
	if 奖品 in ["好饭免单", "好饭7折券", "好饭5折券"]:
		刷新菜单()
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	抽奖页面.hide()
	点击抽奖按钮.disabled = false
	_抽奖中 = false


func _on_visibility_changed() -> void:
	if not visible:
		return
	if 全局.食反需要开屏:
		全局.食反需要开屏 = false
		播放开屏()
	else:
		显示首页内容()


func 播放开屏() -> void:
	_开屏令牌 += 1
	var 令牌 := _开屏令牌
	开屏.visible = true
	scroll_container.visible = false
	退出键.visible = false
	优惠券.hide()
	await get_tree().create_timer(开屏时长).timeout
	if 令牌 != _开屏令牌 or not is_inside_tree() or not visible:
		return
	显示首页内容()


func 显示首页内容() -> void:
	开屏.visible = false
	scroll_container.visible = true
	退出键.visible = true
	_检查优惠券()


func 刷新菜单() -> void:
	for 子 in v_box_container.get_children():
		if 子 == 签到:
			continue
		子.queue_free()
	# queue_free 的节点要等帧末才移除，先保证签到仍在最上方
	v_box_container.move_child(签到, 0)
	for 饭 in 全局.今日菜单:
		var 按钮 := 按钮场景.instantiate()
		v_box_container.add_child(按钮)
		按钮.配置(饭)
	var 底标签 := Label.new()
	底标签.text = "到底了......"
	底标签.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	底标签.add_theme_font_size_override("font_size", 16)
	底标签.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	v_box_container.add_child(底标签)
	_优惠券已展示 = false
	_优惠券已使用 = false
	_检查优惠券()


func _菜单插入位置() -> int:
	return 签到.get_index() + 1


func _on_优惠券_pressed() -> void:
	if _优惠券已使用 or 外卖数据终版.异常饭.is_empty():
		return
	var 饭 := 外卖数据终版.复制一份(外卖数据终版.异常饭[randi() % 外卖数据终版.异常饭.size()])
	饭["价格"] = 0.0
	饭["价格显示"] = "¥0"
	饭["名字"] = "【特惠】" + str(饭.get("名字", ""))
	饭["名字抖动"] = true
	var 送达 := str(饭.get("配送时间距离", "0分钟")).get_slice(" ", 0)
	饭["底边栏"] = "价格 ¥0 ｜ 立即配送 %s送达" % 送达
	全局.今日菜单.insert(0, 饭)
	var 按钮 := 按钮场景.instantiate()
	v_box_container.add_child(按钮)
	v_box_container.move_child(按钮, _菜单插入位置())
	按钮.配置(饭)
	_优惠券已使用 = true
	_隐藏优惠券()


func _今日菜单最低价() -> float:
	if 全局.今日菜单.is_empty():
		return 0.0
	var 最低 := INF
	for 饭 in 全局.今日菜单:
		最低 = minf(最低, 外卖数据终版.读价格(饭))
	return 最低


func _钱买不起任何一个() -> bool:
	return 全局.钱数 + 0.001 < _今日菜单最低价()


func _检查优惠券() -> void:
	if not is_inside_tree():
		return
	if not visible or 开屏.visible or _优惠券已使用:
		return
	if _钱买不起任何一个():
		_显示优惠券动画()
	else:
		_隐藏优惠券()


func _隐藏优惠券() -> void:
	if _优惠券tween and _优惠券tween.is_valid():
		_优惠券tween.kill()
	优惠券.hide()
	优惠券.modulate.a = 0.0
	优惠券.position = _优惠券基准位置
	_优惠券已展示 = false


func _显示优惠券动画() -> void:
	if _优惠券已展示:
		return
	_优惠券已展示 = true
	if _优惠券tween and _优惠券tween.is_valid():
		_优惠券tween.kill()
	优惠券.position = _优惠券基准位置 + Vector2(0, -优惠券下移)
	优惠券.modulate.a = 0.0
	优惠券.show()
	_优惠券tween = create_tween()
	_优惠券tween.set_parallel(true)
	_优惠券tween.tween_property(优惠券, "modulate:a", 1.0, 优惠券动画时长)
	_优惠券tween.tween_property(优惠券, "position:y", _优惠券基准位置.y, 优惠券动画时长)
