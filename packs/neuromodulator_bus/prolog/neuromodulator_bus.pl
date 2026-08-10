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
    neuromodulator_bus_broadcast_operating_state/3,
    % neuromodulator_bus_check_operating_state/1: refuse anything but the two flip-flop positions, by name.
    % (Exported in slice 38 so the tick's day-or-night dispatch judges the state it READS against the
    % bus's OWN domain, rather than growing a second copy of the same refusal and drifting from it.)
    neuromodulator_bus_check_operating_state/1,
    % neuromodulator_bus_global_state/2: read the WIDENED state - a pole and a sub-mode - as one term.
    neuromodulator_bus_global_state/2,
    % neuromodulator_bus_broadcast_global_state/3: announce the widened state, pole and sub-mode together.
    neuromodulator_bus_broadcast_global_state/3,
    % neuromodulator_bus_throw_mode/4: a source throws a MODE at every construct of one kind.
    neuromodulator_bus_throw_mode/4,
    % neuromodulator_bus_thrown_mode/3: read the mode standing thrown at one construct kind.
    neuromodulator_bus_thrown_mode/3,
    % neuromodulator_bus_release_mode_throw/3: withdraw a standing throw, returning the kind to itself.
    neuromodulator_bus_release_mode_throw/3,
    % neuromodulator_bus_check_thrown_mode/1: refuse a hole, a compound, or the reserved silence name.
    neuromodulator_bus_check_thrown_mode/1,
    % neuromodulator_bus_channel/1: the corpus's roster of six named broadcast channels, enumerable.
    neuromodulator_bus_channel/1,
    % neuromodulator_bus_channel_role/2: the computational role the corpus assigns one channel.
    neuromodulator_bus_channel_role/2,
    % neuromodulator_bus_channel_source/2: the source nucleus the corpus names for one channel.
    neuromodulator_bus_channel_source/2,
    % neuromodulator_bus_channel_cognitive/2: the corpus's own COG or NON-COG tag for one channel.
    neuromodulator_bus_channel_cognitive/2,
    % neuromodulator_bus_check_channel/1: refuse a name the roster does not carry - OFFERED, never applied here.
    neuromodulator_bus_check_channel/1,
    % neuromodulator_bus_channel_named/2: resolve the corpus's own name for a channel onto the roster's.
    neuromodulator_bus_channel_named/2
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
% Per the mode-register design authority's Part Nine slice four, the bus also carries the MODE THROW:
% a fourth key shape, mode_throw(ConstructKind), on which one write sets the mode of every construct
% of that kind at once. That channel and the decision it embodies are documented at the foot of this
% file, where the code for it lives.
% Per the Layer 11 global-states catalogue's Chapter 16, which is this pack's own chapter, the bus
% also carries a declared ROSTER of the six named broadcast channels with the role, source nucleus
% and cognitive tag the corpus assigns each. The roster DECLARES and does not GUARD: it is documented
% at the foot of this file, below the mode throw, where the code for it lives.

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
    % SINCE SLICE 46 THE CHANNEL MAY CARRY A WIDENED TERM, and this reader still hands back THE POLE
    % ALONE, deliberately and permanently. Every caller written before the widening asks this question
    % and means "am I awake or asleep"; answering it with a compound would have broken all of them,
    % and answering it with the pole keeps every one of them correct rather than merely compatible.
    (   memberchk(global(operating_state)-Found, Bus)
    ->  % A widened announcement carries the pole in its first field; a bare atom IS the pole.
        (   Found = global_state(Pole, _SubMode)
        ->  State = Pole
        ;   State = Found
        )
    ;   % A bus that never heard a state operates online, the waking default.
        State = online
    ).

% neuromodulator_bus_global_state(+Bus, -GlobalState): read the WIDENED state as one term.
neuromodulator_bus_global_state(Bus, GlobalState) :-
    % An unbound bus is refused, never silently bound by the lookup into a partial list.
    (  var(Bus)
    -> throw(error(instantiation_error, _))
    ;  true
    ),
    % A widened announcement reads back whole; a bare atom is a pole whose sub-mode was never stated,
    % and it reads back as the pole with its sub-mode UNSTATED rather than with one invented for it.
    % Naming the sub-mode a bare announcement should carry is the MASTER REGISTER's job, not the
    % channel's, and the channel does not guess on its behalf.
    (   memberchk(global(operating_state)-Found, Bus)
    ->  (   Found = global_state(_Pole, _SubMode)
        ->  GlobalState = Found
        ;   GlobalState = global_state(Found, unstated)
        )
    ;   % A silent channel reads as the waking default with its sub-mode unstated, for the same reason.
        GlobalState = global_state(online, unstated)
    ).

% neuromodulator_bus_broadcast_global_state(+Bus0, +GlobalState, -Bus): announce pole and sub-mode.
neuromodulator_bus_broadcast_global_state(Bus0, GlobalState, Bus) :-
    % THE CHANNEL JUDGES SHAPE AND NOT POLICY, and that division is deliberate. It refuses a term
    % that is not a widened state, and it refuses a pole the flip-flop does not have - both are
    % STRUCTURAL. It does NOT judge whether a sub-mode belongs to its pole, because WHICH SUB-MODES
    % A POLE HAS IS A ROSTER, and a roster is policy that belongs to the construct that owns it.
    % This is the same division slice 42 drew when mode_register was deliberately not taught that a
    % fault may not be a mode: shape is structural, policy belongs to the process that enforces it.
    (  var(GlobalState)
    -> throw(error(instantiation_error, _))
    ;  true
    ),
    % Refuse anything that is not the widened two-field term, naming what arrived.
    (  GlobalState = global_state(Pole, SubMode)
    -> true
    ;  throw(error(domain_error(neuromodulator_bus_global_state, GlobalState), _))
    ),
    % Refuse a pole the flip-flop does not have, through the channel's own existing domain.
    neuromodulator_bus_check_operating_state(Pole),
    % A sub-mode is named by a plain atom, the same key shape every other name on this bus uses.
    neuromodulator_bus_check_atom(SubMode, neuromodulator_bus_global_sub_mode),
    % Drop any existing state entry so the newest announcement wins, as it does for every level.
    exclude(neuromodulator_bus_matches(global(operating_state)), Bus0, Without),
    % Add the widened state and keep the bus in a canonical sorted order.
    keysort([global(operating_state)-global_state(Pole, SubMode)|Without], Bus).

% neuromodulator_bus_broadcast_operating_state(+Bus0, +State, -Bus): announce the state to every subscriber.
neuromodulator_bus_broadcast_operating_state(Bus0, State, Bus) :-
    % Refuse an unbound state or a third value before touching the bus.
    neuromodulator_bus_check_operating_state(State),
    % Drop any existing state entry so the newest announcement wins, as it does for every level.
    exclude(neuromodulator_bus_matches(global(operating_state)), Bus0, Without),
    % Add the new state and keep the bus in a canonical sorted order.
    keysort([global(operating_state)-State|Without], Bus).

% ---------------------------------------------------------------------------
% THE MODE THROW (konnectome build slice 41)
% ---------------------------------------------------------------------------
%
% THE CORPUS'S OWN COORDINATION MECHANISM, AND IT NEEDS NO CONTROLLER. The mode-register design
% authority's most consequential finding is that there is NO derivation function from a parent's mode
% to a child's - the corpus denies the reduction twice - and that what does the coordinating is ONE
% BROADCAST, WRITTEN ONCE AND READ MANY TIMES. konnectome already owned the broadcast; what it did not
% own was a broadcast that carries a MODE rather than a level. This is that channel: one write, and
% every construct of the named kind departs its current mode by a row its OWN table declares.
%
% THE KEY IS A FOURTH SHAPE AND CANNOT ALIAS THE OTHER THREE. The bus's keys are now: a plain ATOM
% (a modulator level), territory/2 (a level in one territory), global/1 (the operating state), and
% mode_throw/1 (a mode thrown at one construct kind). The atom guard keeps a modulator out of the
% compound shapes, and no two compounds share a name and arity, so no read can answer with another
% channel's value.
%
% THE COMMAND-VERSUS-BIAS DECISION, MADE HERE AND RECORDED AS KONNECTOME'S OWN. The design
% authority's Part Seven item 1 records that the corpus is genuinely silent: keeps it in the Pinpoint
% Report, set from above reads as COMMAND, and biases it toward flashing reads as BIAS, sometimes in
% the same volume. THE CORPUS DOES NOT INSTRUCT, SO KONNECTOME CHOOSES, AND THIS IS THE CHOICE:
%
%   A THROWN MODE IS A COMMAND AT THE DISCRETE GRAIN. BIAS IS THE CHANNEL KONNECTOME ALREADY HAS.
%
% Three reasons, none of them the corpus's, all of them konnectome's:
%
% FIRST, IT UN-CONFLATES TWO OPERATIONS THE DESIGN AUTHORITY SAYS ARE CURRENTLY CONFLATED. Its Part
% Eight records that continuous modulation and discrete throw are different operations on the same
% channel and that konnectome's bus-modulated relay runs them together. konnectome ALREADY OWNS BIAS,
% built and running: relay_modulated reads a level off this bus and scales its gain where it stands.
% Had the throw ALSO been a bias, konnectome would own two bias mechanisms, no command mechanism, and
% the conflation would be permanent. Choosing command is what separates them.
%
% SECOND, A COMMAND COSTS NO INVENTED NUMBER AND A BIAS COSTS AT LEAST ONE. A bias moves a threshold,
% and konnectome has no threshold offset the corpus supplies - it would have to be made up, in a
% repository whose standing rule for this family is that no number in the pack is konnectome's
% invention. A command names a mode the target's own register already declares.
%
% THIRD, COMMAND IS THE REVERSIBLE CHOICE. A bias channel can later be added BESIDE this one as a
% second agency writing rows into the same table, and nothing built on the command has to move. The
% reverse is not true: a bias-only throw cannot be sharpened into a command without inventing the
% threshold above.
%
% AND THE CONFLICT RULE THAT FOLLOWS FROM IT, ALSO KONNECTOME'S OWN (Part Seven item 2). When a
% construct's self-selected transition and a standing throw disagree, THE THROW PREEMPTS. The corpus
% shows preemption in one place and negotiated arbitration in another and states no general rule;
% konnectome takes preemption because it is the rule that can be READ without running the construct,
% which the owner's visualization addendum requires of every register slice. NEGOTIATED ARBITRATION
% IS DEFERRED BY NAME, not denied: it is the shape a later slice would need if two sources ever throw
% at the same kind in the same tick, and this channel deliberately holds ONE standing throw per kind
% so that case cannot arise unnoticed - the newest throw replaces the older, exactly as every other
% broadcast on this bus does.
%
% WHAT THIS CHANNEL DOES NOT DO, STATED SO THE GAP IS A DECISION. It does not address ONE construct:
% a throw is aimed at a KIND, because a broadcast that could name an individual would be a wire, not
% a broadcast. It does not carry a territory, because no reading has yet asked for a throw that
% reaches some territories and not others. And it does not itself move any construct - it publishes,
% and each construct's own transition table decides whether it has anywhere to go.

% The atom a silent channel reads back. It is RESERVED: a write of this name is refused below, so a
% register that happened to declare a mode of the same name could never be thrown by accident, and a
% reader can never mistake silence for an instruction.
neuromodulator_bus_no_mode_thrown(no_mode_thrown).

% neuromodulator_bus_check_thrown_mode(+Mode): refuse a hole, a compound, or the reserved silence name.
neuromodulator_bus_check_thrown_mode(Mode) :-
    % Refuse an unbound or compound mode name exactly as a modulator name is refused.
    neuromodulator_bus_check_atom(Mode, neuromodulator_bus_thrown_mode),
    % Read the reserved name once, from the one place it is written.
    neuromodulator_bus_no_mode_thrown(Reserved),
    % Refuse the silence name aloud: throwing it would publish an instruction that reads as no instruction.
    (  Mode == Reserved
    -> throw(error(domain_error(neuromodulator_bus_thrown_mode, Mode), _))
    ;  true
    ).

% neuromodulator_bus_throw_mode(+Bus0, +ConstructKind, +Mode, -Bus): a source throws a mode at a kind.
neuromodulator_bus_throw_mode(Bus0, ConstructKind, Mode, Bus) :-
    % Refuse an unbound or compound construct kind before touching the bus.
    neuromodulator_bus_check_atom(ConstructKind, neuromodulator_bus_construct_kind),
    % Refuse a hole, a compound, or the reserved silence name as the thrown mode.
    neuromodulator_bus_check_thrown_mode(Mode),
    % Drop any standing throw at this kind so the newest throw wins, as it does for every level.
    exclude(neuromodulator_bus_matches(mode_throw(ConstructKind)), Bus0, Without),
    % Add the new throw and keep the bus in a canonical sorted order.
    keysort([mode_throw(ConstructKind)-Mode|Without], Bus).

% neuromodulator_bus_thrown_mode(+Bus, +ConstructKind, -Mode): the mode standing thrown at one kind.
neuromodulator_bus_thrown_mode(Bus, ConstructKind, Mode) :-
    % An unbound bus is refused, never silently bound by the lookup into a partial list.
    (  var(Bus)
    -> throw(error(instantiation_error, _))
    ;  true
    ),
    % Refuse an unbound or compound construct kind before reading.
    neuromodulator_bus_check_atom(ConstructKind, neuromodulator_bus_construct_kind),
    % A standing throw reads back; a channel nobody has written reads as the reserved silence name.
    (  memberchk(mode_throw(ConstructKind)-Found, Bus)
    -> Mode = Found
    ;  neuromodulator_bus_no_mode_thrown(Mode)
    ).

% neuromodulator_bus_release_mode_throw(+Bus0, +ConstructKind, -Bus): withdraw a standing throw.
% A throw that could never be withdrawn would take a kind's self-selection away permanently, which is
% a larger claim than this slice makes: the throw preempts while it stands, and no longer.
neuromodulator_bus_release_mode_throw(Bus0, ConstructKind, Bus) :-
    % Refuse an unbound or compound construct kind before touching the bus.
    neuromodulator_bus_check_atom(ConstructKind, neuromodulator_bus_construct_kind),
    % Drop this kind's throw entry; a kind with no standing throw is left exactly as it was.
    exclude(neuromodulator_bus_matches(mode_throw(ConstructKind)), Bus0, Without),
    % Keep the bus in the same canonical sorted order every other write leaves it in.
    keysort(Without, Bus).

% ---------------------------------------------------------------------------
% THE SIX NAMED BROADCAST CHANNELS (konnectome build slice 48)
% ---------------------------------------------------------------------------
%
% WHERE THE ROSTER COMES FROM, AND WHY IT IS THE BUS'S OWN CHAPTER. The Layer 11 global-states
% volume's Chapter 16 is THE ASCENDING BROADCAST SYSTEM (The State Announcement Service): "the
% noradrenaline of the locus coeruleus, the serotonin of the raphe, the acetylcholine of the
% brainstem and basal forebrain, the histamine of the tuberomammillary nucleus, the dopamine of the
% ventral tegmental area, plus the orexin of the lateral hypothalamus - considered as a single Layer
% 11 organ". That chapter says "the channels are the six transmitter systems themselves" and calls
% the organ, in its own engineering terms, "the global configuration bus itself". This pack IS that
% organ, and until this slice it carried the channels without ever naming them.
%
% EACH CHANNEL'S ROLE IS THE LAYER 10 SYSTEMS VOLUME'S OWN SUBTITLE, chapters 31 through 36: the
% Reward-Teaching Broadcast, the Gain-and-Reset Broadcast, the Patience-and-Mood Broadcast, the
% Attention-and-Encoding Broadcast, the Wakefulness Broadcast, and the Sleep-Wake Stabiliser. The
% COG and NON-COG tags on those same chapter headings are the corpus's own and are carried through
% unchanged, because a later caller that wants only the cognitive channels should read that judgment
% from the corpus rather than re-derive it.
%
% WHAT THIS SLICE ADDS IS A DECLARATION AND NOT A GUARD. neuromodulator_bus_broadcast/4 and
% neuromodulator_bus_level/3 still accept any atom, exactly as they did before this file mentioned a
% roster, AND THAT IS A FINDING RATHER THAN A COURTESY: THE MODULATOR KEYSPACE IS A NAMESPACE AND
% NOT A ROSTER. stabiliser publishes its stability bias under the atom key stability_bias, on this
% same channel shape, and it is not a neuromodulator and never was. A roster enforced on write would
% have refused a correct, running, tested caller. So the check is written, exported and applied to
% nothing here: a caller who wants the roster's discipline asks for it by name.
%
% KONNECTOME'S OWN DECISION, RECORDED IN THE LEDGER AS DECISION-7, IN TWO HALVES.
%
% FIRST HALF - THE ROSTER IS DECLARED IN THE NAME THE MACHINE ALREADY BROADCASTS, AND THE CORPUS'S
% NAME RESOLVES ONTO IT. The corpus writes noradrenaline; konnectome has broadcast norepinephrine
% since slice 19, from arousal_regulation, and the capstone's told story reads it. The two words name
% one molecule. Adopting the corpus's spelling would have RENAMED A RUNNING CHANNEL, which is a
% migration and not a declaration, and this item's whole warrant is that it changes nothing; and
% declaring the corpus's spelling BESIDE the running one would have been worse, because THIS BUS
% ANSWERS AN UNKNOWN KEY WITH ZERO. A caller written from the corpus and reading noradrenaline off a
% bus carrying norepinephrine would be told, in perfect silence, that arousal is at baseline. THAT IS
% A PLAUSIBLE ANSWER AND NOT AN ERROR, which is the failure mode this repository has now paid three
% times to learn to prefer against. neuromodulator_bus_channel_named/2 is therefore the one place the
% corpus's word is written down, and it RESOLVES rather than aliases: it is a lookup a caller must
% pass through, not a second key on the bus.
%
% SECOND HALF - NO PER-CHANNEL DEFAULT LEVEL IS DECLARED, AND THE REFUSAL IS THE POINT. The corpus
% does supply numbers that look like defaults: a noradrenaline tonic level of 0.3, a serotonin level
% of 0.5, an acetylcholine level of 0.5. EVERY ONE OF THEM IS AN INITIAL VALUE INSIDE ONE CHAPTER'S
% WORKED PSEUDOCODE, not a resting level of the broadcast, and there is no such number at all for
% histamine or for orexin. What the corpus states about this organ's resting condition is the
% opposite of a per-channel scalar: "the blend, not any single chemical, names the mode", and the
% bus is "a mix of six modulators whose blend, not whose bits, encodes the state". A per-channel
% default lifted out of a worked example would be A DEFAULT WITH A BORROWED WARRANT - an invented
% value that has learned to cite, which is what slice 45 refused as a number and slice 46 refused as
% a mode name. The zero this bus has always answered with is not a resting level and does not pretend
% to be one; it is silence, and it stays silence.
%
% WHAT THIS SLICE DOES NOT DO, STATED SO THE GAPS ARE DECISIONS. It declares no BLEND: naming the
% chemical profile that belongs to each global state is the master register's grain and the Layer 11
% modes volume's three blends are the material for it, not this channel's. It gives no channel a mode
% register, though the Layer 10 modes volume supplies one for each. And it wires nothing: four of the
% six channels are named here and written by nobody, which is the same shape slice 46 left when the
% register named sleep sub-modes the machine cannot yet enter, and it is recorded rather than hidden.

% neuromodulator_bus_channel(?Channel): the corpus's roster of six named broadcast channels.
% The order is Chapter 16's own, and the roster is deliberately enumerable: a roster a caller cannot
% walk is a comment. norepinephrine carries the noradrenaline channel, per DECISION-7's first half.
neuromodulator_bus_channel(norepinephrine).
neuromodulator_bus_channel(serotonin).
neuromodulator_bus_channel(acetylcholine).
neuromodulator_bus_channel(histamine).
neuromodulator_bus_channel(dopamine).
neuromodulator_bus_channel(orexin).

% neuromodulator_bus_channel_role(+Channel, -Role): the computational role the corpus assigns.
% Each role is the Layer 10 systems volume's own chapter subtitle, in konnectome's whole-word form.
neuromodulator_bus_channel_role(norepinephrine, gain_and_reset_broadcast).
neuromodulator_bus_channel_role(serotonin, patience_and_mood_broadcast).
neuromodulator_bus_channel_role(acetylcholine, attention_and_encoding_broadcast).
neuromodulator_bus_channel_role(histamine, wakefulness_broadcast).
neuromodulator_bus_channel_role(dopamine, reward_teaching_broadcast).
neuromodulator_bus_channel_role(orexin, sleep_wake_stabiliser).

% neuromodulator_bus_channel_source(+Channel, -Nucleus): the source nucleus Chapter 16 names.
% Acetylcholine is the one channel the corpus gives two sources for, and both are named in one term
% rather than as two rows, because a second row would make the roster's arithmetic read as seven.
neuromodulator_bus_channel_source(norepinephrine, locus_coeruleus).
neuromodulator_bus_channel_source(serotonin, raphe).
neuromodulator_bus_channel_source(acetylcholine, brainstem_and_basal_forebrain).
neuromodulator_bus_channel_source(histamine, tuberomammillary_nucleus).
neuromodulator_bus_channel_source(dopamine, ventral_tegmental_area).
neuromodulator_bus_channel_source(orexin, lateral_hypothalamus).

% neuromodulator_bus_channel_cognitive(+Channel, -Tag): the corpus's own COG or NON-COG judgment.
% Carried through unaltered from the Layer 10 chapter headings; konnectome judges no channel itself.
neuromodulator_bus_channel_cognitive(norepinephrine, cognitive).
neuromodulator_bus_channel_cognitive(serotonin, cognitive).
neuromodulator_bus_channel_cognitive(acetylcholine, cognitive).
neuromodulator_bus_channel_cognitive(histamine, non_cognitive).
neuromodulator_bus_channel_cognitive(dopamine, cognitive).
neuromodulator_bus_channel_cognitive(orexin, non_cognitive).

% neuromodulator_bus_check_channel(+Channel): refuse a name the roster does not carry.
% OFFERED AND APPLIED TO NOTHING IN THIS FILE, per the namespace-is-not-a-roster finding above.
neuromodulator_bus_check_channel(Channel) :-
    % Refuse an unbound or compound name exactly as every other name on this bus is refused.
    neuromodulator_bus_check_atom(Channel, neuromodulator_bus_channel),
    % A name the roster carries passes; anything else is refused aloud, by the roster's own name.
    (  neuromodulator_bus_channel(Channel)
    -> true
    ;  throw(error(domain_error(neuromodulator_bus_channel, Channel), _))
    ).

% neuromodulator_bus_channel_named(+Name, -Channel): resolve a corpus name onto the roster's name.
% This is the ONE place the corpus's own spelling is written down, and it is a lookup rather than a
% second bus key, so a caller written from the corpus can never read a silent zero off a channel that
% is carrying a level under konnectome's name for it.
neuromodulator_bus_channel_named(Name, Channel) :-
    % Refuse an unbound or compound name before any lookup could bind it to something plausible.
    neuromodulator_bus_check_atom(Name, neuromodulator_bus_channel),
    % A roster name resolves to itself; the corpus's own word resolves onto the roster's; nothing else resolves.
    (  neuromodulator_bus_channel(Name)
    -> Channel = Name
    ;  neuromodulator_bus_channel_corpus_name(Name, Channel)
    -> true
    ;  throw(error(domain_error(neuromodulator_bus_channel, Name), _))
    ).

% neuromodulator_bus_channel_corpus_name(+CorpusName, -Channel): the corpus's word for one channel.
% One row, and it is the whole of the divergence: the corpus writes noradrenaline where konnectome
% has broadcast norepinephrine since slice 19. A row here is a translation and never an alias.
neuromodulator_bus_channel_corpus_name(noradrenaline, norepinephrine).
