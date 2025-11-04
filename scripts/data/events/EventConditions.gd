##Uslovi za pojavljivanje dogadjaja
extends Resource
class_name EventConditions

@export var min_turn: int = 0
@export var min_avg_building_level: float = 0.0
@export var requires_building_id: String = ""
@export var requires_building_min_level: int = 0