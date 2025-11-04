extends HBoxContainer

@onready var name_label: Label = $Name
@onready var level_label: Label = $Level
@onready var res_label: Label = $Resource

func set_data(name: String, level: int, resource: String) -> void:
    name_label.text = "%s:" % name
    level_label.text = "Lvl_%d" % level
    res_label.text = "(%s)" % resource