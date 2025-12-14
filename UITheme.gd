extends Node

# UITheme.gd - 统一UI主题和样式工具
# 提供一致的颜色、样式和动画效果

class_name UITheme

# === 颜色定义 ===

# 主色调 - 东方风格紫色系
const PRIMARY = Color(0.6, 0.4, 0.8, 1.0)         # 主紫色
const PRIMARY_DARK = Color(0.4, 0.25, 0.6, 1.0)   # 深紫
const PRIMARY_LIGHT = Color(0.8, 0.6, 1.0, 1.0)   # 浅紫

# 背景色
const BG_DARK = Color(0.05, 0.05, 0.1, 1.0)       # 深色背景
const BG_MEDIUM = Color(0.1, 0.1, 0.18, 1.0)      # 中等背景
const BG_LIGHT = Color(0.15, 0.15, 0.25, 1.0)     # 浅色背景
const BG_PANEL = Color(0.12, 0.12, 0.2, 0.95)     # 面板背景

# 文字色
const TEXT_PRIMARY = Color(0.95, 0.92, 1.0, 1.0)  # 主文字
const TEXT_SECONDARY = Color(0.7, 0.68, 0.8, 1.0) # 次要文字
const TEXT_MUTED = Color(0.5, 0.48, 0.6, 1.0)     # 灰色文字
const TEXT_GOLD = Color(1.0, 0.85, 0.4, 1.0)      # 金色文字

# 功能色
const SUCCESS = Color(0.4, 0.85, 0.5, 1.0)        # 成功/生命
const WARNING = Color(1.0, 0.75, 0.3, 1.0)        # 警告
const DANGER = Color(0.9, 0.35, 0.4, 1.0)         # 危险/伤害
const INFO = Color(0.4, 0.7, 0.95, 1.0)           # 信息/经验

# 元素色（与游戏内元素对应）
const ELEMENT_FIRE = Color(1.0, 0.4, 0.2, 1.0)
const ELEMENT_ICE = Color(0.4, 0.8, 1.0, 1.0)
const ELEMENT_POISON = Color(0.6, 0.9, 0.3, 1.0)
const ELEMENT_LIGHTNING = Color(1.0, 0.95, 0.4, 1.0)

# === 样式创建函数 ===

static func create_panel_style(bg_color: Color = BG_PANEL, border_color: Color = PRIMARY_DARK,
                                border_width: int = 2, corner_radius: int = 8) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	return style

static func create_button_style_normal() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.25, 0.9)
	style.border_color = PRIMARY_DARK
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

static func create_button_style_hover() -> StyleBoxFlat:
	var style = create_button_style_normal()
	style.bg_color = Color(0.2, 0.18, 0.35, 0.95)
	style.border_color = PRIMARY
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	return style

static func create_button_style_pressed() -> StyleBoxFlat:
	var style = create_button_style_normal()
	style.bg_color = Color(0.25, 0.22, 0.4, 1.0)
	style.border_color = PRIMARY_LIGHT
	return style

static func create_button_style_disabled() -> StyleBoxFlat:
	var style = create_button_style_normal()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.7)
	style.border_color = Color(0.3, 0.3, 0.4, 0.5)
	return style

static func create_progress_bar_bg() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

static func create_progress_bar_fill(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

# === 按钮样式应用 ===

static func apply_button_style(button: Button, font_size: int = 18):
	button.add_theme_stylebox_override("normal", create_button_style_normal())
	button.add_theme_stylebox_override("hover", create_button_style_hover())
	button.add_theme_stylebox_override("pressed", create_button_style_pressed())
	button.add_theme_stylebox_override("disabled", create_button_style_disabled())
	button.add_theme_stylebox_override("focus", create_button_style_hover())
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", PRIMARY_LIGHT)
	button.add_theme_color_override("font_disabled_color", TEXT_MUTED)

static func apply_label_style(label: Label, font_size: int = 16, color: Color = TEXT_PRIMARY):
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

static func apply_title_style(label: Label, font_size: int = 48):
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT_PRIMARY)
	label.add_theme_color_override("font_shadow_color", Color(0.3, 0.2, 0.5, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)

static func apply_panel_style(panel: PanelContainer, bg_color: Color = BG_PANEL):
	panel.add_theme_stylebox_override("panel", create_panel_style(bg_color))

# === 进度条样式 ===

static func apply_health_bar_style(bar: ProgressBar):
	bar.add_theme_stylebox_override("background", create_progress_bar_bg())
	var fill = create_progress_bar_fill(SUCCESS)
	# 添加渐变效果
	bar.add_theme_stylebox_override("fill", fill)

static func apply_exp_bar_style(bar: ProgressBar):
	bar.add_theme_stylebox_override("background", create_progress_bar_bg())
	bar.add_theme_stylebox_override("fill", create_progress_bar_fill(INFO))

static func apply_custom_bar_style(bar: ProgressBar, fill_color: Color):
	bar.add_theme_stylebox_override("background", create_progress_bar_bg())
	bar.add_theme_stylebox_override("fill", create_progress_bar_fill(fill_color))

# === 卡片样式 ===

static func create_card_style(accent_color: Color = PRIMARY, selected: bool = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	if selected:
		style.bg_color = Color(0.18, 0.16, 0.28, 0.98)
		style.border_color = accent_color
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
	else:
		style.bg_color = Color(0.12, 0.11, 0.2, 0.95)
		style.border_color = accent_color.darkened(0.4)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2

	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 6
	style.shadow_offset = Vector2(2, 3)
	return style

# === 动画效果 ===

static func animate_button_press(button: Button):
	var tween = button.create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

static func animate_fade_in(node: CanvasItem, duration: float = 0.3):
	node.modulate.a = 0
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)

static func animate_slide_in(node: Control, from_offset: Vector2, duration: float = 0.3):
	var original_pos = node.position
	node.position = original_pos + from_offset
	var tween = node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "position", original_pos, duration)

static func animate_scale_in(node: Control, duration: float = 0.25):
	node.scale = Vector2(0.8, 0.8)
	node.modulate.a = 0
	var tween = node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	tween.tween_property(node, "scale", Vector2(1, 1), duration)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.8)

static func animate_hover(node: Control, hovered: bool):
	var tween = node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	if hovered:
		tween.tween_property(node, "scale", Vector2(1.03, 1.03), 0.15)
	else:
		tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.15)

# === 创建装饰元素 ===

static func create_separator(color: Color = PRIMARY_DARK) -> HSeparator:
	var sep = HSeparator.new()
	var style = StyleBoxLine.new()
	style.color = color
	style.thickness = 2
	sep.add_theme_stylebox_override("separator", style)
	return sep

static func create_glow_rect(color: Color, size: Vector2) -> ColorRect:
	var rect = ColorRect.new()
	rect.color = color
	rect.custom_minimum_size = size
	return rect
