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
    two_process_governor_step/4
]).

% Import membership for judging the two flip-flop positions.
:- use_module(library(lists), [memberchk/2]).

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
