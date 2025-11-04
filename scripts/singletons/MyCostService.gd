##Singleton za baratanje sa resursima kada se odigrava karta
extends Node

##Da li igrac ima dovoljno resursa da odigra datu kartu
func can_pay(card: Card) -> bool:
    for i in card.cost.keys():
        var need := int(card.cost[i])
        if need == 0:
            continue
        var have := int(Game.resources.get(i, 0))
        if have < need:
            return false
    return true

##Koje resurse i koliko nedostaje za datu kartu
func missing_for(card: Card) -> Dictionary:
    var missing := {}
    for i in card.cost.keys():
        var need := int(card.cost[i])
        if need == 0:
            continue
        var have := int(Game.resources.get(i, 0))
        if have < need:
            missing[i] = need - have
    return missing

##Pokusaj da platis: ako nema dovoljno – vrati false, inace izvrsi pay i true
func try_pay(card: Card) -> bool:
    if not can_pay(card):
        return false
    pay(card)
    return true

##Potrosi resurse za datu kartu i emituje promenu
func pay(card: Card) -> void:
    for i in card.cost.keys():
        var need := int(card.cost[i])
        if need != 0:
            Game.resources[i] = int(Game.resources.get(i, 0)) - need
    Game.resources_changed.emit(Game.resources)

##Da li moze da priusti izbor
func can_pay_cost_choice(cost: Dictionary) -> bool:
    for key in cost.keys():
        if int(Game.resources.get(key, 0)) < int(cost[key]):
            return false
    return true

##Plati za izbor
func pay_cost_choice(cost: Dictionary) -> void:
    for key in cost.keys():
        Game.resources[key] = int(Game.resources.get(key, 0)) - int(cost[key])
    Game.resources_changed.emit(Game.resources)