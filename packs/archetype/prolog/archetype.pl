% Declare this file as the 'archetype' module and list the predicates it exports.
:- module(archetype, [
    % archetype_relay/3: the relay rule - pass the weighted input, scaled by gain.
    archetype_relay/3,
    % archetype_integrator/4: the integrator rule - a leaky accumulator.
    archetype_integrator/4,
    % archetype_oscillator/5: the oscillator rule - advance phase and derive receptivity.
    archetype_oscillator/5,
    % archetype_attractor/5: the attractor rule - move toward the nearest stored pattern.
    archetype_attractor/5,
    % archetype_gate/4: the gate rule - flip mode only above threshold, read through the register.
    archetype_gate/4,
    % archetype_gate_register/1: the gate's mode register block, entry by entry.
    archetype_gate_register/1,
    % archetype_gate_modes/1: the formal names of the two modes the gate holds.
    archetype_gate_modes/1,
    % archetype_gate_size/1: how many modes the gate's register holds - itself a statement.
    archetype_gate_size/1,
    % archetype_gate_transitions/1: the gate's explicit transition table.
    archetype_gate_transitions/1,
    % archetype_gate_faults/1: the gate's fault regimes and watchdogs block, no longer empty.
    archetype_gate_faults/1,
    % archetype_gate_automaton/2: this gate instance's hybrid automaton, standing in a given mode.
    archetype_gate_automaton/2,
    % archetype_gate_transfer/2: the rule that holds while a named mode is current.
    archetype_gate_transfer/2,
    % archetype_gate_output/3: apply a mode's own transfer function to an arriving input.
    archetype_gate_output/3,
    % archetype_gate_departure/2: where the transition table sends a gate leaving a mode ITSELF.
    archetype_gate_departure/2,
    % archetype_gate_thrown_departure/2: where the table sends a gate the BROADCAST throws.
    archetype_gate_thrown_departure/2,
    % archetype_gate_throw/3: apply a standing broadcast throw to one gate instance.
    archetype_gate_throw/3,
    % archetype_gate_hysteretic/5: the gate as the corpus's LATCH - two boundaries, not one.
    archetype_gate_hysteretic/5,
    % archetype_gate_effective_threshold/4: the boundary the mode a gate stands in must be pushed past.
    archetype_gate_effective_threshold/4,
    % archetype_comparator/3: the comparator rule - report the prediction error.
    archetype_comparator/3,
    % archetype_step/3: the dispatch - read the archetype and apply the matching rule.
    archetype_step/3
]).

% Import the list and apply utilities used by the attractor's pattern arithmetic.
:- use_module(library(lists), [sum_list/2, memberchk/2]).
% Import the type checker that judges a key or a reading and refuses a hole aloud.
:- use_module(library(error), [must_be/2, domain_error/2, existence_error/2]).
% Import maplist for elementwise pattern operations.
:- use_module(library(apply), [maplist/3, maplist/4]).
% Import the hybrid automaton itself: the gate's two modes are held in the corpus's own term.
:- use_module(library(mode_register), [
    % mode_register_new/6: build and judge one construct's hybrid automaton.
    mode_register_new/6,
    % mode_register_transitions/2: read an automaton's transition table.
    mode_register_transitions/2,
    % mode_register_transfer/3: read the rule filed under one named mode.
    mode_register_transfer/3,
    % mode_register_current/2: read the mode a construct is standing in right now.
    mode_register_current/2,
    % mode_register_departure/3: read a departure out of the table under a NAMED AGENCY.
    mode_register_departure/3
]).

% ---------------------------------------------------------------------------
% THE SIX ARCHETYPE RULES (Appendix 2, Section A2.3)
% ---------------------------------------------------------------------------

% A RELAY is a pipe that passes what it is given, scaled by its gain.
% archetype_relay(+TotalInput, +Gain, -NextActivation): the scaled input.
archetype_relay(TotalInput, Gain, NextActivation) :-
    % Multiply the total weighted input by the current gain.
    NextActivation is TotalInput * Gain.

% An INTEGRATOR is a bucket that fills with input and leaks a little each tick.
% archetype_integrator(+CurrentActivation, +LeakFactor, +TotalInput, -NextActivation): fill and leak.
archetype_integrator(CurrentActivation, LeakFactor, TotalInput, NextActivation) :-
    % Decay the current activation by the leak factor, then add this tick's input.
    NextActivation is CurrentActivation * LeakFactor + TotalInput.

% An OSCILLATOR is a metronome: its phase advances at its natural frequency and wraps.
% archetype_oscillator(+CurrentPhase, +NaturalFrequency, +CycleLength, -NextPhase, -Gain): keep time.
archetype_oscillator(CurrentPhase, NaturalFrequency, CycleLength, NextPhase, Gain) :-
    % Advance the phase by the natural frequency.
    Sum is CurrentPhase + NaturalFrequency,
    % Wrap the advanced phase back into the range of one full cycle.
    NextPhase is Sum - CycleLength * floor(Sum / CycleLength),
    % Derive the receptivity, which rises and falls once per cycle.
    archetype_receptivity(NextPhase, CycleLength, Gain).

% The receptivity is a raised cosine over the cycle, peaking once and troughing once.
% archetype_receptivity(+Phase, +CycleLength, -Gain): a value in the range zero to one.
archetype_receptivity(Phase, CycleLength, Gain) :-
    % Compute the raised cosine of the phase across one cycle.
    Gain is (1 + cos(2 * pi * Phase / CycleLength)) / 2.

% An ATTRACTOR completes a pattern: it moves a step toward the nearest stored memory.
% archetype_attractor(+CurrentPattern, +InputPattern, +StoredPatterns, +StepFraction, -NextPattern): complete.
archetype_attractor(CurrentPattern, InputPattern, StoredPatterns, StepFraction, NextPattern) :-
    % Blend the current pattern with the arriving input pattern.
    archetype_blend(CurrentPattern, InputPattern, Blended),
    % Find the stored pattern most similar to the blended pattern.
    archetype_nearest(Blended, StoredPatterns, Nearest),
    % Move the current pattern a small step toward that nearest stored pattern.
    archetype_move_toward(CurrentPattern, Nearest, StepFraction, NextPattern).

% A GATE is a stiff switch: it flips its mode only when the drive exceeds its threshold.
% archetype_gate(+CurrentMode, +SwitchDrive, +Threshold, -NextMode): flip or hold.
archetype_gate(CurrentMode, SwitchDrive, Threshold, NextMode) :-
    % Build this gate instance's register, standing in the mode it says it is in; a hole or a mode
    % the register does not hold is refused here, at the door, before any threshold is compared.
    archetype_gate_automaton(CurrentMode, Automaton),
    % Fire the one transition whose trigger holds, otherwise the gate stands where it stands.
    ( SwitchDrive > Threshold
      -> archetype_gate_departure_of(Automaton, NextMode)
      ;  NextMode = CurrentMode
    ).

% ---------------------------------------------------------------------------
% THE HYSTERETIC GATE (konnectome build slice 44; the closer of OBSERVATION-8)
% ---------------------------------------------------------------------------
%
% WHAT OBSERVATION-8 RECORDED. Slice 40 validated this gate block by block against the Layer 8 modes
% volume's Entry 36, the mutual-inhibition flip-flop coined the Either-Or Latch, and every block
% matched except one: the corpus's latch is HYSTERETIC - a hysteretic toggle whose modes are simply
% its two self-holding states, turning on at one boundary and off only at a lower one - while
% archetype_gate/4 compares one drive against ONE threshold in both directions, so its two transition
% rows honestly share a single trigger and the same drive that closes an open gate opens a closed one.
%
% WHY IT COULD NOT BE FIXED WHERE IT WAS FOUND. The corpus itself locates the stickiness OUTSIDE the
% switch: "this is a stabiliser, not a switch, so it has no poles of its own". Burying a second
% constant in archetype_gate/4 would have modelled the corpus WRONGLY while appearing to fix it. The
% band therefore arrives from a construct that owns it, and it arrives HERE AS AN ARGUMENT: archetype
% still does not import the bus and still does not import the stabiliser, because a rule library that
% reached for a global channel would stop being one. The join belongs to the caller, as since slice 41.
%
% THE MAPPING KONNECTOME CHOSE, AND IT IS KONNECTOME'S OWN. The corpus states hysteresis for a LEVEL
% comparator - a quantity rising past one boundary and falling past a LOWER one - while this gate
% compares a SWITCHING DRIVE, which is a push rather than a level. The two do not map by themselves,
% so konnectome states the mapping rather than letting one be inferred: LEAVING A MODE COSTS THE
% RAISED BOUNDARY, WHICHEVER MODE IT IS. A drive must exceed Threshold PLUS the bias to move the gate
% at all, so over the whole range between Threshold and Threshold plus the bias BOTH MODES ARE
% STABLE AND WHICH ONE IS REALISED DEPENDS ON HISTORY - which is the corpus's definition of the
% property, quoted almost word for word, and the thing OBSERVATION-8 recorded as missing. The
% corpus's plainer cell-grain sentence holds too: switching on takes more input than keeping it on,
% because keeping it on costs nothing at all.
%
% AND THE ASYMMETRIC MAPPING WAS CONSIDERED AND REJECTED, recorded because it is the reading a later
% session is most likely to reach for. It would have made turning ON cost Threshold plus the bias and
% turning OFF cost Threshold MINUS it, which reads like the corpus's higher-and-lower boundaries. It
% is wrong here, and wrong in an instructive way: with a push-drive rather than a level, that rule
% makes CLOSED ABSORBING over the whole middle range - every mid-sized push closes the gate and none
% reopens it - and a gate that settles and never leaves is the corpus's own STUCK SWITCH fault
% signature, which this pack has listed in its fault block since slice 42. A hysteresis design that
% manufactures a fault regime is not a hysteresis design. konnectome takes the symmetric-cost reading
% and writes down why.
%
% THE BOUNDARY IS STILL WRITTEN PER MODE, one clause each, even though the two clauses agree today.
% That is deliberate: a watcher holding nothing but a mode name can read that mode's boundary without
% running the construct, which the owner's standing visualization request demands of this family, and
% any future asymmetry has to be written down mode by mode rather than smuggled into one expression.
%
% AND THE DEFAULT IS TODAY. At a bias of zero the two boundaries coincide and this predicate is
% archetype_gate/4 exactly, which is why nothing in the repository moved when it shipped: the bus
% answers zero for a bias nobody has published, so a switch that consults the stabiliser and finds
% silence behaves precisely as it did before the stabiliser existed.

% archetype_gate_effective_threshold(+CurrentMode, +Threshold, +StabilityBias, -Effective): the
% boundary THIS mode must be pushed past, which is the whole of the hysteresis in one predicate.
% Leaving CLOSED costs the raised boundary: the closed mode holds itself.
archetype_gate_effective_threshold(closed, Threshold, StabilityBias, Effective) :-
    % The boundary sits a full bias ABOVE the gate's nominal threshold.
    Effective is Threshold + StabilityBias.
% Leaving OPEN costs the raised boundary too: the open mode holds itself by the same amount.
archetype_gate_effective_threshold(open, Threshold, StabilityBias, Effective) :-
    % The boundary sits a full bias ABOVE the gate's nominal threshold.
    Effective is Threshold + StabilityBias.

% archetype_gate_check_stability_bias(+StabilityBias): refuse a bias no gate could honour.
archetype_gate_check_stability_bias(StabilityBias) :-
    % A hole would be bound by the arithmetic above and would invent a band; refuse it aloud first.
    must_be(number, StabilityBias),
    % A NEGATIVE BIAS INVERTS THE BAND - the turn-on boundary below the turn-off boundary - which is a
    % gate that chatters by construction. The stabiliser refuses the same value under its own name;
    % this refusal exists because archetype does not import the stabiliser and must judge what it is
    % handed, and the two refusals are deliberately named separately so neither can hide the other.
    (   StabilityBias >= 0
    ->  true
    ;   domain_error(archetype_gate_stability_bias, StabilityBias)
    ).

% archetype_gate_hysteretic(+CurrentMode, +SwitchDrive, +Threshold, +StabilityBias, -NextMode):
% the gate as the corpus's latch - two boundaries, and which one applies depends on where it stands.
archetype_gate_hysteretic(CurrentMode, SwitchDrive, Threshold, StabilityBias, NextMode) :-
    % Refuse a bias no gate could honour before any boundary is computed from it.
    archetype_gate_check_stability_bias(StabilityBias),
    % Build this gate instance's register, standing in the mode it says it is in; a hole or a mode the
    % register does not hold is refused here, at the door, exactly as the symmetric gate refuses it.
    archetype_gate_automaton(CurrentMode, Automaton),
    % Read the boundary THIS mode must be pushed past, which is where the history lives.
    archetype_gate_effective_threshold(CurrentMode, Threshold, StabilityBias, Effective),
    % Fire the one transition whose trigger holds, otherwise the gate stands where it stands.
    (   SwitchDrive > Effective
    ->  archetype_gate_departure_of(Automaton, NextMode)
    ;   NextMode = CurrentMode
    ).

% A COMPARATOR is a scale: it reports how far the actual input departs from the expected.
% archetype_comparator(+ExpectedInput, +ActualInput, -PredictionError): the signed difference.
archetype_comparator(ExpectedInput, ActualInput, PredictionError) :-
    % Subtract the expected input from the actual input to get the prediction error.
    PredictionError is ActualInput - ExpectedInput.

% ---------------------------------------------------------------------------
% ATTRACTOR HELPERS (composite pattern operations)
% ---------------------------------------------------------------------------

% archetype_average(+X, +Y, -Mean): the arithmetic mean of two numbers.
archetype_average(X, Y, Mean) :-
    % Average the two values.
    Mean is (X + Y) / 2.

% archetype_blend(+A, +B, -Blended): the elementwise mean of two equal-length patterns.
archetype_blend(A, B, Blended) :-
    % Take the elementwise average across the two patterns.
    maplist(archetype_average, A, B, Blended).

% archetype_squared_difference(+X, +Y, -Square): the squared difference of two numbers.
archetype_squared_difference(X, Y, Square) :-
    % Subtract, then square the difference.
    Difference is X - Y,
    % Square the difference.
    Square is Difference * Difference.

% archetype_distance(+A, +B, -Distance): the squared Euclidean distance between two patterns.
archetype_distance(A, B, Distance) :-
    % Square the elementwise differences.
    maplist(archetype_squared_difference, A, B, Squares),
    % Sum the squared differences.
    sum_list(Squares, Distance).

% archetype_nearest(+Target, +Patterns, -Nearest): the stored pattern closest to the target.
archetype_nearest(Target, [First|Rest], Nearest) :-
    % Measure the distance to the first candidate as the running best.
    archetype_distance(Target, First, FirstDistance),
    % Fold the remaining candidates, keeping the closest.
    archetype_nearest_(Rest, Target, First, FirstDistance, Nearest).

% archetype_nearest_(+Rest, +Target, +BestPattern, +BestDistance, -Nearest): the fold's helper.
% With no candidates left, the running best is the nearest.
archetype_nearest_([], _Target, BestPattern, _BestDistance, BestPattern).
% Otherwise compare the next candidate and keep whichever is closer.
archetype_nearest_([Pattern|More], Target, BestPattern, BestDistance, Nearest) :-
    % Measure the distance to this candidate.
    archetype_distance(Target, Pattern, Distance),
    % Keep the closer of the candidate and the running best.
    ( Distance < BestDistance
      -> archetype_nearest_(More, Target, Pattern, Distance, Nearest)
      ;  archetype_nearest_(More, Target, BestPattern, BestDistance, Nearest)
    ).

% archetype_interpolate(+Step, +Current, +Target, -Next): one number moved toward a target.
archetype_interpolate(Step, Current, Target, Next) :-
    % Move from the current value a fraction Step of the way to the target.
    Next is Current + Step * (Target - Current).

% archetype_move_toward(+Current, +Target, +Step, -Next): move a whole pattern toward a target.
archetype_move_toward(Current, Target, Step, Next) :-
    % Interpolate each element of the pattern toward the target by the step fraction.
    maplist(archetype_interpolate(Step), Current, Target, Next).

% ---------------------------------------------------------------------------
% THE GATE'S GENUINE TWO-MODE REGISTER (konnectome build slice 40)
% ---------------------------------------------------------------------------
%
% Slice 39 gave every construct kind a register of ONE, and a register of one is first-class rather
% than degenerate - but it is also the one register length that can hide a mistake, because with a
% single mode the transfer block, the transition table and the current-mode slot cannot disagree
% with each other. The gate is where the register earns its keep: it is the ONE construct in the
% repository whose behaviour was already mode-like, flipping between two named regimes, and the
% modes deep read names it the natural SEED of the whole design.
%
% VALIDATED AGAINST A CORPUS ENTRY WHOSE REGISTER IS TWO. The Layer 8 modes volume's Entry 36, the
% mutual-inhibition flip-flop (the Either-Or Latch), is a hysteretic toggle "whose modes are simply
% its two self-holding states": a register of two, per-mode transfer functions describing what holds
% while each state is realised, a transition table whose rows carry trigger, direction, timescale
% and agency, and a fault block naming instability and a stuck switch. konnectome's gate is read
% against that entry below, block by block, and the ONE place the two shapes differ is declared
% rather than papered over.
%
% WHERE KONNECTOME'S GATE DIFFERS FROM THE CORPUS'S LATCH, DECLARED SO IT IS A KNOWN GAP AND NOT A
% CLAIM: the corpus's latch is HYSTERETIC - it turns on at one boundary and off only at a lower one,
% and the corpus is explicit that the hysteresis is supplied by a STABILISER, "not part of the
% switch", publishing a stability bias of its own. konnectome's gate compares one drive against ONE
% threshold in both directions, so its two transition rows share a single trigger. That is a
% symmetric toggle, not a sticky latch. This slice does NOT invent the second threshold, because the
% design authority already files the stabiliser as its own later slice and because this slice
% promises to change no number. The transition table records the shared trigger honestly, and the
% gap is written in the ledger rather than smoothed over here.
%
% THE CURRENT MODE BELONGS TO THE INSTANCE, NOT TO THE KIND, and that is the second thing this slice
% settles. Slice 39's registers of one could be looked up by construct kind alone, because a mode
% that never changes is a property of the kind. The moment a mode CAN change, two gates of the same
% kind stand in different modes at the same instant, so the current mode arrives as an argument and
% the register is built around it. Everything else in the register - the entries, the transfer
% block, the table, the fault block - is per KIND and is stated once below.

% archetype_gate_mode_entry(?Formal, ?Coined, ?Gloss): one of the gate's two modes, in the corpus's
% own three-field entry schema - formal name, vivid coined name prefixed "the", one-clause gloss.
% While OPEN, the gate is a pipe: what arrives at it leaves it.
archetype_gate_mode_entry(open, 'the Open Sluice',
    'passes what arrives at it onward, unchanged, for as long as the gate stands open').
% While CLOSED, the gate is a wall: what arrives at it stops there.
archetype_gate_mode_entry(closed, 'the Dropped Shutter',
    'blocks what arrives at it, passing nothing onward, for as long as the gate stands closed').

% archetype_gate_register(-Entries): the gate's mode register block, entry by entry.
archetype_gate_register(Entries) :-
    % Gather the gate's two mode entries in the order they are declared above.
    findall(mode_entry(Formal, Coined, Gloss),
            archetype_gate_mode_entry(Formal, Coined, Gloss),
            Entries).

% archetype_gate_modes(-Names): the formal names of the two modes the gate holds.
archetype_gate_modes(Names) :-
    % Gather the formal name of every declared mode, in declaration order.
    findall(Formal, archetype_gate_mode_entry(Formal, _Coined, _Gloss), Names).

% archetype_gate_size(-Size): how many modes the gate's register holds - itself a statement.
archetype_gate_size(Size) :-
    % Read the register's formal names.
    archetype_gate_modes(Names),
    % A register of two says the system trusts this construct to admit or to block, never to decide.
    length(Names, Size).

% archetype_gate_transfer_row(?Formal, ?Rule): the per-mode transfer function block, keyed by mode.
% The open gate's law is to pass what arrives.
archetype_gate_transfer_row(open, gate_pass).
% The closed gate's law is to pass nothing.
archetype_gate_transfer_row(closed, gate_block).

% archetype_gate_transfers(-Transfers): the transfer block, one row per register entry.
archetype_gate_transfers(Transfers) :-
    % Gather every mode's transfer function, in declaration order.
    findall(transfer(Formal, Rule),
            archetype_gate_transfer_row(Formal, Rule),
            Transfers).

% archetype_gate_transition_row(?Trigger, ?From, ?To, ?Timescale, ?Agency): the transition table,
% carrying all four of the corpus's fields and no guard column, exactly as the template writes it.
% A supra-threshold switching drive closes an open gate.
archetype_gate_transition_row(switch_drive_above_threshold, open, closed, one_tick, self_selected).
% The same supra-threshold switching drive, at the same one threshold, opens a closed gate.
archetype_gate_transition_row(switch_drive_above_threshold, closed, open, one_tick, self_selected).

% A mode thrown from the broadcast bus closes an open gate, wherever that gate stands (slice 41).
archetype_gate_transition_row(broadcast_mode_throw, open, closed, one_tick, broadcast_thrown).
% The same broadcast throw opens a closed gate, by a row the gate's own table declares.
archetype_gate_transition_row(broadcast_mode_throw, closed, open, one_tick, broadcast_thrown).

% archetype_gate_transitions(-Rows): the gate's explicit transition table.
archetype_gate_transitions(Rows) :-
    % Gather every declared row, in declaration order.
    findall(transition(Trigger, From, To, Timescale, Agency),
            archetype_gate_transition_row(Trigger, From, To, Timescale, Agency),
            Rows).

% archetype_gate_fault_row(?BoundarySignature, ?WarningCondition, ?Watchdog): the fault regimes and
% watchdogs block, in the corpus's own three-field entry schema. EMPTY UNTIL SLICE 42, AND FILLED
% HERE, because a fault block could not honestly be filled until something existed to do the
% watching - which is the supervisor pack, and which is why this block waited three slices.
%
% BOTH ENTRIES ARE THE CORPUS'S OWN, taken from the Layer 8 modes volume's Entry 36, the
% mutual-inhibition flip-flop coined the Either-Or Latch, which is the corpus entry slice 40
% validated this gate against block by block. That entry names exactly two fault regimes and a
% watchdog, and konnectome takes both rather than inventing a third it has no warrant for.
%
% NEITHER SIGNATURE IS A MODE NAME, AND THAT IS CHECKED RATHER THAN INTENDED. open and closed are the
% register's modes; oscillation and stuck_switch are boundaries this gate was never designed to
% cross. The supervisor refuses a register in which a fault signature is also a declared mode, so the
% corpus's directive is a refusal that fires rather than a sentence somebody remembers.
%
% AND NO THRESHOLD APPEARS HERE. A fault entry names the boundary, the warning and the watcher; the
% ALLOWANCE belongs to the watchdog's reading and is supplied by the caller, because the corpus gives
% konnectome no number at this grain and this family does not invent numbers.
%
% The corpus's latch flips between two self-holding states and can fail by never settling.
archetype_gate_fault_row(oscillation, gate_flipping_faster_than_its_watchdog_allows, oscillation_watchdog).
% The same latch can fail the opposite way, by settling and then never leaving.
archetype_gate_fault_row(stuck_switch, gate_held_in_one_mode_longer_than_its_watchdog_allows, stuck_switch_watchdog).

% archetype_gate_faults(-Faults): the gate's fault regimes and watchdogs block.
archetype_gate_faults(Faults) :-
    % Gather every declared fault entry, in declaration order.
    findall(fault(Signature, Condition, Watchdog),
            archetype_gate_fault_row(Signature, Condition, Watchdog),
            Faults).

% archetype_gate_automaton(+CurrentMode, -Automaton): this gate instance's hybrid automaton.
archetype_gate_automaton(CurrentMode, Automaton) :-
    % Read the register block that every gate of this kind shares.
    archetype_gate_register(Entries),
    % Read the per-mode transfer block that every gate of this kind shares.
    archetype_gate_transfers(Transfers),
    % Read the transition table that every gate of this kind shares.
    archetype_gate_transitions(Rows),
    % Read the fault block, which slice 42 filled from the corpus's own latch entry now that the
    % supervisor exists to watch it. It is still not a list of modes: nothing here has a transfer
    % function, and nothing here is a regime the gate is designed to operate in.
    archetype_gate_faults(Faults),
    % Build the automaton around the mode THIS instance stands in. The constructor judges every
    % block, so an unbound or foreign current mode is refused aloud here.
    mode_register_new(CurrentMode, Entries, Transfers, Rows, Faults, Automaton).

% archetype_gate_transfer(+Mode, -Rule): the rule that holds while the named mode is current.
archetype_gate_transfer(Mode, Rule) :-
    % Build a register standing in the mode being asked about, which judges the key on the way in.
    archetype_gate_automaton(Mode, Automaton),
    % Read the rule filed under that mode, through the register rather than beside it.
    mode_register_transfer(Automaton, Mode, Rule).

% archetype_gate_output(+Mode, +ArrivingInput, -PassedOn): apply the mode's own transfer function.
archetype_gate_output(Mode, ArrivingInput, PassedOn) :-
    % Judge the arriving reading HERE, in the one place both transfer functions come through. The
    % closed gate never reads its input, so guarding inside each law would let a hole reach the
    % blocking law and be answered with a confident zero.
    must_be(number, ArrivingInput),
    % Read the rule that holds in this mode, refusing a mode the register does not hold.
    archetype_gate_transfer(Mode, Rule),
    % Apply that rule, so the gate really is a different machine in each of its two modes.
    archetype_gate_apply(Rule, ArrivingInput, PassedOn).

% archetype_gate_apply(+Rule, +ArrivingInput, -PassedOn): apply one transfer function by name.
archetype_gate_apply(Rule, ArrivingInput, PassedOn) :-
    % A rule the register files but this module cannot run is refused aloud, so the transfer block
    % and the laws below cannot drift apart in silence.
    (   archetype_gate_law(Rule, ArrivingInput, PassedOn)
    ->  true
    ;   domain_error(archetype_gate_transfer_function, Rule)
    ).

% archetype_gate_law(?Rule, +ArrivingInput, -PassedOn): the two transfer functions themselves.
% The open gate's law: what arrives leaves, unchanged.
archetype_gate_law(gate_pass, ArrivingInput, PassedOn) :-
    % Pass the arriving input onward untouched.
    PassedOn is ArrivingInput.
% The closed gate's law: nothing leaves.
archetype_gate_law(gate_block, _ArrivingInput, PassedOn) :-
    % Pass nothing onward.
    PassedOn is 0.

% archetype_gate_departure(+FromMode, -ToMode): where the table sends a gate leaving a mode.
archetype_gate_departure(FromMode, ToMode) :-
    % Build the register standing in the departing mode, refusing a hole or a foreign mode.
    archetype_gate_automaton(FromMode, Automaton),
    % Look the departure up through the one lookup both routes come through.
    archetype_gate_departure_of(Automaton, ToMode).

% archetype_gate_departure_of(+Automaton, -ToMode): the ONE table lookup, keyed on a judged mode.
% Both routes into this lookup - the gate rule itself and the departure reader above - arrive
% carrying a whole automaton rather than a bare mode name, because the constructor has already
% judged the current-mode slot. That is the slice-39 review's rule applied to new code: when a value
% can reach a lookup by more than one route, guard it where the routes MEET, not where each begins.
%
% SLICE 41 NAMES THE AGENCY THIS LOOKUP WANTS, AND THE BEHAVIOUR IS PINNED IDENTICAL BY DOING SO.
% Until this slice every row in the table was self_selected, so "the first row leaving this mode" had
% exactly one answer and an unkeyed memberchk could not be wrong. Slice 41 writes a SECOND agency's
% rows into the same table, and from that moment an unkeyed lookup would answer with whichever row
% was declared first - correct today by accident of declaration order, and silently wrong the day
% anyone reorders the rows. The agency is therefore named here. This is the default-drift lens paid
% out before it cost anything: the gate's SELF-SELECTED flip is the flip this predicate has always
% described, and it is now the flip this predicate asks for.
archetype_gate_departure_of(Automaton, ToMode) :-
    % Read the self-selected departure out of the register, which is the one authority on direction.
    mode_register_departure(Automaton, self_selected, ToMode).

% archetype_gate_thrown_departure(+FromMode, -ToMode): where the table sends a gate the BUS throws.
% The throw's departure is read out of the SAME table by the SAME lookup, differing only in the
% agency it names - which is what makes a thrown transition a row of the gate's own register rather
% than a second path into the gate.
archetype_gate_thrown_departure(FromMode, ToMode) :-
    % Build the register standing in the mode being left, refusing a hole or a foreign mode.
    archetype_gate_automaton(FromMode, Automaton),
    % Read the departure this table declares under the broadcast's agency.
    mode_register_departure(Automaton, broadcast_thrown, ToMode).

% archetype_gate_throw(+ThrownMode, +CurrentMode, -NextMode): apply a standing throw to one gate.
%
% THE COMMAND DECISION IS ENACTED HERE AND IS DOCUMENTED IN FULL AT THE FOOT OF neuromodulator_bus.
% A standing throw SETS the gate's mode; it does not nudge a threshold. It preempts self-selection
% while it stands. It is applied per instance, so ONE bus write moves every gate that reads it, and
% each gate arrives at its answer through its own register rather than through a controller.
%
% THREE CASES ARE STANDING STILL, NOT MOVING, AND EACH IS A DIFFERENT SILENCE. A channel nobody has
% written reads as the reserved silence name and leaves the gate exactly where it stood. A throw that
% names the mode the gate is ALREADY in leaves it there too, because a command to be what you are is
% satisfied without a transition - and this is what makes one broadcast safe to read every tick. A
% throw naming a mode this register does not hold is neither of those: it is refused aloud.
archetype_gate_throw(ThrownMode, CurrentMode, NextMode) :-
    % Refuse an unbound thrown mode before anything is looked up with it as a key.
    must_be(atom, ThrownMode),
    % Build the register standing in this gate's current mode, which judges that mode on the way in.
    archetype_gate_automaton(CurrentMode, _Automaton),
    % Read the gate's own mode vocabulary, so a foreign mode is caught by the register, not by a list
    % of names written a second time somewhere else.
    archetype_gate_modes(Names),
    % Work out where this gate stands after the throw.
    (   % A silent channel is not an instruction: the gate keeps its own mode and its own agency.
        ThrownMode == no_mode_thrown
    ->  NextMode = CurrentMode
    ;   % A mode this gate does not have is refused aloud, naming the mode that was thrown at it.
        \+ memberchk(ThrownMode, Names)
    ->  existence_error(mode_entry, ThrownMode)
    ;   % A throw naming the mode already held is satisfied where the gate stands, with no transition.
        ThrownMode == CurrentMode
    ->  NextMode = CurrentMode
    ;   % Otherwise the table must declare this departure under the broadcast's agency, or the throw
        % is one this construct's register gives it no way to obey, and that is refused aloud too.
        archetype_gate_thrown_departure(CurrentMode, Declared),
        (   Declared == ThrownMode
        ->  NextMode = ThrownMode
        ;   existence_error(mode_transition, ThrownMode)
        )
    ).

% ---------------------------------------------------------------------------
% THE DISPATCH (Appendix 2, Section A2.2): one canonical computation, rewired.
% ---------------------------------------------------------------------------

% archetype_step(+Archetype, +Inputs, -Outputs): read the archetype and apply the matching rule.
% A relay construct: read its total input and gain, produce its next activation.
archetype_step(relay, Inputs, Outputs) :-
    % Read the total weighted input arriving at the construct.
    get_dict(total_input, Inputs, TotalInput),
    % Read the current gain the neuromodulators have set.
    get_dict(gain, Inputs, Gain),
    % Apply the relay rule.
    archetype_relay(TotalInput, Gain, Activation),
    % Return the next activation.
    Outputs = _{activation: Activation}.
% An integrator construct: read its activation, leak, and input, produce its next activation.
archetype_step(integrator, Inputs, Outputs) :-
    % Read the current activation.
    get_dict(activation, Inputs, CurrentActivation),
    % Read the leak factor slightly less than one.
    get_dict(leak_factor, Inputs, LeakFactor),
    % Read the total input for this tick.
    get_dict(total_input, Inputs, TotalInput),
    % Apply the integrator rule.
    archetype_integrator(CurrentActivation, LeakFactor, TotalInput, Activation),
    % Return the next activation.
    Outputs = _{activation: Activation}.
% An oscillator construct: read its phase, frequency, and cycle, produce phase and gain.
archetype_step(oscillator, Inputs, Outputs) :-
    % Read the current phase.
    get_dict(phase, Inputs, Phase),
    % Read the natural frequency.
    get_dict(natural_frequency, Inputs, NaturalFrequency),
    % Read the cycle length.
    get_dict(cycle_length, Inputs, CycleLength),
    % Apply the oscillator rule.
    archetype_oscillator(Phase, NaturalFrequency, CycleLength, NextPhase, Gain),
    % Return the next phase and the derived gain.
    Outputs = _{phase: NextPhase, gain: Gain}.
% An attractor construct: read its pattern, input, memories, and step, produce its next pattern.
archetype_step(attractor, Inputs, Outputs) :-
    % Read the current activation pattern.
    get_dict(pattern, Inputs, Pattern),
    % Read the arriving input pattern.
    get_dict(input_pattern, Inputs, InputPattern),
    % Read the stored patterns.
    get_dict(stored_patterns, Inputs, StoredPatterns),
    % Read the step fraction.
    get_dict(step_fraction, Inputs, StepFraction),
    % Apply the attractor rule.
    archetype_attractor(Pattern, InputPattern, StoredPatterns, StepFraction, NextPattern),
    % Return the next pattern.
    Outputs = _{pattern: NextPattern}.
% A gate construct: read its mode, switch drive, and threshold, produce its next mode.
archetype_step(gate, Inputs, Outputs) :-
    % Read the current mode.
    get_dict(mode, Inputs, Mode),
    % Read the drive to switch the gate.
    get_dict(switch_drive, Inputs, SwitchDrive),
    % Read the switching threshold.
    get_dict(threshold, Inputs, Threshold),
    % Apply the gate rule.
    archetype_gate(Mode, SwitchDrive, Threshold, NextMode),
    % Return the next mode.
    Outputs = _{mode: NextMode}.
% A comparator construct: read its expected and actual inputs, produce the prediction error.
archetype_step(comparator, Inputs, Outputs) :-
    % Read the expected input.
    get_dict(expected_input, Inputs, ExpectedInput),
    % Read the actual input.
    get_dict(actual_input, Inputs, ActualInput),
    % Apply the comparator rule.
    archetype_comparator(ExpectedInput, ActualInput, PredictionError),
    % Return the prediction error as the next activation.
    Outputs = _{activation: PredictionError}.
