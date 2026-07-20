% Declare this file as the 'observer' module and list the predicates it exports.
:- module(observer, [
    % observer_tick_type/1: the content-addressed identifier of the reusable "tick" occurrent.
    observer_tick_type/1,
    % observer_tick_instant/3: the deterministic absolute instant of a numbered tick.
    observer_tick_instant/3,
    % observer_record_tick/3: record one tick as a Causalontology token_occurrence.
    observer_record_tick/3,
    % observer_record_ticks/3: record a whole run of ticks as token_occurrences.
    observer_record_ticks/3
]).

% Reuse PrologAI's Causalontology core to content-address a record; konnectome does not fork it.
:- use_module(library(causal_core), [causal_core_identify/3]).
% Import maplist for recording a whole run of ticks.
:- use_module(library(apply), [maplist/4]).

% The observer records the tick-by-tick history as Causalontology token_occurrences (Appendix 3,
% Section A3.4: "the tick-by-tick records are token occurrences"). Each tick instantiates one shared
% "tick" occurrent type, and each beat is one token_occurrence stamped at its own absolute instant.
% konnectome ticks are dimensionless-ordinal in the scheduler; the one-second-per-tick mapping below
% is only a nominal, reproducible carrier for the token_occurrence's mandatory absolute interval.

% observer_tick_type(-TickTypeId): mint (deterministically) the reusable "tick" occurrent identifier.
observer_tick_type(TickTypeId) :-
    % Build the "tick" occurrent as a Causalontology record: an event kind of happening.
    TickType = _{type: "occurrent", label: "tick", category: "event"},
    % Content-address it; the identifier is the same on every run because the content is fixed.
    causal_core_identify(TickType, occurrent, TickTypeId).

% observer_tick_instant(+SimulationStart, +TickNumber, -InstantString): tick N's absolute instant.
observer_tick_instant(SimulationStart, TickNumber, InstantString) :-
    % Parse the simulation start, an RFC 3339 timestamp, into a POSIX second count.
    parse_time(SimulationStart, iso_8601, BaseStamp),
    % Advance the clock by one nominal second per ordinal tick, keeping whole seconds.
    Stamp is truncate(BaseStamp) + TickNumber,
    % Express that instant back in Coordinated Universal Time.
    stamp_date_time(Stamp, DateTime, 'UTC'),
    % Format it as an RFC 3339 timestamp with the mandatory trailing Z.
    format_time(string(InstantString), "%Y-%m-%dT%H:%M:%SZ", DateTime).

% observer_build_occurrence(+TickTypeId, +InstantString, -Record): assemble one content-addressed token_occurrence.
observer_build_occurrence(TickTypeId, InstantString, Record) :-
    % Build the token_occurrence: it instantiates the tick type and starts at its instant.
    Base = _{type: "token_occurrence", instantiates: TickTypeId, interval: _{start: InstantString}},
    % Content-address it over its identity-bearing fields (instantiates and interval).
    causal_core_identify(Base, token_occurrence, Id),
    % Attach the identifier, yielding the complete stored record.
    put_dict(id, Base, Id, Record).

% observer_record_tick(+SimulationStart, +TickNumber, -Record): record one tick as a token_occurrence.
observer_record_tick(SimulationStart, TickNumber, Record) :-
    % Get the shared tick occurrent type identifier.
    observer_tick_type(TickTypeId),
    % Compute this tick's absolute instant.
    observer_tick_instant(SimulationStart, TickNumber, InstantString),
    % Assemble the content-addressed token_occurrence for this tick.
    observer_build_occurrence(TickTypeId, InstantString, Record).

% observer_record_one_(+SimulationStart, +TickTypeId, +TickNumber, -Record): the per-tick worker.
observer_record_one_(SimulationStart, TickTypeId, TickNumber, Record) :-
    % Compute this tick's absolute instant.
    observer_tick_instant(SimulationStart, TickNumber, InstantString),
    % Assemble the content-addressed token_occurrence, reusing the shared tick type.
    observer_build_occurrence(TickTypeId, InstantString, Record).

% observer_record_ticks(+SimulationStart, +TickNumbers, -Records): record a whole run of ticks.
observer_record_ticks(SimulationStart, TickNumbers, Records) :-
    % Mint the shared tick occurrent type once for the whole run.
    observer_tick_type(TickTypeId),
    % Record each numbered tick as its own token_occurrence.
    maplist(observer_record_one_(SimulationStart, TickTypeId), TickNumbers, Records).
