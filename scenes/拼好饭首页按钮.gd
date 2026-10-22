extends Button

const 小标签场景 := preload("res://小标签.tscn")

var 饭: Dictionary = {}
## 价格小数点前后的字号，直接改这两个数即可
var 小数点前字号 := 26
var 小数点后字号 := 18


func 配置(饭数据: Dictionary) -> void:
	# 先写入背景色，再 duplicate，保证列表与详情页同色
	外卖数据终版.取背景色(饭数据)
	饭 = 饭数据.duplicate(true)
	$名字Label.text = str(饭.get("名字", ""))
	_更新价格显示()
	$评分Label.text = str(饭.get("评分", ""))
	$口碑小标题Label.text = str(饭.get("口碑", ""))
	_更新口碑标签()
	$配送时间Label.text = str(饭.get("配送时间", ""))
	$距离Label.text = str(饭.get("距离", ""))
	$已售份数Label.text = str(饭.get("已售", ""))
	$前标签Label.text = str(饭.get("前标签", ""))
	_更新评分店铺名()
	_更新外卖图片()
	_更新背景色()


func _更新外卖图片() -> void:
	var 图 := 外卖数据终版.读图片(饭)
	if 图:
		$外卖对应图片.texture = 图


func _更新背景色() -> void:
	$饭背景.self_modulate = 外卖数据终版.取背景色(饭)


func _更新口碑标签() -> void:
	var 容器 := $小标签滚动/小标签HBoxContainer
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


func _更新价格显示() -> void:
	var 原文 := str(饭.get("价格显示", ""))
	var 点 := 原文.find(".")
	var 前 := 原文
	var 后 := ""
	if 点 >= 0:
		前 = 原文.substr(0, 点)
		后 = 原文.substr(点)
	$价格Label.text = "[b][font_size=%d]%s[/font_size][font_size=%d]%s[/font_size][/b]" % [
		小数点前字号, 前, 小数点后字号, 后
	]


func _更新评分店铺名() -> void:
	var 评分原文 := str(饭.get("评分", "")).replace("分", "")
	var 店名 := str(饭.get("名字", ""))
	$评分店铺名Label.text = "[font_size=16]★%s[/font_size]    %s" % [评分原文, 店名]


func _on_pressed() -> void:
	全局.选中外卖(饭)
	全局.打开页("外卖详细页")
