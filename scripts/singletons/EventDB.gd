## Broker baze podataka za dogadjaje
## Singleton koji ucitava sve .tres/.res fajlove iz datog direktorijuma i drzi ih u memoriji.
extends Node

@export_dir var events_dir := "res://data/events"
@export var scan_recursive := true

var all_events: Array[GameEvent] = []
var events_by_id: Dictionary = {}

func _ready() -> void:
    load_events_from_file()

func load_events_from_file() -> void:
    all_events.clear()
    events_by_id.clear()
    var paths := collect_event_paths(events_dir, scan_recursive)
    paths.sort()

    for path in paths:
        var res := ResourceLoader.load(path)

        if res == null:
            push_warning("EventDB ne moze da ucita: %s" % path)
            continue
            
        if res is GameEvent:
            var game_event := res as GameEvent

            if game_event.id == "":
                push_warning("EventDB je nasao dogadjaj bez id-a na %s" % path)
                continue

            if events_by_id.has(game_event.id):
                push_warning("EventDB je nasao duplikat id '%s' na %s" % [game_event.id, path])
                continue

            events_by_id[game_event.id] = game_event
            all_events.append(game_event)

    print("EventDB je ucitao %d eventova." % all_events.size())

##Rekurzivno skupi sve event-ove u direktorijumu i poddirektorijumima
func collect_event_paths(dir_path: String, recursive: bool) -> Array[String]:
    var all_event_paths: Array[String] = []
    var directory := DirAccess.open(dir_path)
    if directory == null:
        push_warning("EventDB ne moze da otvori folder: %s" % dir_path)
        return all_event_paths

    directory.list_dir_begin()
    while true:
        var event_name := directory.get_next()
        if event_name == "": 
            break
            
        if event_name.begins_with("."): 
            continue


        var full := dir_path.path_join(event_name)

        if directory.current_is_dir():
            if recursive:
                all_event_paths.append_array(collect_event_paths(full, recursive))
        else:
            if event_name.ends_with(".tres") or event_name.ends_with(".res"):
                all_event_paths.append(full)

    directory.list_dir_end()

    return all_event_paths

##Vrati sve ucitane event-ove
func get_all() -> Array[GameEvent]:
    return all_events.duplicate()

##Vrati specifican event ciji je ID prosledjen
func get_by_id(id: String) -> GameEvent:
    return events_by_id.get(id, null) as GameEvent

##Da li moze da taj event uopste da se dogodi u trenutnom stanju igre
func are_conditions_met(event: GameEvent) -> bool:
    if event == null:
        return false

    var condition := event.conditions
    if condition:

        if Game.turn < condition.min_turn: #Nije proslo dovoljno poteza
            return false

        if condition.requires_building_id != "": #Nema potrebnu zgradu
            if BuildingManager.get_level(condition.requires_building_id) < condition.requires_building_min_level:
                return false

        if condition.min_avg_building_level > 0.0: #Nema dovoljno razvijenu koloniju
            var avg := average_building_level()
            if avg < condition.min_avg_building_level:
                return false

    return true

##Sracunavanje prosecnog nivoa svih zgrada
func average_building_level() -> float:
    var levels: Dictionary = BuildingManager.get_levels_dict()
    var count := levels.size()

    if count == 0:
        return 0.0

    var sum := 0
    for level in levels.values():
        sum += int(level)
    return float(sum) / float(count)