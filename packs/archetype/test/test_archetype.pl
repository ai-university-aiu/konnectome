% Load the archetype module under test from the library path.
:- use_module(library(archetype)).
% Load the mode register, so the gate's automaton is read with the corpus's own accessors.
:- use_module(library(mode_register)).
% Load the broadcast bus, so slice 41's throw can be tested END TO END - one write on the bus, many
% gates moved - rather than only at the archetype's own door. The archetype MODULE deliberately does
% not import the bus: a rule library that reached for a global channel would stop being a rule
% library. The join belongs to the caller, and this suite stands in for one.
:- use_module(library(neuromodulator_bus)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Iterate the integrator N times with a fixed leak factor and a fixed input.
iterate_integrator(0, Activation, _Leak, _Input, Activation) :- !.
% Each step applies the integrator rule and counts down.
iterate_integrator(N, Activation0, Leak, Input, Activation) :-
    % Continue only while ticks remain.
    N > 0,
    % Apply one integrator step.
    archetype_integrator(Activation0, Leak, Input, Activation1),
    % Count this tick down.
    N1 is N - 1,
    % Continue from the new activation.
    iterate_integrator(N1, Activation1, Leak, Input, Activation).

% Iterate the oscillator N times with a fixed frequency and cycle, returning the final phase.
iterate_oscillator(0, Phase, _Freq, _Cycle, Phase) :- !.
% Each step advances the phase and counts down.
iterate_oscillator(N, Phase0, Freq, Cycle, Phase) :-
    % Continue only while ticks remain.
    N > 0,
    % Apply one oscillator step, ignoring the gain here.
    archetype_oscillator(Phase0, Freq, Cycle, Phase1, _Gain),
    % Count this tick down.
    N1 is N - 1,
    % Continue from the new phase.
    iterate_oscillator(N1, Phase1, Freq, Cycle, Phase).

% Iterate the attractor N times with fixed input, memories, and step, returning the final pattern.
iterate_attractor(0, Pattern, _Input, _Stored, _Step, Pattern) :- !.
% Each step moves the pattern toward the nearest memory and counts down.
iterate_attractor(N, Pattern0, Input, Stored, Step, Pattern) :-
    % Continue only while ticks remain.
    N > 0,
    % Apply one attractor step.
    archetype_attractor(Pattern0, Input, Stored, Step, Pattern1),
    % Count this tick down.
    N1 is N - 1,
    % Continue from the new pattern.
    iterate_attractor(N1, Pattern1, Input, Stored, Step, Pattern).

% Two patterns are close enough when every pair of elements is within the tolerance.
patterns_close([], [], _Eps).
% Compare the heads, then recurse on the tails.
patterns_close([X|Xs], [Y|Ys], Eps) :-
    % The elementwise absolute difference is within tolerance.
    abs(X - Y) =< Eps,
    % Recurse on the rest of the patterns.
    patterns_close(Xs, Ys, Eps).

% Open the test block for the archetype pack.
:- begin_tests(archetype).

% TEST OF THE RELAY: a pipe passes what it is given, scaled by gain.
test(relay_scales) :-
    % Four units of input at gain one and a half.
    archetype_relay(4, 1.5, Activation),
    % The output is the input times the gain.
    assertion(Activation =:= 6.0).

% TEST OF THE INTEGRATOR: a bucket fills toward a bound and, with no input, leaks toward zero.
test(integrator_fills_and_leaks) :-
    % Fifty ticks of constant input one at leak nine tenths rise toward the bound of ten.
    iterate_integrator(50, 0, 0.9, 1, Filled),
    % The filled activation is close to but below the bound of ten.
    assertion(Filled > 9.0),
    % And it never exceeds the bound.
    assertion(Filled < 10.0),
    % Fifty ticks of no input from ten decay toward zero.
    iterate_integrator(50, 10, 0.9, 0, Leaked),
    % The leaked activation is near zero.
    assertion(Leaked < 0.1).

% TEST OF THE OSCILLATOR: a metronome keeps time; phase wraps and gain rises and falls once per cycle.
test(oscillator_keeps_time) :-
    % Twelve ticks at frequency one over a cycle of twelve return the phase to its start.
    iterate_oscillator(12, 0, 1, 12, Phase),
    % The phase has wrapped back to zero.
    assertion(abs(Phase - 0) =< 1.0e-9),
    % At phase zero the receptivity peaks at one.
    archetype_oscillator(11, 1, 12, _P0, GainPeak),
    % The peak gain is one.
    assertion(abs(GainPeak - 1.0) =< 1.0e-9),
    % Half a cycle later the receptivity troughs at zero.
    archetype_oscillator(5, 1, 12, _P1, GainTrough),
    % The trough gain is zero.
    assertion(abs(GainTrough - 0.0) =< 1.0e-9).

% TEST OF THE ATTRACTOR: a memory completes from a fragment, converging to the nearer stored pattern.
test(attractor_completes_from_fragment) :-
    % One stored pattern and a competing one.
    Stored = [[1.0, 0.0, 1.0, 0.0], [0.0, 1.0, 0.0, 1.0]],
    % A fragment close to the first stored pattern but corrupted in its last element.
    Fragment = [1.0, 0.0, 1.0, 0.8],
    % Forty steps toward the nearest memory, feeding the fragment as the standing input.
    iterate_attractor(40, Fragment, Fragment, Stored, 0.3, Completed),
    % The pattern has converged to the whole first stored pattern.
    assertion(patterns_close(Completed, [1.0, 0.0, 1.0, 0.0], 0.05)).

% TEST OF THE GATE: a stiff switch holds below threshold, flips above, and then resists flipping back.
test(gate_resists_flipping) :-
    % A sub-threshold drive leaves the mode unchanged.
    archetype_gate(open, 0.3, 0.5, HeldMode),
    % The gate stays open.
    assertion(HeldMode == open),
    % A supra-threshold drive flips the mode.
    archetype_gate(open, 0.7, 0.5, FlippedMode),
    % The gate is now closed.
    assertion(FlippedMode == closed),
    % A later sub-threshold drive does not flip it back.
    archetype_gate(closed, 0.3, 0.5, ResistedMode),
    % The gate resists and stays closed.
    assertion(ResistedMode == closed).

% TEST OF THE COMPARATOR: a scale reports zero when balanced, positive above, negative below.
test(comparator_reports_difference) :-
    % Equal expectation and actual gives zero.
    archetype_comparator(5, 5, Balanced),
    % The balanced error is zero.
    assertion(Balanced =:= 0),
    % An actual above expectation gives a positive error.
    archetype_comparator(5, 8, Above),
    % The error is positive.
    assertion(Above =:= 3),
    % An actual below expectation gives a negative error.
    archetype_comparator(5, 2, Below),
    % The error is negative.
    assertion(Below =:= -3).

% TEST OF THE DISPATCH: each archetype routes to its matching rule and no other (A2.9).
test(dispatch_routes_each_archetype) :-
    % The relay dispatch scales its input by gain.
    archetype_step(relay, _{total_input: 4, gain: 1.5}, RelayOut),
    % Its output activation is six.
    assertion(get_dict(activation, RelayOut, 6.0)),
    % The comparator dispatch reports the difference.
    archetype_step(comparator, _{expected_input: 5, actual_input: 8}, ComparatorOut),
    % Its output activation is the prediction error three.
    assertion(get_dict(activation, ComparatorOut, 3)),
    % The gate dispatch flips above threshold.
    archetype_step(gate, _{mode: open, switch_drive: 0.7, threshold: 0.5}, GateOut),
    % Its output mode is closed.
    assertion(get_dict(mode, GateOut, closed)).

% ---------------------------------------------------------------------------
% THE GATE'S GENUINE TWO-MODE REGISTER (konnectome build slice 40)
% ---------------------------------------------------------------------------

% TEST OF THE REGISTER'S SIZE: the gate holds two modes, and two is a statement, not a placeholder.
test(gate_register_holds_exactly_two_modes) :-
    % Read the formal names the gate's register declares.
    archetype_gate_modes(Modes),
    % They are the gate's own vocabulary, in the order the register declares them.
    assertion(Modes == [open, closed]),
    % And the register's size is two - the corpus's commonest register length.
    archetype_gate_size(Size),
    % A register of two says the system trusts this construct to admit or to block, not to decide.
    assertion(Size == 2).

% TEST OF THE ENTRY SCHEMA: every entry carries the corpus's three fields and no more.
test(gate_register_entries_carry_three_fields) :-
    % Read the register block itself, entry by entry.
    archetype_gate_register(Entries),
    % There are exactly two entries.
    assertion(length(Entries, 2)),
    % The open entry names itself formally and coins a vivid name prefixed "the".
    memberchk(mode_entry(open, OpenCoined, OpenGloss), Entries),
    % Its coined name is the gate's own.
    assertion(OpenCoined == 'the Open Sluice'),
    % The gloss says what the gate does while open.
    assertion(atom(OpenGloss)),
    % The closed entry does the same.
    memberchk(mode_entry(closed, ClosedCoined, ClosedGloss), Entries),
    % Its coined name is the gate's own.
    assertion(ClosedCoined == 'the Dropped Shutter'),
    % And its gloss likewise.
    assertion(atom(ClosedGloss)).

% TEST THAT THE AUTOMATON IS THE CORPUS'S OWN TERM: four blocks and a current-mode slot.
test(gate_automaton_is_a_hybrid_automaton) :-
    % Build the automaton for a gate standing open.
    archetype_gate_automaton(open, Automaton),
    % It is the hybrid automaton of five slots, judged by the mode register's own constructor.
    assertion(Automaton = hybrid_automaton(_, _, _, _, _)),
    % Read its current mode back out.
    mode_register_current(Automaton, Current),
    % The gate is open.
    assertion(Current == open).

% TEST OF THE PER-INSTANCE CURRENT MODE: the mode belongs to the instance, not to the construct kind.
test(gate_automaton_stands_in_the_mode_it_is_given) :-
    % The same construct kind, standing somewhere else.
    archetype_gate_automaton(closed, Automaton),
    % Read the current mode back out.
    mode_register_current(Automaton, Current),
    % A second gate of the same kind is closed while the first is open.
    assertion(Current == closed).

% TEST THAT THE TWO MODES ARE TWO DIFFERENT MACHINES, which is the corpus's central claim.
test(gate_modes_carry_different_transfer_functions) :-
    % Read the rule that holds while the gate is open.
    archetype_gate_transfer(open, OpenRule),
    % Read the rule that holds while the gate is closed.
    archetype_gate_transfer(closed, ClosedRule),
    % The two rules are not the same rule; while a mode holds, the gate is a different machine.
    assertion(OpenRule \== ClosedRule).

% TEST OF THE OPEN TRANSFER FUNCTION: the open gate passes what arrives, unchanged.
test(open_gate_passes_what_arrives) :-
    % Four units arriving at an open gate.
    archetype_gate_output(open, 4, Passed),
    % All four pass.
    assertion(Passed =:= 4).

% TEST OF THE CLOSED TRANSFER FUNCTION: the closed gate passes nothing.
test(closed_gate_passes_nothing) :-
    % Four units arriving at a closed gate.
    archetype_gate_output(closed, 4, Passed),
    % Nothing passes.
    assertion(Passed =:= 0).

% TEST THAT THE TRANSFER FUNCTION IS READ THROUGH THE REGISTER, not chosen beside it.
test(gate_output_refuses_a_mode_the_register_does_not_hold) :-
    % A mode the register never declared is refused aloud, naming what arrived.
    catch(( archetype_gate_output(ajar, 4, _Passed), Outcome = answered ),
          error(Error, _), Outcome = refused(Error)),
    % The transfer lookup refused rather than answering, and named the missing register entry.
    assertion(Outcome == refused(existence_error(mode_entry, ajar))).

% TEST OF THE TRANSITION TABLE: it is explicit, and every row carries all four corpus fields.
test(gate_transition_table_carries_four_fields_per_row) :-
    % Read the transition table.
    archetype_gate_transitions(Rows),
    % Slice 41 doubled the table: each of the two modes now carries a self-selected departure AND a
    % broadcast-thrown one, so the gate has four rows where it had two.
    assertion(length(Rows, 4)),
    % Every row is the corpus's four-field row: trigger, direction, timescale and agency.
    forall(member(Row, Rows),
           assertion(Row = transition(_Trigger, _From, _To, _Timescale, _Agency))).

% TEST OF THE DIRECTIONS: the table names both departures explicitly.
test(gate_transition_table_names_both_directions) :-
    % Read the transition table.
    archetype_gate_transitions(Rows),
    % Opening to closed is an explicit row.
    assertion(memberchk(transition(switch_drive_above_threshold, open, closed, _, _), Rows)),
    % Closing to open is an explicit row.
    assertion(memberchk(transition(switch_drive_above_threshold, closed, open, _, _), Rows)).

% TEST OF THE MANDATORY TIMESCALE: the corpus forbids a table that models transitions as timeless.
test(gate_transitions_carry_a_timescale) :-
    % Read the transition table.
    archetype_gate_transitions(Rows),
    % Every row names a timescale, and konnectome's gate flips within the tick it is asked in.
    forall(member(transition(_T, _F, _To, Timescale, _A), Rows),
           assertion(Timescale == one_tick)).

% TEST OF AGENCY, the field the corpus says must never be omitted - and the field slice 41 gave a
% second value. Until slice 41 nothing above this gate could throw it and every row was honestly
% self-selected; the whole point of slice 41 is that this is no longer true.
test(gate_transitions_carry_two_agencies) :-
    % Read the transition table.
    archetype_gate_transitions(Rows),
    % Collect the agency of every row.
    findall(Agency, member(transition(_T, _F, _To, _Ts, Agency), Rows), Agencies),
    % Sort them, dropping duplicates.
    sort(Agencies, Distinct),
    % Exactly two agencies govern this machine: the gate itself, and the broadcast above it.
    assertion(Distinct == [broadcast_thrown, self_selected]),
    % Every row still names one of them; the field is never omitted, which is the corpus's rule.
    forall(member(transition(_T2, _F2, _To2, _Ts2, One), Rows),
           assertion(memberchk(One, [self_selected, broadcast_thrown]))).

% TEST OF THE TRIGGERS: one trigger per agency, and konnectome's SELF-SELECTED flip is still a
% symmetric toggle rather than a hysteretic latch - the gap slice 40 declared has not been closed here.
test(gate_transitions_carry_one_trigger_per_agency) :-
    % Read the transition table.
    archetype_gate_transitions(Rows),
    % Collect the trigger of every self-selected row.
    findall(Trigger, member(transition(Trigger, _F, _To, _Ts, self_selected), Rows), SelfTriggers),
    % Sort them, dropping duplicates.
    sort(SelfTriggers, SelfDistinct),
    % Both self-selected directions still fire on the one condition, at the one threshold.
    assertion(SelfDistinct == [switch_drive_above_threshold]),
    % Collect the trigger of every broadcast-thrown row.
    findall(Thrown, member(transition(Thrown, _F2, _To2, _Ts2, broadcast_thrown), Rows), ThrownTriggers),
    % Sort them, dropping duplicates.
    sort(ThrownTriggers, ThrownDistinct),
    % Both thrown directions fire on the one broadcast, which is what makes it ONE write read many times.
    assertion(ThrownDistinct == [broadcast_mode_throw]).

% TEST OF THE FAULT BLOCK: faults are watched, never admitted, and konnectome has no watcher yet.
test(gate_fault_block_is_present_and_empty) :-
    % Build the automaton.
    archetype_gate_automaton(open, Automaton),
    % Read the fault regimes and watchdogs block.
    mode_register_faults(Automaton, Faults),
    % The block exists and is empty, because the supervisor channel does not exist yet.
    assertion(Faults == []).

% TEST THAT THE FLIP IS READ OUT OF THE TABLE, so the table is the one authority on direction.
test(gate_departure_is_read_from_the_transition_table) :-
    % The departure from open lands on closed.
    archetype_gate_departure(open, FromOpen),
    % The gate closes.
    assertion(FromOpen == closed),
    % The departure from closed lands on open.
    archetype_gate_departure(closed, FromClosed),
    % The gate opens.
    assertion(FromClosed == open).

% TEST OF THE UNBOUND CURRENT MODE, the defect the register closes at the door.
test(gate_refuses_an_unbound_current_mode) :-
    % A hole where the gate's current mode belongs is refused, not filled in from the register.
    catch(( archetype_gate(_Hole, 0.7, 0.5, _Next), Outcome = answered ),
          error(Error, _), Outcome = refused(Error)),
    % The gate refused rather than answering, and named the instantiation fault.
    assertion(Outcome == refused(instantiation_error)).

% TEST OF A FOREIGN CURRENT MODE: a gate cannot stand in a mode its register does not hold.
test(gate_refuses_a_mode_outside_its_register) :-
    % A mode the register never declared is refused aloud, even below threshold.
    catch(( archetype_gate(ajar, 0.3, 0.5, _Next), Outcome = answered ),
          error(Error, _), Outcome = refused(Error)),
    % The gate refused rather than answering, and named the missing register entry.
    assertion(Outcome == refused(existence_error(mode_entry, ajar))).

% TEST THAT THE REGISTER CHANGES NO NUMBER: the gate's whole behaviour is pinned across both modes.
test(gate_behaviour_is_pinned_identical) :-
    % Below threshold from open, the gate holds open.
    archetype_gate(open, 0.3, 0.5, A),
    % It holds.
    assertion(A == open),
    % Above threshold from open, the gate closes.
    archetype_gate(open, 0.7, 0.5, B),
    % It flips.
    assertion(B == closed),
    % Below threshold from closed, the gate holds closed.
    archetype_gate(closed, 0.3, 0.5, C),
    % It holds.
    assertion(C == closed),
    % Above threshold from closed, the gate opens again - one threshold, both ways.
    archetype_gate(closed, 0.7, 0.5, D),
    % It flips back.
    assertion(D == open),
    % Exactly at the threshold the drive is not ABOVE it, so the gate holds.
    archetype_gate(open, 0.5, 0.5, E),
    % It holds.
    assertion(E == open).

% TEST OF THE DISPATCH, unchanged in shape: the gate's dict output still carries the mode alone.
test(gate_dispatch_output_shape_is_unchanged) :-
    % Step a gate through the archetype dispatch.
    archetype_step(gate, _{mode: closed, switch_drive: 0.7, threshold: 0.5}, Outputs),
    % Read the output dict's pairs.
    dict_pairs(Outputs, _Tag, Pairs),
    % The output dict carries the next mode and nothing else.
    assertion(Pairs == [mode-open]).

% TEST OF EXTERNAL OBSERVABILITY, which the standing owner request's visualization panel needs.
test(gate_current_mode_is_readable_without_running_the_gate) :-
    % A watcher holding only the gate's mode can build its register and read the mode back.
    archetype_gate_automaton(closed, Automaton),
    % Read the current mode as an ordinary value the world carries.
    mode_register_current(Automaton, Current),
    % No rule was run to learn it.
    assertion(Current == closed),
    % And the same watcher can read the rule that holds right now.
    mode_register_current_rule(Automaton, Rule),
    % Which is the closed gate's own transfer function.
    assertion(Rule == gate_block).

% TEST THAT EVERY DECLARED MODE CAN ACTUALLY RUN: the register, the transfer block and the laws
% below them are three lists that must agree, and this walks all three rather than trusting the eye.
test(every_declared_gate_mode_has_a_runnable_law) :-
    % Read the formal names the register declares.
    archetype_gate_modes(Modes),
    % Every one of them resolves to a rule the module can actually apply to an arriving reading.
    forall(member(Mode, Modes),
           ( archetype_gate_output(Mode, 3, Passed), assertion(number(Passed)) )).

% TEST OF THE ARRIVING READING: a hole is refused in the one place both transfer functions meet.
test(gate_output_refuses_an_unbound_input) :-
    % A closed gate never reads its input, so an unguarded blocking law would answer a hole with zero.
    catch(( archetype_gate_output(closed, _Hole, _Passed), Outcome = answered ),
          error(Error, _), Outcome = refused(Error)),
    % The gate refuses instead, at the door both modes come through.
    assertion(Outcome == refused(instantiation_error)).

% ---------------------------------------------------------------------------
% THE BUS THROWS A TRANSITION (konnectome build slice 41)
% ---------------------------------------------------------------------------

% BEHAVIOUR PINNED IDENTICAL: the gate's own flip is untouched by the arrival of a second agency.
% This is the test that would have failed had the departure lookup stayed unkeyed and the new rows
% been declared first, so it is the pin that makes the reordering hazard checkable rather than
% remembered.
test(self_selected_departure_is_unchanged_by_the_new_rows) :-
    % The gate's own departure from open still lands on closed.
    archetype_gate_departure(open, FromOpen),
    % The gate closes, exactly as it did before slice 41.
    assertion(FromOpen == closed),
    % The gate's own departure from closed still lands on open.
    archetype_gate_departure(closed, FromClosed),
    % The gate opens, exactly as it did before slice 41.
    assertion(FromClosed == open).

% TEST THAT THE THROWN DEPARTURE IS A ROW OF THE GATE'S OWN TABLE, not a second path into the gate.
test(thrown_departure_is_read_from_the_same_table) :-
    % The broadcast's departure from open lands on closed.
    archetype_gate_thrown_departure(open, FromOpen),
    % Which is the row the table declares under the broadcast's agency.
    assertion(FromOpen == closed),
    % The broadcast's departure from closed lands on open.
    archetype_gate_thrown_departure(closed, FromClosed),
    % Which is the other row it declares.
    assertion(FromClosed == open).

% TEST OF THE COMMAND DECISION: a throw SETS the mode, and it sets it the same way from either side.
test(a_throw_sets_the_mode) :-
    % Throw closed at a gate standing open.
    archetype_gate_throw(closed, open, Closed),
    % The gate is now closed, because the throw is a command and not a nudge.
    assertion(Closed == closed),
    % Throw open at a gate standing closed.
    archetype_gate_throw(open, closed, Open),
    % The gate is now open.
    assertion(Open == open).

% TEST OF THE FIRST SILENCE: a channel nobody has written is not an instruction.
test(silence_leaves_the_gate_where_it_stands) :-
    % Apply the reserved silence name to an open gate.
    archetype_gate_throw(no_mode_thrown, open, StillOpen),
    % The gate keeps its own mode and its own agency.
    assertion(StillOpen == open),
    % Apply it to a closed gate.
    archetype_gate_throw(no_mode_thrown, closed, StillClosed),
    % The gate keeps that mode too.
    assertion(StillClosed == closed).

% TEST OF THE SECOND SILENCE: a command to be what you already are is satisfied without a transition.
% This is what makes one standing broadcast safe to read on every tick rather than only on the tick
% it was written - the property a bus with no clock of its own must have.
test(a_throw_of_the_held_mode_is_idempotent) :-
    % Throw open at a gate that is already open.
    archetype_gate_throw(open, open, First),
    % It stands where it is.
    assertion(First == open),
    % Read the same standing throw again on a later tick.
    archetype_gate_throw(open, First, Second),
    % And again nothing moves, so the throw does not oscillate the gate it commands.
    assertion(Second == open).

% TEST OF PREEMPTION, the conflict rule this slice decided as konnectome's own: where the gate's own
% transition and a standing throw disagree, the THROW wins. A gate standing open would self-select
% closed on a supra-threshold drive; the throw of open holds it open instead.
test(a_standing_throw_preempts_self_selection) :-
    % What the gate would do by itself, from open.
    archetype_gate_departure(open, SelfSelected),
    % Which is to close.
    assertion(SelfSelected == closed),
    % What it does under a standing throw of its held mode, on the same tick.
    archetype_gate_throw(open, open, Thrown),
    % The throw preempts: the gate stays open, and the two answers genuinely differ.
    assertion(Thrown == open),
    % Stated as the comparison it is, so the test fails if the two ever stop disagreeing.
    assertion(Thrown \== SelfSelected).

% TEST OF THE REFUSAL: a mode this register does not hold is refused aloud, never silently ignored.
test(a_throw_of_a_foreign_mode_is_refused) :-
    % Throw a mode the gate's register has never declared.
    catch(( archetype_gate_throw(ajar, open, _Next), Outcome = answered ),
          error(Error, _), Outcome = refused(Error)),
    % The gate refuses by name, naming the register entry that does not exist.
    assertion(Outcome == refused(existence_error(mode_entry, ajar))).

% TEST OF THE HOLE: an unbound thrown mode is refused before it is used as a key.
test(an_unbound_throw_is_refused) :-
    % Throw a hole at an open gate.
    catch(( archetype_gate_throw(_Hole, open, _Next), Outcome = answered ),
          error(Error, _), Outcome = refused(Error)),
    % The unbound-wrong-judgement lens: a hole would otherwise be bound to the first mode it met.
    assertion(Outcome == refused(instantiation_error)).

% TEST OF THE OTHER HOLE: an unbound CURRENT mode is refused by the register on the way in.
test(a_throw_at_an_unbound_current_mode_is_refused) :-
    % Throw closed at a gate whose current mode is a hole.
    catch(( archetype_gate_throw(closed, _Hole, _Next), Outcome = answered ),
          error(Error, _), Outcome = refused(Error)),
    % The register's own current-mode guard refuses it, rather than this slice growing a second copy.
    assertion(Outcome == refused(instantiation_error)).

% THE SLICE'S HEADLINE TEST, END TO END: ONE WRITE, MANY COORDINATED TRANSITIONS. This is the
% corpus's coordination mechanism in miniature - a broadcast written once and read many times, with
% no controller anywhere and no derivation function from a parent's mode to a child's.
test(one_bus_write_moves_every_gate_that_reads_it) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Three gates stand in a mixture of modes, as instances of one kind may.
    Standing = [open, closed, open],
    % One source throws closed at the gate KIND - one write, addressed to nobody in particular.
    neuromodulator_bus_throw_mode(Bus0, gate, closed, Bus),
    % Every gate reads the same bus for itself.
    neuromodulator_bus_thrown_mode(Bus, gate, Thrown),
    % And each applies it through its own register.
    findall(Next, ( member(Mode, Standing), archetype_gate_throw(Thrown, Mode, Next) ), Moved),
    % All three now stand in the thrown mode, having arrived there by two different routes.
    assertion(Moved == [closed, closed, closed]).

% TEST THAT WITHDRAWING THE THROW RETURNS THE KIND TO ITSELF, so a command preempts while it stands
% and no longer - the boundary that keeps this slice from being a permanent seizure of self-selection.
test(releasing_the_throw_returns_the_gate_to_self_selection) :-
    % Start from an empty bus and throw closed at the gate kind.
    neuromodulator_bus_new(Bus0),
    % Write the throw.
    neuromodulator_bus_throw_mode(Bus0, gate, closed, Bus1),
    % Withdraw it again.
    neuromodulator_bus_release_mode_throw(Bus1, gate, Bus2),
    % The channel now reads as silent.
    neuromodulator_bus_thrown_mode(Bus2, gate, Thrown),
    % Which is the reserved silence name.
    assertion(Thrown == no_mode_thrown),
    % So an open gate reading it keeps its own mode, and its own agency with it.
    archetype_gate_throw(Thrown, open, Next),
    % The gate stands where it stood.
    assertion(Next == open).

% Close the test block for the archetype pack.
:- end_tests(archetype).
