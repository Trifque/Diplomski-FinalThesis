##Banner u okviru UI-a koji pokazuje sve trenutno aktivne event-ove

extends HBoxContainer
class_name EventBanner


func _ready() -> void:
    EventManager.active_events_changed.connect(show_active_events)
    show_active_events(EventManager.active_events)  # inicijalno


##Prikazi trenutno aktivne event-ove
func show_active_events(active_events: Array) -> void:
    #Ocisti stare
    for child in get_children():
        child.queue_free()

    if active_events.is_empty():
        var empty_label := Label.new()
        empty_label.text = "Nema aktivnih događaja"
        empty_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
        add_child(empty_label)
        return

    #Napravi po jedan label za svaki aktivan event
    for active_event in active_events:
        var event: GameEvent = active_event.event
        var turns_left := int(active_event.turns_left)

        var label := Label.new()
        label.text = "Event: %s\n(Preostali potezi: %d)" % [event.title, turns_left]
        label.tooltip_text = label.text
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

        #Da obojimo i time oznacimo da li je event pozitivan, negativan ili mesan
        var color := Color.WHITE
        match event.kind:
            GameEvent.Kind.GOOD:  color = Color(0.7, 1.0, 0.7)
            GameEvent.Kind.BAD:   color = Color(1.0, 0.6, 0.6)
            GameEvent.Kind.MIXED: color = Color(1.0, 0.95, 0.6)
        label.add_theme_color_override("font_color", color)

        add_child(label)