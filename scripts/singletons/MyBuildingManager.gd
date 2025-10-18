##Singleton za baratanje sa kartama za gradjevine.
##Cuva koji su nivo sve zgrade, ocitava i poziva odgovarajuce funkcije.

extends Node

##Koja zgrada se menja i postaje koji nivo
signal building_changed(id: String, level: int)

var levels : Dictionary[String, int]= {}                #Npr. { "wood_logging": 2 }
var deck_manager: DeckManager = null   #Referenca na aktivni DeckManager (u sceni)

##Povezi referencu sa aktivnim DeckManager-om
func register_deck(dm: DeckManager) -> void:
    deck_manager = dm

##Vrati nivo zadate zgrade
func get_level(id: String) -> int:
    return int(levels.get(id, 0))

##Funkcija koja povecava nivo zgrade i onda ubacuje ili izbacuje odgovarajuce karte iz spila
func build_or_upgrade(params: Dictionary) -> void:
    var bid := String(params.get("building_id", ""))
    if bid == "":
        push_warning("BuildingManager ne moze da nadje id od zgrade.")
        return

    var to_level := int(params.get("to_level", 0))
    levels[bid] = to_level
    building_changed.emit(bid, to_level)
    
    #Moramo da ucitamo iz file-a podatke pa onda da ih tipizujemo i cast-ujemo u odgovarajuci format
    var add_raw: Array = (params.get("deck_add", []) as Array)
    var remove_raw: Array = (params.get("deck_remove", []) as Array)

    var add: Array[Dictionary] = []
    var remove: Array[Dictionary] = []

    #Potvrdi format i ubaci u add
    for card_and_count in add_raw:
        if card_and_count is Dictionary:
            add.append(card_and_count)

    #Potvrdi format i ubaci u remove
    for card_and_count in remove_raw:
        if card_and_count is Dictionary:
            remove.append(card_and_count)

    if deck_manager == null:
        push_warning("BuildingManager ne moze da se poveze sa DeckManager-om.")
        return

    #Dodaj nove karte u spil
    for card_and_count in add:
        var add_id: String = String(card_and_count.get("id", ""))
        var add_count: int = int(card_and_count.get("count", 1))
        if add_id != "":
            deck_manager.add_to_deck(add_id, add_count)

    #Ukloni stare karte
    for card_and_count in remove:
        var remove_id: String = String(card_and_count.get("id", ""))
        #-1 znaci "ukloni sve primerke"
        var remove_count: int = int(card_and_count.get("count", -1))
        if remove_id != "":
            deck_manager.remove_from_deck(remove_id, remove_count)
