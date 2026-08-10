% Load the watchdog module under test from the library path.
:- use_module(library(watchdog)).
% Load the supervisor, because the point of this pack is to feed that one, and a reading that the
% real supervisor will not accept is not a reading. The join is tested, not assumed.
:- use_module(library(supervisor)).
% Load the archetype, so the readings are judged against the REAL gate's fault block rather than
% against a fixture written to suit them.
:- use_module(library(archetype)).
% Load the tick engine, so the window-from-a-duration conversion is tested against the convention.
:- use_module(library(tick_engine)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% watchdog_test_history(+Modes, -History): build a history observing one mode per tick from tick one.
watchdog_test_history(Modes, History) :-
    % Start from the empty history, which has seen nothing.
    watchdog_history_new(Empty),
    % Fold the modes in, one per tick, counting ticks from one.
    watchdog_test_fold(Modes, 1, Empty, History).

% watchdog_test_fold(+Modes, +Tick, +History0, -History): observe each mode at its own tick.
% An exhausted mode list leaves the history as it stands.
watchdog_test_fold([], _Tick, History, History).
% Each mode is observed at the current tick, and the next mode at the next tick.
watchdog_test_fold([Mode|Rest], Tick, History0, History) :-
    % Record this mode at this tick.
    watchdog_observe(History0, Tick, Mode, History1),
    % Advance to the next tick.
    Next is Tick + 1,
    % Observe the remaining modes.
    watchdog_test_fold(Rest, Next, History1, History).

% Open the test block for the watchdog pack.
:- begin_tests(watchdog).

% ---------------------------------------------------------------------------
% THE HISTORY ITSELF
% ---------------------------------------------------------------------------

% An empty history has seen nothing, spans nothing, and says so.
test(an_empty_history_spans_nothing) :-
    % Take a fresh history.
    watchdog_history_new(History),
    % It holds no observations.
    watchdog_history_observations(History, 0),
    % And it spans no ticks, which is zero and not one.
    watchdog_history_span(History, 0).

% One observation spans exactly one tick, because a span is inclusive of both its ends.
test(one_observation_spans_one_tick) :-
    % Observe a single mode at a single tick.
    watchdog_test_history([open], History),
    % One observation is held.
    watchdog_history_observations(History, 1),
    % And it spans one tick rather than zero.
    watchdog_history_span(History, 1).

% The current mode reads back without running the construct, which is the addendum's own constraint.
test(the_current_mode_reads_back_from_the_history_alone) :-
    % Observe three ticks ending in the closed mode.
    watchdog_test_history([open, open, closed], History),
    % The newest tick and the mode standing at it read back together.
    watchdog_history_current(History, Tick, Mode),
    % The newest tick is the third.
    Tick == 3,
    % And the mode standing at it is the one last observed.
    Mode == closed.

% An empty history has no current mode, and refuses rather than inventing a plausible one.
test(an_empty_history_has_no_current_mode, throws(error(domain_error(watchdog_non_empty_history, _), _))) :-
    % Take a fresh history.
    watchdog_history_new(History),
    % Asking it what mode is standing is a question it cannot honestly answer.
    watchdog_history_current(History, _Tick, _Mode).

% A history need not observe every tick, and its span is measured in TICKS rather than observations.
test(a_sampled_history_spans_more_ticks_than_it_holds_observations) :-
    % Observe at ticks one, four and seven only.
    watchdog_history_new(Empty),
    % The first observation.
    watchdog_observe(Empty, 1, open, One),
    % The second, three ticks later.
    watchdog_observe(One, 4, open, Two),
    % The third, three ticks later again.
    watchdog_observe(Two, 7, closed, History),
    % Three observations are held.
    watchdog_history_observations(History, 3),
    % But seven ticks are spanned, first to last inclusive.
    watchdog_history_span(History, 7).

% ---------------------------------------------------------------------------
% TIME DOES NOT RUN BACKWARDS, AND IT DOES NOT STAND STILL
% ---------------------------------------------------------------------------

% An observation at an earlier tick than the newest is refused aloud rather than reordered.
test(an_observation_that_runs_time_backwards_is_refused,
     throws(error(domain_error(watchdog_advancing_tick, 2), _))) :-
    % A history reaching tick five.
    watchdog_test_history([open, open, open, open, open], History),
    % Observing at tick two would rewrite history, and is refused naming the offending tick.
    watchdog_observe(History, 2, closed, _Rewritten).

% A second observation at the SAME tick is refused too, because it would double-count that tick.
test(a_repeated_tick_is_refused,
     throws(error(domain_error(watchdog_advancing_tick, 3), _))) :-
    % A history reaching tick three.
    watchdog_test_history([open, open, closed], History),
    % Observing tick three again would count one tick twice in every reading afterwards.
    watchdog_observe(History, 3, open, _Doubled).

% An unbound history is refused rather than bound into whatever shape the walk wanted.
test(an_unbound_history_is_refused, throws(error(instantiation_error, _))) :-
    % Recording onto a hole would invent the history it recorded onto.
    watchdog_observe(_Hole, 1, open, _History).

% An unbound mode is refused rather than bound to the name the caller forgot to supply.
test(an_unbound_mode_is_refused, throws(error(instantiation_error, _))) :-
    % A fresh history.
    watchdog_history_new(Empty),
    % Recording a hole as a mode would put a variable where a mode name belongs.
    watchdog_observe(Empty, 1, _Hole, _History).

% An unbound tick is refused rather than invented.
test(an_unbound_tick_is_refused, throws(error(instantiation_error, _))) :-
    % A fresh history.
    watchdog_history_new(Empty),
    % Recording at a hole would invent both a tick and the reading taken across it.
    watchdog_observe(Empty, _Hole, open, _History).

% ---------------------------------------------------------------------------
% THE WINDOW
% ---------------------------------------------------------------------------

% A window of zero ticks measures nothing and is refused, in every predicate that takes one.
test(a_window_of_zero_is_refused, throws(error(type_error(positive_integer, 0), _))) :-
    % A history of three ticks.
    watchdog_test_history([open, closed, open], History),
    % A zero window would report every construct clean forever, so it is refused at the door.
    watchdog_flips_in_window(History, 0, _Flips).

% A history shorter than the window has NOT measured that window, and says so.
test(a_short_history_has_not_measured_a_long_window) :-
    % Four ticks observed.
    watchdog_test_history([open, closed, open, closed], History),
    % A window of four is exactly spanned.
    watchdog_window_measured(History, 4),
    % A window of five is not, and the predicate fails rather than answering approximately.
    \+ watchdog_window_measured(History, 5).

% A window may be stated as a wall-clock duration and converted through the convention.
test(a_window_may_be_stated_in_milliseconds) :-
    % Three hundred milliseconds is thirty ticks under DECISION-2, exactly and without rounding.
    watchdog_window_ticks(300, Window),
    % The conversion is the tick engine's, not a second copy of the convention living here.
    Window == 30.

% A duration that does not land on a tick boundary is refused, and the refusal is the engine's own.
test(a_window_that_does_not_land_on_a_tick_is_refused,
     throws(error(domain_error(whole_tick_duration, 5), _))) :-
    % Five milliseconds is half a tick, and half a tick is a rounding waiting to happen.
    watchdog_window_ticks(5, _Window).

% ---------------------------------------------------------------------------
% THE FIRST READING: FLIPS IN A WINDOW
% ---------------------------------------------------------------------------

% A mode that never changes has flipped no times.
test(a_held_mode_has_not_flipped) :-
    % Five ticks all in the open mode.
    watchdog_test_history([open, open, open, open, open], History),
    % No adjacent pair differs, so no flip is counted.
    watchdog_flips_in_window(History, 5, Flips),
    % Which is zero.
    Flips == 0.

% A mode alternating every tick has flipped once per boundary between observations.
test(an_alternating_mode_flips_once_per_pair) :-
    % Five ticks alternating, which is four adjacent pairs and every one of them a change.
    watchdog_test_history([open, closed, open, closed, open], History),
    % Four flips are counted across the whole five-tick window.
    watchdog_flips_in_window(History, 5, Flips),
    % Which is four.
    Flips == 4.

% THE WINDOW TRAILS THE PRESENT, so flips older than it are not counted.
test(flips_older_than_the_window_are_not_counted) :-
    % Six ticks: three flips at the start, then a held mode.
    watchdog_test_history([open, closed, open, closed, closed, closed], History),
    % Over the whole six ticks, three flips.
    watchdog_flips_in_window(History, 6, All),
    % Which is three.
    All == 3,
    % Over the trailing three ticks, the mode has been held throughout.
    watchdog_flips_in_window(History, 3, Recent),
    % So no flip is counted there.
    Recent == 0.

% ---------------------------------------------------------------------------
% THE SECOND READING: TICKS HELD IN ONE MODE
% ---------------------------------------------------------------------------

% A mode just entered has been held one tick, not zero, because a hold includes its own tick.
test(a_mode_just_entered_has_been_held_one_tick) :-
    % Three ticks ending in a mode entered at the last of them.
    watchdog_test_history([open, open, closed], History),
    % The hold is measured back from the newest observation.
    watchdog_ticks_held_in_window(History, 3, Held),
    % Which is one tick.
    Held == 1.

% A mode held throughout the window reads the window's own length, and no more.
test(a_mode_held_throughout_reads_the_window_length) :-
    % Ten ticks all in one mode.
    watchdog_test_history([open, open, open, open, open, open, open, open, open, open], History),
    % Measured over a window of four, the hold is four - not ten, because the window bounds it.
    watchdog_ticks_held_in_window(History, 4, Held),
    % Which is four.
    Held == 4.

% A hold is measured in TICKS and not in observations, so a sampled history reports the real duration.
test(a_hold_is_measured_in_ticks_not_observations) :-
    % Observe the same mode at ticks one, five and nine only.
    watchdog_history_new(Empty),
    % The first observation.
    watchdog_observe(Empty, 1, open, One),
    % The second, four ticks later.
    watchdog_observe(One, 5, open, Two),
    % The third, four ticks later again.
    watchdog_observe(Two, 9, open, History),
    % Three observations, but the mode has been held for nine ticks.
    watchdog_ticks_held_in_window(History, 9, Held),
    % Which is nine and not three.
    Held == 9.

% ---------------------------------------------------------------------------
% DECISION-4: AN UNSPANNED WINDOW IS NOT-YET-MEASURED, NEVER CLEAN
% ---------------------------------------------------------------------------

% THE CENTRAL TEST OF THIS SLICE. A history too short for the window yields NO reading, so the
% supervisor reports the boundary unwatched rather than publishing a clean bill of health for a
% boundary nobody has watched long enough to judge.
test(a_history_too_short_for_its_window_yields_no_reading) :-
    % Four ticks observed, with one flip among them.
    watchdog_test_history([open, open, closed, closed], History),
    % A window of twenty is asked for, which four ticks do not span.
    watchdog_gate_readings(History, 20, 3, 100, Readings, NotMeasured),
    % No reading is offered, because an honest one cannot be taken yet.
    Readings == [],
    % Both boundaries are named as not yet measured, carrying the window asked and the span held.
    NotMeasured == [watchdog_not_measured(oscillation, 20, 4),
                    watchdog_not_measured(stuck_switch, 20, 4)].

% AND THE CONSEQUENCE AT THE WATCHER, WHICH IS THE POINT: the supervisor reports both of the gate's
% corpus-named boundaries as UNWATCHED, by name, rather than as clean.
test(an_unmeasured_window_leaves_the_gate_unwatched_at_the_supervisor) :-
    % A history too short for the window.
    watchdog_test_history([open, open, closed, closed], History),
    % Which yields no readings at all.
    watchdog_gate_readings(History, 20, 3, 100, Readings, _NotMeasured),
    % Build the real gate's automaton, standing in the mode it was last seen in.
    archetype_gate_automaton(closed, Automaton),
    % Hand the real supervisor the real gate and the empty reading set.
    supervisor_watch(Automaton, Readings, Report),
    % Nothing is warned about, because nothing was measured.
    supervisor_report_warnings(Report, []),
    % And both boundaries are reported unwatched, with their watchdogs named.
    supervisor_report_unwatched(Report, Unwatched),
    % Which is exactly the two the corpus supplies for this construct.
    Unwatched == [supervisor_unwatched(oscillation, oscillation_watchdog),
                  supervisor_unwatched(stuck_switch, stuck_switch_watchdog)].

% ---------------------------------------------------------------------------
% THE JOIN: THE FIRST FAULT REGIME IN THIS REPOSITORY EVER ACTUALLY WATCHED
% ---------------------------------------------------------------------------

% A spanned window yields both readings, under the signatures the gate's own fault block declares.
test(a_spanned_window_yields_both_readings_under_the_gates_own_signatures) :-
    % Six ticks with three flips, ending in a mode held for one tick.
    watchdog_test_history([open, closed, open, closed, closed, closed], History),
    % Read over the whole six, with allowances the caller supplies.
    watchdog_gate_readings(History, 6, 3, 100, Readings, NotMeasured),
    % Nothing went unmeasured.
    NotMeasured == [],
    % Both readings are offered, keyed to the gate's two corpus-named boundaries.
    Readings == [supervisor_reading(oscillation, 3, 3),
                 supervisor_reading(stuck_switch, 3, 100)].

% OBSERVATION-9 CLOSED, PROVED AT THE WATCHER. Handed a real reading, the supervisor reports the
% gate's boundaries as watched and clean rather than as unwatched.
test(a_watched_gate_within_its_allowances_is_clean_and_no_longer_unwatched) :-
    % Six ticks with three flips.
    watchdog_test_history([open, closed, open, closed, closed, closed], History),
    % Read with an allowance of three flips, which three flips do not exceed.
    watchdog_gate_readings(History, 6, 3, 100, Readings, _NotMeasured),
    % Build the real gate's automaton in the mode it stands in.
    archetype_gate_automaton(closed, Automaton),
    % Hand the real supervisor the real gate and the real readings.
    supervisor_watch(Automaton, Readings, Report),
    % No boundary was crossed, so nothing is warned about.
    supervisor_report_warnings(Report, []),
    % AND NOTHING IS UNWATCHED - which is the sentence konnectome could not say before this slice.
    supervisor_report_unwatched(Report, []).

% A gate flipping past its allowance is WARNED about, by name, carrying the numbers judged on.
test(a_gate_flipping_past_its_allowance_is_warned_about) :-
    % Six ticks alternating every tick, which is five flips.
    watchdog_test_history([open, closed, open, closed, open, closed], History),
    % Read with an allowance of two flips, which five flips plainly exceed.
    watchdog_gate_readings(History, 6, 2, 100, Readings, _NotMeasured),
    % Build the real gate's automaton.
    archetype_gate_automaton(closed, Automaton),
    % Hand both to the real supervisor.
    supervisor_watch(Automaton, Readings, Report),
    % The oscillation boundary is warned about, carrying its condition, its watchdog and its numbers.
    supervisor_report_warnings(Report, Warnings),
    % Exactly one warning, because only one boundary was crossed.
    Warnings == [supervisor_warning(oscillation,
                                    gate_flipping_faster_than_its_watchdog_allows,
                                    oscillation_watchdog,
                                    5, 2)],
    % And nothing is unwatched, because both boundaries were read.
    supervisor_report_unwatched(Report, []).

% THE OPPOSITE FAILURE, AND IT IS THE ONE SLICE 44 EXISTS TO PREVENT. A gate that settles and never
% leaves crosses the stuck-switch boundary, and the watchdog says so.
test(a_gate_stuck_in_one_mode_is_warned_about) :-
    % Eight ticks all in the closed mode, which is the corpus's stuck-switch signature exactly.
    watchdog_test_history([closed, closed, closed, closed, closed, closed, closed, closed], History),
    % Read with a generous flip allowance and a hold allowance of five ticks.
    watchdog_gate_readings(History, 8, 10, 5, Readings, _NotMeasured),
    % Build the real gate's automaton, standing in the mode it has not left.
    archetype_gate_automaton(closed, Automaton),
    % Hand both to the real supervisor.
    supervisor_watch(Automaton, Readings, Report),
    % The stuck-switch boundary is warned about, carrying the eight ticks held against the five allowed.
    supervisor_report_warnings(Report, Warnings),
    % Exactly one warning, because the flip allowance was not crossed.
    Warnings == [supervisor_warning(stuck_switch,
                                    gate_held_in_one_mode_longer_than_its_watchdog_allows,
                                    stuck_switch_watchdog,
                                    8, 5)],
    % And nothing is unwatched.
    supervisor_report_unwatched(Report, []).

% BOTH BOUNDARIES CANNOT BE CROSSED AT ONCE BY THE SAME HISTORY, and that is a property of the design
% rather than a coincidence: a gate cannot both flip too often and hold too long over one window.
% This is the absorbing-state lens's cousin, and it is checked rather than assumed.
test(the_two_boundaries_are_not_simultaneously_crossable) :-
    % Six ticks alternating, which is the most flips a six-tick window can hold.
    watchdog_test_history([open, closed, open, closed, open, closed], History),
    % Five flips over six ticks.
    watchdog_flips_in_window(History, 6, Flips),
    % Which is five.
    Flips == 5,
    % And the mode has been held for exactly one tick, which is the least any hold can be.
    watchdog_ticks_held_in_window(History, 6, Held),
    % Which is one.
    Held == 1.

% An unbound allowance is refused BEFORE any reading is taken, rather than at the comparison where
% the error would name nothing useful.
test(an_unbound_allowance_is_refused, throws(error(instantiation_error, _))) :-
    % A history long enough to be read.
    watchdog_test_history([open, closed, open, closed], History),
    % A hole where the flip allowance belongs makes every verdict a guess.
    watchdog_gate_readings(History, 4, _Hole, 100, _Readings, _NotMeasured).

% An unbound hold allowance is refused just as strictly, in the same place.
test(an_unbound_hold_allowance_is_refused, throws(error(instantiation_error, _))) :-
    % A history long enough to be read.
    watchdog_test_history([open, closed, open, closed], History),
    % A hole where the hold allowance belongs is refused with the same firmness.
    watchdog_gate_readings(History, 4, 3, _Hole, _Readings, _NotMeasured).

% Close the test block for the watchdog pack.
:- end_tests(watchdog).
