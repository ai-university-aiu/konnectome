% Declare this file as the 'two_process_governor' module and list the predicates it exports.
:- module(two_process_governor, [
    % two_process_governor_new/1: a fresh governor at midnight with no debt and the corpus-shaped defaults.
    two_process_governor_new/1,
    % two_process_governor_new/2: a fresh governor at midnight with no debt and the caller's parameters.
    two_process_governor_new/2,
    % two_process_governor_pressure/2: read the governor's standing sleep pressure, Process S.
    two_process_governor_pressure/2,
    % two_process_governor_phase/2: read the governor's circadian phase, the clock behind Process C.
    two_process_governor_phase/2,
    % two_process_governor_circadian_drive/2: read the day wave's alerting drive at the current phase.
    two_process_governor_circadian_drive/2,
    % two_process_governor_step/4: advance both processes one tick and select the operating state.
    two_process_governor_step/4,
    % two_process_governor_day_length/2: read the governor's own day, in ticks, from its parameters.
    two_process_governor_day_length/2,
    % two_process_governor_register/1: the flip-flop's two poles, in the corpus's own three-field schema.
    two_process_governor_register/1,
    % two_process_governor_modes/1: the formal names of the two poles the flip-flop holds.
    two_process_governor_modes/1,
    % two_process_governor_size/1: how many poles the register holds - two, and never three.
    two_process_governor_size/1,
    % two_process_governor_transitions/1: the flip-flop's explicit transition table, both crossings.
    two_process_governor_transitions/1,
    % two_process_governor_faults/1: the flip-flop's fault regimes and watchdogs, from the corpus.
    two_process_governor_faults/1,
    % two_process_governor_automaton/2: this governor's hybrid automaton, standing at a given pole.
    two_process_governor_automaton/2,
    % two_process_governor_watch_window/2: the window a watchdog measures this governor over - its own day.
    two_process_governor_watch_window/2,
    % two_process_governor_watch_allowances/3: the two allowances, both derived from the governor's day.
    two_process_governor_watch_allowances/3,
    % two_process_governor_watch/3: the join - a history of poles judged into a supervisor's report.
    two_process_governor_watch/3
]).

% Import membership for judging the two flip-flop positions.
:- use_module(library(lists), [memberchk/2]).
% Import the hybrid automaton, so the flip-flop's poles are held in the corpus's own term rather than
% beside it - the same constructor every register in this repository has used since slice 39.
:- use_module(library(mode_register), [
    % mode_register_new/6: build and judge one construct's hybrid automaton.
    mode_register_new/6
]).
% Import the watchdog, which is what supplies the readings this governor's boundaries are judged on.
:- use_module(library(watchdog), [
    % watchdog_gate_readings/6: two boundaries read from a windowed history - flips, and ticks held.
    watchdog_gate_readings/6
]).
% Import the supervisor, which judges the readings and publishes the warnings.
:- use_module(library(supervisor), [
    % supervisor_watch/3: judge one construct's fault block against the watchdogs' readings.
    supervisor_watch/3
]).

% The two-process governor is the Layer 11 state machinery's scheduler (Chapters 11, 14, and 15):
% Process S, the homeostatic sleep pressure, a debt that rises one rate per waking tick and is
% paid down by a steeper rate per sleeping tick, floored at zero (Chapter 14, the rising bill);
% and Process C, the circadian drive, a day wave that rises from midnight to a midday peak and
% falls back, opposing the debt so alertness can be high exactly when the debt is greatest
% (Chapter 15, the day wave, realized here as a triangle wave - an honest simplification of the
% corpus's smooth waveform that keeps every number a glass-box ratio). The selection is the
% sleep-wake flip-flop of Chapter 11: when the pressure less the drive reaches the sleep
% threshold the switch snaps offline, and only when the paid-down pressure less the drive falls
% to the wake threshold does it snap back online. The two thresholds are deliberately far apart:
% the hysteresis band between them is the stabiliser of Chapter 13 in its simplest form, the
% finger on the switch that keeps a mid-band debt from chattering the state. The governor never
% touches the bus itself: it subscribes to the current selection and publishes the next one to
% its caller, and the tick - the loop that owns the bus - does the announcing (Chapter 16).
% The default parameters live the corpus's day at one tick per hour: a rise of one against a
% discharge of two over a twenty-four-tick day, an amplitude of four, and thresholds of sixteen
% and two, giving a long consolidated waking and a consolidated night, roughly sixteen and eight.

% two_process_governor_default_parameters(-Parameters): the corpus-shaped defaults, one tick per hour.
two_process_governor_default_parameters(two_process_parameters(1, 2, 24, 4, 16, 2)).

% two_process_governor_check_number(+Value): refuse a hole or a non-number where a number must stand.
two_process_governor_check_number(Value) :-
    % An unbound value cannot be judged, and must never be silently bound by the arithmetic below.
    (  var(Value)
    -> throw(error(instantiation_error, _))
    % Every process variable and rate is a plain number.
    ;  number(Value)
    -> true
    % Anything else is refused aloud before any arithmetic pretends to judge it.
    ;  throw(error(type_error(number, Value), _))
    ).

% two_process_governor_check_parameters(+Parameters): refuse a parameter block the day cannot run on.
two_process_governor_check_parameters(Parameters) :-
    % An unbound block cannot be judged, and must never be silently bound into an invented day.
    (  var(Parameters)
    -> throw(error(instantiation_error, _))
    ;  true
    ),
    % The block carries the six whole-word parameters in their fixed places.
    (  Parameters = two_process_parameters(PressureRise, PressureDischarge, DayLength, CircadianAmplitude, SleepThreshold, WakeThreshold)
    -> true
    % A block of any other shape is refused by the governor's own name.
    ;  throw(error(domain_error(two_process_governor_parameters, Parameters), _))
    ),
    % The rise of the debt is a number.
    two_process_governor_check_number(PressureRise),
    % The discharge of the debt is a number.
    two_process_governor_check_number(PressureDischarge),
    % The day wave's amplitude is a number.
    two_process_governor_check_number(CircadianAmplitude),
    % The sleep threshold is a number.
    two_process_governor_check_number(SleepThreshold),
    % The wake threshold is a number.
    two_process_governor_check_number(WakeThreshold),
    % REVIEW FIX (unbound-wrong-judgement lens, the fifth slice running): integer/1 fails SILENTLY on a
    % hole, so an unbound day length used to fall through to the domain refusal carrying the hole
    % itself; a hole where a value should be is refused as uninstantiated, like every other field.
    (  var(DayLength)
    -> throw(error(instantiation_error, _))
    ;  true
    ),
    % A clock needs a day: the day length is a positive whole number of ticks, refused by name otherwise.
    (  integer(DayLength), DayLength > 0
    -> true
    ;  throw(error(domain_error(two_process_governor_day_length, DayLength), _))
    ),
    % An inverted band chatters: the wake threshold must sit strictly below the sleep threshold.
    (  WakeThreshold < SleepThreshold
    -> true
    % The refusal names the band, so a chattering governor can never be built in silence.
    ;  throw(error(domain_error(two_process_governor_hysteresis, WakeThreshold-SleepThreshold), _))
    ).

% two_process_governor_check_governor(+Governor): refuse a governor the step cannot judge.
two_process_governor_check_governor(Governor) :-
    % An unbound governor cannot be judged, and must never be silently bound into an invented one.
    (  var(Governor)
    -> throw(error(instantiation_error, _))
    ;  true
    ),
    % The governor carries its pressure, its phase, and its parameter block in their fixed places.
    (  Governor = two_process_governor(Pressure, Phase, Parameters)
    -> true
    % A term of any other shape is refused by the governor's own name.
    ;  throw(error(domain_error(two_process_governor, Governor), _))
    ),
    % The standing pressure is a number.
    two_process_governor_check_number(Pressure),
    % The phase is a number.
    two_process_governor_check_number(Phase),
    % The parameter block is judged whole, so every rate is a number before any path can shortcut it.
    two_process_governor_check_parameters(Parameters).

% two_process_governor_check_operating_state(+State): refuse anything but the two flip-flop positions.
two_process_governor_check_operating_state(State) :-
    % An unbound state cannot be judged, and must be refused before any wrong pretends to name it.
    (  var(State)
    -> throw(error(instantiation_error, _))
    % The flip-flop has exactly two positions and spends no time halfway; both are plain atoms.
    ;  memberchk(State, [online, offline])
    -> true
    % A third value is refused aloud, by the governor's own name, so no halfway state can ride in.
    ;  throw(error(domain_error(two_process_governor_operating_state, State), _))
    ).

% two_process_governor_new(-Governor): a fresh governor at midnight with no debt, on the defaults.
two_process_governor_new(Governor) :-
    % Take the corpus-shaped default parameters.
    two_process_governor_default_parameters(Parameters),
    % Build the fresh governor on them.
    two_process_governor_new(Parameters, Governor).

% two_process_governor_new(+Parameters, -Governor): a fresh governor at midnight with no debt.
two_process_governor_new(Parameters, Governor) :-
    % Refuse a parameter block the day cannot run on before any governor carries it.
    two_process_governor_check_parameters(Parameters),
    % The day begins at midnight, phase zero, with the whole debt paid.
    Governor = two_process_governor(0, 0, Parameters).

% two_process_governor_pressure(+Governor, -Pressure): read the standing sleep pressure, Process S.
two_process_governor_pressure(Governor, Pressure) :-
    % Refuse a governor the read cannot judge.
    two_process_governor_check_governor(Governor),
    % The pressure sits in the governor's first place.
    Governor = two_process_governor(Pressure, _Phase, _Parameters).

% two_process_governor_phase(+Governor, -Phase): read the circadian phase, the clock behind Process C.
two_process_governor_phase(Governor, Phase) :-
    % Refuse a governor the read cannot judge.
    two_process_governor_check_governor(Governor),
    % The phase sits in the governor's second place.
    Governor = two_process_governor(_Pressure, Phase, _Parameters).

% two_process_governor_wave(+Phase, +DayLength, +Amplitude, -Drive): the triangle day wave.
two_process_governor_wave(Phase, DayLength, Amplitude, Drive) :-
    % Midday is half the day from midnight.
    HalfDay is DayLength / 2,
    % The wave falls linearly with the distance from midday.
    DistanceFromMidday is abs(Phase - HalfDay),
    % Zero at midnight, the full amplitude at midday, and straight lines between.
    Drive is Amplitude * (HalfDay - DistanceFromMidday) / HalfDay.

% two_process_governor_circadian_drive(+Governor, -Drive): the day wave's drive at the current phase.
two_process_governor_circadian_drive(Governor, Drive) :-
    % Refuse a governor the read cannot judge.
    two_process_governor_check_governor(Governor),
    % Unpack the phase and the wave's shape.
    Governor = two_process_governor(_Pressure, Phase, two_process_parameters(_Rise, _Discharge, DayLength, Amplitude, _Sleep, _Wake)),
    % Read the wave at this phase.
    two_process_governor_wave(Phase, DayLength, Amplitude, Drive).

% two_process_governor_next_pressure(+State, +Pressure, +Rise, +Discharge, -Next): the debt's one tick.
% A waking tick adds the rise: the bill climbs while awake (Chapter 14).
two_process_governor_next_pressure(online, Pressure, Rise, _Discharge, Next) :-
    % One tick of waking adds exactly one rise.
    Next is Pressure + Rise.
% A sleeping tick pays the discharge, and the debt never goes below zero.
two_process_governor_next_pressure(offline, Pressure, _Rise, Discharge, Next) :-
    % The floor at zero is not a shortcut: the subtraction is judged even when the floor answers.
    Next is max(0, Pressure - Discharge).

% two_process_governor_select(+State, +Balance, +SleepThreshold, +WakeThreshold, -Selection): the flip-flop.
% An online switch snaps offline only when the debt's balance reaches the sleep threshold (Chapter 11).
two_process_governor_select(online, Balance, SleepThreshold, _WakeThreshold, Selection) :-
    % Inside the hysteresis band the switch holds; at or past the threshold it snaps.
    ( Balance >= SleepThreshold -> Selection = offline ; Selection = online ).
% An offline switch snaps online only when the paid-down balance falls to the wake threshold.
two_process_governor_select(offline, Balance, _SleepThreshold, WakeThreshold, Selection) :-
    % Inside the hysteresis band the switch holds; at or below the threshold morning comes.
    ( Balance =< WakeThreshold -> Selection = online ; Selection = offline ).

% two_process_governor_step(+Governor0, +State0, -Governor, -State): one tick of the whole scheduler.
two_process_governor_step(Governor0, State0, Governor, State) :-
    % Refuse a governor the step cannot judge, every field a bound number, on every path.
    two_process_governor_check_governor(Governor0),
    % Refuse an unbound state or a third position before either process moves.
    two_process_governor_check_operating_state(State0),
    % Unpack the governor's two process variables and its day's shape.
    Governor0 = two_process_governor(Pressure0, Phase0, Parameters),
    % Unpack the six parameters.
    Parameters = two_process_parameters(PressureRise, PressureDischarge, DayLength, CircadianAmplitude, SleepThreshold, WakeThreshold),
    % Process S moves: the debt rises through waking and is paid down through sleep, floored at zero.
    two_process_governor_next_pressure(State0, Pressure0, PressureRise, PressureDischarge, Pressure),
    % Process C moves: the clock advances one tick and wraps at the day length.
    Phase is (Phase0 + 1) mod DayLength,
    % Read the day wave's alerting drive at the new phase.
    two_process_governor_wave(Phase, DayLength, CircadianAmplitude, Drive),
    % The balance the flip-flop judges is the debt less the drive set against it (Chapter 15's opposition).
    Balance is Pressure - Drive,
    % The flip-flop selects: snap past a threshold, hold inside the hysteresis band (Chapters 11 and 13).
    two_process_governor_select(State0, Balance, SleepThreshold, WakeThreshold, State),
    % Commit the advanced governor.
    Governor = two_process_governor(Pressure, Phase, Parameters).

% ---------------------------------------------------------------------------
% THE FLIP-FLOP AS A REGISTER, AND THE FIRST CALLER EVER WIRED TO A WATCHDOG
% (konnectome build slice 47)
% ---------------------------------------------------------------------------
%
% THIS SECTION EXISTS TO PAY A DEBT SLICE 45 LEFT IN THE OPEN. Slice 45 built the first watchdog and
% wired it to nobody, and said so: nothing in the running machine kept a history, so the capability
% was proved in a test suite and absent from the machine. It also declined to choose a WINDOW LENGTH,
% recorded as DECISION-4, on the ground that the caller who owns a watchdog owns its numbers - and
% named the consequence plainly: the first slice that joins a real construct to a real watchdog must
% choose a window and say why. THIS IS THAT SLICE, AND THIS GOVERNOR IS THAT CALLER.
%
% WHY THIS CONSTRUCT AND NOT ANOTHER, WHICH IS THE FIRST THING THAT HAD TO BE DECIDED. The watchdog's
% two boundaries came from the Layer 8 modes volume's Entry 36, the mutual-inhibition flip-flop.
% konnectome has TWO constructs answering to that entry: the gate archetype, validated against it
% block by block at slice 40, and THIS GOVERNOR, which is the same motif installed at whole-organism
% scale and which the corpus catalogues separately as Layer 11's Entry 11, the sleep-wake flip-flop.
% THE GOVERNOR IS THE RIGHT FIRST CALLER AND THE GATE IS NOT, for one reason that decides it: THE
% GOVERNOR HAS A CYCLE OF ITS OWN AND THE GATE DOES NOT. A window is a duration, and a duration is
% only meaningful against something; the gate archetype is generic and is installed wherever a world
% wants one, with no timescale of its own to measure against, which is exactly why slice 45 could
% find no honest window for it. The governor carries a DAY LENGTH in its own parameter block.
%
% THE REGISTER IS VALIDATED AGAINST LAYER 11's ENTRY 11, BLOCK BY BLOCK, in the discipline slice 40
% established for the gate. Entry 11's own opening sentence is the one that made this safe to build:
% "this is a governor, not a state, and by design it has exactly two stable positions and forbids the
% middle". konnectome's selection rule has forbidden the middle since slice 37.
%
% ONE DIVERGENCE FROM THE CORPUS ENTRY IS RECORDED RATHER THAN SMOOTHED OVER, and it costs a fault
% regime. Entry 11's boundary signature is "time spent in the contested mid-band the design exists to
% forbid". KONNECTOME'S FLIP-FLOP HAS NO MID-BAND TIME TO SPEND: its selection is a comparison that
% returns one of two atoms in the same tick, so there is no third condition it could linger in and
% nothing to measure. That regime is therefore NOT declared here, deliberately, because a fault block
% listing a boundary nothing can ever cross would report it UNWATCHED forever and would teach every
% reader that this governor has an unwatched fault when it has no such regime at all. The two regimes
% that ARE declared are the two Entry 11's warning condition names - a side that cannot HOLD, and a
% switch that CHATTERS - and both are measurable from a history of poles.

% two_process_governor_day_length(+Governor, -DayLength): the governor's own day, in ticks.
two_process_governor_day_length(Governor, DayLength) :-
    % Refuse a governor whose fields cannot be judged before reading a day out of it.
    two_process_governor_check_governor(Governor),
    % Unpack the parameter block, which has carried the day length since slice 37.
    Governor = two_process_governor(_Pressure, _Phase, Parameters),
    % The day length is the third parameter, read from the one place it lives.
    Parameters = two_process_parameters(_Rise, _Discharge, DayLength, _Amplitude, _Sleep, _Wake).

% The two poles, in Entry 11's own order, with Entry 11's own coined names carried as formal names.
% The wake pole: the arousal nuclei winning, the whole organism assigned to the waking states.
two_process_governor_pole(online, 'The Toggle Up', 'runs the waking states while it holds').
% The sleep pole: the sleep-promoting side winning, the organism assigned to the sleep states.
two_process_governor_pole(offline, 'The Toggle Down', 'runs the sleep states while it holds').

% two_process_governor_register(-Entries): the flip-flop's two poles in the register's three fields.
two_process_governor_register(Entries) :-
    % Gather both poles in declaration order, which is Entry 11's own order.
    findall(mode_entry(Pole, Formal, Does),
            two_process_governor_pole(Pole, Formal, Does),
            Entries).

% two_process_governor_modes(-Modes): the formal names of the two poles the flip-flop holds.
two_process_governor_modes(Modes) :-
    % Gather the pole names alone, which is what a fault signature is judged against.
    findall(Pole, two_process_governor_pole(Pole, _Formal, _Does), Modes).

% two_process_governor_size(-Size): how many poles the register holds - two, and never three.
two_process_governor_size(Size) :-
    % Read the register and count it, rather than restating a number that could drift from it.
    two_process_governor_register(Entries),
    % The length is itself a statement: this register is two because the corpus's is two.
    length(Entries, Size).

% two_process_governor_transfer_row(-Pole, -Rule): what runs while each pole holds.
% At the wake pole the debt rises, which is Process S's waking half.
two_process_governor_transfer_row(online, pressure_rises).
% At the sleep pole the debt is paid down, which is Process S's sleeping half.
two_process_governor_transfer_row(offline, pressure_discharges).

% two_process_governor_transfers(-Transfers): the per-mode transfer block, one rule per pole.
two_process_governor_transfers(Transfers) :-
    % Gather both rules, keyed by the pole they hold under.
    findall(transfer(Pole, Rule), two_process_governor_transfer_row(Pole, Rule), Transfers).

% The transition table, both of Entry 11's crossings, each carrying trigger, direction, timescale and
% agency. THE AGENCY IS THE ENTRY'S OWN AND IT IS THE SHARPEST THING IN THIS BLOCK: Entry 11 says the
% crossings are "thrown by Process S and Process C, NOT INTERNAL TO THE SWITCH". So neither row's
% agency is self_selected - the switch does not decide, it is decided.
two_process_governor_transition_row(pressure_over_drive, online, offline, fast_and_complete, thrown_by_the_two_processes).
% And the return crossing, thrown by the same two processes, on the same timescale.
two_process_governor_transition_row(drive_over_pressure, offline, online, fast_and_complete, thrown_by_the_two_processes).

% two_process_governor_transitions(-Rows): the flip-flop's explicit transition table.
two_process_governor_transitions(Rows) :-
    % Gather both crossings in declaration order.
    findall(transition(Trigger, From, To, Timescale, Agency),
            two_process_governor_transition_row(Trigger, From, To, Timescale, Agency),
            Rows).

% The fault block, from Entry 11's own FAULT REGIMES AND WATCHDOGS section, and NOT from anywhere
% else. The watchdog named in both rows is the OREXIN STABILISER of the corpus's Chapter 13, which is
% the construct konnectome built as the stabiliser pack at slice 44 - so the watchdog field names a
% pack that exists rather than a hope.
% A switch that chatters, which Entry 11 attributes to the stabiliser's loss.
two_process_governor_fault_row(state_chatter, switch_flipping_more_often_than_a_day_allows, stabiliser).
% A side that cannot hold, which Entry 11 names in both directions at once.
two_process_governor_fault_row(state_locked, pole_held_longer_than_a_whole_day, stabiliser).

% two_process_governor_faults(-Faults): the flip-flop's fault regimes and watchdogs block.
two_process_governor_faults(Faults) :-
    % Gather both declared regimes in declaration order.
    findall(fault(Signature, Condition, Watchdog),
            two_process_governor_fault_row(Signature, Condition, Watchdog),
            Faults).

% two_process_governor_automaton(+CurrentPole, -Automaton): this governor's hybrid automaton.
two_process_governor_automaton(CurrentPole, Automaton) :-
    % Refuse an unbound pole or a third position through the governor's own long-standing domain,
    % rather than letting the register's constructor be the first thing to notice.
    two_process_governor_check_operating_state(CurrentPole),
    % Read the four blocks every governor of this kind shares.
    two_process_governor_register(Entries),
    % The per-pole transfer block.
    two_process_governor_transfers(Transfers),
    % The transition table, both crossings.
    two_process_governor_transitions(Rows),
    % And the fault block, which is no longer empty and never was empty here.
    two_process_governor_faults(Faults),
    % Build the automaton around the pole THIS governor stands at, judged by the constructor.
    mode_register_new(CurrentPole, Entries, Transfers, Rows, Faults, Automaton).

% ---------------------------------------------------------------------------
% THE WINDOW AND THE TWO ALLOWANCES - DECISION-6, TAKEN HERE
% ---------------------------------------------------------------------------
%
% THE WINDOW IS NOT A NUMBER. IT IS THE GOVERNOR'S OWN DAY, READ FROM ITS OWN PARAMETER BLOCK.
%
% That is the whole decision, and it is what makes it possible to choose a window at all without
% inventing one. Slice 45 searched the corpus for a window and found only Entry 36's "states last
% minutes to hours", refused it, and coined the sentence: A DEFAULT WITH A BORROWED WARRANT IS AN
% INVENTED NUMBER THAT HAS LEARNED TO CITE. The refusal was right and it also pointed at the answer:
% the corpus's quantity is not really "hours". It is "a substantial fraction of the daily cycle" -
% minutes-to-hours stated against a roughly twenty-four-hour clock. THE CORPUS'S TIMESCALE IS
% RELATIVE TO A CYCLE, and konnectome's governor has a cycle. So the window is the cycle, and the
% number is nobody's: change the governor's day length and the window changes with it, in the same
% tick, with no constant anywhere to fall out of step.
%
% AND BOTH ALLOWANCES ARE DERIVED FROM THE SAME DAY, FOR THE SAME REASON.
%
% THE CHATTER ALLOWANCE IS TWO CROSSINGS PER DAY, AND IT IS THE CORPUS'S ARITHMETIC RATHER THAN
% KONNECTOME'S TASTE. A healthy day, in the corpus's own account of this switch, contains exactly two
% crossings: one down into sleep and one back up into waking. A third crossing inside one day is
% precisely the STATE INTRUSION that Entry 11's warning condition names and that Chapter 13 attributes
% to the stabiliser's loss. Two is therefore not a tolerance somebody picked; it is what one day of a
% working flip-flop contains, and anything above it is the fault by the corpus's own definition.
%
% THE LOCK ALLOWANCE IS THE WHOLE DAY LESS ONE TICK, WHICH IS THE LARGEST HOLD THAT IS NOT A WHOLE
% DAY. A pole held for an entire day is a pole that never left, and a day containing only one pole is
% a day in which the other side never won - which is the other half of Entry 11's warning condition,
% named in both directions at once. Expressing it as the day less one tick is not a fudge: it is the
% exact boundary between "held for less than a day" and "held for a whole day", stated so that the
% comparison is a strict one, as every other allowance in this repository is.
%
% WHAT DECISION-6 DOES NOT DECIDE. It does not supply a window for any OTHER construct: a construct
% with no cycle of its own still has no honest window, and the gate archetype is exactly such a
% construct, so DECISION-4's first half stands untouched for everything but this one caller. It does
% not decide an escalation policy - what to DO about a warning is still undecided, as it has been
% since slice 42. It does not decide that a history must be kept every tick, though the readings mean
% less if it is not (see the watchdog's own sampling note). And it does not change one number in the
% governor's behaviour: nothing here is read by the step, and the day the governor runs is the day it
% has run since slice 37.

% two_process_governor_watch_window(+Governor, -Window): the window a watchdog measures this governor
% over, which is the governor's own day and not a constant.
two_process_governor_watch_window(Governor, Window) :-
    % Read the day from the parameter block that has carried it since slice 37.
    two_process_governor_day_length(Governor, Window).

% two_process_governor_watch_allowances(+Governor, -ChatterAllowance, -LockAllowance): the two
% allowances, both derived from the governor's own day.
two_process_governor_watch_allowances(Governor, ChatterAllowance, LockAllowance) :-
    % Read the day, which is the only quantity either allowance is built from.
    two_process_governor_day_length(Governor, DayLength),
    % A healthy day contains exactly two crossings, down and up, so two is the allowance and a third
    % is the corpus's own state-intrusion signature.
    ChatterAllowance = 2,
    % The largest hold that is not a whole day, so a pole occupying the entire day crosses it.
    LockAllowance is DayLength - 1.

% two_process_governor_watch(+Governor, +History, -Report): the join, end to end.
two_process_governor_watch(Governor, History, Report) :-
    % Read the window from the governor's own day, which judges the governor on the way in.
    two_process_governor_watch_window(Governor, Window),
    % Read both allowances from the same day, so the three quantities can never disagree.
    two_process_governor_watch_allowances(Governor, ChatterAllowance, LockAllowance),
    % Take the readings from the history. THE WATCHDOG'S READINGS ARE FILED UNDER THE GATE'S OWN
    % SIGNATURE NAMES, and this governor's boundaries are named differently, so the readings are
    % RE-KEYED below rather than renamed at the source: the watchdog measures flips and holds, which
    % are construct-neutral quantities, and what those quantities MEAN is each construct's own claim.
    watchdog_gate_readings(History, Window, ChatterAllowance, LockAllowance, Readings, _NotMeasured),
    % Re-key the readings onto this governor's own boundary names, dropping nothing.
    two_process_governor_rekey(Readings, Rekeyed),
    % Build this governor's automaton, standing at the pole it currently occupies, so the supervisor
    % judges the REAL fault block rather than a fixture.
    two_process_governor_pole_of(History, Pole),
    % The automaton carries the two regimes Entry 11 supplies.
    two_process_governor_automaton(Pole, Automaton),
    % And the supervisor judges them, publishing warnings, clean regimes and unwatched ones apart.
    supervisor_watch(Automaton, Rekeyed, Report).

% two_process_governor_rekey(+Readings, -Rekeyed): file the watchdog's readings under this
% construct's own boundary names.
% An empty reading set - which is what an unspanned window yields - re-keys to nothing, so the
% supervisor reports BOTH regimes unwatched, which is true and is the point.
two_process_governor_rekey([], []).
% A flip count is this governor's chatter reading.
two_process_governor_rekey([supervisor_reading(oscillation, Value, Allowance)|Rest],
                          [supervisor_reading(state_chatter, Value, Allowance)|More]) :-
    % Re-key the remaining readings.
    two_process_governor_rekey(Rest, More).
% A hold count is this governor's lock reading.
two_process_governor_rekey([supervisor_reading(stuck_switch, Value, Allowance)|Rest],
                          [supervisor_reading(state_locked, Value, Allowance)|More]) :-
    % Re-key the remaining readings.
    two_process_governor_rekey(Rest, More).

% two_process_governor_pole_of(+History, -Pole): the pole the history says the governor stands at.
two_process_governor_pole_of(History, Pole) :-
    % An empty history has no pole to report, and the governor's own domain refuses a hole aloud
    % rather than letting a supervisor judge a machine standing nowhere.
    (   History = [observation(_Tick, Found)|_Older]
    ->  Pole = Found
    ;   throw(error(domain_error(two_process_governor_watched_history, History), _))
    ),
    % Judge the pole through the governor's own long-standing domain, so a history carrying a third
    % position is refused here rather than deep inside the register's constructor.
    two_process_governor_check_operating_state(Pole).
