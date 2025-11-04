##Opcija za T2 dogadjaje (dugme u modalu): trosak + skup efekata + trajanje
extends Resource
class_name EventChoice

@export var label: String
@export var cost: Dictionary = {}
@export var duration: int = 1

##Efekti koji se odmah dese
@export var start_effects: Array[EventEffect] = []

##Efekti koji se desavaju jednom po potezu ili traju tokom vise poteza
@export var tick_effects: Array[EventEffect] = []

##Efekti koji se desavaju na kraju
@export var end_effects: Array[EventEffect] = []