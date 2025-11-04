## Glavni resurs dogadjaje. On zapravo ih i predstavlja (T1/T2/T3)
extends Resource
class_name GameEvent

enum Kind { GOOD, BAD, MIXED }
enum Tier { T1 = 1, T2 = 2, T3 = 3 }

@export var id: String
@export var title: String

@export var tier: int = Tier.T1
@export var kind: int = Kind.GOOD

##Osnovno trajanje (u potezima)
@export var duration: int = 0

##Razmak do sledece pojave
@export var weight: int = 1
@export var cooldown: int = 0

##Uslovi za dostupnost
@export var conditions: EventConditions

##Efekti po fazama
@export var start_effects: Array[EventEffect] = []
@export var tick_effects: Array[EventEffect] = []
@export var end_effects: Array[EventEffect] = []

##Lista izbora
@export var choices: Array[EventChoice] = []

##Cilj (praćenje + success/fail efekti)
@export var objective: EventObjective