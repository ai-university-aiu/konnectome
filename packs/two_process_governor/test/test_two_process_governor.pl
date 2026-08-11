% Load the two_process_governor module under test from the library path.
:- use_module(library(two_process_governor)).
% Load the watchdog, because slice 47's whole subject is this governor being WATCHED by it, and a
% join tested against a fixture history would prove the join and not the wiring.
:- use_module(library(watchdog)).
% Load the supervisor, which is what the readings are ultimately judged by.
:- use_module(library(supervisor)).
% Load the mode register, because the governor now carries a hybrid automaton like every other
% construct in this repository.
:- use_module(library(mode_register)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Import the apply and list utilities the slice 47 tests use to build histories by hand.
:- use_module(library(apply), [foldl/4]).
% Import numlist, nth1 and reverse for the constructed histories and the pinned day.
:- use_module(library(lists), [numlist/3, nth1/3, reverse/2]).
% Import yall so the lambda expressions in those tests resolve.
:- use_module(library(yall)).

% Open the test block for the two_process_governor pack.
:- begin_tests(two_process_governor).

% A fresh governor starts the day at midnight with no sleep debt and its corpus-shaped defaults.
test(new_governor_starts_discharged_at_midnight) :-
    % Make a fresh governor with the default parameters.
    two_process_governor_new(Governor),
    % Read the sleep pressure back.
    two_process_governor_pressure(Governor, Pressure),
    % Read the circadian phase back.
    two_process_governor_phase(Governor, Phase),
    % Confirm the debt starts at zero.
    assertion(Pressure =:= 0),
    % Confirm the day starts at phase zero.
    assertion(Phase =:= 0).

% One online step raises the pressure by exactly the rise rate: the bill climbs while awake.
test(online_step_raises_pressure_by_rise_rate) :-
    % Make a fresh governor with the default parameters.
    two_process_governor_new(Governor0),
    % Step it once under the online state.
    two_process_governor_step(Governor0, online, Governor, _State),
    % Read the pressure after the step.
    two_process_governor_pressure(Governor, Pressure),
    % Confirm one tick of waking added exactly the default rise of one.
    assertion(Pressure =:= 1).

% One offline step pays the debt down by the discharge rate, and the debt never goes below zero.
test(offline_step_discharges_and_floors_at_zero) :-
    % Build a governor holding a small standing debt of one.
    two_process_governor_new(two_process_parameters(1, 2, 24, 4, 16, 2), Governor0),
    % Step it once online so the pressure stands at one.
    two_process_governor_step(Governor0, online, Governor1, _StateA),
    % Step it once offline, which discharges by two against a debt of one.
    two_process_governor_step(Governor1, offline, Governor2, _StateB),
    % Read the pressure after the discharge.
    two_process_governor_pressure(Governor2, Pressure),
    % Confirm the debt floored at zero rather than going negative.
    assertion(Pressure =:= 0).

% The circadian phase advances by one each tick and wraps at the day length: the clock keeps a day.
test(phase_advances_and_wraps_at_day_length) :-
    % Build a governor with a tiny three-tick day so the wrap is cheap to reach.
    two_process_governor_new(two_process_parameters(1, 2, 3, 0, 100, -100), Governor0),
    % Step the governor three ticks under the online state.
    two_process_governor_step(Governor0, online, Governor1, _StateA),
    % The second step.
    two_process_governor_step(Governor1, online, Governor2, _StateB),
    % The third step completes one whole day.
    two_process_governor_step(Governor2, online, Governor3, _StateC),
    % Read the phase after one whole day.
    two_process_governor_phase(Governor3, Phase),
    % Confirm the clock wrapped back to midnight.
    assertion(Phase =:= 0).

% The circadian drive is the day wave: zero at midnight, the full amplitude at midday.
test(circadian_drive_is_the_day_wave) :-
    % Build a governor with amplitude six over a twelve-tick day.
    two_process_governor_new(two_process_parameters(1, 2, 12, 6, 100, -100), Governor0),
    % Read the drive at midnight, phase zero.
    two_process_governor_circadian_drive(Governor0, MidnightDrive),
    % Confirm the alerting wave is silent at midnight.
    assertion(MidnightDrive =:= 0),
    % Step the governor six ticks to midday.
    two_process_governor_step(Governor0, online, Governor1, _A),
    % The second step.
    two_process_governor_step(Governor1, online, Governor2, _B),
    % The third step.
    two_process_governor_step(Governor2, online, Governor3, _C),
    % The fourth step.
    two_process_governor_step(Governor3, online, Governor4, _D),
    % The fifth step.
    two_process_governor_step(Governor4, online, Governor5, _E),
    % The sixth step reaches midday.
    two_process_governor_step(Governor5, online, Governor6, _F),
    % Read the drive at midday.
    two_process_governor_circadian_drive(Governor6, MiddayDrive),
    % Confirm the alerting wave peaks at the full amplitude at midday.
    assertion(MiddayDrive =:= 6).

% Below the sleep threshold the switch holds online: a small debt does not flip the day.
test(holds_online_below_sleep_threshold) :-
    % Make a fresh governor with the default parameters.
    two_process_governor_new(Governor0),
    % Step it once under the online state.
    two_process_governor_step(Governor0, online, _Governor, State),
    % Confirm one tick of debt leaves the switch online.
    assertion(State == online).

% When the pressure less the circadian drive reaches the sleep threshold, the switch snaps offline.
test(flips_offline_when_debt_beats_the_day_wave) :-
    % Build a governor one step short of the flip: threshold three, no circadian opposition.
    two_process_governor_new(two_process_parameters(1, 2, 24, 0, 3, 0), Governor0),
    % The first waking step, debt one, holds online.
    two_process_governor_step(Governor0, online, Governor1, StateA),
    % Confirm the switch still holds.
    assertion(StateA == online),
    % The second waking step, debt two, still holds online.
    two_process_governor_step(Governor1, online, Governor2, StateB),
    % Confirm the switch still holds.
    assertion(StateB == online),
    % The third waking step raises the debt to the threshold of three.
    two_process_governor_step(Governor2, online, _Governor3, StateC),
    % Confirm the switch snapped offline.
    assertion(StateC == offline).

% The circadian opposition is real: the same debt that flips the night holds the evening awake.
test(day_wave_opposes_the_same_debt) :-
    % Build a governor whose day wave can fully cover the sleep threshold at midday.
    two_process_governor_new(two_process_parameters(3, 2, 4, 6, 3, 0), Governor0),
    % One waking step moves the clock to phase one of a four-tick day and the debt to three.
    two_process_governor_step(Governor0, online, _Governor1, State),
    % At phase one of a four-tick day the wave stands at three, holding the three-point debt at bay.
    assertion(State == online),
    % Build the night twin: the same rates and thresholds with the day wave silenced.
    two_process_governor_new(two_process_parameters(3, 2, 4, 0, 3, 0), NightGovernor0),
    % The same single waking step under a silent wave.
    two_process_governor_step(NightGovernor0, online, _NightGovernor1, NightState),
    % Without the opposing wave the same debt flips the switch offline.
    assertion(NightState == offline).

% Between the two thresholds the switch holds its current state: the hysteresis band is the snap's memory.
test(hysteresis_band_holds_the_current_state) :-
    % Build a governor with a sleep threshold of five and a wake threshold of one.
    two_process_governor_new(two_process_parameters(1, 1, 24, 0, 5, 1), Governor0),
    % Three waking steps raise the debt to three, inside the band.
    two_process_governor_step(Governor0, online, Governor1, _A),
    % The second step.
    two_process_governor_step(Governor1, online, Governor2, _B),
    % The third step leaves the debt at three, between one and five.
    two_process_governor_step(Governor2, online, Governor3, _C),
    % A fourth online step moves the debt to four, still inside the band.
    two_process_governor_step(Governor3, online, _Governor4, OnlineState),
    % An online governor inside the band stays online.
    assertion(OnlineState == online),
    % The same three-point debt carried by a sleeping governor discharges to two, still inside the band.
    two_process_governor_step(Governor3, offline, _Governor5, OfflineState),
    % An offline governor inside the band stays offline: the same numbers, two answers, one memory.
    assertion(OfflineState == offline).

% Once the debt is paid below the wake threshold, the switch snaps back online: morning comes.
test(flips_online_when_the_debt_is_paid) :-
    % Build a governor with a wake threshold of two and a discharge of two.
    two_process_governor_new(two_process_parameters(1, 2, 24, 0, 4, 2), Governor0),
    % Four waking steps raise the debt to four, snapping the switch offline.
    two_process_governor_step(Governor0, online, Governor1, _A),
    % The second step.
    two_process_governor_step(Governor1, online, Governor2, _B),
    % The third step.
    two_process_governor_step(Governor2, online, Governor3, _C),
    % The fourth step reaches the sleep threshold.
    two_process_governor_step(Governor3, online, Governor4, StateD),
    % Confirm the night began.
    assertion(StateD == offline),
    % One sleeping step pays the debt down to two, the wake threshold.
    two_process_governor_step(Governor4, offline, _Governor5, StateE),
    % Confirm the morning came.
    assertion(StateE == online).

% The default governor lives the corpus's day: long consolidated waking, then a consolidated night.
test(default_governor_lives_a_consolidated_day) :-
    % Make a fresh governor with the default parameters.
    two_process_governor_new(Governor0),
    % Walk it through thirty ticks, always feeding back the state it last selected.
    two_process_governor_walk(30, Governor0, online, States),
    % The walk must contain both positions: the day ends and the night ends.
    assertion(memberchk(offline, States)),
    % The switch must snap, never chatter: the thirty ticks hold exactly two transitions.
    two_process_governor_walk_transitions(States, online, Transitions),
    % One fall into sleep and one rise into morning is a consolidated day.
    assertion(Transitions =:= 2).

% An unbound governor cannot be judged and is refused aloud, never silently bound.
test(unbound_governor_is_refused, [throws(error(instantiation_error, _))]) :-
    % Step an unbound governor, which must throw rather than invent one.
    two_process_governor_step(_Governor0, online, _Governor, _State).

% An unbound operating state cannot be judged and is refused aloud, never silently bound.
test(unbound_state_is_refused, [throws(error(instantiation_error, _))]) :-
    % Make a fresh governor with the default parameters.
    two_process_governor_new(Governor0),
    % Step it under an unbound state, which must throw rather than invent a position.
    two_process_governor_step(Governor0, _State0, _Governor, _State).

% A third operating-state value is refused by the state's own name: the flip-flop has two positions.
test(third_state_value_is_refused, [throws(error(domain_error(two_process_governor_operating_state, drowsy), _))]) :-
    % Make a fresh governor with the default parameters.
    two_process_governor_new(Governor0),
    % Step it under a state the flip-flop does not have.
    two_process_governor_step(Governor0, drowsy, _Governor, _State).

% A governor carrying an unbound pressure is refused before any arithmetic pretends to judge it.
test(unbound_pressure_is_refused, [throws(error(instantiation_error, _))]) :-
    % Build a governor whose pressure is a hole where a number should be.
    two_process_governor_step(two_process_governor(_Pressure, 0, two_process_parameters(1, 2, 24, 4, 16, 2)), online, _Governor, _State).

% The discharge floor is not a short-circuit: an unbound discharge rate is refused even at pressure zero.
test(unbound_discharge_is_refused_even_at_the_floor, [throws(error(instantiation_error, _))]) :-
    % Build a governor at pressure zero whose discharge rate is a hole where a number should be.
    two_process_governor_step(two_process_governor(0, 0, two_process_parameters(1, _Discharge, 24, 4, 16, 2)), offline, _Governor, _State).

% An inverted hysteresis band is refused at build time: a wake threshold above the sleep threshold chatters.
test(inverted_hysteresis_is_refused, [throws(error(domain_error(two_process_governor_hysteresis, _), _))]) :-
    % Build a governor whose wake threshold stands above its sleep threshold.
    two_process_governor_new(two_process_parameters(1, 2, 24, 4, 2, 16), _Governor).

% A day length that is not a positive whole number of ticks is refused by name: a clock needs a day.
test(bad_day_length_is_refused, [throws(error(domain_error(two_process_governor_day_length, 0), _))]) :-
    % Build a governor whose day has no ticks at all.
    two_process_governor_new(two_process_parameters(1, 2, 0, 4, 16, 2), _Governor).

% REVIEW PIN (unbound-wrong-judgement lens): an unbound day length is a hole, refused as
% uninstantiated - never a domain refusal carrying the hole itself, because integer/1 fails silently.
test(unbound_day_length_is_refused_as_uninstantiated, [throws(error(instantiation_error, _))]) :-
    % Build a governor whose day length is a hole where a whole number of ticks should stand.
    two_process_governor_new(two_process_parameters(1, 2, _DayLength, 4, 16, 2), _Governor).

% REVIEW PIN (the review's second note, kept honest): a hand-built governor with a fractional phase
% is outside every public constructor's reach, and it still dies ALOUD - in mod's own typed refusal -
% never silently; this pin records that the loudness is relied upon, not accidental.
test(fractional_phase_dies_aloud, [throws(error(type_error(integer, _), _))]) :-
    % Step a hand-built governor whose phase is a fraction no clock of whole ticks can reach.
    two_process_governor_step(two_process_governor(0, 0.5, two_process_parameters(1, 2, 24, 4, 16, 2)), online, _Governor, _State).

% Close the test block for the two_process_governor pack.
% ---------------------------------------------------------------------------
% SLICE 47 - THE FLIP-FLOP AS A REGISTER, AND THE FIRST CALLER WIRED TO A WATCHDOG
% ---------------------------------------------------------------------------

% two_process_governor_test_run(+Ticks, -History): run a real governor and record every pole it
% stood at, one observation per tick, into a real watchdog history. THIS IS THE WIRING, and every
% test below drives it rather than a fixture, so what is proved is the running machine.
two_process_governor_test_run(Ticks, History) :-
    % A real governor with the corpus-shaped defaults.
    two_process_governor_new(Governor),
    % A real, empty watchdog history.
    watchdog_history_new(Empty),
    % Run the day, recording as it goes, starting awake as the bus's default has since slice 35.
    two_process_governor_test_step(1, Ticks, Governor, online, Empty, History).

% two_process_governor_test_step(+Tick, +Ticks, +Governor0, +State0, +History0, -History): one tick.
% The run ends when the last tick has been recorded.
two_process_governor_test_step(Tick, Ticks, _Governor, _State, History, History) :-
    % Past the end of the run, hand the history back as it stands.
    Tick > Ticks,
    % And commit to this clause rather than also trying the next.
    !.
% Each tick advances the governor and records the pole it settled at.
two_process_governor_test_step(Tick, Ticks, Governor0, State0, History0, History) :-
    % Advance both processes one tick and let the flip-flop select.
    two_process_governor_step(Governor0, State0, Governor, State),
    % Record the pole it settled at, at this tick, in the real history.
    watchdog_observe(History0, Tick, State, History1),
    % Advance the tick.
    Next is Tick + 1,
    % And run the rest of the day.
    two_process_governor_test_step(Next, Ticks, Governor, State, History1, History).

% The register is two, and the corpus's Entry 11 says it is two: exactly two stable positions, and
% the middle forbidden.
test(the_flip_flop_register_is_two_and_never_three) :-
    % Read the size from the register rather than from a restated number.
    two_process_governor_size(Size),
    % Which is two.
    Size == 2,
    % And the two poles are the two the bus has carried since slice 35, unchanged.
    two_process_governor_modes(Modes),
    % In Entry 11's own order: the wake pole, then the sleep pole.
    Modes == [online, offline].

% NEITHER CROSSING IS SELF-SELECTED, and that is Entry 11's own sharpest sentence made checkable:
% the crossings are thrown by Process S and Process C, NOT INTERNAL TO THE SWITCH.
test(neither_crossing_is_self_selected) :-
    % Read the transition table.
    two_process_governor_transitions(Rows),
    % It is not empty, so the check below cannot pass vacuously.
    Rows \== [],
    % And no row anywhere carries the self_selected agency - the switch does not decide, it is decided.
    forall(member(transition(_T, _F, _To, _Ts, Agency), Rows), Agency \== self_selected).

% The fault block is the corpus's, and it carries the stabiliser as its watchdog - which names the
% pack konnectome built at slice 44 rather than a hope.
test(the_fault_block_names_the_stabiliser_as_its_watchdog) :-
    % Read the fault block.
    two_process_governor_faults(Faults),
    % Both regimes are watched by the construct Entry 11 and Chapter 13 name.
    Faults == [fault(state_chatter, switch_flipping_more_often_than_a_day_allows, stabiliser),
               fault(state_locked, pole_held_longer_than_a_whole_day, stabiliser)].

% AND NEITHER SIGNATURE IS A POLE NAME, checked by the supervisor's own directive rather than by eye.
test(the_governors_faults_are_not_its_modes) :-
    % Build the automaton at the wake pole.
    two_process_governor_automaton(online, Automaton),
    % The supervisor's directive holds, so this register may be watched at all.
    supervisor_faults_are_not_modes(Automaton).

% A third pole is refused when an automaton is asked for, through the governor's own domain.
test(an_automaton_at_a_third_pole_is_refused,
     throws(error(domain_error(two_process_governor_operating_state, drowsing), _))) :-
    % A position the flip-flop does not have cannot be stood at.
    two_process_governor_automaton(drowsing, _Automaton).

% DECISION-6: THE WINDOW IS THE GOVERNOR'S OWN DAY, READ FROM ITS PARAMETERS AND NOT A CONSTANT.
test(the_window_is_the_governors_own_day) :-
    % A governor with the corpus-shaped defaults, whose day is twenty-four ticks.
    two_process_governor_new(Governor),
    % The window is that day.
    two_process_governor_watch_window(Governor, Window),
    % Which is twenty-four.
    Window == 24.

% AND THE WINDOW MOVES WITH THE DAY, which is what makes it nobody's invented number. A governor
% given a shorter day is watched over a shorter window, in the same tick, with no constant to drift.
test(the_window_moves_with_the_day) :-
    % A governor with a twelve-tick day rather than the default twenty-four.
    two_process_governor_new(two_process_parameters(1, 2, 12, 4, 16, 2), Governor),
    % The window follows it exactly.
    two_process_governor_watch_window(Governor, Window),
    % Which is twelve.
    Window == 12,
    % And so does the lock allowance, which is the largest hold that is not a whole day.
    two_process_governor_watch_allowances(Governor, Chatter, Lock),
    % The chatter allowance is two crossings, because a healthy day contains two whatever its length.
    Chatter == 2,
    % And the lock allowance is eleven.
    Lock == 11.

% THE SLICE'S CENTRAL TEST. A REAL governor runs a REAL day into a REAL history, and the REAL
% supervisor reports it healthy - nothing warned, and NOTHING UNWATCHED. That last block being empty
% is the sentence the running machine could not say before this slice.
test(a_real_governor_running_a_real_day_is_watched_and_clean) :-
    % Run a full day of the real scheduler, recording the pole at every tick.
    two_process_governor_test_run(24, History),
    % A real governor to supply the window and the allowances from its own parameters.
    two_process_governor_new(Governor),
    % Judge it, end to end, through the watchdog and the supervisor.
    two_process_governor_watch(Governor, History, Report),
    % No boundary was crossed, so nothing is warned about.
    supervisor_report_warnings(Report, []),
    % AND NOTHING IS UNWATCHED. The running machine is now watched.
    supervisor_report_unwatched(Report, []).

% THE HEALTHY DAY SITS AT ITS ALLOWANCE RATHER THAN COMFORTABLY INSIDE IT, and that is checked
% because it is the difference between an allowance that means something and one that is merely
% generous. A day of this governor contains at most two crossings, which is exactly what the corpus
% says a healthy day contains.
test(a_healthy_day_contains_at_most_the_allowed_two_crossings) :-
    % Run a day and a half, so that a window ending anywhere in it is a genuine trailing window.
    two_process_governor_test_run(36, History),
    % Count the crossings over the trailing day.
    watchdog_flips_in_window(History, 24, Flips),
    % Which is at most the two a healthy day contains.
    Flips =< 2.

% AND THE HISTORY IS TOO SHORT AT FIRST, WHICH THE MACHINE REPORTS RATHER THAN GLOSSES. Four ticks
% into its first day, the governor's boundaries are UNWATCHED by name - not clean.
test(a_governor_four_ticks_into_its_first_day_is_unwatched_not_clean) :-
    % Four ticks of a real run, against a twenty-four-tick window.
    two_process_governor_test_run(4, History),
    % A real governor.
    two_process_governor_new(Governor),
    % Judged end to end.
    two_process_governor_watch(Governor, History, Report),
    % Nothing is warned about, because nothing could honestly be measured.
    supervisor_report_warnings(Report, []),
    % And both regimes are reported unwatched, by name, with the stabiliser named as the watchdog
    % that did not report - which is DECISION-4's second half reaching the running machine.
    supervisor_report_unwatched(Report, Unwatched),
    % Exactly the two regimes Entry 11 supplies.
    Unwatched == [supervisor_unwatched(state_chatter, stabiliser),
                  supervisor_unwatched(state_locked, stabiliser)].

% A CHATTERING SWITCH IS WARNED ABOUT, under this governor's own boundary name. The history is
% constructed rather than run, because a governor that chatters is one konnectome does not have -
% which is the point: the watchdog exists to notice a fault the machine is not currently committing.
test(a_chattering_switch_is_warned_about) :-
    % Twenty-four ticks alternating every tick, which is twenty-three crossings in one day.
    numlist(1, 24, Ticks),
    % Build the history by hand, alternating poles.
    foldl([Tick, History0, History]>>(
              ( 0 is Tick mod 2 -> Pole = online ; Pole = offline ),
              watchdog_observe(History0, Tick, Pole, History)
          ), Ticks, [], History),
    % A real governor to supply the window and the allowances.
    two_process_governor_new(Governor),
    % Judged end to end.
    two_process_governor_watch(Governor, History, Report),
    % The chatter boundary is warned about, carrying Entry 11's condition and the stabiliser's name.
    supervisor_report_warnings(Report, Warnings),
    % Twenty-three crossings against an allowance of two.
    Warnings == [supervisor_warning(state_chatter,
                                    switch_flipping_more_often_than_a_day_allows,
                                    stabiliser,
                                    23, 2)],
    % And nothing is unwatched, because both regimes were read.
    supervisor_report_unwatched(Report, []).

% A LOCKED SWITCH IS WARNED ABOUT, which is the opposite failure and the one Entry 11 names in both
% directions at once.
test(a_locked_switch_is_warned_about) :-
    % Twenty-four ticks all at the sleep pole, which is a whole day in which waking never won.
    numlist(1, 24, Ticks),
    % Build the history by hand, never leaving the pole.
    foldl([Tick, History0, History]>>watchdog_observe(History0, Tick, offline, History),
          Ticks, [], History),
    % A real governor to supply the window and the allowances.
    two_process_governor_new(Governor),
    % Judged end to end.
    two_process_governor_watch(Governor, History, Report),
    % The lock boundary is warned about, carrying twenty-four ticks held against twenty-three allowed.
    supervisor_report_warnings(Report, Warnings),
    % Exactly one warning, because a locked switch crosses no chatter boundary.
    Warnings == [supervisor_warning(state_locked,
                                    pole_held_longer_than_a_whole_day,
                                    stabiliser,
                                    24, 23)],
    % And nothing is unwatched.
    supervisor_report_unwatched(Report, []).

% A history standing at a pole the flip-flop does not have is refused, rather than judged.
test(a_history_at_a_third_pole_is_refused,
     throws(error(domain_error(two_process_governor_operating_state, drowsing), _))) :-
    % A single observation at a position the switch cannot occupy.
    watchdog_observe([], 1, drowsing, History),
    % A real governor.
    two_process_governor_new(Governor),
    % Which cannot be judged standing nowhere.
    two_process_governor_watch(Governor, History, _Report).

% An empty history is refused rather than judged as a machine standing nowhere.
test(an_empty_history_is_refused,
     throws(error(domain_error(two_process_governor_watched_history, []), _))) :-
    % A real governor.
    two_process_governor_new(Governor),
    % With nothing recorded about it at all.
    two_process_governor_watch(Governor, [], _Report).

% THE STEP IS UNTOUCHED, AND THIS IS THE BEHAVIOUR-PINNED-IDENTICAL PROMISE MADE CHECKABLE. Every
% predicate this slice added is a READ; none of them is consulted by the step, and a day run today is
% the day this governor has run since slice 37.
test(the_watched_day_is_the_same_day_the_governor_has_always_run) :-
    % Run a day and read back the poles in order.
    two_process_governor_test_run(24, History),
    % Reverse it into tick order, since a history is held newest first.
    reverse(History, InOrder),
    % The day is consolidated: a long waking, then a night, exactly as slice 37 built it.
    InOrder = [observation(1, online)|_Rest],
    % Seventeen ticks of waking before the switch snaps, unchanged by anything in this slice.
    nth1(17, InOrder, observation(17, online)),
    % And the eighteenth tick is the night.
    nth1(18, InOrder, observation(18, offline)).

% A parameter block of the wrong shape entirely is refused by the governor's own name, because the six
% parameters are read out of fixed places and a term of another shape would have no places to read.
test(a_parameter_block_of_the_wrong_shape_is_refused,
     [throws(error(domain_error(two_process_governor_parameters, mystery), _))]) :-
    % Build a governor on a bare atom where the six-field parameter block must stand.
    two_process_governor_new(mystery, _Governor).

:- end_tests(two_process_governor).

% two_process_governor_walk(+Ticks, +Governor, +State, -States): walk the governor, feeding back each selection.
two_process_governor_walk(0, _Governor, _State, []) :-
    % A walk of zero ticks selects nothing.
    !.
% The recursive case steps once and walks the rest.
two_process_governor_walk(Ticks, Governor0, State0, [State|States]) :-
    % Step the governor once under the state it last selected.
    two_process_governor_step(Governor0, State0, Governor, State),
    % One tick has been walked.
    Remaining is Ticks - 1,
    % Walk the remaining ticks from the new governor under the new state.
    two_process_governor_walk(Remaining, Governor, State, States).

% two_process_governor_walk_transitions(+States, +StartState, -Count): count the state changes along a walk.
two_process_governor_walk_transitions([], _Previous, 0).
% The recursive case compares each selection with the one before it.
two_process_governor_walk_transitions([State|States], Previous, Count) :-
    % Count the rest of the walk from this state.
    two_process_governor_walk_transitions(States, State, Rest),
    % A changed selection is one transition; an unchanged one is none.
    ( State == Previous -> Count = Rest ; Count is Rest + 1 ).

% Import memberchk for the consolidated-day telling.
:- use_module(library(lists), [memberchk/2]).


