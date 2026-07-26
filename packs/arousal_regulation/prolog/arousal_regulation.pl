% Declare the arousal_regulation module and the public interface of the regulation pilot.
:- module(arousal_regulation, [
    % arousal_regulation_baseline/1: the tonic resting level regulation returns arousal to.
    arousal_regulation_baseline/1,
    % arousal_regulation_arouse/3: raise arousal - a norepinephrine level written onto the bus.
    arousal_regulation_arouse/3,
    % arousal_regulation_level/2: read the current arousal level off the bus.
    arousal_regulation_level/2,
    % arousal_regulation_step/2: one regulation tick - move arousal partway back toward baseline.
    arousal_regulation_step/2,
    % arousal_regulation_settle/3: run a fixed number of regulation ticks.
    arousal_regulation_settle/3,
    % arousal_regulation_regulate/3: regulate until arousal settles exactly at baseline, counting the ticks.
    arousal_regulation_regulate/3
]).

% Reuse the neuromodulatory bus: arousal is not a new store, it is norepinephrine on the shared bus.
:- use_module(library(neuromodulator_bus), [
    % neuromodulator_bus_broadcast/4: write a modulator's new level for everyone to read.
    neuromodulator_bus_broadcast/4,
    % neuromodulator_bus_level/3: read a modulator's current level.
    neuromodulator_bus_level/3
]).

% The arousal_regulation pack realizes the second of Rung Four's two remaining pilots: regulation, an
% aroused state brought back toward baseline over time. It invents no store and no eleventh component.
% The book carries arousal as norepinephrine from the locus coeruleus, a level on the neuromodulatory
% bus - Architecture Component 4 - so arousal here is exactly that level, read and rewritten through
% the one bus the architecture already permits. The ONE konnectome rule this pack adds is the return:
% each regulation tick closes a fixed fraction of the distance from the current level to the tonic
% baseline, and when the level comes within a hair of baseline it settles EXACTLY there - it does not
% leave a residue above baseline, and it never dips below it. Arousal is a raising of the level above
% rest, so regulation carries it DOWN to baseline and stops. That echoes the same PRINCIPLE the drive
% system's own capped step keeps - a homeostatic return settles AT what it defends, never past it -
% though the mechanic differs: the drive system moves a fixed absolute step and caps it at the
% set-point, while regulation here closes a fixed FRACTION of the distance and snaps to baseline
% within a small epsilon, which is what makes the return terminate in finitely many ticks for any
% starting arousal, not only the exact halvings. Nothing in a cousin is edited; the bus is read and
% written only through its own public interface; there is no new record kind and no new modulator.

% arousal_regulation_baseline(-Baseline): the tonic resting level - calm, the reference every phasic signal moves around.
arousal_regulation_baseline(0.0).

% arousal_regulation_decay_rate(-Rate): the fraction of the distance to baseline one regulation tick closes.
arousal_regulation_decay_rate(0.5).

% arousal_regulation_epsilon(-Epsilon): within this of baseline, the regulated level settles exactly at baseline.
arousal_regulation_epsilon(0.01).

% arousal_regulation_modulator(-Modulator): arousal rides on norepinephrine, the locus coeruleus's broadcast.
arousal_regulation_modulator(norepinephrine).

% arousal_regulation_arouse(+Bus0, +Level, -Bus): raise arousal by broadcasting a norepinephrine level.
arousal_regulation_arouse(Bus0, Level, Bus) :-
    % Arousal above baseline is a real, measurable level.
    arousal_regulation_check_level(Level),
    % Arousal rides on norepinephrine.
    arousal_regulation_modulator(Modulator),
    % Write the aroused level onto the shared bus for every construct to read.
    neuromodulator_bus_broadcast(Bus0, Modulator, Level, Bus).

% arousal_regulation_check_level(+Level): arousal must be a number at or above the tonic baseline.
arousal_regulation_check_level(Level) :-
    % A real level is a number.
    number(Level),
    % The tonic baseline is the floor arousal rises from.
    arousal_regulation_baseline(Baseline),
    % Arousal is a raising of the level, never a level below rest.
    Level >= Baseline,
    % A good level is accepted.
    !.
% Any other level is refused as a hard error.
arousal_regulation_check_level(Level) :-
    % Refuse a non-numeric or below-baseline arousal with a named, inspectable error.
    throw(error(arousal_regulation_bad_level(Level),
                context(arousal_regulation_arouse/3, "arousal must be a number at or above the tonic baseline"))).

% arousal_regulation_level(+Bus, -Level): read the current arousal level off the bus.
arousal_regulation_level(Bus, Level) :-
    % Arousal rides on norepinephrine.
    arousal_regulation_modulator(Modulator),
    % Read norepinephrine's current broadcast level; an unaroused bus reads as baseline zero.
    neuromodulator_bus_level(Bus, Modulator, Level).

% arousal_regulation_step(+Bus0, -Bus): one regulation tick - move arousal partway back toward baseline.
arousal_regulation_step(Bus0, Bus) :-
    % Read the current arousal level.
    arousal_regulation_level(Bus0, Level),
    % The tonic baseline arousal returns to.
    arousal_regulation_baseline(Baseline),
    % Compute the regulated level: closer to baseline, and never past it.
    arousal_regulation_toward(Level, Baseline, Regulated),
    % Arousal rides on norepinephrine.
    arousal_regulation_modulator(Modulator),
    % Write the regulated level back onto the bus.
    neuromodulator_bus_broadcast(Bus0, Modulator, Regulated, Bus).

% arousal_regulation_toward(+Level, +Baseline, -Regulated): close a fraction of the distance, settling exactly at baseline when near.
% The distance is taken as an absolute value so the return is correct from either side, though an
% aroused level is at or above baseline in practice, so in this pilot the level only ever descends.
arousal_regulation_toward(Level, Baseline, Baseline) :-
    % The remaining distance from baseline, from whichever side.
    Distance is abs(Level - Baseline),
    % Within a hair of baseline, the state has settled.
    arousal_regulation_epsilon(Epsilon),
    % A settled state rests exactly at baseline, never a residue past it.
    Distance =< Epsilon,
    % The settled case is taken.
    !.
% Otherwise close a fixed fraction of the distance to baseline.
arousal_regulation_toward(Level, Baseline, Regulated) :-
    % The fraction of the distance one tick closes.
    arousal_regulation_decay_rate(Rate),
    % Move from the current level toward baseline by that fraction, never crossing it.
    Regulated is Baseline + (Level - Baseline) * (1 - Rate).

% arousal_regulation_settle(+Bus0, +NumTicks, -Bus): run a fixed number of regulation ticks.
arousal_regulation_settle(Bus0, NumTicks, Bus) :-
    % The tick count must be a whole, non-negative number of ticks.
    arousal_regulation_check_ticks(NumTicks),
    % Run the ticks from the aroused bus.
    arousal_regulation_settle_loop(Bus0, NumTicks, Bus).

% arousal_regulation_check_ticks(+NumTicks): the tick count must be a non-negative integer.
arousal_regulation_check_ticks(NumTicks) :-
    % A count of ticks is a whole number.
    integer(NumTicks),
    % A run cannot be a negative number of ticks.
    NumTicks >= 0,
    % A good count is accepted.
    !.
% Any other tick count is refused as a hard error.
arousal_regulation_check_ticks(NumTicks) :-
    % Refuse a non-integer or negative tick count with a named, inspectable error.
    throw(error(arousal_regulation_bad_ticks(NumTicks),
                context(arousal_regulation_settle/3, "the tick count must be a non-negative integer"))).

% arousal_regulation_settle_loop(+Bus0, +NumTicks, -Bus): apply regulation ticks one after another.
arousal_regulation_settle_loop(Bus, 0, Bus) :-
    % No ticks left: the bus is returned as it stands.
    !.
% One tick, then the rest.
arousal_regulation_settle_loop(Bus0, NumTicks, Bus) :-
    % There are ticks remaining to run.
    NumTicks > 0,
    % Run one regulation tick.
    arousal_regulation_step(Bus0, Bus1),
    % One fewer tick remains.
    Remaining is NumTicks - 1,
    % Run the remaining ticks from the regulated bus.
    arousal_regulation_settle_loop(Bus1, Remaining, Bus).

% arousal_regulation_regulate(+Bus0, -Bus, -NumTicks): regulate until arousal settles at baseline, counting the ticks.
arousal_regulation_regulate(Bus0, Bus, NumTicks) :-
    % Read the current arousal level.
    arousal_regulation_level(Bus0, Level),
    % The tonic baseline arousal returns to.
    arousal_regulation_baseline(Baseline),
    % Regulate from here until the level is exactly baseline.
    arousal_regulation_regulate_loop(Bus0, Level, Baseline, Bus, NumTicks).

% arousal_regulation_regulate_loop(+Bus0, +Level, +Baseline, -Bus, -NumTicks): tick until arousal rests at baseline.
arousal_regulation_regulate_loop(Bus, Level, Baseline, Bus, 0) :-
    % Arousal already rests exactly at baseline: no ticks are needed.
    Level =:= Baseline,
    % The settled case is taken.
    !.
% Arousal is still above baseline, so regulate one more tick.
arousal_regulation_regulate_loop(Bus0, _Level, Baseline, Bus, NumTicks) :-
    % Run one regulation tick.
    arousal_regulation_step(Bus0, Bus1),
    % Read the newly regulated level.
    arousal_regulation_level(Bus1, Level1),
    % Regulate onward from the new level, which is strictly closer to baseline and settles in finite ticks.
    arousal_regulation_regulate_loop(Bus1, Level1, Baseline, Bus, Rest),
    % Count this tick among those the return took.
    NumTicks is Rest + 1.
