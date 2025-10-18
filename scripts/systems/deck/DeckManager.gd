##Glavni singleton za karte. U njemu se cuvaju sve aktivne karte u vidu spila podeljenog na 
#tri dela: draw_pile, hand i discard_pile

extends Node
class_name DeckManager

#Da prikazemo promenu koje se karte nalaze u ruci igracam tj. koje moze da igra
signal hand_changed(cards: Array[Card])

#Export-ujemo ove vrednosti da ih lakse podesavamo u engine-u ako hocemo
@export var hand_size := 5
@export var draw_on_start := true
@export var copies_per_card: int = 2

#Nase glavne promenljive za singleton: sve karte u trenutnoj igri, talon, deponija karata i karte u ruci
var library: Array[Card] = []
var draw_pile: Array[Card]= []
var discard_pile: Array[Card]= []
var hand: Array[Card] = []

func _ready() -> void:
    build_library_from_db()
    reset_piles()
    if draw_on_start:
        refill_hand()

##Dovuci sve pocetne karte preko CardDB i napuni biblioteku
func build_library_from_db() -> void:
    library.clear()
    var starter_cards := CardDB.get_all_starting_cards()
    for card in starter_cards:
        for i in range(copies_per_card):
            library.append(card.duplicate(true))

##Resetuj kompletno stanje karata.
##Brise ruku i deponiju, a ponovo prekopira sve karte u igri u talon nakon sto ih promesa
func reset_piles() -> void:
    draw_pile = library.duplicate()
    shuffle_with_game_rng(draw_pile)
    discard_pile.clear()
    hand.clear()

##Popuni ruku do maksimalne kolicine karata koja moze biti u ruci
func refill_hand() -> void:
    while hand.size() < hand_size:
        if draw_pile.is_empty():
            if discard_pile.is_empty():
                break
            draw_pile = discard_pile.duplicate()
            discard_pile.clear()
            shuffle_with_game_rng(draw_pile)
        hand.append(draw_pile.pop_back())
    hand_changed.emit(hand)

##Nas nacin mesanja karata, koristimo Fisher–Yates metodu
func shuffle_with_game_rng(arr: Array) -> void:
    var n := arr.size()
    for i in range(n - 1, 0, -1):
        var j := Game.rng.randi_range(0, i)
        var tmp = arr[i]
        arr[i] = arr[j]
        arr[j] = tmp

##Proveri da li moze da se igra data karta
func can_play(c: Card) -> bool:
    return CostService.can_pay(c)

##Odigraj datu kartu
func play(index: int) -> bool:
    if index < 0 or index >= hand.size():
        return false
    var card: Card = hand[index]
    if not CostService.can_pay(card):
        return false

    #Plati za odigravanje karte
    CostService.pay(card)
    #Izbaci kartu u deponiju
    var played: Card = hand.pop_at(index)
    if not played.exhaust:
        discard_pile.append(played)
    #Odigraj efekat karte
    EffectSystem.apply_card(card)

    hand_changed.emit(hand)
    return true

##Ubaci zadatu kartu i njenu odredjenu kolicinu kopija u TALON I BIBLIOTEKU
func add_card_copies_by_id(id: String, copies: int) -> void:
    for i in range(copies):
        var base_card := CardDB.get_card_by_id(id)
        if base_card != null:
            var dup := base_card.duplicate(true)
            library.append(dup)
            draw_pile.append(dup)
    shuffle_with_game_rng(draw_pile)

##Izbaci zatadu kartu i njene kopije IZ SVEGA
func remove_card_copies_by_id(id: String, max_remove: int = 9999) -> void:
    var removed := 0
    #iz ruke
    for i in range(hand.size() - 1, -1, -1):
        if hand[i].id == id:
            hand.remove_at(i)
            removed += 1
            if removed >= max_remove: break
    #iz talona
    if removed < max_remove:
        for i in range(draw_pile.size() - 1, -1, -1):
            if draw_pile[i].id == id:
                draw_pile.remove_at(i)
                removed += 1
                if removed >= max_remove: break
    #iz deponije karata
    if removed < max_remove:
        for i in range(discard_pile.size() - 1, -1, -1):
            if discard_pile[i].id == id:
                discard_pile.remove_at(i)
                removed += 1
                if removed >= max_remove: break
    #iz biblioteke karata (znaci skroz iz trenutne igre)
    if removed < max_remove:
        for i in range(library.size() - 1, -1, -1):
            if library[i].id == id:
                library.remove_at(i)
                removed += 1
                if removed >= max_remove: break
    if removed > 0:
        hand_changed.emit(hand)

##Dodaj nove karte SAMO U TALON
func add_to_deck(card_id: String, count: int = 1, shuffle_after: bool = true) -> void:
    for i in range(count):
        var base_card := CardDB.get_card_by_id(card_id)
        if base_card:
            draw_pile.append(base_card.duplicate(true))
        else:
            push_warning("DeckManager: Nepoznat card_id '%s' u add_to_deck" % card_id)

    if shuffle_after:
        shuffle_with_game_rng(draw_pile)

##Skida kartu i njene kopije iz RUKE, TALONA I DEPONIJE ALI NE I IZ BIBLIOTEKE
func remove_from_deck(card_id: String, count: int = -1) -> void:
    var to_remove := count
    to_remove -= remove_from_array(hand, card_id, to_remove)
    if to_remove != 0:
        to_remove -= remove_from_array(draw_pile, card_id, to_remove)
    if to_remove != 0:
        to_remove -= remove_from_array(discard_pile, card_id, to_remove)
    hand_changed.emit(hand)

##Obrisi kartu iz konkretnog Array-a
func remove_from_array(array: Array[Card], card_id: String, count: int) -> int:
    var removed := 0
    var i := 0
    while i < array.size():
        var c := array[i] as Card
        if c and c.id == card_id:
            array.remove_at(i)
            removed += 1
            if count >= 0 and removed >= count:
                break
        else:
            i += 1
    return removed
