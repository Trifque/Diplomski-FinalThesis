extends Node

#Ocemo da omogucimo tipovanje i autcomplete pri koriscenju autoload-a


# Signali za UI i ostale sisteme – emitujemo kad se promeni potez ili stanje resursa
signal turn_changed(new_turn: int)
signal resources_changed(resources: Dictionary)

#Takodje cemo kreirati Seed za RNG kako bismo mogli da pouzdano i konstantno rekreiramo uslove zarad testiranja
var rng := RandomNumberGenerator.new()
var seed : int = 0

# Interno čuvamo potez u privatnoj promenljivoj (_turn) i kroz property "turn"
# emituјemo signal kad se vrednost zapravo promeni.
var _turn : int = 0
var turn: int:
    get: return _turn
    set(value):
        _turn = value
        turn_changed.emit(_turn)

#Kreiramo nacin da vodimo racuna o resursima. Koristimo Dictionary data strukturu.
#Ona predstavlja par podataka: ime podatka i konkretna vrednost podatka
var resources := {"wood" : 0, "stone" : 0, "food" : 0}

#Zapocinjemo novu igru i koristimo ili seed koji cemo da prosledimo ovoj funkciji ili sistemski u slucaju
#ako nismo prosledili seed. Resetujemo potez i resurse i emitujemo inicijalno stanje.
func start_new_session(p_seed: int = 0) -> void:
    seed = p_seed if p_seed != 0 else int(Time.get_unix_time_from_system())
    rng.seed = seed
    turn = 0
    resources = {"wood" : 0, "stone" : 0, "food" : 0}
    resources_changed.emit(resources)

#Dodajemo funkciju next_turn u koju cemo kasnije dodavati hook-ove i trigger-e za stvari koje se desavaju prilikom prelaska
#u sledeci potez poput prihoda resursa, aktiviranje dogadjaja i slicno
func next_turn() -> void:
    turn += 1
    #dodajemo probne vrednosti
    resources["wood"] += 1
    resources_changed.emit(resources)
