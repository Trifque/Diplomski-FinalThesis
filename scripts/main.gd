extends Node2D
#Nasledjujemo Node2D kako bismo mogli da upotrebimo lifecycle callback-ove (_ready,_process i druge)

#Kreiramo novu promenljivu po imenu turns_label koja je referenca na instancu Turns.
#Turns-u pristupamo preko skracene putanje $ i Label tipa
#@onready pozivamo posto hocemo da se prvo inicijalizuje UI pa tek kasnije pred sam pocetak igre da pristupimo tim vrednostima
#Ovako osiguravamo da $UI/Label zaista postoji kada ga zahtevamo i da nece doci do greske
@onready var turns_label : Label = $UI/Turns
@onready var wood_label : Label = $UI/Wood
@onready var stone_label : Label = $UI/Stone
@onready var food_label : Label = $UI/Food

#Promenili smo main posto u okviru Singleton-a Game.gd mi cemo cuvati celokupno stanje nase igre
#(broj poteza, koliko imamo resursa, trenutno aktivni bonusi itd.)
#To znaci da ovde u Main sceni mi sada ili saljemo promenjene podatke ili prihvatamo trenutno stanje od singletona Game
func _ready() -> void:
	Game.turn_changed.connect(_on_turn_changed)
	Game.resources_changed.connect(_on_resources_changed)
	Game.start_new_session()
	_on_turn_changed(Game.turn)
	_on_resources_changed(Game.resources)

#Funkcija koja poziva funkciju singletona za pokretanje narednog poteza kada se pritisne dugme
#za sledeci potez (space)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("next_turn"):
		Game.next_turn()

#Menja tekst label-a za poteze
func _on_turn_changed(new_turn: int) -> void:
	turns_label.text = "Turn: %d" % new_turn

#Funkcija koja ce menjati tekst za Label-e resursa kako bi se adekvatno predstavilo stanje igre
func _on_resources_changed(res: Dictionary) -> void:
	wood_label.text = "Wood: %d" % int(res.get("wood", 0))
	stone_label.text = "Wood: %d" % int(res.get("stone", 0))
	food_label.text = "Wood: %d" % int(res.get("food", 0))