##Menadzer dogadjaja: RNG paljenje, trajanje, cooldown, tick i end efekti
extends Node

#salji kada je event ubacen/izbacen iz liste aktivnih event-ova
signal event_started(event: GameEvent)
signal event_ended(event: GameEvent)
#Saljemo celu listu radi bannera
signal active_events_changed(list: Array)
#Salji kada je u pitanju T2 event - event sa izborima pa se pali panel za njega
signal choice_required(event: GameEvent)
#Salji kada je u pitanju T3 event - pratimo koliko se karata odigralo koje su potrebne da se ispune zahtevi
signal objective_updated(event: GameEvent, progress: int, goal: int, turns_left: int)

#Sansa da pokrenemo novi event na pocetku poteza
@export var trigger_chance := 0.33
#Koliko istovremeno aktivnih dogadjaja dozvoljavamo
@export var max_concurrent_events := 3

#Svaki zapis aktivnog event-a: { "event": GameEvent, "turns_left": int }
var active_events: Array[Dictionary] = []
#Preostali potezi do sledeceg moguceg paljenja proteklih zavrsenih event-ova
var cooldowns: Dictionary = {}


func _ready() -> void:
    Game.turn_changed.connect(on_turn_changed)


func on_turn_changed(_new_turn: int) -> void:
    apply_tick_and_advance()
    cooldowns_tick()
    maybe_trigger_new()


##Upotrebi efekte dogadjaja, smanji jos koliko poteza je aktivan i deaktiviraj one koji su zavrsili
func apply_tick_and_advance() -> void:
    var to_remove: Array[int] = []

    for i in range(active_events.size()):
        var active_event := active_events[i]
        var event: GameEvent = active_event.event

        var tick_effects: Array[EventEffect] = active_event.get("tick_effects", event.tick_effects)
        var end_effects: Array[EventEffect] = active_event.get("end_effects", event.end_effects)

        #Tick efekti (npr. gain_resource po potezu. yield_mod se ne primenjuje ovde posto je dodatak na igranje drugih karata)
        apply_effects(tick_effects)

        #Odbrojavanje trajanja
        active_event.turns_left -= 1

        #Ako je T3 event, odbrojavamo deadline zahteva
        if active_event.has("objective_state"):
            var objective_state: Dictionary = active_event.objective_state
            objective_state.deadline_left = int(objective_state.deadline_left) - 1
            active_event.objective_state = objective_state
            # (opciono) javi UI-u napredak
            objective_updated.emit(event, int(objective_state.progress), int(objective_state.goal), int(objective_state.deadline_left))

        active_events[i] = active_event

        #Kraj dogadjaja
        if active_event.turns_left <= 0:
            apply_effects(end_effects)

            #U slucaju da je T3 event proveravamo da li su svi uslovi ispunjeni
            if active_event.has("objective_state") and event.objective and String(event.objective.objective_type) == "play_cards_gain_resource":
                var objective_state: Dictionary = active_event.objective_state
                var success := int(objective_state.progress) >= int(objective_state.goal)
                var effects := event.objective.on_success if success else event.objective.on_fail
                apply_effects(effects)

            if event.cooldown > 0:
                cooldowns[event.id] = event.cooldown
            to_remove.append(i)
            event_ended.emit(event)

    #Ukloni zavrsene (od kraja ka pocetku)
    for i in range(to_remove.size() - 1, -1, -1):
        active_events.remove_at(to_remove[i])
    
    active_events_changed.emit(active_events)


##Prodji kroz niz event-ova na cooldown-u i umanji im cooldown za 1, ako im je gotov
##cooldown, obrisi ih iz niza
func cooldowns_tick() -> void:

    for key in cooldowns.keys():
        cooldowns[key] = int(cooldowns[key]) - 1

        if cooldowns[key] <= 0:
            cooldowns.erase(key)


##Proveri da li ce se aktivirati event na ovome potezu
func maybe_trigger_new() -> void:

    #ima li mesta?
    if active_events.size() >= max_concurrent_events:
        return

    #ima li sanse?
    if Game.rng.randf() > trigger_chance:
        return

    #Event-ovi koji su dostupni po uslovima, nisu na cooldown-u i nisu vec aktivni
    var potential_events: Array[GameEvent] = []

    for event in EventDB.get_all():

        if cooldowns.has(event.id): 
            continue

        if is_active(event.id): 
            continue

        if EventDB.are_conditions_met(event):
            potential_events.append(event)

    if potential_events.is_empty():
        return

    #Tezinski izbor po weight
    var total_weight := 0

    for event in potential_events: 
        total_weight += max(event.weight, 1)

    var pick := Game.rng.randi_range(1, total_weight)
    var accumulated_weight := 0
    var chosen: GameEvent = null

    for event in potential_events:
        accumulated_weight += max(event.weight, 1)
        if pick <= accumulated_weight:
            chosen = event
            break

    if chosen == null:
        return

    start_event(chosen)


##Proverava da li je event ciji je ID prosledjen trenutno aktivan
func is_active(id: String) -> bool:

    for active_event in active_events:

        var event: GameEvent = active_event.event

        if event.id == id:
            return true

    return false


##Pokreni event. Primeni efekte, dodaj u active_events
func start_event(event: GameEvent) -> void:

    #Da li je T2 event? Ako jeste, salji da se pali modal
    if event.choices.size() > 0:
        choice_required.emit(event)
        return

    #Da li je T3 event? Ako jeste, dodaj u listu aktivnih i napravi polja za pracene zahteva
    if event.objective:
        var objective_type := String(event.objective.objective_type)

        if objective_type == "play_cards_gain_resource":
            var goal_plays:int = int(event.objective.params.get("min_plays", 0))
            var target_resource: String = String(event.objective.params.get("resource", ""))
            var deadline: int = max(1, int(event.objective.deadline))

            apply_effects(event.start_effects)

            active_events.append({
                "event": event,
                #Vezujemo trajanje za rok objective-a (jasnije za igraca)
                "turns_left": deadline,
                "objective_type": objective_type,
                "objective_state": {
                    "progress": 0,
                    "goal": goal_plays,
                    "resource": target_resource,
                    "deadline_left": deadline
                }
            })
            event_started.emit(event)
            active_events_changed.emit(active_events)
            return

    if event.duration <= 0:
        #Instant event: start + end, odmah na cooldown i gotovo
        apply_effects(event.start_effects)
        apply_effects(event.end_effects)

        if event.cooldown > 0:
            cooldowns[event.id] = event.cooldown
        
        event_started.emit(event)
        event_ended.emit(event)
        return

    apply_effects(event.start_effects)
    active_events.append({ "event": event, "turns_left": event.duration })
    event_started.emit(event)
    active_events_changed.emit(active_events)


##Uzmi dati event i izbor napravljen za njega, primeni izbor i dodaj event u active_events
func apply_choice(event: GameEvent, choice: EventChoice) -> void:

    if not event or not choice:
        push_warning("apply_choice nije dobio nista")
        return

    #Defensive: proveri da li je choice deo tog eventa
    if not event.choices.has(choice):
        push_warning("apply_choice je primetio da prosledjeni choice ne pripada eventu '%s'" % event.id)
        return

    #Trosak izbora
    if not CostService.can_pay_cost_choice(choice.cost):
        push_warning("apply_choice je primetio da nema dovoljno resursa za izbor '%s'" % choice.label)
        return
    CostService.pay_cost_choice(choice.cost)

    #Primeni start efekte izbora i aktiviraj override tick/end efekte
    apply_effects(choice.start_effects)

    if choice.duration > 0:
        active_events.append({
            "event": event,
            "turns_left": choice.duration,
            "tick_effects": choice.tick_effects,
            "end_effects":  choice.end_effects
        })
        event_started.emit(event)
        active_events_changed.emit(active_events)
    else:
        #Instant choice
        apply_effects(choice.end_effects)
        if event.cooldown > 0:
            cooldowns[event.id] = event.cooldown
        event_started.emit(event)
        event_ended.emit(event)    


##Primeni prosledjene efekte
func apply_effects(effects: Array[EventEffect]) -> void:
    for effect in effects:

        if effect == null: 
            continue

        match effect.effect_type:
            "gain_resource":
                var resource := String(effect.params.get("resource", "food"))
                var amount := int(effect.params.get("amount", 1))
                Game.resources[resource] = int(Game.resources.get(resource, 0)) + amount
                Game.resources_changed.emit(Game.resources)
            #yield_mod je modifikator i NE implementiramo ga ovde
            "yield_mod":
                print("Aktivirao se event sa yield_mod-om.")
            _:
                push_warning("EventManager nema implementiran effect_type: %s" % effect.effect_type)


##Primeni yield_mod kog cemo pozivati u MyEffectSystem-u koji ce onda da to dalje prosledi
##do odgovarajucih karata
func apply_yield_on_gain(resource: String, base_amount: int) -> int:
    var add_bonus := 0

    for active_event in active_events:
        var event: GameEvent = active_event.event
        var tick_effects: Array[EventEffect] = active_event.get("tick_effects",event.tick_effects)

        for effect in tick_effects:

            if effect == null or effect.effect_type != "yield_mod":
                continue

            var scope := String(effect.params.get("scope", "resource"))
            var applies := false

            #Vazi za SVE resurse
            if scope == "global":
                applies = true
            #Vazi samo za taj resource
            elif scope == "resource":
                var res_from_eff := String(effect.params.get("resource", ""))
                applies = (res_from_eff == resource)
            else:
                #Nepoznat scope -> preskacemo
                continue

            if not applies:
                continue

            var operation := String(effect.params.get("operation", "add"))
            var value := int(effect.params.get("value", 0))

            if operation == "add":
                add_bonus += value
            else:
                #Ovde kasnije mozemo dodati npr. "mul" za multiplicative, "scale" za odnos, itd.
                pass

    return base_amount + add_bonus

##Funkcija koja broji odigrane karte zarad postizanja zahteva T3 event-ova
func notify_gain(resource: String, _amount: int) -> void:
    # Ovo zovi SAMO iz sistema karata (ne iz event tick-ova), da bi brojalo "plays", ne pasivni income.
    for i in range(active_events.size()):
        var active_event : Dictionary = active_events[i]

        if not active_event.has("objective_state"):
            continue

        var event: GameEvent = active_event.event

        if not event.objective:
            continue

        if String(event.objective.objective_type) != "play_cards_gain_resource":
            continue

        var objective_state : Dictionary = active_event.objective_state

        if String(objective_state.resource) == resource:
            objective_state.progress = int(objective_state.progress) + 1  # broj odigranih KARATA (ne amount)
            active_event.objective_state = objective_state
            active_events[i] = active_event
            objective_updated.emit(event, int(objective_state.progress), int(objective_state.goal), int(objective_state.deadline_left))