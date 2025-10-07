extends Node2D
#Nasledjujemo Node2D kako bismo mogli da upotrebimo lifecycle callback-ove (_ready,_process i druge)

#trenutni cilj nam je da uzmemo iz UI-a segment Label koji nam pokazuje koliko je poteza proslo od pocetka igre
#stavili smo da tokom inicijalizacije u UI bude instanciran objekat klase Label po imenu Turns i da prikazuje tekst: Turns: 0
#da bismo mogli da menjamo tu vrednost, neophodno je da mu pristupimo u okviru ovog koda

@onready var label : Label = $UI/Turns

#Kreiramo novu promenljivu po imenu label koja je pokazivac na instancu Turns.
#Turns-u pristupamo preko skracene putanje $ i Label tipa
#@onready pozivamo posto hocemo da se prvo inicijalizuje UI pa tek kasnije pred sam pocetak igre da pristupimo tim vrednostima
#Ovako osiguravamo da $UI/Label zaista postoji kada ga zahtevamo i da nece doci do greske

var turn: int = 0

#Kreiramo novu promenljivu koja ce da nam prati na kom smo trenutnom potezu. Samo je broj

func _ready() -> void:
	print("Main ready: starting turn = ", turn)
	_update_ui()

#Kada nas cvor udje u scene tree pozvace se funkcija ready
#Ona se i samo tada poziva, cineci je idealnim kadnidatom za inicijalizaciju nase skripte
#Dodali smo print funkciju kako bismo lakse proveravali i ispratili situaciju u konzoli
#_update_ui() je nova funkcija koju smo definisali nize

func _process(delta: float) -> void:
	pass

#Funkcija _process se poziva na pocetku svakog frame-a i time sluzi za frame-rate nezavisne stvari (npr. animacije ili tajmeri)
#ne sluzi trenutno za nase poteze, ali ce nam trebati za kasnije, pa je ovo vise podsetnik za mene

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("next_turn"):
		_on_next_turn()

#_unhandled_input se poziva za svaki input koji nijedan child nije upotrebio (nas input je custom, te sigurno ga niko nije koristio)
#Dobija se ovim generican InputEvent (bazicna klasa), pa prvo proveravamo da li je bas nas custom input sa if-om
#U slucaju da jeste nas input, pozivamo custom funkciju _on_next_turn()

func _on_next_turn() -> void:
	turn += 1
	print("Next turn nam je: ", turn)
	_update_ui()

#U okviru on_next_turn funkcije za sada samo povecavamo koliko je poteza proteklo

func _update_ui() -> void:
	label.text = "Turn: %d" % turn

#Pomocna funkcija za update-ovanje teksta promenljive label. Posto to radimmo vise puta bolje izdvojiti u odvojenu funkciju
#kako bismo izbegli redundansu
