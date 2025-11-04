##Singleton za ocitavanje efekata i na osnovu njih poziva odgovarajuce funkcije
##koje ce da implementiraju promene za taj konkretni tip efekta

extends Node

##Ocitaj efekat sa karte i pozovi funkciju za njega
func apply_card(card: Card) -> void:
    match card.effect_type:
        "gain_resource":
            var resource := String(card.effect_params.get("resource", "food"))
            var amount := int(card.effect_params.get("amount", 1))
            amount = EventManager.apply_yield_on_gain(resource, amount)
            Game.resources[resource] = int(Game.resources.get(resource, 0)) + amount
            Game.resources_changed.emit(Game.resources)

            EventManager.notify_gain(resource, amount)

        "building":
            BuildingManager.build_or_upgrade(card.effect_params)

        _:
            push_warning("Nisi implementirao ovaj efekat tikvane: %s" % card.effect_type)