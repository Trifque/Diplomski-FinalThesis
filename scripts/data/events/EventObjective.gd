##Cilj (T3): tip + parametri + rok + nagrada/kazna
extends Resource
class_name EventObjective

@export var objective_type: String
@export var params: Dictionary = {}
@export var deadline: int = 0
@export var on_success: Array[EventEffect] = []
@export var on_fail: Array[EventEffect] = []