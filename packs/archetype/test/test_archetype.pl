% Load the archetype module under test from the library path.
:- use_module(library(archetype)).
% Load the mode register, so the gate's automaton is read with the corpus's own accessors.
:- use_module(library(mode_register)).
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
    % The gate has exactly two departures, one from each of its two modes.
    assertion(length(Rows, 2)),
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

% TEST OF AGENCY, the field the corpus says must never be omitted.
test(gate_transitions_carry_agency) :-
    % Read the transition table.
    archetype_gate_transitions(Rows),
    % Nothing above throws this gate yet, so both departures are honestly self-selected.
    forall(member(transition(_T, _F, _To, _Ts, Agency), Rows),
           assertion(Agency == self_selected)).

% TEST OF THE SHARED TRIGGER: konnectome's gate is a symmetric toggle, not a hysteretic latch.
test(gate_transitions_share_one_trigger) :-
    % Read the transition table.
    archetype_gate_transitions(Rows),
    % Collect the trigger of every row.
    findall(Trigger, member(transition(Trigger, _F, _To, _Ts, _A), Rows), Triggers),
    % Sort the triggers, dropping duplicates.
    sort(Triggers, Distinct),
    % Both directions fire on the one condition, at the one threshold - the honest current shape.
    assertion(Distinct == [switch_drive_above_threshold]).

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

% Close the test block for the archetype pack.
:- end_tests(archetype).
