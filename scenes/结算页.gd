extends Node2D

signal 确认继续

const 收货人名字 := "良九"
const 异常表情池 := [
	preload("res://美术素材/结算页素材/结算表情1.png"),
	preload("res://美术素材/结算页素材/结算表情3.png"),
]
const 正常表情 := preload("res://美术素材/结算页素材/结算表情2.png")

@onready var 下单时间值: Label = $纸/下单时间值
@onready var 收货人值: Label = $纸/收货人值
@onready var 商品名: Label = $纸/商品名
@onready var 商品价格: Label = $纸/商品价格
@onready var 余额值: Label = $纸/余额值
@onready var 健康说明: Label = $纸/健康说明
@onready var 健康心: Label = $纸/健康心
@onready var 是否拒绝: Label = $纸/是否拒绝
@onready var 剩余拒绝次数值: Label = $纸/剩余拒绝次数值
@onready var 脚注: Label = $纸/脚注
@onready var 结算页表情: Sprite2D = $纸/结算页表情
@onready var 点击: Button = $点击
@onready var 下一天按钮: Button = $下一天


func _ready() -> void:
	点击.pressed.connect(_on_点击)
	下一天按钮.pressed.connect(_on_下一天)
	hide()


func 显示结算() -> void:
	_刷新内容()
	下一天按钮.hide()
	点击.disabled = false
	show()


func _刷新内容() -> void:
	var 饭 := 全局.当前外卖
	var 日 := 全局.起始日 + 全局.天数 - 1
	下单时间值.text = "%d月%d日 11:00" % [全局.起始月, 日]
	收货人值.text = 收货人名字
	商品名.text = str(饭.get("名字", "未知外卖"))
	商品价格.text = _价格文本(饭)
	余额值.text = "￥ %.2f" % 全局.钱数
	var 心数 := clampi(全局.健康, 0, 5)
	健康心.text = "%s%s" % ["♥".repeat(心数), "♡".repeat(5 - 心数)]
	健康说明.text = _健康说明文本(心数)
	是否拒绝.text = "是" if 全局.今日拒绝进食 else "否"
	剩余拒绝次数值.text = str(全局.剩余拒绝次数)
	脚注.text = _脚注文本(饭)
	_刷新表情()


func _刷新表情() -> void:
	# 吃了异常饭（健康-1）→ 表情1/3 随机；正常饭或未减健康 → 表情2
	if 全局.昨日吃了异常饭:
		结算页表情.texture = 异常表情池[randi() % 异常表情池.size()]
	else:
		结算页表情.texture = 正常表情


func _价格文本(饭: Dictionary) -> String:
	var 显示 := str(饭.get("价格显示", "")).strip_edges()
	if 显示.is_empty():
		return "￥ %.2f" % 外卖数据终版.读价格(饭)
	if 显示.begins_with("¥") or 显示.begins_with("￥"):
		return "￥ " + 显示.substr(1).strip_edges()
	if 显示.is_valid_float() or 显示.replace(".", "").is_valid_int():
		return "￥ %.2f" % 显示.to_float()
	return 显示


func _健康说明文本(心数: int) -> String:
	match 心数:
		5:
			return "您的健康度很饱满。"
		4, 3:
			return "您的健康度有些下降。"
		2, 1:
			return "您的健康度下降了。"
		_:
			return "您的健康度完全下降了！"


func _脚注文本(饭: Dictionary) -> String:
	if 全局.今日拒绝进食:
		return "今天没有吃饭。"
	if bool(饭.get("是否异常", false)):
		return "不详的预感加深了！"
	return "今天也算吃上了。"


func _on_点击() -> void:
	点击.disabled = true
	下一天按钮.show()


func _on_下一天() -> void:
	下一天按钮.hide()
	hide()
	确认继续.emit()
