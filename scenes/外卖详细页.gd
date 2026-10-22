extends Node2D

const 小标签场景 := preload("res://小标签.tscn")
const 评价用户名 := ["一串神秘的用户名", "路过的拼友"]

@onready var button: Button = $Button
@onready var 按钮上价格label: Label = $按钮上价格Label
@onready var 价格: RichTextLabel = $ScrollContainer/VBoxContainer/Control/价格
@onready var 评价卡1: PanelContainer = $ScrollContainer/VBoxContainer/评价外边/Control3/评价卡1
@onready var 评价卡2: PanelContainer = $ScrollContainer/VBoxContainer/评价外边/Control3/评价卡2
@onready var 已售: Label = $ScrollContainer/VBoxContainer/Control/已售
@onready var 名字: RichTextLabel = $ScrollContainer/VBoxContainer/Control4/名字
@onready var 外卖对应食物: TextureRect = $ScrollContainer/VBoxContainer/HBoxContainer3/外卖对应食物TextureRect
@onready var 食物背景: TextureRect = $ScrollContainer/VBoxContainer/HBoxContainer3/Control/食物TextureRect2
@onready var 评分: NinePatchRect = $ScrollContainer/VBoxContainer/Control2/评分行/评分
const 粉边框色 := "FDDAE1"
const 评分字色 := Color(1, 0.37254903, 0.34117648, 1)


func 显示当前外卖() -> void:
	var 饭 := 全局.当前外卖
	var 图 := 外卖数据终版.读图片(饭)
	if 图:
		外卖对应食物.texture = 图
	食物背景.self_modulate = 外卖数据终版.取背景色(饭)
	按钮上价格label.text = str(饭.get("价格显示", ""))
	价格.text = str(饭.get("价格显示", ""))
	var 名称 := str(饭.get("名字", ""))
	if bool(饭.get("名字抖动", false)) or 名称.begins_with("【特惠】"):
		名字.text = "[shake rate=25 level=8]%s[/shake]" % 名称
	else:
		名字.text = 名称
	_套粉边框标签(评分, str(饭.get("评分", "")))
	_填充评价卡(评价卡1, str(饭.get("用户评价1", "")), 评价用户名[0])
	_填充评价卡(评价卡2, str(饭.get("用户评价2", "")), 评价用户名[1])
	已售.text = str("已售" + 饭.get("已售", ""))
	_更新口碑标签(饭)
	$ScrollContainer/VBoxContainer/小词条Label.text = str(饭.get("小词条", ""))
	_套粉边框标签($ScrollContainer/VBoxContainer/Control2/评分行/质量保证词条, str(饭.get("质量保证", "")))
	$ScrollContainer/VBoxContainer/HBoxContainer2/Control/配送费Label.text = str(饭.get("配送费", ""))
	$ScrollContainer/VBoxContainer/HBoxContainer2/Control/配送时间距离Label.text = str(饭.get("配送时间距离", ""))
	var 店名 := str(饭.get("店铺名称", ""))
	$ScrollContainer/VBoxContainer/详情外边/详情列/店铺卡/店铺行/店铺名称Label.text = 店名
	var 店字 := "店"
	if not 店名.is_empty():
		店字 = 店名.substr(0, 1)
	$ScrollContainer/VBoxContainer/详情外边/详情列/店铺卡/店铺行/店铺标/店铺字.text = 店字
	$ScrollContainer/VBoxContainer/附近拼单Label.text = str(饭.get("附近拼单", ""))
	$ScrollContainer/VBoxContainer/详情外边/详情列/套餐卡/套餐列/套餐内容Label.text = str(饭.get("套餐内容", ""))
	$ScrollContainer/VBoxContainer/详情外边/详情列/套餐卡/套餐列/套餐规格Label.text = str(饭.get("套餐规格", ""))
	$ScrollContainer/VBoxContainer/底边栏Label.text = str(饭.get("底边栏", ""))


func _填充评价卡(卡: PanelContainer, 原文: String, 用户名: String) -> void:
	var 解析 := _解析评价(原文)
	var 评论 := str(解析.get("评论", "")).strip_edges()
	var 回复 := str(解析.get("回复", "")).strip_edges()
	if 评论.is_empty() and 回复.is_empty():
		卡.hide()
		return
	卡.show()
	卡.get_node("内容/用户行/用户名").text = 用户名
	卡.get_node("内容/评论文本").text = 评论 if not 评论.is_empty() else "（配图）"
	var 商家回复: PanelContainer = 卡.get_node("内容/商家回复")
	var 回复文本: RichTextLabel = 卡.get_node("内容/商家回复/回复文本")
	if 回复.is_empty():
		商家回复.hide()
	else:
		商家回复.show()
		回复文本.text = "[b]商家回复：[/b]%s" % 回复


func _解析评价(原文: String) -> Dictionary:
	var 文本 := 原文.strip_edges()
	if 文本.is_empty() or 文本 == "配图":
		return {"评论": 文本, "回复": ""}
	var 标记列表 := ["-商家回复", "－商家回复", "—商家回复"]
	for 标记 in 标记列表:
		var i := 文本.find(标记)
		if i >= 0:
			return {
				"评论": _去引号(文本.substr(0, i)),
				"回复": _去引号(文本.substr(i + 标记.length())),
			}
	return {"评论": _去引号(文本), "回复": ""}


func _去引号(原文: String) -> String:
	var s := 原文.strip_edges()
	# 去掉成对的中英文引号
	for 对 in [["“", "”"], ["\"", "\""], ["「", "」"], ["『", "』"]]:
		if s.begins_with(对[0]) and s.ends_with(对[1]) and s.length() >= 2:
			s = s.substr(1, s.length() - 2).strip_edges()
	return s


func _套粉边框标签(标签: NinePatchRect, 文本: String) -> void:
	标签.self_modulate = Color.html(粉边框色)
	标签.设置文本(文本)
	var 字: Label = 标签.get_node("Label")
	字.add_theme_color_override("font_color", 评分字色)
	字.add_theme_font_size_override("font_size", 16)


func _更新口碑标签(饭: Dictionary) -> void:
	var 容器 := $ScrollContainer/VBoxContainer/Control4/小标签HBoxContainer
	for 子 in 容器.get_children():
		容器.remove_child(子)
		子.free()
	var 词组 := _拆口碑(str(饭.get("口碑", "")))
	for 序号 in 词组.size():
		var 标签 := 小标签场景.instantiate()
		容器.add_child(标签)
		标签.设置文本(词组[序号])
		标签.设置序号颜色(序号)


func _拆口碑(原文: String) -> PackedStringArray:
	var 结果 := PackedStringArray()
	var 表达式 := RegEx.new()
	表达式.compile("【([^】]*)】")
	for 匹配 in 表达式.search_all(原文):
		var 词 := 匹配.get_string(1).strip_edges()
		if not 词.is_empty():
			结果.append(词)
	return 结果


func _on_button_pressed() -> void:
	全局.打开页("提交订单页")
