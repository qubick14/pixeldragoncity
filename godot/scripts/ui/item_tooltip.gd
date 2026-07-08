extends PanelContainer


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.045, 0.96)
	style.border_color = Color(0.62, 0.42, 0.18, 1.0)
	style.set_border_width_all(2)
	add_theme_stylebox_override("panel", style)


func set_item(data: Dictionary) -> void:
	visible = true
	$Content/NameLabel.text = String(data.get("display_name", data.get("item_id", "")))
	$Content/KindLabel.text = String(data.get("kind", ""))
	$Content/QualityLabel.text = String(data.get("quality", ""))
	$Content/DescriptionLabel.text = String(data.get("description", ""))
	$Content/PriceLabel.text = "Buy %d / Sell %d" % [
		int(data.get("price", 0)),
		int(data.get("sell_price", 0)),
	]


func hide_tooltip() -> void:
	visible = false
