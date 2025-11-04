## Broker baze podataka za karte
## Singleton koji ucitava sve .tres/.res fajlove iz datog direktorijuma i drzi ih u memoriji.

extends Node

@export_dir var cards_dir := "res://data/cards"  # folder sa kartama
@export var scan_recursive := true               # da li pretrazujemo i podfoldere

var all_cards: Array[Card] = []     # originalne Card resource instance (tretiramo ih kao “blueprint-ove”)
var cards_by_id: Dictionary = {}    # mapa id(String) -> Card (originalna instanca)

func _ready() -> void:
    load_cards_from_file()

## Ucitavanje svih karti iz fajl-sistema u memoriju (all_cards + cards_by_id).
func load_cards_from_file() -> void:
    cards_by_id.clear()
    all_cards.clear()

    var paths: Array[String] = collect_card_paths(cards_dir, scan_recursive)
    paths.sort()  # stabilan poredak

    for path in paths:
        var res := ResourceLoader.load(path)
        if res == null:
            push_warning("CardDB ne moze da ucita resurs: %s" % path)
            continue
        if res is Card:
            var card := res as Card
            if card.id == "":
                push_warning("Karta na %s nema id pa je preskacemo." % path)
                continue
            if cards_by_id.has(card.id):
                push_warning("Duplikat id-ja '%s' na mestu %s. Zadrzacemo prvi primerak." % [card.id, path])
                continue
            all_cards.append(card)
            cards_by_id[card.id] = card

    print("CardDB je ucitao %d karata." % all_cards.size())

##Rekurzivno skupi sve card-ove u direktorijumu i poddirektorijumima
func collect_card_paths(dir_path: String, recursive: bool) -> Array[String]:
    var all_paths_to_cards: Array[String] = []
    var directory := DirAccess.open(dir_path)
    if directory == null:
        push_warning("CardDB ne moze da otvori folder: %s" % dir_path)
        return all_paths_to_cards

    directory.list_dir_begin()
    while true:
        var card_name := directory.get_next()

        if card_name == "":
            break  # kraj iteracije/nema sta vise da ucita

        if card_name.begins_with("."):
            continue  # preskačemo skrivene stavke (.import, .git, .DS_Store...)

        var full_path_to_card := dir_path.path_join(card_name)

        if directory.current_is_dir():
            if recursive:
                all_paths_to_cards.append_array(collect_card_paths(full_path_to_card, recursive))
        else:
            if card_name.ends_with(".tres") or card_name.ends_with(".res"):
                all_paths_to_cards.append(full_path_to_card)

    directory.list_dir_end()
    return all_paths_to_cards

## Vrati kartu po id-ju (originalnu instancu), ili null ako ne postoji.
func get_card_by_id(id: String) -> Card:
    return cards_by_id.get(id, null) as Card

## Vrati sve karte (originalne instance).
func get_all_cards() -> Array[Card]:
    return all_cards.duplicate()  # plitka kopija niza (karte ostaju iste instance)

## Vrati sve pocetne karte (originalne), tj. one sa starting_card == true.
func get_all_starting_cards() -> Array[Card]:
    var starting_cards: Array[Card] = []
    for card in all_cards:
        if card.starting_card:
            starting_cards.append(card)
    return starting_cards