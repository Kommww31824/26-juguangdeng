extends CanvasLayer

signal 结局结束

const 通报全文 := """情况通报
10月31日10时，我所接报警称，某小区某室租客多日未出门、敲门无人应答。
民警会同120、消防到场开门后发现，租客良某已无生命体征。

经勘察走访，无他人侵入痕迹，初步判断为猝死，已排除刑事案件。

目前，街道、社区已协助联系家属并做好善后事宜。请居民尊重逝者与家属隐私，不传谣、不传播现场影像。

剡西分所；"""

const 打字间隔 := 0.04

@onready var 通报文本: Label = $Label
@onready var 感谢游玩: Sprite2D = $感谢游玩
@onready var 点击继续: Button = $点击继续

var _播放中 := false
var _打字中 := false
var _打字令牌 := 0
var _可点继续 := false


func _ready() -> void:
	hide()
	感谢游玩.hide()
	感谢游玩.modulate.a = 0.0
	通报文本.text = ""
	点击继续.hide()
	点击继续.pressed.connect(_on_点击继续)


func 开始结局() -> void:
	if _播放中:
		return
	_播放中 = true
	_可点继续 = false
	_打字令牌 += 1
	通报文本.text = ""
	感谢游玩.modulate.a = 0.0
	感谢游玩.hide()
	点击继续.hide()
	show()
	await _播放打字机(通报全文)
	if not is_inside_tree():
		return
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	感谢游玩.show()
	var tw := create_tween()
	tw.tween_property(感谢游玩, "modulate:a", 1.0, 0.8)
	await tw.finished
	if not is_inside_tree():
		return
	_可点继续 = true
	点击继续.show()


func _播放打字机(全文: String) -> void:
	_打字令牌 += 1
	var 令牌 := _打字令牌
	_打字中 = true
	通报文本.text = ""
	for i in 全文.length():
		if 令牌 != _打字令牌 or not is_inside_tree():
			return
		通报文本.text += 全文[i]
		await get_tree().create_timer(打字间隔).timeout
	if 令牌 == _打字令牌:
		_打字中 = false


func _on_点击继续() -> void:
	if not _可点继续:
		return
	_可点继续 = false
	点击继续.hide()
	全局.重置游戏()
	hide()
	_播放中 = false
	结局结束.emit()
	get_tree().change_scene_to_packed(load("res://scenes/开始.tscn"))
