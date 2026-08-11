% Load the supervisor module under test from the library path.
:- use_module(library(supervisor)).
% Load the mode register, because a fault block is one of the hybrid automaton's four blocks.
:- use_module(library(mode_register)).
% Load the archetype, so the watcher is tested against a REAL construct's fault block and not only
% against fixtures written to suit it. The gate is the one konnectome construct whose fault regimes
% come from the corpus, so it is the one that can embarrass this pack if the pack is wrong.
:- use_module(library(archetype)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% A two-mode automaton carrying two fault regimes, used by the tests below.
% watched_automaton(-Automaton): a machine with two modes and two boundaries it must not cross.
watched_automaton(Automaton) :-
    % Build a register of two whose fault block names two regimes and their watchdogs.
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds'),
                       mode_entry(loud, 'the Raised Voice', 'does its work while it holds')],
                      [transfer(quiet, hold), transfer(loud, relay(1))],
                      [transition(own_drive, quiet, loud, one_tick, self_selected)],
                      [fault(oscillation, flips_too_fast, oscillation_watchdog),
                       fault(overheating, runs_too_hot, thermal_watchdog)],
                      Automaton).

% Open the test block for the supervisor pack.
:- begin_tests(supervisor).

% ---------------------------------------------------------------------------
% THE DIRECTIVE: A FAULT IS NOT A MODE
% ---------------------------------------------------------------------------

% A register whose fault signatures are all outside its mode vocabulary passes the directive.
test(a_well_formed_register_passes_the_directive) :-
    % A machine whose two boundaries are neither of its two modes.
    watched_automaton(Automaton),
    % The directive holds, so the register may be watched.
    supervisor_faults_are_not_modes(Automaton).

% THE SLICE'S CENTRAL REFUSAL: a fault signature that is also a declared mode is refused aloud. The
% corpus forbids this by name, and konnectome now enforces it rather than remembering it.
test(a_fault_named_for_a_mode_is_refused,
     throws(error(domain_error(supervisor_fault_is_not_a_mode, loud), _))) :-
    % Build a register that tries to admit one of its own modes as a fault regime.
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds'),
                       mode_entry(loud, 'the Raised Voice', 'does its work while it holds')],
                      [transfer(quiet, hold), transfer(loud, relay(1))],
                      [],
                      [fault(loud, runs_too_hot, thermal_watchdog)],
                      Automaton),
    % The supervisor refuses to watch it, because a designed behaviour for being broken would then
    % run silently and forever.
    supervisor_faults_are_not_modes(Automaton).

% The refusal also fires on the way into a watch, so a malformed register can never be reported on.
test(a_watch_refuses_a_register_that_admits_a_fault_as_a_mode,
     throws(error(domain_error(supervisor_fault_is_not_a_mode, loud), _))) :-
    % Build the same offending register.
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'holds'),
                       mode_entry(loud, 'the Raised Voice', 'works')],
                      [transfer(quiet, hold), transfer(loud, relay(1))],
                      [], [fault(loud, runs_too_hot, thermal_watchdog)], Automaton),
    % Try to watch it with a perfectly good reading; the register is judged first.
    supervisor_watch(Automaton, [supervisor_reading(loud, 1, 10)], _Report).

% A malformed fault entry is refused aloud rather than skipped.
test(a_malformed_fault_entry_is_refused,
     throws(error(domain_error(fault, mystery), _))) :-
    % Build a register whose fault block holds a bare atom.
    mode_register_new(quiet, [mode_entry(quiet, 'the Held Breath', 'holds')],
                      [transfer(quiet, hold)], [], [mystery], Automaton),
    % The supervisor refuses it by name.
    supervisor_faults_are_not_modes(Automaton).

% ---------------------------------------------------------------------------
% THE THREE OUTCOMES
% ---------------------------------------------------------------------------

% A reading that crosses its allowance produces a warning carrying the numbers it was judged on.
test(a_crossed_boundary_produces_a_warning) :-
    % A machine with two watched boundaries.
    watched_automaton(Automaton),
    % One watchdog reports a value above the allowance it supplies; the other reports within.
    supervisor_watch(Automaton,
                     [supervisor_reading(oscillation, 9, 4),
                      supervisor_reading(overheating, 2, 40)],
                     Report),
    % Read the warnings.
    supervisor_report_warnings(Report, Warnings),
    % Exactly one boundary was crossed.
    assertion(Warnings == [supervisor_warning(oscillation, flips_too_fast, oscillation_watchdog, 9, 4)]),
    % And nothing was left unwatched, because both watchdogs reported.
    supervisor_report_unwatched(Report, Unwatched),
    % The unwatched block is empty.
    assertion(Unwatched == []).

% A reading that holds within its allowance produces no warning, and is not reported as unwatched.
test(a_held_boundary_produces_nothing) :-
    % A machine with two watched boundaries.
    watched_automaton(Automaton),
    % Both watchdogs report values within their allowances.
    supervisor_watch(Automaton,
                     [supervisor_reading(oscillation, 1, 4),
                      supervisor_reading(overheating, 2, 40)],
                     Report),
    % No warning was raised.
    supervisor_report_warnings(Report, Warnings),
    % The warning block is empty.
    assertion(Warnings == []),
    % And a WATCHED regime is not an unwatched one; a clean report is a real statement.
    supervisor_report_unwatched(Report, Unwatched),
    % The unwatched block is empty too.
    assertion(Unwatched == []).

% A BOUNDARY EXACTLY AT ITS ALLOWANCE HAS NOT BEEN CROSSED, and the boundary case is pinned rather
% than left to whoever next reads the comparison.
test(a_boundary_exactly_at_its_allowance_is_not_crossed) :-
    % A machine with two watched boundaries.
    watched_automaton(Automaton),
    % A watchdog reports a value exactly equal to its allowance.
    supervisor_watch(Automaton,
                     [supervisor_reading(oscillation, 4, 4),
                      supervisor_reading(overheating, 2, 40)],
                     Report),
    % Read the warnings.
    supervisor_report_warnings(Report, Warnings),
    % Equal is not above, so nothing is warned about.
    assertion(Warnings == []).

% THE THIRD OUTCOME, AND THE ONE A TWO-OUTCOME DESIGN WOULD LOSE: a regime nobody watched is reported
% as unwatched, by name and with its watchdog, rather than passing as clean.
test(an_unwatched_regime_is_reported_as_unwatched_not_clean) :-
    % A machine with two watched boundaries.
    watched_automaton(Automaton),
    % Only one watchdog reports at all.
    supervisor_watch(Automaton, [supervisor_reading(oscillation, 1, 4)], Report),
    % Nothing was warned about.
    supervisor_report_warnings(Report, Warnings),
    % The warning block is empty, which on its own would look like health.
    assertion(Warnings == []),
    % But the second regime is named as unwatched, carrying the watchdog that did not report.
    supervisor_report_unwatched(Report, Unwatched),
    % Silence is not health, and the report says which silence it is.
    assertion(Unwatched == [supervisor_unwatched(overheating, thermal_watchdog)]).

% A register with no watchdogs at all reports every regime unwatched and nothing clean.
test(a_watch_with_no_readings_reports_everything_unwatched) :-
    % A machine with two watched boundaries.
    watched_automaton(Automaton),
    % No watchdog reports anything.
    supervisor_watch(Automaton, [], Report),
    % Both regimes are named as unwatched.
    supervisor_report_unwatched(Report, Unwatched),
    % Neither is reported clean.
    assertion(Unwatched == [supervisor_unwatched(oscillation, oscillation_watchdog),
                            supervisor_unwatched(overheating, thermal_watchdog)]).

% A register whose fault block is empty has nothing to watch and says so without complaint.
test(an_empty_fault_block_watches_cleanly) :-
    % The smallest register the corpus admits, whose fault block is empty.
    mode_register_new(quiet, [mode_entry(quiet, 'the Held Breath', 'holds')],
                      [transfer(quiet, hold)], [], [], Automaton),
    % Watching it is legal and produces two empty blocks.
    supervisor_watch(Automaton, [], Report),
    % Nothing warned.
    supervisor_report_warnings(Report, Warnings),
    % The warning block is empty.
    assertion(Warnings == []),
    % And nothing unwatched, because there was nothing to watch.
    supervisor_report_unwatched(Report, Unwatched),
    % The unwatched block is empty.
    assertion(Unwatched == []).

% ---------------------------------------------------------------------------
% THE REFUSALS
% ---------------------------------------------------------------------------

% TWO READINGS FOR ONE BOUNDARY ARE REFUSED, not silently resolved in favour of the first. This is
% slice 41's declaration-order lens applied to code written the slice after it was earned.
test(two_readings_for_one_boundary_are_refused,
     throws(error(domain_error(supervisor_single_reading_per_signature, oscillation), _))) :-
    % A machine with two watched boundaries.
    watched_automaton(Automaton),
    % Two watchdogs report on the same boundary and disagree about the allowance.
    supervisor_watch(Automaton,
                     [supervisor_reading(oscillation, 9, 4),
                      supervisor_reading(oscillation, 9, 40)],
                     _Report).

% A malformed reading is refused aloud, naming what arrived.
test(a_malformed_reading_is_refused,
     throws(error(domain_error(supervisor_reading, mystery), _))) :-
    % A machine with two watched boundaries.
    watched_automaton(Automaton),
    % A readings store holding a bare atom.
    supervisor_watch(Automaton, [mystery], _Report).

% An unbound readings store is refused, never walked as an empty one.
test(an_unbound_readings_store_is_refused,
     throws(error(instantiation_error, _))) :-
    % A machine with two watched boundaries.
    watched_automaton(Automaton),
    % A hole where the readings should be would otherwise report everything unwatched, confidently.
    supervisor_watch(Automaton, _Hole, _Report).

% REVIEW PIN, the unbound-wrong-judgement lens: an unbound VALUE is refused before it is compared.
% A hole reaching the comparison would raise an arithmetic error naming nothing a caller can act on,
% and a supervisor that guesses is worse than no supervisor at all.
test(an_unbound_reading_value_is_refused,
     throws(error(instantiation_error, _))) :-
    % A machine with two watched boundaries.
    watched_automaton(Automaton),
    % A watchdog reports a hole as its measurement.
    supervisor_watch(Automaton, [supervisor_reading(oscillation, _Hole, 4)], _Report).

% And an unbound ALLOWANCE is judged exactly as strictly as the value, in the same place.
test(an_unbound_reading_allowance_is_refused,
     throws(error(instantiation_error, _))) :-
    % A machine with two watched boundaries.
    watched_automaton(Automaton),
    % A watchdog reports a real measurement against a hole.
    supervisor_watch(Automaton, [supervisor_reading(oscillation, 9, _Hole)], _Report).

% An unbound boundary signature is refused, never bound by the gather to the first fault it meets.
test(an_unbound_reading_signature_is_refused,
     throws(error(instantiation_error, _))) :-
    % A machine with two watched boundaries.
    watched_automaton(Automaton),
    % A reading keyed by a hole would otherwise answer for whichever regime came first.
    supervisor_watch(Automaton, [supervisor_reading(_Hole, 9, 4)], _Report).

% ---------------------------------------------------------------------------
% THE CHANNEL
% ---------------------------------------------------------------------------

% An empty channel reports every construct kind as having nothing watched, never as clean.
test(an_empty_channel_reports_nothing_watched) :-
    % A fresh channel.
    supervisor_channel_new(Channel),
    % Read the report standing for a kind nobody has watched.
    supervisor_report(Channel, gate, Report),
    % It carries two empty blocks, which is the honest statement that no watch has happened.
    assertion(Report == supervisor_report([], [])).

% A published report can be read back by whoever can act on it.
test(publish_then_read) :-
    % A machine with two watched boundaries, watched.
    watched_automaton(Automaton),
    % One boundary crossed.
    supervisor_watch(Automaton, [supervisor_reading(oscillation, 9, 4)], Report),
    % Publish the report for the construct kind it concerns.
    supervisor_channel_new(Channel0),
    % Write it onto the channel.
    supervisor_publish(Channel0, gate, Report, Channel),
    % Read it back.
    supervisor_report(Channel, gate, Found),
    % The report read is the report published.
    assertion(Found == Report).

% The newest watch replaces the older one, so a stale warning cannot outlive its own fault.
test(newest_report_wins) :-
    % A machine with two watched boundaries.
    watched_automaton(Automaton),
    % A first watch finds a crossed boundary.
    supervisor_watch(Automaton, [supervisor_reading(oscillation, 9, 4),
                                 supervisor_reading(overheating, 2, 40)], Alarmed),
    % A later watch finds everything within allowance.
    supervisor_watch(Automaton, [supervisor_reading(oscillation, 1, 4),
                                 supervisor_reading(overheating, 2, 40)], Calm),
    % Publish the first, then the second.
    supervisor_channel_new(Channel0),
    % The alarming report.
    supervisor_publish(Channel0, gate, Alarmed, Channel1),
    % Then the calm one.
    supervisor_publish(Channel1, gate, Calm, Channel2),
    % Read the standing report.
    supervisor_report(Channel2, gate, Found),
    % The newest watch is the one that stands, so a warning cannot outlive the condition it named.
    assertion(Found == Calm).

% A report published for one kind is invisible to every other kind.
test(a_report_reaches_only_the_kind_it_names) :-
    % A machine with two watched boundaries, watched and found crossed.
    watched_automaton(Automaton),
    % One boundary crossed.
    supervisor_watch(Automaton, [supervisor_reading(oscillation, 9, 4)], Report),
    % Publish it for the gate kind.
    supervisor_channel_new(Channel0),
    % Write it.
    supervisor_publish(Channel0, gate, Report, Channel),
    % Read the report standing for a different kind.
    supervisor_report(Channel, relay, Other),
    % That kind has had nothing watched, which is not the gate's warning and not a clean bill either.
    assertion(Other == supervisor_report([], [])).

% A term that is not a report may not be published, so the channel cannot carry an unreadable value.
test(publishing_a_non_report_is_refused,
     throws(error(domain_error(supervisor_report, mystery), _))) :-
    % A fresh channel.
    supervisor_channel_new(Channel0),
    % Try to publish a bare atom.
    supervisor_publish(Channel0, gate, mystery, _Channel).

% An unbound report is refused before it can be published as a clean bill of health.
test(publishing_an_unbound_report_is_refused,
     throws(error(instantiation_error, _))) :-
    % A fresh channel.
    supervisor_channel_new(Channel0),
    % Try to publish a hole.
    supervisor_publish(Channel0, gate, _Hole, _Channel).

% An unbound construct kind is refused at the write, never bound into a key nobody addressed.
test(an_unbound_kind_is_refused_at_the_publish,
     throws(error(instantiation_error, _))) :-
    % A fresh channel.
    supervisor_channel_new(Channel0),
    % Try to publish for no kind at all.
    supervisor_publish(Channel0, _Hole, supervisor_report([], []), _Channel).

% REVIEW PIN, the unbound-wrong-judgement lens: an unbound construct kind is refused at the READ too,
% because a lookup would bind it to whichever kind the channel lists first and hand back that kind's
% failure report to a caller who addressed nobody.
test(an_unbound_kind_is_refused_at_the_read,
     throws(error(instantiation_error, _))) :-
    % A channel carrying one kind's report.
    supervisor_channel_new(Channel0),
    % Write it, so a lookup would have something to bind to.
    supervisor_publish(Channel0, gate, supervisor_report([], []), Channel),
    % Try to read the report standing for no kind at all.
    supervisor_report(Channel, _Hole, _Report).

% An unbound channel is refused at the read, exactly as an unbound bus is on the broadcast bus.
test(an_unbound_channel_is_refused_at_the_read,
     throws(error(instantiation_error, _))) :-
    % A hole where the channel should be would invent a channel and a clean report with it.
    supervisor_report(_Hole, gate, _Report).

% ---------------------------------------------------------------------------
% THE GATE, WATCHED FOR REAL (the slice's headline)
% ---------------------------------------------------------------------------

% THE FAULT BLOCK THAT WAS EMPTY FOR THREE SLICES IS NOW WATCHED, and the corpus's own two regimes
% are the ones being watched. This is the test that closes slice 39's IOU.
test(the_gate_is_watched_against_the_corpus_two_regimes) :-
    % A real gate, standing open.
    archetype_gate_automaton(open, Automaton),
    % Its fault signatures are not its modes, so the directive holds on a real construct.
    supervisor_faults_are_not_modes(Automaton),
    % Two watchdogs report: the gate is flipping faster than allowed and has not been held too long.
    supervisor_watch(Automaton,
                     [supervisor_reading(oscillation, 12, 3),
                      supervisor_reading(stuck_switch, 5, 100)],
                     Report),
    % One warning is raised, naming the boundary, the condition, the watchdog and both numbers.
    supervisor_report_warnings(Report, Warnings),
    % The gate is oscillating.
    assertion(Warnings == [supervisor_warning(oscillation,
                                              gate_flipping_faster_than_its_watchdog_allows,
                                              oscillation_watchdog, 12, 3)]),
    % And nothing about the gate was left unwatched.
    supervisor_report_unwatched(Report, Unwatched),
    % Both regimes had a watchdog.
    assertion(Unwatched == []).

% A WARNING IS NOT A MODE, AND THIS IS THE ASSERTION THAT SAYS SO. The gate is warned about while
% standing in a perfectly ordinary mode, and the warning changes neither the mode it stands in nor
% the rule in force. A supervisor that could move a construct would be a controller, not a watcher.
test(a_warning_moves_neither_the_mode_nor_the_rule) :-
    % A real gate, standing open.
    archetype_gate_automaton(open, Automaton),
    % Read the mode and the rule in force before the watch.
    mode_register_current(Automaton, ModeBefore),
    % And the rule that holds right now.
    mode_register_current_rule(Automaton, RuleBefore),
    % Watch it, and find it in breach of a boundary.
    supervisor_watch(Automaton, [supervisor_reading(oscillation, 12, 3)], Report),
    % A warning was genuinely raised, so this test is not passing vacuously.
    supervisor_report_warnings(Report, Warnings),
    % One warning stands.
    assertion(Warnings = [_One]),
    % The gate still stands in the mode it stood in.
    mode_register_current(Automaton, ModeAfter),
    % Unchanged.
    assertion(ModeAfter == ModeBefore),
    % And still runs the rule it ran.
    mode_register_current_rule(Automaton, RuleAfter),
    % Unchanged, because a fault has no transfer function and a warning is not a transition.
    assertion(RuleAfter == RuleBefore).

% ---------------------------------------------------------------------------
% THE RULE CONSULTS THE FLAG (slice 66, OBSERVATION-19's closer)
% ---------------------------------------------------------------------------

% A helper: a machine that admits one of its modes as a fault, in the corpus's own manner.
% admitting_automaton(-Automaton): a construct that says which of its modes is a way of being broken.
admitting_automaton(Automaton) :-
    % The admitted mode is BOTH a declared mode and a declared fault signature, which the blanket ban
    % refused outright and which the design authority says a tagged minority may be.
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds'),
                       mode_entry(runaway, 'the Runaway', 'flips as fast as its input changes',
                                  [admitted_as_fault('a fault regime, admitted only because it names the failure')])],
                      [transfer(quiet, hold), transfer(runaway, relay(1))],
                      [transition(own_drive, quiet, runaway, one_tick, self_selected)],
                      [fault(runaway, flips_too_fast, oscillation_watchdog)],
                      Automaton).

% THE BLANKET BAN IS SOFTENED EXACTLY WHERE THE AUTHORITY SAYS IT SHOULD BE AND NOWHERE ELSE. A mode
% that is also a fault signature passes the directive when, and only when, its own entry admits it.
test(an_admitted_fault_may_stand_in_the_register) :-
    admitting_automaton(Automaton),
    % The directive holds, so the register may be watched.
    supervisor_faults_are_not_modes(Automaton).

% AND THE UNADMITTED CASE IS REFUSED EXACTLY AS IT ALWAYS WAS, which is what makes this a softening
% rather than a repeal. The same register without the tag is the register the ban was written for.
test(the_same_register_without_the_tag_is_still_refused,
     throws(error(domain_error(supervisor_fault_is_not_a_mode, runaway), _))) :-
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds'),
                       mode_entry(runaway, 'the Runaway', 'flips as fast as its input changes')],
                      [transfer(quiet, hold), transfer(runaway, relay(1))],
                      [transition(own_drive, quiet, runaway, one_tick, self_selected)],
                      [fault(runaway, flips_too_fast, oscillation_watchdog)],
                      Automaton),
    supervisor_faults_are_not_modes(Automaton).

% AN ADMISSION IS PER MODE AND NOT PER REGISTER, which is the design authority's FIRST qualification -
% the rule is per construct, not per regime - carried down to the entry. A register holding one
% admitted mode does not thereby admit a second, untagged one.
test(one_admitted_mode_does_not_admit_a_second_untagged_one,
     throws(error(domain_error(supervisor_fault_is_not_a_mode, overheating), _))) :-
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds'),
                       mode_entry(runaway, 'the Runaway', 'flips as fast as its input changes',
                                  [admitted_as_fault('admitted only because it names the failure')]),
                       mode_entry(overheating, 'the Overheated One', 'runs too hot while it holds')],
                      [transfer(quiet, hold), transfer(runaway, relay(1)),
                       transfer(overheating, relay(2))],
                      [],
                      [fault(runaway, flips_too_fast, oscillation_watchdog),
                       fault(overheating, runs_too_hot, thermal_watchdog)],
                      Automaton),
    supervisor_faults_are_not_modes(Automaton).

% THE DEPARTURE FROM THE STRICT RULE IS READABLE, WHICH IS THE HALF THAT KEEPS IT FROM BEING A HOLE.
% Asking a construct what it has been allowed to be broken in returns an argument, not a shrug.
test(the_admissions_are_readable_with_their_reasons) :-
    admitting_automaton(Automaton),
    supervisor_admissions(Automaton, Admissions),
    assertion(Admissions == [mode_register_admission(runaway,
                                'a fault regime, admitted only because it names the failure')]).

% A register that admits nothing says so as an empty list, so "nothing is admitted here" is a readable
% answer rather than a failure a caller has to interpret.
test(a_register_that_admits_nothing_says_so) :-
    watched_automaton(Automaton),
    supervisor_admissions(Automaton, Admissions),
    assertion(Admissions == []).

% AND AN ADMITTED FAULT IS STILL WATCHED. Admission changes what the register may declare, not what
% the supervisor does about it: the boundary is compared against its allowance exactly as before.
test(an_admitted_fault_is_still_watched_and_still_warned_about) :-
    admitting_automaton(Automaton),
    supervisor_watch(Automaton, [supervisor_reading(runaway, 12, 3)], Report),
    supervisor_report_warnings(Report, Warnings),
    assertion(Warnings == [supervisor_warning(runaway, flips_too_fast, oscillation_watchdog, 12, 3)]).

% An admitted fault nobody watches is reported unwatched, not clean - the third outcome survives the
% softening untouched.
test(an_admitted_fault_nobody_watches_is_reported_unwatched) :-
    admitting_automaton(Automaton),
    supervisor_watch(Automaton, [], Report),
    supervisor_report_unwatched(Report, Unwatched),
    assertion(Unwatched == [supervisor_unwatched(runaway, oscillation_watchdog)]).

% Close the test block for the supervisor pack.
:- end_tests(supervisor).
