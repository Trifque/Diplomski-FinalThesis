##Modal za event-ove koje imaju opcije od kojih se mora izabrati jedna

extends Panel
class_name EventChoiceModal

signal choice_selected(event: GameEvent, choice: EventChoice)
signal closed

@onready var title_label: Label = $MarginContainer/VBoxContainer/Title
@onready var choices_box: HBoxContainer = $MarginContainer/VBoxContainer/Choices
@onready var close_btn: Button = $MarginContainer/VBoxContainer/Close
@onready var body_label: RichTextLabel = $MarginContainer/VBoxContainer/Body

var current_event: GameEvent = null

func _ready() -> void:
    close_btn.pressed.connect(on_close_pressed)

func show_for_event(event: GameEvent, body_text: String = "") -> void:
    current_event = event
    title_label.text = event.title
    body_label.text = body_text

    #Ocisti stara dugmad
    for choice in choices_box.get_children():
        choice.queue_free()

    #Napravi dugme po svakoj opciji
    for choice in event.choices:
        var button := Button.new()
        button.text = format_choice_label(choice)
        button.disabled = not CostService.can_pay_cost_choice(choice.cost)
        button.pressed.connect(on_choice_pressed.bind(choice))
        choices_box.add_child(button)

    show()

func on_choice_pressed(choice: EventChoice) -> void:
    if not CostService.can_pay_cost_choice(choice.cost):
        #Sigurnosna provera – UI je vec disable-ovao, ali za svaki slucaj
        return
    emit_signal("choice_selected", current_event, choice)

func on_close_pressed() -> void:
    emit_signal("closed")
    hide()

func format_choice_label(choice: EventChoice) -> String:
    var parts: Array[String] = []

    # format troska
    for resource in ["wood","stone","food"]:
        var amount := int(choice.cost.get(resource, 0))
        if amount > 0:
            parts.append("%s-%d" % [resource.capitalize(), amount])
    var cost := "" if parts.is_empty() else " [" + ", ".join(parts) + "]"

    #Format trajanja
    var duration := "" if choice.duration <= 0 else " (Trajace %d poteza)" % choice.duration

    return choice.label + cost + duration