## Levi deo UI-a koji prikazuje sve izgradjene zgrade i njihove nivoe

extends VBoxContainer

@onready var list: ItemList = ensure_list()

func _ready() -> void:
	# Slusaj promene nivoa zgrada
	if not BuildingManager.building_changed.is_connected(_on_building_changed):
		BuildingManager.building_changed.connect(_on_building_changed)
	refresh()

func _exit_tree() -> void:
	if BuildingManager.building_changed.is_connected(_on_building_changed):
		BuildingManager.building_changed.disconnect(_on_building_changed)

func _on_building_changed(_id: String, _level: int) -> void:
	# Bezbedno osvezavanje posle layout-a
	call_deferred("refresh")

##Osvezi listu/podatke u listi
func refresh() -> void:
	list.clear()

	var levels: Dictionary = BuildingManager.get_levels_dict()  # { bid: level }
	var ids: Array[String] = []

	# Izvuci i tipizuj ID-jeve
	for building_id_var in levels.keys():
		var building_id: String = String(building_id_var)
		ids.append(building_id)

	
	ids.sort()

	var added: int = 0
	for building_id in ids:
		var lvl: int = int(levels.get(building_id, 0))
		if lvl <= 0:
			continue
		var line: String = "%s: Lvl_%d" % [building_id, lvl]
		list.add_item(line)
		added += 1

	if added == 0:
		list.add_item("No buildings yet")

##Pravi ItemList-u
func ensure_list() -> ItemList:
	#Ako vec postoji dete tipa ItemList, koristi ga; u suprotnom napravi novo.
	for child in get_children():
		var it := child as ItemList
		if it != null:
			configure_list(it)
			return it

	var new_list := ItemList.new()
	configure_list(new_list)
	add_child(new_list)
	return new_list

##Kako da izgleda lista
func configure_list(it: ItemList) -> void:
	it.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	it.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	it.select_mode = ItemList.SELECT_SINGLE
	it.allow_rmb_select = false
	it.auto_height = false
	it.same_column_width = false
