##Singleton za ocitavanje efekata i na osnovu njih poziva odgovarajuce funkcije
##koje ce da implementiraju promene za taj konkretni tip efekta

extends Node

##Ocitaj efekat sa karte i pozovi funkciju za njega
func apply_card(card: Card) -> void:
    match card.effect_type:
        "gain_resource":
            var r := String(card.effect_params.get("resource", "food"))
            var amt := int(card.effect_params.get("amount", 1))
            Game.resources[r] = int(Game.resources.get(r, 0)) + amt
            Game.resources_changed.emit(Game.resources)

        "building":
            BuildingManager.build_or_upgrade(card.effect_params)

        _:
            push_warning("Nisi implementirao ovaj efekat tikvane: %s" % card.effect_type)
