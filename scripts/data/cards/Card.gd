##Pravimo Resource kao osnovni format za nase karte.
##Podaci su: ID, naziv, da li se karta utrosi kada se odigra, da li je u pocetnom spilu,
##koliko kosta da se odigra, srkacenica za efekat i 
##parametri za implementiranje efekata u kodu.
extends Resource
class_name Card

@export var id: String
@export var title: String
@export var exhaust: bool = false
@export var starting_card: bool = true
@export var cost: Dictionary= {"wood" : 0, "stone" : 0, "food" : 0}
@export var effect_type: String
@export var effect_params : Dictionary = {}

#Da redosled prikaza resursa bude konzistentan
const COST_ORDER := ["wood","stone","food"]

##Vraca naslov i koliko kosta da se karta odigra u formatu Ime [naziv_materijala-broj]
func ui_title_and_cost() -> String:
    var parts: Array[String] = []
    for k in COST_ORDER:
        var v := int(cost.get(k, 0))
        if v > 0:
            parts.append("%s-%d" % [k.capitalize(), v])
            
    var return_string := "%s [%s]" % [title, ", ".join(parts)] if (parts.size() > 0) else title
    return return_string