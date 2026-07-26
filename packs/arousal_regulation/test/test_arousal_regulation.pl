% Load the module under test from the library path.
:- use_module(library(arousal_regulation)).
% Load the Prolog Unit test framework.
:- use_module(library(plunit)).
% Load the neuromodulatory bus so the tests can start from a fresh bus and read levels independently.
:- use_module(library(neuromodulator_bus), [
    % neuromodulator_bus_new/1: a fresh bus, every modulator at zero.
    neuromodulator_bus_new/1,
    % neuromodulator_bus_level/3: re-derive the arousal level the pack claims to write.
    neuromodulator_bus_level/3
]).

% Open the arousal_regulation test block.
:- begin_tests(arousal_regulation).

% The tonic baseline is calm - a level of zero.
test(baseline_is_calm) :-
    % Read the baseline the pack defends.
    arousal_regulation_baseline(Baseline),
    % Calm is zero arousal.
    assertion(Baseline =:= 0).

% Arousal is written onto the bus as norepinephrine, and reads back at the level set.
test(arousal_rides_on_norepinephrine) :-
    % Start from a fresh, calm bus.
    neuromodulator_bus_new(Bus0),
    % Raise arousal to one.
    arousal_regulation_arouse(Bus0, 1.0, Bus),
    % Read the arousal level back through the pack.
    arousal_regulation_level(Bus, Level),
    % The level is what was set.
    assertion(Level =:= 1.0),
    % Independently, norepinephrine on the bus carries that level.
    neuromodulator_bus_level(Bus, norepinephrine, Independent),
    % The pack wrote arousal onto norepinephrine, number for number.
    assertion(Independent =:= 1.0).

% A fresh bus reads as baseline arousal.
test(fresh_bus_reads_as_baseline) :-
    % Start from a fresh bus.
    neuromodulator_bus_new(Bus0),
    % Read its arousal.
    arousal_regulation_level(Bus0, Level),
    % An unaroused bus is at baseline.
    assertion(Level =:= 0).

% One regulation tick closes half the distance to baseline.
test(one_tick_closes_half_the_distance) :-
    % Start aroused at one.
    neuromodulator_bus_new(Bus0),
    % Raise arousal to one.
    arousal_regulation_arouse(Bus0, 1.0, Bus1),
    % Regulate one tick.
    arousal_regulation_step(Bus1, Bus2),
    % Read the regulated level.
    arousal_regulation_level(Bus2, Level),
    % Half the distance to baseline is closed.
    assertion(Level =:= 0.5).

% A fixed run of ticks brings arousal geometrically toward baseline.
test(settle_runs_a_fixed_number_of_ticks) :-
    % Start aroused at one.
    neuromodulator_bus_new(Bus0),
    % Raise arousal to one.
    arousal_regulation_arouse(Bus0, 1.0, Bus1),
    % Run two regulation ticks.
    arousal_regulation_settle(Bus1, 2, Bus2),
    % Read the level after two ticks.
    arousal_regulation_level(Bus2, Level),
    % Two halvings leave a quarter.
    assertion(Level =:= 0.25).

% Regulation settles exactly at baseline in a finite, deterministic number of ticks.
test(regulate_settles_exactly_at_baseline) :-
    % Start aroused at one.
    neuromodulator_bus_new(Bus0),
    % Raise arousal to one.
    arousal_regulation_arouse(Bus0, 1.0, Bus1),
    % Regulate until settled, counting the ticks.
    arousal_regulation_regulate(Bus1, Bus, NumTicks),
    % Read the settled level.
    arousal_regulation_level(Bus, Level),
    % The aroused state comes to rest exactly at baseline.
    assertion(Level =:= 0),
    % From an arousal of one, the return takes eight ticks.
    assertion(NumTicks == 8).

% Regulation never overshoots: every step stays at or above baseline, and each is closer than the last.
test(regulation_never_overshoots_baseline) :-
    % Start aroused at one.
    neuromodulator_bus_new(Bus0),
    % Raise arousal to one.
    arousal_regulation_arouse(Bus0, 1.0, Bus1),
    % Read the level before regulating.
    arousal_regulation_level(Bus1, Before),
    % Regulate one tick.
    arousal_regulation_step(Bus1, Bus2),
    % Read the level after.
    arousal_regulation_level(Bus2, After),
    % The regulated level is strictly closer to baseline.
    assertion(After < Before),
    % And never below it - a regulated state rests at baseline, it does not overshoot.
    assertion(After >= 0).

% An already-calm bus needs no regulation - it settles in zero ticks.
test(calm_bus_settles_in_zero_ticks) :-
    % Start from a fresh, calm bus.
    neuromodulator_bus_new(Bus0),
    % Regulate it.
    arousal_regulation_regulate(Bus0, Bus, NumTicks),
    % A calm bus is already at rest.
    arousal_regulation_level(Bus, Level),
    % It is at baseline.
    assertion(Level =:= 0),
    % And needed no ticks to get there.
    assertion(NumTicks == 0).

% A larger arousal simply takes more ticks to bring home - the return is monotone in the starting level.
test(higher_arousal_takes_at_least_as_long) :-
    % A fresh bus aroused to one.
    neuromodulator_bus_new(BusA0),
    % Raise arousal to one.
    arousal_regulation_arouse(BusA0, 1.0, BusA),
    % A fresh bus aroused to two.
    neuromodulator_bus_new(BusB0),
    % Raise arousal to two.
    arousal_regulation_arouse(BusB0, 2.0, BusB),
    % Regulate the lower arousal.
    arousal_regulation_regulate(BusA, _BusAEnd, TicksA),
    % Regulate the higher arousal.
    arousal_regulation_regulate(BusB, _BusBEnd, TicksB),
    % The higher arousal takes at least as many ticks to bring home.
    assertion(TicksB >= TicksA).

% Arousal below baseline is refused - arousal is a raising, never a level below rest.
test(below_baseline_arousal_is_refused, throws(error(arousal_regulation_bad_level(-1.0), _))) :-
    % Start from a fresh bus.
    neuromodulator_bus_new(Bus0),
    % A negative arousal cannot be written as a raising of the level.
    arousal_regulation_arouse(Bus0, -1.0, _Bus).

% A non-numeric arousal is refused with a named error.
test(non_numeric_arousal_is_refused, throws(error(arousal_regulation_bad_level(high), _))) :-
    % Start from a fresh bus.
    neuromodulator_bus_new(Bus0),
    % Arousal must be a measurable number, not a word.
    arousal_regulation_arouse(Bus0, high, _Bus).

% A negative tick count is refused with a named error.
test(negative_ticks_refused, throws(error(arousal_regulation_bad_ticks(-1), _))) :-
    % Start aroused at one.
    neuromodulator_bus_new(Bus0),
    % Raise arousal to one.
    arousal_regulation_arouse(Bus0, 1.0, Bus1),
    % A run cannot be a negative number of ticks.
    arousal_regulation_settle(Bus1, -1, _Bus).

% Close the arousal_regulation test block.
:- end_tests(arousal_regulation).
