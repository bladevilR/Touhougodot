extends Control

# MetaUpgradeMenu.gd - 局外升级界面美化版
# 显示和管理局外永久升级

@onready var currency_label = $TopBar/CurrencyContainer/CurrencyLabel
@onready var title_label = $TopBar/TitleLabel
@onready var category_container = $MainContainer/LeftPanel/CategoryContainer
@onready var upgrade_scroll = $MainContainer/RightPanel/UpgradeScroll
@onready var upgrade_grid = $MainContainer/RightPanel/UpgradeScroll/UpgradeGrid
@onready var detail_panel = $MainContainer/RightPanel/DetailPanel
@onready var detail_name = $MainContainer/RightPanel/DetailPanel/MarginContainer/VBoxContainer/NameLabel
@onready var detail_desc = $MainContainer/RightPanel/DetailPanel/MarginContainer/VBoxContainer/DescLabel
@onready var detail_level = $MainContainer/RightPanel/DetailPanel/MarginContainer/VBoxContainer/LevelLabel
@onready var detail_effect = $MainContainer/RightPanel/DetailPanel/MarginContainer/VBoxContainer/EffectLabel
@onready var detail_cost = $MainContainer/RightPanel/DetailPanel/MarginContainer/VBoxContainer/CostLabel
@onready var purchase_button = $MainContainer/RightPanel/DetailPanel/MarginContainer/VBoxContainer/PurchaseButton
@onready var back_button = $TopBar/BackButton
@onready var left_panel = $MainContainer/LeftPanel

var current_category: MetaProgressionData.UpgradeCategory = MetaProgressionData.UpgradeCategory.BASIC
var selected_upgrade_id: String = ""
var category_buttons: Array[Button] = []
var upgrade_cards: Dictionary = {}

func _ready():
	MetaProgressionData.initialize()

	_setup_ui_style()
	_create_category_buttons()
	_update_currency_display()
	_show_category(current_category)
	_hide_detail_panel()

	back_button.pressed.connect(_on_back_pressed)
	purchase_button.pressed.connect(_on_purchase_pressed)

	if MetaProgressionManager:
		MetaProgressionManager.currency_changed.connect(_on_currency_changed)
		MetaProgressionManager.upgrade_purchased.connect(_on_upgrade_purchased)

	_animate_intro()

func _setup_ui_style():
	UITheme.apply_title_style(title_label, 32)
	UITheme.apply_label_style(currency_label, 26, UITheme.TEXT_GOLD)
	UITheme.apply_button_style(back_button, 16)
	UITheme.apply_button_style(purchase_button, 18)
	UITheme.apply_panel_style(left_panel)
	UITheme.apply_panel_style(detail_panel)

var _button_group: ButtonGroup

func _get_or_create_button_group() -> ButtonGroup:
	if _button_group == null:
		_button_group = ButtonGroup.new()
	return _button_group

func _create_category_buttons():
	var categories = [
		MetaProgressionData.UpgradeCategory.BASIC,
		MetaProgressionData.UpgradeCategory.OFFENSE,
		MetaProgressionData.UpgradeCategory.DEFENSE,
		MetaProgressionData.UpgradeCategory.UTILITY,
		MetaProgressionData.UpgradeCategory.SPECIAL
	]

	for i in range(categories.size()):
		var category = categories[i]
		var button = Button.new()
		button.text = MetaProgressionData.get_category_name(category)
		button.custom_minimum_size = Vector2(200, 55)
		button.toggle_mode = true
		button.button_group = _get_or_create_button_group()

		var color = MetaProgressionData.get_category_color(category)
		_style_category_button(button, color)

		button.pressed.connect(_on_category_selected.bind(category))
		category_container.add_child(button)
		category_buttons.append(button)

		if category == current_category:
			button.button_pressed = true

func _style_category_button(button: Button, color: Color):
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	normal_style.border_width_left = 4
	normal_style.border_width_right = 0
	normal_style.border_width_top = 0
	normal_style.border_width_bottom = 0
	normal_style.border_color = color.darkened(0.4)
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_bottom_left = 6
	button.add_theme_stylebox_override("normal", normal_style)

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.6)
	pressed_style.border_color = color.lightened(0.2)
	pressed_style.border_width_left = 6
	button.add_theme_stylebox_override("pressed", pressed_style)

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.14, 0.13, 0.2, 0.95)
	hover_style.border_color = color
	button.add_theme_stylebox_override("hover", hover_style)

	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", color.lightened(0.3))
	button.add_theme_color_override("font_pressed_color", color.lightened(0.5))

func _update_currency_display():
	var currency = MetaProgressionManager.get_currency() if MetaProgressionManager else 0
	currency_label.text = str(currency)

func _show_category(category: MetaProgressionData.UpgradeCategory):
	current_category = category

	for child in upgrade_grid.get_children():
		child.queue_free()
	upgrade_cards.clear()

	var upgrades = MetaProgressionData.get_upgrades_by_category(category)

	for i in range(upgrades.size()):
		var upgrade = upgrades[i]
		var card = _create_upgrade_card(upgrade)
		upgrade_grid.add_child(card)
		upgrade_cards[upgrade.id] = card

		# 延迟动画
		card.modulate.a = 0
		card.scale = Vector2(0.9, 0.9)
		await get_tree().create_timer(0.03).timeout
		var tween = card.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.2)
		tween.tween_property(card, "scale", Vector2(1, 1), 0.25)

	_hide_detail_panel()

func _create_upgrade_card(upgrade: MetaProgressionData.MetaUpgrade) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 140)

	var style = UITheme.create_card_style(MetaProgressionData.get_category_color(upgrade.category), false)
	card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# 名称
	var name_label = Label.new()
	name_label.text = upgrade.name
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", MetaProgressionData.get_category_color(upgrade.category).lightened(0.3))
	vbox.add_child(name_label)

	# 等级进度
	var level = MetaProgressionManager.get_upgrade_level(upgrade.id) if MetaProgressionManager else 0

	var level_container = HBoxContainer.new()
	level_container.add_theme_constant_override("separation", 8)
	vbox.add_child(level_container)

	var level_label = Label.new()
	level_label.text = "Lv.%d/%d" % [level, upgrade.max_level]
	level_label.add_theme_font_size_override("font_size", 13)
	level_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	level_label.name = "LevelLabel"
	level_container.add_child(level_label)

	var progress = ProgressBar.new()
	progress.min_value = 0
	progress.max_value = upgrade.max_level
	progress.value = level
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(100, 10)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.name = "ProgressBar"
	UITheme.apply_custom_bar_style(progress, MetaProgressionData.get_category_color(upgrade.category))
	level_container.add_child(progress)

	# 描述（简短）
	var desc_label = Label.new()
	desc_label.text = upgrade.description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.y = 30
	vbox.add_child(desc_label)

	# 花费
	var cost = upgrade.get_cost_for_level(level)
	var cost_label = Label.new()
	cost_label.name = "CostLabel"
	if cost >= 0:
		cost_label.text = "花费: %d" % cost
		var can_afford = MetaProgressionManager.can_afford(cost) if MetaProgressionManager else false
		cost_label.add_theme_color_override("font_color", UITheme.SUCCESS if can_afford else UITheme.DANGER)
	else:
		cost_label.text = "已满级"
		cost_label.add_theme_color_override("font_color", UITheme.WARNING)
	cost_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(cost_label)

	card.gui_input.connect(_on_card_clicked.bind(upgrade.id))
	card.mouse_entered.connect(_on_card_hover.bind(card, upgrade, true))
	card.mouse_exited.connect(_on_card_hover.bind(card, upgrade, false))

	card.set_meta("upgrade_id", upgrade.id)
	return card

func _on_card_clicked(event: InputEvent, upgrade_id: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_upgrade(upgrade_id)

func _on_card_hover(card: PanelContainer, upgrade: MetaProgressionData.MetaUpgrade, hovered: bool):
	var is_selected = card.get_meta("upgrade_id") == selected_upgrade_id
	var style = UITheme.create_card_style(MetaProgressionData.get_category_color(upgrade.category), is_selected or hovered)
	card.add_theme_stylebox_override("panel", style)

	if not is_selected:
		UITheme.animate_hover(card, hovered)

func _select_upgrade(upgrade_id: String):
	selected_upgrade_id = upgrade_id
	var upgrade = MetaProgressionData.UPGRADES.get(upgrade_id)
	if upgrade == null:
		_hide_detail_panel()
		return

	# 更新所有卡片样式
	for id in upgrade_cards:
		var card = upgrade_cards[id]
		var upg = MetaProgressionData.UPGRADES.get(id)
		var is_selected = id == selected_upgrade_id
		var style = UITheme.create_card_style(MetaProgressionData.get_category_color(upg.category), is_selected)
		card.add_theme_stylebox_override("panel", style)

	_show_detail_panel(upgrade)

func _show_detail_panel(upgrade: MetaProgressionData.MetaUpgrade):
	var level = MetaProgressionManager.get_upgrade_level(upgrade.id) if MetaProgressionManager else 0
	var color = MetaProgressionData.get_category_color(upgrade.category)

	detail_name.text = upgrade.name
	detail_name.add_theme_color_override("font_color", color.lightened(0.3))

	detail_desc.text = upgrade.description

	detail_level.text = "等级: %d / %d" % [level, upgrade.max_level]

	var current_effect = upgrade.get_effect_at_level(level)
	var next_effect = upgrade.get_effect_at_level(level + 1)
	if level < upgrade.max_level:
		detail_effect.text = "效果: +%.1f → +%.1f" % [current_effect, next_effect]
		detail_effect.add_theme_color_override("font_color", UITheme.SUCCESS)
	else:
		detail_effect.text = "效果: +%.1f (最大)" % current_effect
		detail_effect.add_theme_color_override("font_color", UITheme.WARNING)

	var cost = upgrade.get_cost_for_level(level)
	if cost >= 0:
		detail_cost.text = "升级花费: %d 灵魂碎片" % cost
		var can_afford = MetaProgressionManager.can_afford(cost) if MetaProgressionManager else false
		purchase_button.disabled = not can_afford
		purchase_button.text = "升级" if can_afford else "碎片不足"
		detail_cost.add_theme_color_override("font_color", UITheme.SUCCESS if can_afford else UITheme.DANGER)
	else:
		detail_cost.text = "已达到最大等级"
		detail_cost.add_theme_color_override("font_color", UITheme.WARNING)
		purchase_button.disabled = true
		purchase_button.text = "已满级"

	if detail_panel.modulate.a < 1.0:
		var tween = detail_panel.create_tween()
		tween.tween_property(detail_panel, "modulate:a", 1.0, 0.2)

func _hide_detail_panel():
	detail_panel.modulate.a = 0
	selected_upgrade_id = ""

func _refresh_upgrade_card(upgrade_id: String):
	if not upgrade_cards.has(upgrade_id):
		return

	var old_card = upgrade_cards[upgrade_id]
	var index = old_card.get_index()
	old_card.queue_free()

	var upgrade = MetaProgressionData.UPGRADES.get(upgrade_id)
	if upgrade:
		var new_card = _create_upgrade_card(upgrade)
		upgrade_grid.add_child(new_card)
		upgrade_grid.move_child(new_card, index)
		upgrade_cards[upgrade_id] = new_card

		if upgrade_id == selected_upgrade_id:
			var style = UITheme.create_card_style(MetaProgressionData.get_category_color(upgrade.category), true)
			new_card.add_theme_stylebox_override("panel", style)

func _animate_intro():
	title_label.modulate.a = 0
	currency_label.modulate.a = 0

	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(currency_label, "modulate:a", 1.0, 0.3)

	for i in range(category_buttons.size()):
		category_buttons[i].modulate.a = 0
		await get_tree().create_timer(0.05).timeout
		var btn_tween = category_buttons[i].create_tween()
		btn_tween.tween_property(category_buttons[i], "modulate:a", 1.0, 0.2)

# === 回调 ===

func _on_category_selected(category: MetaProgressionData.UpgradeCategory):
	_show_category(category)

func _on_purchase_pressed():
	if selected_upgrade_id.is_empty():
		return

	if MetaProgressionManager and MetaProgressionManager.purchase_upgrade(selected_upgrade_id):
		_refresh_upgrade_card(selected_upgrade_id)
		_select_upgrade(selected_upgrade_id)

		# 购买成功动画
		var tween = purchase_button.create_tween()
		tween.tween_property(purchase_button, "modulate", Color(0.5, 1.0, 0.5), 0.1)
		tween.tween_property(purchase_button, "modulate", Color.WHITE, 0.15)

func _on_currency_changed(new_amount: int):
	_update_currency_display()

	# 货币变化动画
	var tween = currency_label.create_tween()
	tween.tween_property(currency_label, "scale", Vector2(1.15, 1.15), 0.1)
	tween.tween_property(currency_label, "scale", Vector2(1.0, 1.0), 0.15)

	_show_category(current_category)
	if not selected_upgrade_id.is_empty():
		_select_upgrade(selected_upgrade_id)

func _on_upgrade_purchased(upgrade_id: String, _new_level: int):
	_refresh_upgrade_card(upgrade_id)

func _on_back_pressed():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		if is_instance_valid(self):
			get_tree().change_scene_to_file("res://TitleScreen.tscn")
	)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
