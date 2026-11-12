class_name Skins
extends RefCounted


const LIST: Array = [
	{"id": "skin1", "price": 50, "sprite": "cat_skin1", "tint": Color(1.0, 0.72, 0.85)},
	{"id": "skin2", "price": 100, "sprite": "cat_skin2", "tint": Color(0.70, 0.85, 1.0)},
	{"id": "skin3", "price": 150, "sprite": "cat_skin3", "tint": Color(0.75, 1.0, 0.78)},
	{"id": "skin4", "price": 250, "sprite": "cat_skin4", "tint": Color(1.0, 0.90, 0.55)},
]


static func find(id: String) -> Dictionary:
	for s in LIST:
		if s["id"] == id:
			return s
	return {}


## Картинка кота для скина (closed = глаза закрыты). Нет спрайта скина: берутся обычные open_default / closed_default
static func texture(id: String, closed: bool, open_default: Texture2D, closed_default: Texture2D) -> Texture2D:
	var s: Dictionary = find(id)
	if not s.is_empty() and s["sprite"] != "":
		var open_tex: Texture2D = UIKit.art_texture(s["sprite"])
		if open_tex != null:
			if closed:
				var closed_tex: Texture2D = UIKit.art_texture(s["sprite"] + "_closed")
				return closed_tex if closed_tex != null else open_tex
			return open_tex
	if closed and closed_default != null:
		return closed_default
	return open_default


## Оттенок: у настоящего спрайта скина оттенка нет
static func tint(id: String) -> Color:
	var s: Dictionary = find(id)
	if s.is_empty():
		return Color.WHITE
	if s["sprite"] != "" and UIKit.art_texture(s["sprite"]) != null:
		return Color.WHITE
	return s["tint"]
