class_name ShopScreen
extends Control
## Магазин скинов: сетка 2x2, под каждым скином цена (иконка монеты + число).
## Тап по ячейке: купить (если хватает монет), надеть, а по надетому скину снять.
## Заголовок и отступы повторяют главное меню, кнопка Back стоит на месте кнопки SHOP.

signal closed

const CELL_SIZE := Vector2(480, 470)
const GRID_GAP := 30

var top_inset: float = 0.0   # отступ сверху под вырез камеры (ставит main.gd)

var _coin_label: Label
var _cells: Array[PanelContainer] = []
var _rows: Array[HBoxContainer] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", int(top_inset) + 30)
	margin.add_theme_constant_override("margin_bottom", 150)
	add_child(UIKit.pass_through(margin))

	var col := VBoxContainer.new()
	margin.add_child(UIKit.pass_through(col))

	# верхний ряд как в меню: баланс монет слева (справа пусто, но высота та же)
	var top := HBoxContainer.new()
	col.add_child(UIKit.pass_through(top))
	var coin_box := HBoxContainer.new()
	coin_box.add_theme_constant_override("separation", 14)
	coin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coin_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(UIKit.pass_through(coin_box))
	var coin_icon: Control = UIKit.coin_icon(64.0)
	coin_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin_box.add_child(coin_icon)
	_coin_label = UIKit.label("", 60, UIKit.GOLD)
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	coin_box.add_child(_coin_label)
	top.add_child(UIKit.spacer(UIKit.ICON_BTN))   # держит высоту ряда равной высоте ряда меню

	col.add_child(UIKit.spacer(50))
	var title := UIKit.label("SHOP", 150)
	title.add_theme_font_override("font", Fonts.title())   # тот же шрифт, что у названия игры
	col.add_child(title)
	col.add_child(UIKit.spacer(30))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", GRID_GAP)
	grid.add_theme_constant_override("v_separation", GRID_GAP)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(UIKit.pass_through(grid))
	for i in Skins.LIST.size():
		grid.add_child(_make_cell(i))

	# кнопка Back на месте кнопки SHOP из меню
	var back := UIKit.button("Back", Vector2(380, 110), 60, UIKit.CREAM)
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)
	back.anchor_left = 0.5
	back.anchor_right = 0.5
	back.anchor_top = 1.0
	back.anchor_bottom = 1.0
	back.offset_left = -190.0
	back.offset_right = 190.0
	back.offset_top = -260.0
	back.offset_bottom = -150.0

	_refresh()


func _make_cell(i: int) -> PanelContainer:
	var skin: Dictionary = Skins.LIST[i]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CELL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_cell_input.bind(i))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(UIKit.pass_through(col))

	var preview: Control = _cat_preview(skin)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(preview)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	col.add_child(UIKit.pass_through(row))

	_cells.append(panel)
	_rows.append(row)
	return panel


## Высота обычного кота в ячейке, px. Скины с шляпой рисуются в том же масштабе (выше только полотно)
const PREVIEW_CAT_H := 260.0


## Высота области предпросмотра: самый высокий скин (со шляпой) должен помещаться
func _preview_h() -> float:
	var base: Texture2D = UIKit.art_texture("cat")
	if base == null:
		return 280.0
	var k: float = PREVIEW_CAT_H / base.get_size().y
	var h: float = PREVIEW_CAT_H
	for skin in Skins.LIST:
		var t: Texture2D = Skins.texture(skin["id"], false, base, null)
		h = maxf(h, t.get_size().y * k)
	return h + 10.0


## Кот для ячейки: спрайт (со скином или обычный) с оттенком, а если спрайтов нет, фигурный кот.
## Все коты выровнены по лапам (нижний край) и нарисованы в одном масштабе.
func _cat_preview(skin: Dictionary) -> Control:
	var id: String = skin["id"]
	var tint: Color = Skins.tint(id)
	var base: Texture2D = UIKit.art_texture("cat")
	var tex: Texture2D = Skins.texture(id, false, base, UIKit.art_texture("cat_closed"))
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, _preview_h())
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tex != null and base != null:
		var k: float = PREVIEW_CAT_H / base.get_size().y
		var sz: Vector2 = tex.get_size() * k
		var r := TextureRect.new()
		r.texture = tex
		r.modulate = tint
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(r)
		r.anchor_left = 0.5
		r.anchor_right = 0.5
		r.anchor_top = 1.0
		r.anchor_bottom = 1.0
		r.offset_left = -sz.x * 0.5
		r.offset_right = sz.x * 0.5
		r.offset_top = -sz.y
		r.offset_bottom = 0.0
		return holder
	holder.draw.connect(func() -> void:
		var col: Color = UIKit.ORANGE * tint
		var cx: float = holder.size.x * 0.5
		var bottom: float = holder.size.y - 10.0
		holder.draw_rect(Rect2(cx - 75.0, bottom - 190.0, 150.0, 190.0), col)
		holder.draw_colored_polygon(PackedVector2Array([Vector2(cx - 67.0, bottom - 190.0), Vector2(cx - 67.0, bottom - 226.0), Vector2(cx - 27.0, bottom - 190.0)]), col)
		holder.draw_colored_polygon(PackedVector2Array([Vector2(cx + 67.0, bottom - 190.0), Vector2(cx + 67.0, bottom - 226.0), Vector2(cx + 27.0, bottom - 190.0)]), col)
		holder.draw_circle(Vector2(cx - 32.0, bottom - 130.0), 10.0, UIKit.DARK)
		holder.draw_circle(Vector2(cx + 32.0, bottom - 130.0), 10.0, UIKit.DARK))
	return holder


func _on_cell_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_tap(i)


func _tap(i: int) -> void:
	var skin: Dictionary = Skins.LIST[i]
	var id: String = skin["id"]
	if SaveData.selected_skin == id:
		SaveData.selected_skin = "default"   # снять скин
		Sfx.click()
	elif SaveData.owned_skins.has(id):
		SaveData.selected_skin = id          # надеть купленный
		Sfx.click()
	elif SaveData.try_spend(int(skin["price"])):
		SaveData.owned_skins.append(id)      # купить и сразу надеть
		SaveData.selected_skin = id
		if Sfx.instance != null:
			Sfx.instance.play("done")
	else:
		_deny(i)                             # не хватает монет
		return
	SaveData.save()
	_refresh()


func _deny(i: int) -> void:
	var p: PanelContainer = _cells[i]
	p.modulate = Color(1.0, 0.55, 0.55)
	create_tween().tween_property(p, "modulate", Color.WHITE, 0.35)
	if Sfx.instance != null:
		Sfx.instance.play("wrong")


func _refresh() -> void:
	_coin_label.text = "%d" % SaveData.coins
	for i in Skins.LIST.size():
		var skin: Dictionary = Skins.LIST[i]
		var id: String = skin["id"]
		var equipped: bool = SaveData.selected_skin == id
		var owned: bool = SaveData.owned_skins.has(id)
		var border: Color = UIKit.GREEN if equipped else UIKit.DARK
		_cells[i].add_theme_stylebox_override("panel", UIKit.box(UIKit.CREAM, border, 36, 12 if equipped else 6, 20.0, 20.0))
		var row: HBoxContainer = _rows[i]
		for c in row.get_children():
			row.remove_child(c)
			c.queue_free()
		if owned:
			row.add_child(UIKit.label("EQUIPPED" if equipped else "OWNED", 48, Color("2f9e63") if equipped else UIKit.DARK, false))
		else:
			var affordable: bool = SaveData.coins >= int(skin["price"])
			row.add_child(UIKit.coin_icon(52.0))   # иконка монеты без слова Coins
			row.add_child(UIKit.label("%d" % int(skin["price"]), 52, UIKit.DARK if affordable else Color("c92a2a"), false))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.13, 0.09, 0.07, 1.0))
