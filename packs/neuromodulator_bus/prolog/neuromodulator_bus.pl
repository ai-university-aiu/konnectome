% Declare this file as the 'neuromodulator_bus' module and list the predicates it exports.
:- module(neuromodulator_bus, [
    % neuromodulator_bus_new/1: an empty bus, every modulator level at zero.
    neuromodulator_bus_new/1,
    % neuromodulator_bus_broadcast/4: a source writes a modulator's level for everyone to read.
    neuromodulator_bus_broadcast/4,
    % neuromodulator_bus_level/3: read one modulator's current level.
    neuromodulator_bus_level/3,
    % neuromodulator_bus_broadcast_territory/5: a source writes a modulator's level into one territory.
    neuromodulator_bus_broadcast_territory/5,
    % neuromodulator_bus_level_territory/4: read a modulator's level in one territory, diffuse fallback.
    neuromodulator_bus_level_territory/4,
    % neuromodulator_bus_operating_state/2: read the global operating state, online by default.
    neuromodulator_bus_operating_state/2,
    % neuromodulator_bus_broadcast_operating_state/3: announce the global operating state to every subscriber.
    neuromodulator_bus_broadcast_operating_state/3
]).

% Import membership for reading a level from the bus.
:- use_module(library(lists), [memberchk/2]).
% Import exclude for replacing a modulator's old level when a new one is broadcast.
:- use_module(library(apply), [exclude/3]).

% The neuromodulatory bus is Architecture Component 4: a broadcast channel of global brain-chemical
% levels (dopamine, norepinephrine, and the rest). It is the one place the architecture permits a
% global value: source nuclei write it, and every construct's update and learning rule read it.
% The bus is an ordered list of Modulator-Level pairs; an absent modulator reads as level zero.
% Per the guiding book's FR-6, a broadcast field also carries a level PER TARGET TERRITORY: a
% territory entry is the pair territory(Modulator, Territory)-Level beside the global pairs. A
% territory with its own level reads that level; a territory without one falls back to the global
% broadcast, the diffuse field, exactly as a molecule released from a small nucleus diffuses to
% every target that has no local concentration of its own; and with neither, the level is zero.
% Per the Layer 11 global-states catalogue (Chapters 11 and 16), the bus also carries the GLOBAL
% OPERATING STATE: a single binary selection with exactly two values, online and offline, announced
% on the same bus every subscriber already reads - the state announcement service. Its key is the
% third key shape, the compound global(operating_state), which the atom-only modulator guard and
% the territory/2 shape can never alias; an absent entry reads as online, the waking default, so a
% bus built before this state existed behaves exactly as it always did.

% neuromodulator_bus_check_atom(+Value, +ErrorName): refuse a name that is not a plain atom, by name.
neuromodulator_bus_check_atom(Value, ErrorName) :-
    % An unbound name cannot be judged, and must never be silently bound by a lookup.
    (  var(Value)
    -> throw(error(instantiation_error, _))
    % A modulator or territory name is a plain atom, never a compound that could alias a bus key.
    ;  atom(Value)
    -> true
    % Anything else is refused aloud, so the two key shapes can never collide in silence.
    ;  throw(error(domain_error(ErrorName, Value), _))
    ).

% neuromodulator_bus_new(-Bus): an empty bus, on which every modulator reads as zero.
neuromodulator_bus_new([]).

% neuromodulator_bus_level(+Bus, +Modulator, -Level): read a modulator's current broadcast level.
neuromodulator_bus_level(Bus, Modulator, Level) :-
    % Refuse an unbound or compound modulator name before touching the bus.
    neuromodulator_bus_check_atom(Modulator, neuromodulator_bus_modulator),
    % Return the stored level if present, otherwise zero.
    ( memberchk(Modulator-Found, Bus) -> Level = Found ; Level = 0 ).

% neuromodulator_bus_matches(+Modulator, +Pair): the pair carries this modulator's level.
neuromodulator_bus_matches(Modulator, Modulator-_Level).

% neuromodulator_bus_broadcast(+Bus0, +Modulator, +Level, -Bus): a source writes a modulator's level.
neuromodulator_bus_broadcast(Bus0, Modulator, Level, Bus) :-
    % Refuse an unbound or compound modulator name before touching the bus.
    neuromodulator_bus_check_atom(Modulator, neuromodulator_bus_modulator),
    % Drop any existing level for this modulator so the newest broadcast wins.
    exclude(neuromodulator_bus_matches(Modulator), Bus0, Without),
    % Add the new level and keep the bus in a canonical sorted order.
    keysort([Modulator-Level|Without], Bus).

% neuromodulator_bus_broadcast_territory(+Bus0, +Modulator, +Territory, +Level, -Bus): a local write.
neuromodulator_bus_broadcast_territory(Bus0, Modulator, Territory, Level, Bus) :-
    % Refuse an unbound or compound modulator name before touching the bus.
    neuromodulator_bus_check_atom(Modulator, neuromodulator_bus_modulator),
    % Refuse an unbound or compound territory name for the same reason.
    neuromodulator_bus_check_atom(Territory, neuromodulator_bus_territory),
    % Drop any existing level for this modulator in this territory so the newest broadcast wins.
    exclude(neuromodulator_bus_matches(territory(Modulator, Territory)), Bus0, Without),
    % Add the new territory level and keep the bus in a canonical sorted order.
    keysort([territory(Modulator, Territory)-Level|Without], Bus).

% neuromodulator_bus_level_territory(+Bus, +Modulator, +Territory, -Level): a local read, diffuse fallback.
neuromodulator_bus_level_territory(Bus, Modulator, Territory, Level) :-
    % Refuse an unbound or compound modulator name before touching the bus.
    neuromodulator_bus_check_atom(Modulator, neuromodulator_bus_modulator),
    % Refuse an unbound or compound territory name for the same reason.
    neuromodulator_bus_check_atom(Territory, neuromodulator_bus_territory),
    % A territory with its own level reads that level; otherwise it reads the diffuse global field.
    (  memberchk(territory(Modulator, Territory)-Found, Bus)
    -> Level = Found
    % The global read already answers zero when the field itself is silent.
    ;  neuromodulator_bus_level(Bus, Modulator, Level)
    ).

% neuromodulator_bus_check_operating_state(+State): refuse anything but the two flip-flop positions.
neuromodulator_bus_check_operating_state(State) :-
    % An unbound state cannot be judged, and must be refused before any wrong pretends to name it.
    (  var(State)
    -> throw(error(instantiation_error, _))
    % The flip-flop has exactly two positions and spends no time halfway; both are plain atoms.
    ;  memberchk(State, [online, offline])
    -> true
    % A third value is refused aloud, by the state's own name, so no halfway state can ever ride the bus.
    ;  throw(error(domain_error(neuromodulator_bus_operating_state, State), _))
    ).

% neuromodulator_bus_operating_state(+Bus, -State): read the global operating state, online by default.
neuromodulator_bus_operating_state(Bus, State) :-
    % REVIEW FIX (unbound-wrong-judgement lens): an unbound bus must be refused, never silently
    % bound by the lookup into a partial list carrying an invented, unbound state.
    (  var(Bus)
    -> throw(error(instantiation_error, _))
    ;  true
    ),
    % An announced state reads back; a bus that never heard one operates online, the waking default.
    ( memberchk(global(operating_state)-Found, Bus) -> State = Found ; State = online ).

% neuromodulator_bus_broadcast_operating_state(+Bus0, +State, -Bus): announce the state to every subscriber.
neuromodulator_bus_broadcast_operating_state(Bus0, State, Bus) :-
    % Refuse an unbound state or a third value before touching the bus.
    neuromodulator_bus_check_operating_state(State),
    % Drop any existing state entry so the newest announcement wins, as it does for every level.
    exclude(neuromodulator_bus_matches(global(operating_state)), Bus0, Without),
    % Add the new state and keep the bus in a canonical sorted order.
    keysort([global(operating_state)-State|Without], Bus).
