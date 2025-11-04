##Koncentrovane informacije za jedan T3 event: koji je event, kako napreduje ispunjavanje zahteva i koliko je jos vremena preostalo

extends VBoxContainer
class_name ObjectiveBadge

@onready var title_label: Label = $Title
@onready var progress_bar: ProgressBar = $Progress
@onready var timer_label: Label = $Timer

var event_id: String = ""

##Napravi bedz za dati T3 event
func setup(event: GameEvent, goal: int, turns_left: int) -> void:
	event_id = event.id
	title_label.text = event.title
	progress_bar.min_value = 0
	progress_bar.max_value = max(1, goal)
	progress_bar.value = 0
	timer_label.text = "Turns remaining: %d \n" % turns_left

##Update-uj zadate informacije
func update_status(progress_value: int, goal: int, turns_left: int) -> void:
	progress_bar.max_value = max(1, goal)
	progress_bar.value = clamp(progress_value, 0, progress_bar.max_value)
	timer_label.text = "Turns remaining: %d \n" % turns_left
