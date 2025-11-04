##Panel gde su upisani svi aktivni T3 event-ovi

extends VBoxContainer
class_name ObjectivePanel

var badges: Dictionary = {}  # id -> ObjectiveBadge
var badge_scene := preload("res://UI/ObjectiveBadge.tscn")

func _ready() -> void:
	EventManager.event_started.connect(on_event_started)
	EventManager.event_ended.connect(on_event_ended)
	EventManager.objective_updated.connect(on_objective_updated)

	#U slucaju ako su aktivni vec T3 event-ovi dok se ucitava scena
	for active_event in EventManager.active_events:
		var event := active_event.get("event") as GameEvent
		if event and event.objective and String(event.objective.objective_type) == "play_cards_gain_resource":
			var objective_state := active_event.get("objective_state", {}) as Dictionary

			if not objective_state.is_empty():
				var badge := badge_scene.instantiate() as ObjectiveBadge
				badges[event.id] = badge
				add_child(badge)
				badge.setup(event, int(objective_state.get("goal", 0)), int(objective_state.get("deadline_left", 0)))

##Kada zapocne T3 event, ubaci ga u panel
func on_event_started(event: GameEvent) -> void:
	print("Krenuo event T3: ", event.id)

	if not event.objective: 
		return

	if String(event.objective.objective_type) != "play_cards_gain_resource": 
		return

	var object_state := find_objective_state(event.id)
	if object_state.is_empty(): 
		return

	var badge := badge_scene.instantiate() as ObjectiveBadge
	badges[event.id] = badge
	add_child(badge)
	badge.setup(event, int(object_state.get("goal", 0)), int(object_state.get("deadline_left", 0)))

##Kada se zavrsi T3 izbaci dati badge od eventa iz panel-a
func on_event_ended(event: GameEvent) -> void:
	var badge: ObjectiveBadge = badges.get(event.id, null)

	if badge:
		badge.queue_free()
		badges.erase(event.id)

##Update-uj badge za zadati T3 event
func on_objective_updated(event: GameEvent, progress: int, goal: int, turns_left: int) -> void:
	var badge: ObjectiveBadge = badges.get(event.id, null)

	if badge:
		badge.update_status(progress, goal, turns_left)

##Vidi u kom je stanju napredovanja zadati T3 event
func find_objective_state(event_id: String) -> Dictionary:
	for active_event in EventManager.active_events:
		var event := active_event.get("event") as GameEvent

		if event and event.id == event_id and active_event.has("objective_state"):
			return (active_event.get("objective_state", {}) as Dictionary)

	return {}
