extends PanelContainer


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
