extends Node2D

@onready var button: Button = $Button
@onready var 钱不够提示: Label = $钱不够提示
@onready var 支付成功: Node2D = $支付成功
@onready var 余额: Label = $支付成功/余额

var _支付中 := false


func _ready() -> void:
	#button.text = "提交订单"
	钱不够提示.hide()
	支付成功.hide()


func 显示当前外卖() -> void:
	var 饭 := 全局.当前外卖
	var 图 := 外卖数据终版.读图片(饭)
	if 图:
		$食物对应TextureRect.texture = 图
	$名字Label.text = str(饭.get("名字", ""))
	$价格Label.text = str(饭.get("价格显示", ""))
	$小计Label.text = "%s" % str(饭.get("价格显示", "¥%.2f" % 全局.当前餐价()))
	$小计Label2.text = "%s" % str(饭.get("价格显示", "¥%.2f" % 全局.当前餐价()))
	$支付方式Label.text = "负宝支付√"
	钱不够提示.hide()
	支付成功.hide()
	_支付中 = false


func _on_button_pressed() -> void:
	if _支付中:
		return
	if not 全局.付款买饭():
		钱不够提示.text = "钱不够 ¥%.2f，支付失败。" % 全局.当前餐价()
		钱不够提示.show()
		支付成功.hide()
		return
	钱不够提示.hide()
	_支付中 = true
	余额.text = "¥" +str(全局.钱数)
	支付成功.show()
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	全局.打开页("订单进度页")
