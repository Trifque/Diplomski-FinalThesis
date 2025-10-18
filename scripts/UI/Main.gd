extends Node2D
##Main skripta koja pokrece celu igru i u kojoj drzimo UI komponente barem za sada


#@onready pozivamo posto hocemo da se prvo inicijalizuje UI pa tek kasnije pred sam pocetak igre da pristupimo tim vrednostima
#Ovako osiguravamo da Label-i zaista postoje kada ih zahtevamo i da nece doci do greske
@onready var turns_label : Label = $UI/Turns
@onready var wood_label : Label = $UI/Wood
@onready var stone_label : Label = $UI/Stone
@onready var food_label : Label = $UI/Food

@onready var hand_box: HBoxContainer = $UI/Hand
@onready var deck: DeckManager = $Deck


func _ready() -> void:

    BuildingManager.register_deck(deck)

    Game.turn_changed.connect(on_turn_changed)
    Game.resources_changed.connect(on_resources_changed)
    deck.hand_changed.connect(on_hand_changed)

    Game.start_new_session()
    
    on_hand_changed(deck.hand)

    on_turn_changed(Game.turn)
    on_resources_changed(Game.resources)
    on_hand_changed(deck.hand)

    #Posto smo u UI stavili da su karte zapravo dugmad, sada spajamo tu dugmad sa kartama i njihovim sposobnostima
    for i in range(hand_box.get_child_count()):
        var card_button: Button = hand_box.get_child(i)
        card_button.pressed.connect(on_card_pressed.bind(i))

##Funkcija koja pokrece promene koje trebaju da se izvrse za sledeci potez
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("next_turn"):
        Game.next_turn()

#Menja tekst label-a za poteze
func on_turn_changed(new_turn: int) -> void:
    turns_label.text = "Turn: %d" % new_turn

    if new_turn > 0:
        deck.refill_hand()


##Funkcija koja ce menjati tekst za Label-e resursa kako bi se adekvatno predstavilo stanje igre
func on_resources_changed(res: Dictionary) -> void:
    wood_label.text = "Wood: %d" % int(res.get("wood", 0))
    stone_label.text = "Stone: %d" % int(res.get("stone", 0))
    food_label.text = "Food: %d" % int(res.get("food", 0))
    on_hand_changed(deck.hand)

##Funkcija koja upisuje tekst na dugmad prema ruci. U slucaju da ima vise dugmadi nego karata u ruci,
##dugme se onemoguci
func on_hand_changed(cards: Array[Card]) -> void:
    for i in range(hand_box.get_child_count()):
        var button: Button = hand_box.get_child(i)
        if i < cards.size():
            var c: Card = cards[i]
            button.text = c.ui_title_and_cost()
            button.disabled = not deck.can_play(c)
        else:
            button.text = "(prazno)"
            button.disabled = true

##Funkcija koja, ukoliko se karta odigra, refresh-uje ruku i podatke u okviru nje
func on_card_pressed(index : int) -> void:
    if deck.play(index):
        on_hand_changed(deck.hand)
