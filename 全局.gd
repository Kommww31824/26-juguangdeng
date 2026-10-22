extends Node

signal 页请求(页名: String)
signal 数值已变化
signal 日已刷新
signal 进门过渡请求
signal 确认等待取餐请求
signal 手出现请求
signal 签到已变化


func 播放进门过渡() -> void:
	进门过渡请求.emit()

const 无手机页 := ["门", "门外场景", "吃饭场景"]
## 游戏日历：第 1 天点外卖 = 10/14 🌙11:00；开始吃饭 = 次日 🌙00:00
const 起始月 := 10
const 起始日 := 14
## 签到覆盖 10/14–10/21，共 8 天；下标 0 = 14 号
const 签到总天数 := 8
const 签到_漏签 := "漏签"
const 签到_待签 := "当天待签"
const 签到_已签 := "已签完"

var 天数 := 1
var 健康 := 5
var 钱数 := 60.0
var 今日好菜数量 := 0
var 今日坏菜数量 := 0
var 昨日吃了异常饭 := false
var 当前外卖: Dictionary = {}
var 今日菜单: Array = []
var 本餐已结算 := false
var 本餐已付款 := false
var 当前页 := "手机桌面页"
var 页历史: Array = []
var 食反需要开屏 := false
## 长度 8，依次为 14–21 号：漏签 / 当天待签 / 已签完；未到之日为空字符串
var 签到记录: Array = []
## 连续签到满 7 天的转盘抽奖是否已抽完
var 七天抽奖已完成 := false
## 本餐是否点了「不吃了」；进入下一天时清零
var 今日拒绝进食 := false
## 游戏全程剩余可拒绝进食次数
const 初始拒绝次数 := 2
var 剩余拒绝次数 := 初始拒绝次数

const 默认鼠标 := preload("res://美术素材/自定义鼠标/默认鼠标.png")
const 默认鼠标点击 := preload("res://美术素材/自定义鼠标/默认鼠标点击.png")
const 拿外卖鼠标 := preload("res://美术素材/自定义鼠标/拿外卖鼠标.png")
const 拿外卖鼠标点击 := preload("res://美术素材/自定义鼠标/拿外卖鼠标点击.png")
const 查看鼠标 := preload("res://美术素材/自定义鼠标/查看鼠标.png")
const 查看鼠标点击 := preload("res://美术素材/自定义鼠标/查看鼠标点击.png")
const 吃饭鼠标原图 := preload("res://美术素材/自定义鼠标/吃饭鼠标.png")
const 全局音效流 := preload("res://音乐音效/全局音效.mp3")
## 原图筷子尖约在 (2, 440)；缩放到最长边 128 后换算热区
const 吃饭鼠标热区原图 := Vector2(2, 440)
const 鼠标最长边 := 128

var _鼠标常态: Texture2D
var _鼠标点击: Texture2D
var _鼠标热区 := Vector2.ZERO
var _鼠标热区基准 := Vector2.ZERO
var _吃饭鼠标: Texture2D
var _吃饭鼠标热区 := Vector2.ZERO
var _全局音效: AudioStreamPlayer
const 毒抖幅度 := 4.0


func _ready() -> void:
	randomize()
	_准备吃饭鼠标()
	使用默认鼠标()
	_播放全局音效()
	初始化签到记录()
	生成今日菜单()
	数值已变化.emit()


func _播放全局音效() -> void:
	_全局音效 = AudioStreamPlayer.new()
	add_child(_全局音效)
	var 流 := 全局音效流.duplicate()
	if 流 is AudioStreamMP3:
		流.loop = true
	_全局音效.stream = 流
	_全局音效.play()


func _process(_delta: float) -> void:
	if _鼠标常态 == null:
		return
	if 健康 < 3:
		var 图 := _鼠标常态
		var 最大 := Vector2(
			maxi(0, 图.get_width() - 1),
			maxi(0, 图.get_height() - 1)
		)
		_鼠标热区 = Vector2(
			clampf(_鼠标热区基准.x + randf_range(-毒抖幅度, 毒抖幅度), 0.0, 最大.x),
			clampf(_鼠标热区基准.y + randf_range(-毒抖幅度, 毒抖幅度), 0.0, 最大.y)
		)
		_应用当前鼠标()
	elif _鼠标热区 != _鼠标热区基准:
		_鼠标热区 = _鼠标热区基准
		_应用当前鼠标()


func _准备吃饭鼠标() -> void:
	var 图 := 吃饭鼠标原图.get_image()
	var 边 := maxi(图.get_width(), 图.get_height())
	var 比例 := float(鼠标最长边) / float(边)
	图.resize(
		maxi(1, int(round(图.get_width() * 比例))),
		maxi(1, int(round(图.get_height() * 比例))),
		Image.INTERPOLATE_LANCZOS
	)
	_吃饭鼠标 = ImageTexture.create_from_image(图)
	_吃饭鼠标热区 = Vector2(
		roundi(吃饭鼠标热区原图.x * 比例),
		roundi(吃饭鼠标热区原图.y * 比例)
	)


func 使用默认鼠标() -> void:
	_切换鼠标(默认鼠标, 默认鼠标点击)


func 使用拿外卖鼠标() -> void:
	_切换鼠标(拿外卖鼠标, 拿外卖鼠标点击)


func 使用查看鼠标() -> void:
	_切换鼠标(查看鼠标, 查看鼠标点击)


func 使用吃饭鼠标() -> void:
	_切换鼠标(_吃饭鼠标, _吃饭鼠标, _吃饭鼠标热区)


func _切换鼠标(常态: Texture2D, 点击: Texture2D, 热区: Vector2 = Vector2.ZERO) -> void:
	_鼠标常态 = 常态
	_鼠标点击 = 点击
	_鼠标热区基准 = 热区
	_鼠标热区 = 热区
	_应用当前鼠标()


func _应用当前鼠标() -> void:
	if _鼠标常态 == null:
		return
	var 按下 := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	Input.set_custom_mouse_cursor(
		_鼠标点击 if 按下 else _鼠标常态,
		Input.CURSOR_ARROW,
		_鼠标热区
	)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if Input.is_key_pressed(KEY_H) and Input.is_key_pressed(KEY_P):
			健康 = 2
			数值已变化.emit()
			get_viewport().set_input_as_handled()
			return
	if _鼠标常态 == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_应用当前鼠标()


func 初始化签到记录() -> void:
	签到记录.clear()
	签到记录.resize(签到总天数)
	for i in 签到总天数:
		签到记录[i] = ""
	刷新签到状态()


## 按当前天数刷新：过去未签→漏签，今天未签→当天待签，已签保持，未来清空
func 刷新签到状态() -> void:
	if 签到记录.size() != 签到总天数:
		初始化签到记录()
		return
	var 今日索引 := 天数 - 1
	for i in 签到总天数:
		if i < 今日索引:
			if 签到记录[i] != 签到_已签:
				签到记录[i] = 签到_漏签
		elif i == 今日索引:
			if 签到记录[i] != 签到_已签:
				签到记录[i] = 签到_待签
		else:
			签到记录[i] = ""
	签到已变化.emit()


func 取签到状态(日序号: int) -> String:
	## 日序号从 1 起：1 = 14 号
	var i := 日序号 - 1
	if i < 0 or i >= 签到记录.size():
		return ""
	return str(签到记录[i])


func 能否签到(日序号: int) -> bool:
	return 日序号 == 天数 and 取签到状态(日序号) == 签到_待签


func 执行签到(日序号: int = -1) -> bool:
	if 日序号 < 0:
		日序号 = 天数
	if not 能否签到(日序号):
		return false
	签到记录[日序号 - 1] = 签到_已签
	签到已变化.emit()
	数值已变化.emit()
	return true


func 连续签到天数() -> int:
	var 连续 := 0
	for i in mini(天数, 签到总天数):
		if 签到记录[i] == 签到_已签:
			连续 += 1
		elif 签到记录[i] == 签到_待签:
			# 今天还没签，不打断已经签过的天数
			break
		else:
			连续 = 0
	return 连续


func 可否七天抽奖() -> bool:
	return not 七天抽奖已完成 and 连续签到天数() >= 7


func _确保原价(饭: Dictionary) -> void:
	if not 饭.has("原价"):
		饭["原价"] = 外卖数据终版.读价格(饭)


func _写入菜单价(饭: Dictionary, 新价: float, 优惠前缀: String = "") -> void:
	饭["价格"] = snapped(新价, 0.01)
	if 优惠前缀.is_empty():
		饭["价格显示"] = "¥%.2f" % 饭["价格"]
	elif 优惠前缀 == "免单":
		饭["价格显示"] = "¥%.1f" % 饭["价格"]
	else:
		饭["价格显示"] = "%s¥%.2f" % [优惠前缀, 饭["价格"]]
	饭["底边栏"] = "价格 %s ｜ 立即配送 %s送达" % [
		饭["价格显示"],
		str(饭.get("配送时间距离", "0分钟")).get_slice(" ", 0),
	]


## 转盘结果：好饭免单 / 好饭7折券 / 好饭5折券 / 神秘大礼 / 没中
func 发放抽奖奖品(奖品名: String) -> void:
	match 奖品名:
		"好饭免单":
			for 饭 in 今日菜单:
				_确保原价(饭)
				_写入菜单价(饭, 0.0, "免单")
		"好饭7折券":
			for 饭 in 今日菜单:
				_确保原价(饭)
				_写入菜单价(饭, float(饭["原价"]) * 0.7, "7折后")
		"好饭5折券":
			for 饭 in 今日菜单:
				_确保原价(饭)
				_写入菜单价(饭, float(饭["原价"]) * 0.5, "5折后")
		"神秘大礼":
			钱数 = snapped(钱数 + 50.0, 0.01)
			#健康 = mini(5, 健康 + 5)
			数值已变化.emit()
		"没中":
			pass
	七天抽奖已完成 = true


func 选中外卖(饭: Dictionary) -> void:
	当前外卖 = 饭.duplicate(true)
	本餐已结算 = false
	本餐已付款 = false


func 当前餐价() -> float:
	if 当前外卖.is_empty():
		return 0.0
	return 外卖数据终版.读价格(当前外卖)


func 能否付款() -> bool:
	return 钱数 + 0.001 >= 当前餐价()


func 付款买饭() -> bool:
	if 本餐已付款:
		return true
	if not 能否付款():
		return false
	钱数 = snapped(钱数 - 当前餐价(), 0.01)
	本餐已付款 = true
	数值已变化.emit()
	return true


func 结算用餐() -> void:
	if 本餐已结算 or 当前外卖.is_empty():
		return
	本餐已结算 = true
	今日拒绝进食 = false
	昨日吃了异常饭 = bool(当前外卖.get("是否异常", false))
	if 昨日吃了异常饭:
		健康 = max(0, 健康 - 1)
	数值已变化.emit()


func 登记拒绝进食() -> void:
	今日拒绝进食 = true
	剩余拒绝次数 = maxi(0, 剩余拒绝次数 - 1)
	本餐已结算 = true
	昨日吃了异常饭 = false
	数值已变化.emit()


func 进入下一天() -> void:
	天数 += 1
	当前外卖 = {}
	本餐已结算 = false
	本餐已付款 = false
	今日拒绝进食 = false
	生成今日菜单()
	刷新签到状态()
	数值已变化.emit()
	日已刷新.emit()


func 重置游戏() -> void:
	天数 = 1
	健康 = 5
	钱数 = 60.0
	今日好菜数量 = 0
	今日坏菜数量 = 0
	昨日吃了异常饭 = false
	当前外卖 = {}
	今日菜单 = []
	本餐已结算 = false
	本餐已付款 = false
	当前页 = "手机桌面页"
	页历史.clear()
	食反需要开屏 = false
	七天抽奖已完成 = false
	今日拒绝进食 = false
	剩余拒绝次数 = 初始拒绝次数
	初始化签到记录()
	生成今日菜单()
	使用默认鼠标()
	数值已变化.emit()
	日已刷新.emit()


func 打开页(页名: String, 记入历史: bool = true) -> void:
	if 记入历史 and 当前页 != 页名:
		页历史.append(当前页)
	当前页 = 页名
	页请求.emit(页名)


func 请求进门过渡() -> void:
	进门过渡请求.emit()


func 请求确认等待取餐() -> void:
	确认等待取餐请求.emit()


func 请求手出现() -> void:
	手出现请求.emit()


func 返回上一级() -> void:
	if 页历史.is_empty():
		打开页("手机桌面页", false)
		return
	打开页(str(页历史.pop_back()), false)


func 清空历史并打开(页名: String) -> void:
	页历史.clear()
	当前页 = "手机桌面页"
	打开页(页名, true)


func 是否隐藏手机(页名: String = 当前页) -> bool:
	return 页名 in 无手机页


func 是否吃饭时段(页名: String = 当前页) -> bool:
	return 页名 == "吃饭场景"


## 点外卖：起始日+(天数-1) 的 11:00；吃饭：再加一天的 00:00
func 当前时间文本() -> String:
	var 日 := 起始日 + 天数 - 1
	var 时分 := "23:00"
	if 是否吃饭时段():
		日 += 1
		时分 = "00:00"
	return "%d/%d %s" % [起始月, 日, 时分]


## 尚未进入下一天时，预告次日点外卖时间（如第1天吃完后显示 10/15 🌙11:00）
func 下一天时间文本() -> String:
	return "%d/%d 11:00" % [起始月, 起始日 + 天数]


func 生成今日菜单() -> void:
	var 正常数 := 5 if 天数 == 1 else 3
	var 异常数 := 1
	if 天数 >= 2:
		if 昨日吃了异常饭:
			异常数 = randi_range(2, 4)
		else:
			异常数 = randi_range(1, 2)
	今日好菜数量 = 正常数
	今日坏菜数量 = 异常数
	今日菜单 = 外卖数据终版.抽取(外卖数据终版.正常饭, 正常数)
	今日菜单.append_array(外卖数据终版.抽取(外卖数据终版.异常饭, 异常数))
	今日菜单.shuffle()
