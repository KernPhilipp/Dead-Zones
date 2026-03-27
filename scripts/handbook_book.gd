extends Control

const ZombieHandbookData = preload("res://scripts/zombie_handbook_data.gd")

@onready var chapter_tabs: HBoxContainer = $BookFrame/OuterMargin/RootVBox/ChapterTabsBg/TabsMargin/ChapterTabs
@onready var chapter_label: Label = $BookFrame/OuterMargin/RootVBox/ContentRow/LeftColumn/LeftMargin/LeftVBox/ChapterLabel
@onready var entry_tree: Tree = $BookFrame/OuterMargin/RootVBox/ContentRow/LeftColumn/LeftMargin/LeftVBox/EntryTree
@onready var page_title: Label = $BookFrame/OuterMargin/RootVBox/ContentRow/RightColumn/RightMargin/RightVBox/TitleRibbon/RibbonMargin/PageTitle
@onready var page_image: TextureRect = $BookFrame/OuterMargin/RootVBox/ContentRow/RightColumn/RightMargin/RightVBox/ContentSplit/PortraitPanel/PortraitMargin/PageImage
@onready var page_image_hint: Label = $BookFrame/OuterMargin/RootVBox/ContentRow/RightColumn/RightMargin/RightVBox/ContentSplit/PortraitPanel/PortraitMargin/PageImageHint
@onready var page_body: RichTextLabel = $BookFrame/OuterMargin/RootVBox/ContentRow/RightColumn/RightMargin/RightVBox/ContentSplit/BodyPanel/BodyMargin/PageBody
@onready var page_counter: Label = $BookFrame/OuterMargin/RootVBox/ContentRow/RightColumn/RightMargin/RightVBox/Footer/PageCounter
@onready var page_group_label: Label = $BookFrame/OuterMargin/RootVBox/ContentRow/RightColumn/RightMargin/RightVBox/Footer/GroupLabel
@onready var close_button: Button = $BookFrame/OuterMargin/RootVBox/TopBar/CloseButton
@onready var prev_button: Button = $BookFrame/OuterMargin/RootVBox/ContentRow/RightColumn/RightMargin/RightVBox/Footer/PrevButton
@onready var next_button: Button = $BookFrame/OuterMargin/RootVBox/ContentRow/RightColumn/RightMargin/RightVBox/Footer/NextButton

var pages: Array[Dictionary] = []
var current_page_index: int = -1
var chapter_order: Array[String] = []
var chapter_to_page_indices: Dictionary = {}
var current_chapter: String = ""
var tab_style_normal: StyleBoxFlat
var tab_style_hover: StyleBoxFlat
var tab_style_pressed: StyleBoxFlat
var tab_style_focus: StyleBoxFlat
var _suppress_tree_selection_signal: bool = false

const CHAPTER_ICON_MAP: Dictionary = {
	"Uebersicht": "<>",
	"Zombie-Arten": "ZX",
	"Todesarten": "DT",
	"Grundlagen": "GL"
}
const ENTRY_PLACEHOLDER_IMAGE_PATH := "res://assets/handbook/placeholder_missing.svg"

func _ready():
	visible = false
	_build_pages()
	_build_navigation_model()
	_build_tab_theme()
	_build_chapter_tabs()
	_apply_visual_accents()

	entry_tree.item_selected.connect(_on_tree_selected)
	close_button.pressed.connect(_on_close_pressed)
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)

	if not chapter_order.is_empty():
		_select_chapter(chapter_order[0], -1)

func open_book():
	visible = true
	if current_page_index < 0 and not pages.is_empty():
		_show_page(0)
	entry_tree.grab_focus()

func close_book():
	visible = false

func is_open() -> bool:
	return visible

func _build_pages():
	pages.clear()
	_add_page(
		"Uebersicht",
		"",
		"Feldhandbuch der Untoten",
		_build_main_overview_page(),
		"",
		_build_main_overview_side_panel()
	)

	var handbook_categories: Array[Dictionary] = ZombieHandbookData.get_handbook_categories()
	var species_entries: Array[Dictionary] = ZombieHandbookData.get_species_entries()
	var species_by_category: Dictionary = {}
	for category in handbook_categories:
		species_by_category[String(category["name"])] = []
	for entry in species_entries:
		var category_name: String = String(entry["handbook_category_name"])
		if not species_by_category.has(category_name):
			species_by_category[category_name] = []
		var list_ref: Array = species_by_category[category_name]
		list_ref.append(entry)

	_add_page(
		"Zombie-Arten",
		"",
		"Artenuebersicht",
		"Alle Zombiearten sind hier nach [b]Handbuch-Kategorien[/b] geordnet."
	)

	for category in handbook_categories:
		var category_name: String = String(category["name"])
		var category_list: Array = species_by_category.get(category_name, [])
		var overview_lines: Array[String] = []
		for entry in category_list:
			overview_lines.append("- " + String(entry["name"]))

		var overview_body: String = String(category["description"]) + "\n\n"
		overview_body += "[b]Arten in dieser Kategorie:[/b]\n" + _join_lines(overview_lines)
		_add_page("Zombie-Arten", category_name, category_name, overview_body)

		for entry in category_list:
			var species_body: String = ""
			species_body += "[b]Kategorie:[/b] " + String(entry["handbook_category_name"]) + "\n"
			species_body += "[b]Interne ID:[/b] " + String(entry["internal_id"]) + "\n\n"
			species_body += "[b]Aussehen:[/b]\n" + String(entry["appearance_description"]) + "\n\n"
			species_body += "[b]Kurzbeschreibung:[/b]\n" + String(entry["short_description"]) + "\n\n"
			species_body += "[b]Funktionsprofil:[/b]\n" + String(entry["functional_profile"]) + "\n\n"
			species_body += "[b]Bedrohungsprofil:[/b]\n" + String(entry["threat_profile"]) + "\n\n"
			species_body += "[b]Notiz:[/b]\n" + String(entry["notes"])
			_add_page(
				"Zombie-Arten",
				category_name,
				String(entry["name"]),
				species_body,
				String(entry["handbook_image"]),
				"",
				true
			)

	var death_class_entries: Array[Dictionary] = ZombieHandbookData.get_death_class_entries()
	var death_subtype_entries: Array[Dictionary] = ZombieHandbookData.get_death_subtype_entries()
	var death_subtypes_by_class: Dictionary = {}
	for death_class_entry in death_class_entries:
		death_subtypes_by_class[String(death_class_entry["name"])] = []
	for subtype_entry in death_subtype_entries:
		var death_class_name: String = String(subtype_entry["death_class_name"])
		if not death_subtypes_by_class.has(death_class_name):
			death_subtypes_by_class[death_class_name] = []
		var subtype_list: Array = death_subtypes_by_class[death_class_name]
		subtype_list.append(subtype_entry)

	_add_page(
		"Todesarten",
		"",
		"Todesarten-Uebersicht",
		"Jede Todesart gehoert zu genau einer Todesklasse und hat eine Seltenheit."
	)
	for death_class_entry in death_class_entries:
		var death_class_name: String = String(death_class_entry["name"])
		var overview_body: String = "Todesarten in der Klasse [b]" + death_class_name + "[/b]."
		_add_page("Todesarten", death_class_name, death_class_name, overview_body)

		for subtype_entry in death_subtypes_by_class.get(death_class_name, []):
			var subtype_body: String = ""
			subtype_body += "[b]Todesklasse:[/b] " + String(subtype_entry["death_class_name"]) + "\n"
			subtype_body += "[b]Seltenheit:[/b] " + String(subtype_entry["rarity_name"]) + "\n"
			subtype_body += "[b]Implementierungsstatus:[/b] " + String(subtype_entry["implementation_status_name"]) + "\n"
			subtype_body += "[b]RacheBonus:[/b] " + ("Ja" if bool(subtype_entry["revenge_bonus"]) else "Nein") + "\n"
			subtype_body += "[b]Interne ID:[/b] " + String(subtype_entry["id"]) + "\n\n"
			subtype_body += "[b]Beschreibung:[/b]\n" + String(subtype_entry["description"]) + "\n\n"
			subtype_body += "[b]Effekt jetzt:[/b]\n" + String(subtype_entry["runtime_effect"]) + "\n\n"
			subtype_body += "[b]Gameplay-Folge (geprueft):[/b]\n" + String(subtype_entry["gameplay_followup"]) + "\n\n"
			subtype_body += "[b]Gefahr:[/b] " + String(subtype_entry["danger_hint"]) + "\n"
			subtype_body += "[b]Konter:[/b] " + String(subtype_entry["counter_hint"]) + "\n\n"

			var active_hook_lines: Array[String] = []
			for hook_name in subtype_entry.get("active_hooks", []):
				active_hook_lines.append("- " + String(hook_name))
			var planned_hook_lines: Array[String] = []
			for hook_name in subtype_entry.get("planned_hooks", []):
				planned_hook_lines.append("- " + String(hook_name))

			subtype_body += "[b]Aktive Runtime-Hooks:[/b]\n" + _join_lines(active_hook_lines) + "\n\n"
			subtype_body += "[b]Spaeter geplant:[/b]\n" + _join_lines(planned_hook_lines) + "\n\n"
			subtype_body += "[b]AI-Art-Prompt:[/b]\n" + String(subtype_entry["ai_prompt"])

			_add_page(
				"Todesarten",
				death_class_name,
				String(subtype_entry["name"]),
				subtype_body,
				String(subtype_entry["image_path"]),
				"",
				true
			)

	_add_page("Grundlagen", "", "Gameplay-Klassen", _build_gameplay_classes_page())
	_add_page("Grundlagen", "", "Mort-Grad", _build_mort_grade_page())
	_add_page("Grundlagen", "", "Rang-Hierarchie", _build_rank_page())
	_add_page("Grundlagen", "", "Wellen-System", _build_wave_runtime_page())
	_add_page("Grundlagen", "", "Seltenheitssystem", _build_rarity_page())
	_add_page(
		"Grundlagen",
		"",
		"Systemtrennung",
		"[b]Wichtig:[/b] Gameplay-Klasse und Todesklasse sind strikt getrennte Layer.\n"
		+ "Handbuch-Kategorien dienen nur der Anzeige und Sortierung."
	)

func _build_gameplay_classes_page() -> String:
	var lines: Array[String] = []
	for class_entry in ZombieHandbookData.get_gameplay_class_glossary():
		lines.append("- " + String(class_entry["name"]) + ": " + String(class_entry["description"]))
	return "[b]Gameplay-Klassen:[/b]\n" + _join_lines(lines)

func _build_mort_grade_page() -> String:
	var mort: Dictionary = ZombieHandbookData.get_mort_grade_glossary()
	var text: String = "[b]" + String(mort["name"]) + "[/b]\n"
	text += String(mort["description"]) + "\n\n"
	text += "[b]Neutralpunkt:[/b] Grad " + str(int(mort["neutral_grade"])) + "\n"
	text += String(mort["distribution_focus"]) + "\n"
	text += String(mort["distribution_note"]) + "\n\n"
	text += "- " + String(mort["low_mort"]) + "\n"
	text += "- " + String(mort["high_mort"]) + "\n\n"
	text += "[b]Stufenbereiche:[/b]\n"
	for tier_note in mort.get("tier_notes", []):
		text += "- " + String(tier_note) + "\n"

	text += "\n[b]Gewichtete Spawn-Verteilung (0-10):[/b]\n"
	for entry in mort.get("entries", []):
		var grade: int = int(entry["grade"])
		var probability_percent: float = float(entry["probability_percent"])
		var speed_mult: float = float(entry["speed_mult"])
		var damage_mult: float = float(entry["damage_mult"])
		var attack_mult: float = float(entry["attack_cooldown_mult"])
		text += "- Grad %d | Spawn %.6f%% | Tempo x%.3f | Schaden x%.3f | Attack-CD x%.3f\n" % [
			grade,
			probability_percent,
			speed_mult,
			damage_mult,
			attack_mult
		]
	return text

func _build_rank_page() -> String:
	var text: String = "[b]Rangstufen (Tabellenansicht):[/b]\n\n"
	text += "[table=10]"
	text += "[cell][b]Rang[/b][/cell]"
	text += "[cell][b]Power[/b][/cell]"
	text += "[cell][b]Groesse[/b][/cell]"
	text += "[cell][b]HP[/b][/cell]"
	text += "[cell][b]Schaden[/b][/cell]"
	text += "[cell][b]Tempo[/b][/cell]"
	text += "[cell][b]Threat[/b][/cell]"
	text += "[cell][b]Intervall[/b][/cell]"
	text += "[cell][b]Speed-Cap[/b][/cell]"
	text += "[cell][b]Visual[/b][/cell]"

	for rank_entry in ZombieHandbookData.get_rank_glossary():
		text += "[cell]%s[/cell]" % String(rank_entry["name"])
		text += "[cell]%d[/cell]" % int(rank_entry["rank_power"])
		text += "[cell]x%.2f[/cell]" % float(rank_entry["size_mult"])
		text += "[cell]x%.2f[/cell]" % float(rank_entry["health_mult"])
		text += "[cell]x%.2f[/cell]" % float(rank_entry["damage_mult"])
		text += "[cell]x%.2f[/cell]" % float(rank_entry["speed_mult"])
		text += "[cell]x%.2f[/cell]" % float(rank_entry["threat_mult"])
		text += "[cell]x%.2f[/cell]" % float(rank_entry["spawn_interval_factor"])
		text += "[cell]%.2f[/cell]" % float(rank_entry["speed_cap"])
		text += "[cell]%s[/cell]" % String(rank_entry["visual_intensity"])

	text += "[/table]\n\n"
	text += "[b]Rollenbild:[/b]\n"
	for rank_entry in ZombieHandbookData.get_rank_glossary():
		text += "- %s: %s\n" % [
			String(rank_entry["name"]),
			String(rank_entry["description"])
		]
	return text

func _build_main_overview_page() -> String:
	var text: String = "[b]Dieses Nachschlagewerk erklaert alle bekannten Zombiearten und Todesarten.[/b]\n\n"
	text += "Oben waehlt man Kapitel, links den konkreten Eintrag.\n\n"
	text += "[b]Im Uebersicht-Reiter:[/b] Die Gruppen links sind ausklappbar und die Eintraege sind anklickbar.\n\n"
	text += "[b]Schnellzugriff auf Uebersichten:[/b]\n"
	text += "- ZX Zombie-Arten: Artenuebersicht\n"
	text += "- DT Todesarten: Todesarten-Uebersicht\n"
	text += "- GL Grundlagen: Gameplay-Klassen\n"
	text += "- GL Grundlagen: Mort-Grad\n"
	text += "- GL Grundlagen: Rang-Hierarchie\n"
	text += "- GL Grundlagen: Wellen-System\n"
	text += "- GL Grundlagen: Seltenheitssystem\n"
	text += "- GL Grundlagen: Systemtrennung\n\n"
	text += "[b]Tipp:[/b] Im linken Bereich lassen sich Gruppen ein- und ausklappen."
	return text

func _build_main_overview_side_panel() -> String:
	var text := "Uebersichts-Register\n\n"
	text += "ZX  Artenuebersicht\n"
	text += "DT  Todesarten-Uebersicht\n"
	text += "GL  Gameplay-Klassen\n"
	text += "GL  Mort-Grad\n"
	text += "GL  Rang-Hierarchie\n"
	text += "GL  Wellen-System\n"
	text += "GL  Seltenheitssystem\n"
	text += "GL  Systemtrennung"
	return text

func _build_wave_runtime_page() -> String:
	var runtime_info: Dictionary = ZombieHandbookData.get_wave_runtime_glossary()
	var text: String = "[b]" + String(runtime_info.get("title", "Wellen-System")) + "[/b]\n"
	text += String(runtime_info.get("summary", "")) + "\n\n"
	text += "[b]Ablauf:[/b]\n"
	for step_text in runtime_info.get("steps", []):
		text += "- " + String(step_text) + "\n"

	text += "\n[b]Standardwerte:[/b]\n"
	for default_line in runtime_info.get("defaults", []):
		text += "- " + String(default_line) + "\n"

	text += "\n[b]Hinweise:[/b]\n"
	for note_line in runtime_info.get("notes", []):
		text += "- " + String(note_line) + "\n"
	return text

func _build_rarity_page() -> String:
	var lines: Array[String] = []
	for rarity_entry in ZombieHandbookData.get_death_rarity_glossary():
		lines.append("- " + String(rarity_entry["name"]) + ": " + String(rarity_entry["description"]))
	return "[b]Seltenheit der Todesarten:[/b]\n" + _join_lines(lines)

func _add_page(
	chapter: String,
	group: String,
	title: String,
	body: String,
	image_path: String = "",
	side_panel_text: String = "",
	use_placeholder_image: bool = false
):
	pages.append({
		"chapter": chapter,
		"group": group,
		"title": title,
		"body": body,
		"image_path": image_path,
		"side_panel_text": side_panel_text,
		"use_placeholder_image": use_placeholder_image
	})

func _build_navigation_model():
	chapter_order.clear()
	chapter_to_page_indices.clear()
	var seen_chapters: Dictionary = {}

	for index in range(pages.size()):
		var page: Dictionary = pages[index]
		var chapter_name: String = String(page.get("chapter", "Uebersicht"))
		if not seen_chapters.has(chapter_name):
			seen_chapters[chapter_name] = true
			chapter_order.append(chapter_name)
			chapter_to_page_indices[chapter_name] = []

		var chapter_pages: Array = chapter_to_page_indices[chapter_name]
		chapter_pages.append(index)
		chapter_to_page_indices[chapter_name] = chapter_pages

func _build_chapter_tabs():
	for child in chapter_tabs.get_children():
		child.queue_free()

	for chapter_name in chapter_order:
		var tab_button := Button.new()
		tab_button.toggle_mode = true
		tab_button.custom_minimum_size = Vector2(130, 34)
		tab_button.text = _tab_label_for_chapter(chapter_name)
		tab_button.add_theme_font_size_override("font_size", 15)
		tab_button.add_theme_stylebox_override("normal", tab_style_normal)
		tab_button.add_theme_stylebox_override("hover", tab_style_hover)
		tab_button.add_theme_stylebox_override("pressed", tab_style_pressed)
		tab_button.add_theme_stylebox_override("focus", tab_style_focus)
		tab_button.set_meta("chapter_name", chapter_name)
		tab_button.pressed.connect(_on_chapter_tab_pressed.bind(chapter_name))
		chapter_tabs.add_child(tab_button)

func _chapter_display_name(chapter_name: String) -> String:
	return chapter_name.to_upper()

func _tab_label_for_chapter(chapter_name: String) -> String:
	var icon: String = String(CHAPTER_ICON_MAP.get(chapter_name, "[]"))
	return icon + "  " + _chapter_display_name(chapter_name)

func _build_tab_theme():
	tab_style_normal = StyleBoxFlat.new()
	tab_style_normal.bg_color = Color(0.21, 0.23, 0.28, 1)
	tab_style_normal.border_width_left = 1
	tab_style_normal.border_width_top = 1
	tab_style_normal.border_width_right = 1
	tab_style_normal.border_width_bottom = 1
	tab_style_normal.border_color = Color(0.36, 0.4, 0.46, 1)
	tab_style_normal.corner_radius_top_left = 5
	tab_style_normal.corner_radius_top_right = 5
	tab_style_normal.corner_radius_bottom_left = 5
	tab_style_normal.corner_radius_bottom_right = 5

	tab_style_hover = tab_style_normal.duplicate(true)
	tab_style_hover.bg_color = Color(0.29, 0.32, 0.39, 1)
	tab_style_hover.border_color = Color(0.47, 0.53, 0.61, 1)

	tab_style_pressed = tab_style_normal.duplicate(true)
	tab_style_pressed.bg_color = Color(0.42, 0.24, 0.56, 1)
	tab_style_pressed.border_color = Color(0.67, 0.46, 0.86, 1)
	tab_style_pressed.shadow_color = Color(0.15, 0.05, 0.22, 0.9)
	tab_style_pressed.shadow_size = 4

	tab_style_focus = tab_style_pressed.duplicate(true)

func _apply_visual_accents():
	if entry_tree != null:
		var list_panel := StyleBoxFlat.new()
		list_panel.bg_color = Color(0.84, 0.8, 0.69, 0.98)
		list_panel.border_width_left = 1
		list_panel.border_width_top = 1
		list_panel.border_width_right = 1
		list_panel.border_width_bottom = 1
		list_panel.border_color = Color(0.42, 0.36, 0.25, 1)
		list_panel.corner_radius_top_left = 5
		list_panel.corner_radius_top_right = 5
		list_panel.corner_radius_bottom_left = 5
		list_panel.corner_radius_bottom_right = 5
		entry_tree.add_theme_stylebox_override("panel", list_panel)
		entry_tree.add_theme_color_override("font_color", Color(0.16, 0.12, 0.08, 1))
		entry_tree.add_theme_color_override("font_selected_color", Color(0.96, 0.94, 1, 1))
		entry_tree.add_theme_color_override("font_hovered_color", Color(0.24, 0.18, 0.36, 1))
		entry_tree.add_theme_color_override("guide_color", Color(0.52, 0.44, 0.34, 0.6))
		entry_tree.add_theme_color_override("title_button_color", Color(0.21, 0.16, 0.13, 1))

	if page_body != null:
		page_body.add_theme_color_override("default_color", Color(0.87, 0.89, 0.95, 1))
		page_body.add_theme_font_size_override("normal_font_size", 16)

func _select_chapter(chapter_name: String, preferred_page_index: int):
	if not chapter_to_page_indices.has(chapter_name):
		return

	_suppress_tree_selection_signal = true
	current_chapter = chapter_name
	chapter_label.text = _chapter_display_name(chapter_name)

	for child in chapter_tabs.get_children():
		if child is Button:
			var tab_button: Button = child
			tab_button.button_pressed = String(tab_button.get_meta("chapter_name", "")) == chapter_name

	entry_tree.clear()
	entry_tree.hide_root = true
	entry_tree.columns = 1

	var root: TreeItem = entry_tree.get_root()
	if root == null:
		root = entry_tree.create_item()
	if root == null:
		_suppress_tree_selection_signal = false
		return
	var chapter_pages: Array = chapter_to_page_indices[chapter_name]
	if chapter_name == "Uebersicht":
		_build_overview_navigation_tree(root, chapter_pages)
	else:
		var group_order: Array[String] = []
		var grouped_page_indices: Dictionary = {}
		for chapter_page_index in chapter_pages:
			var page_index: int = int(chapter_page_index)
			var page: Dictionary = pages[page_index]
			var raw_group_name: String = String(page.get("group", "")).strip_edges()
			var group_name: String = raw_group_name if raw_group_name != "" else "Allgemein"
			if not grouped_page_indices.has(group_name):
				grouped_page_indices[group_name] = []
				group_order.append(group_name)
			var grouped: Array = grouped_page_indices[group_name]
			grouped.append(page_index)
			grouped_page_indices[group_name] = grouped

		for group_name in group_order:
			var group_item: TreeItem = entry_tree.create_item(root)
			if group_item == null:
				continue
			group_item.set_text(0, group_name.to_upper())
			group_item.set_selectable(0, false)
			group_item.collapsed = true

			var grouped: Array = grouped_page_indices[group_name]
			for page_index in grouped:
				var page_item: TreeItem = entry_tree.create_item(group_item)
				if page_item == null:
					continue
				page_item.set_text(0, String(pages[int(page_index)]["title"]))
				page_item.set_metadata(0, int(page_index))

	var first_entry_item: TreeItem = _find_first_entry_item(root)
	if first_entry_item == null:
		_suppress_tree_selection_signal = false
		return

	var selected_item: TreeItem = first_entry_item
	if preferred_page_index >= 0:
		var preferred_item: TreeItem = _find_item_for_page_index(root, preferred_page_index)
		if preferred_item != null:
			selected_item = preferred_item

	var selected_parent: TreeItem = selected_item.get_parent()
	if selected_parent != null:
		selected_parent.collapsed = false

	entry_tree.set_selected(selected_item, 0)
	var selected_page_index: int = _extract_page_index(selected_item.get_metadata(0))
	if selected_page_index >= 0:
		_show_page(selected_page_index, false)
	_suppress_tree_selection_signal = false

func _build_overview_navigation_tree(root: TreeItem, overview_chapter_pages: Array):
	var sections: Array[Dictionary] = []
	var overview_indices: Array[int] = []
	for page_variant in overview_chapter_pages:
		overview_indices.append(int(page_variant))
	sections.append({
		"name": "Allgemein",
		"page_indices": overview_indices,
		"sync_navigation": false
	})

	var species_overview_index: int = _find_chapter_overview_page_index("Zombie-Arten")
	if species_overview_index >= 0:
		sections.append({
			"name": "Zombie-Arten",
			"page_indices": [species_overview_index],
			"sync_navigation": true
		})

	var death_overview_index: int = _find_chapter_overview_page_index("Todesarten")
	if death_overview_index >= 0:
		sections.append({
			"name": "Todesarten",
			"page_indices": [death_overview_index],
			"sync_navigation": true
		})

	var basics_indices: Array[int] = []
	for page_variant in chapter_to_page_indices.get("Grundlagen", []):
		basics_indices.append(int(page_variant))
	if not basics_indices.is_empty():
		sections.append({
			"name": "Grundlagen",
			"page_indices": basics_indices,
			"sync_navigation": true
		})

	for section in sections:
		var page_indices: Array = section.get("page_indices", [])
		if page_indices.is_empty():
			continue
		var group_item: TreeItem = entry_tree.create_item(root)
		if group_item == null:
			continue
		group_item.set_text(0, String(section.get("name", "Gruppe")).to_upper())
		group_item.set_selectable(0, false)
		group_item.collapsed = true
		var sync_navigation: bool = bool(section.get("sync_navigation", false))
		for page_variant in page_indices:
			var page_index: int = int(page_variant)
			var page_item: TreeItem = entry_tree.create_item(group_item)
			if page_item == null:
				continue
			page_item.set_text(0, String(pages[page_index]["title"]))
			page_item.set_metadata(0, {
				"page_index": page_index,
				"sync_navigation": sync_navigation
			})

func _find_chapter_overview_page_index(chapter_name: String) -> int:
	if not chapter_to_page_indices.has(chapter_name):
		return -1
	var chapter_pages: Array = chapter_to_page_indices[chapter_name]
	for page_variant in chapter_pages:
		var page_index: int = int(page_variant)
		var page: Dictionary = pages[page_index]
		if String(page.get("group", "")).strip_edges() == "":
			return page_index
	if chapter_pages.is_empty():
		return -1
	return int(chapter_pages[0])

func _show_page(index: int, sync_navigation: bool = true):
	if index < 0 or index >= pages.size():
		return

	current_page_index = index
	var page: Dictionary = pages[index]
	page_title.text = String(page["title"])
	page_body.text = String(page["body"])
	page_group_label.text = "Kapitel: %s | Gruppe: %s" % [
		String(page.get("chapter", "-")),
		String(page.get("group", "-"))
	]
	_update_page_image(
		String(page.get("image_path", "")),
		String(page.get("side_panel_text", "")),
		bool(page.get("use_placeholder_image", false))
	)
	page_counter.text = "Eintrag " + str(index + 1) + " / " + str(pages.size())
	prev_button.disabled = (index <= 0)
	next_button.disabled = (index >= pages.size() - 1)

	if sync_navigation:
		var page_chapter: String = String(page.get("chapter", ""))
		if page_chapter != current_chapter:
			_select_chapter(page_chapter, index)
		else:
			_sync_tree_selection(index)

func _sync_tree_selection(page_index: int):
	var root: TreeItem = entry_tree.get_root()
	if root == null:
		return
	var match_item: TreeItem = _find_item_for_page_index(root, page_index)
	if match_item != null:
		var parent_item: TreeItem = match_item.get_parent()
		if parent_item != null:
			parent_item.collapsed = false
		entry_tree.set_selected(match_item, 0)

func _on_chapter_tab_pressed(chapter_name: String):
	_select_chapter(chapter_name, -1)

func _on_tree_selected():
	if _suppress_tree_selection_signal:
		return
	var selected: TreeItem = entry_tree.get_selected()
	if selected == null:
		return
	var metadata = selected.get_metadata(0)
	var page_index: int = _extract_page_index(metadata)
	if page_index < 0:
		return
	_show_page(page_index, _extract_sync_navigation(metadata))

func _on_prev_pressed():
	_show_page(current_page_index - 1)

func _on_next_pressed():
	_show_page(current_page_index + 1)

func _on_close_pressed():
	close_book()

func _update_page_image(
	image_path: String,
	side_panel_text: String = "",
	use_placeholder_image: bool = false
):
	if page_image == null or page_image_hint == null:
		return

	page_image.texture = null
	page_image_hint.visible = false

	if image_path == "":
		if use_placeholder_image and _try_set_page_image_texture(ENTRY_PLACEHOLDER_IMAGE_PATH):
			return
		page_image_hint.visible = true
		if side_panel_text != "":
			page_image_hint.text = side_panel_text
		else:
			page_image_hint.text = "Kein Bild fuer diese Seite."
		return

	if _try_set_page_image_texture(image_path):
		return

	if use_placeholder_image and _try_set_page_image_texture(ENTRY_PLACEHOLDER_IMAGE_PATH):
		return

	page_image_hint.visible = true
	page_image_hint.text = "Bild konnte nicht geladen werden:\n" + image_path

func _try_set_page_image_texture(resource_path: String) -> bool:
	var loaded = load(resource_path)
	if loaded != null and loaded is Texture2D:
		page_image.texture = loaded
		return true
	return false

func _extract_page_index(metadata: Variant) -> int:
	if typeof(metadata) == TYPE_INT:
		return int(metadata)
	if typeof(metadata) == TYPE_DICTIONARY:
		var metadata_dict: Dictionary = metadata
		if metadata_dict.has("page_index"):
			return int(metadata_dict["page_index"])
	return -1

func _extract_sync_navigation(metadata: Variant) -> bool:
	if typeof(metadata) == TYPE_DICTIONARY:
		var metadata_dict: Dictionary = metadata
		return bool(metadata_dict.get("sync_navigation", false))
	return false

func _join_lines(lines: Array[String]) -> String:
	if lines.is_empty():
		return "-"
	var output: String = ""
	for i in range(lines.size()):
		output += lines[i]
		if i < lines.size() - 1:
			output += "\n"
	return output

func _find_first_entry_item(root: TreeItem) -> TreeItem:
	var child: TreeItem = root.get_first_child()
	while child != null:
		var nested: TreeItem = child.get_first_child()
		if nested != null:
			return nested
		child = child.get_next()
	return null

func _find_item_for_page_index(root: TreeItem, page_index: int) -> TreeItem:
	var child: TreeItem = root.get_first_child()
	while child != null:
		var metadata = child.get_metadata(0)
		if _extract_page_index(metadata) == page_index:
			return child
		var nested: TreeItem = _find_item_for_page_index(child, page_index)
		if nested != null:
			return nested
		child = child.get_next()
	return null
