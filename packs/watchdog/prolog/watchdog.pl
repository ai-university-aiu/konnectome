% Declare this file as the 'watchdog' module and list the predicates it exports.
:- module(watchdog, [
    % watchdog_history_new/1: an empty history, which has seen nothing and measures nothing.
    watchdog_history_new/1,
    % watchdog_observe/4: record what mode one construct instance stood in at one ordinal tick.
    watchdog_observe/4,
    % watchdog_history_observations/2: how many observations the history holds.
    watchdog_history_observations/2,
    % watchdog_history_span/2: how many ticks the history covers, first to last inclusive.
    watchdog_history_span/2,
    % watchdog_history_current/3: the newest tick and the mode standing at it.
    watchdog_history_current/3,
    % watchdog_window_measured/2: whether the history yet spans a window of the asked-for length.
    watchdog_window_measured/2,
    % watchdog_window_ticks/2: read a window stated as a wall-clock duration, through the convention.
    watchdog_window_ticks/2,
    % watchdog_flips_in_window/3: how many times the mode changed inside the trailing window.
    watchdog_flips_in_window/3,
    % watchdog_ticks_held_in_window/3: how many ticks the current mode has been held, inside the window.
    watchdog_ticks_held_in_window/3,
    % watchdog_gate_readings/6: the gate's two corpus-named boundaries, read as supervisor readings.
    watchdog_gate_readings/6
]).

% Import the type checker that judges a tick, a mode or a window and refuses a hole aloud.
:- use_module(library(error), [must_be/2, domain_error/2]).
% Import the list utility that reads the oldest observation from the newest-first history.
:- use_module(library(lists), [last/2]).
% Import the tick engine, because a window is a DURATION and slice 43 declared the only unit one may
% be stated in. This pack is that convention's first real consumer.
:- use_module(library(tick_engine), [
    % tick_engine_ticks_from_milliseconds/2: the sole conversion from a wall-clock quantity into ticks.
    tick_engine_ticks_from_milliseconds/2
]).

% ---------------------------------------------------------------------------
% WHAT THIS PACK IS, AND THE OBSERVATION IT CLOSES
% ---------------------------------------------------------------------------
%
% KONNECTOME HAD A WATCHER AND NO WATCHDOGS, AND THIS PACK IS THE FIRST WATCHDOG. Slice 42 built the
% supervisor, which judges readings it is HANDED and keeps no history of its own. That left every
% fault regime in the repository UNWATCHED in the supervisor's own vocabulary - reported honestly as
% unwatched rather than dishonestly as clean, which is why the supervisor needed a third outcome
% before it needed a second reading. OBSERVATION-9 named the closer: the slice that gives a construct
% a windowed history, or the tick engine a per-construct counter. This is that slice.
%
% THE DEPENDENCY WAS PAID BEFORE THE SLICE ARRIVED. A watchdog counts events over a WINDOW, and a
% window is a duration; konnectome had no unit to state one in until slice 43 declared the
% ticks-per-second convention as DECISION-2. That is why OBSERVATION-9 stayed open through slice 43
% and slice 44: supplying a unit and building the process that uses it are different acts.
%
% THE TWO BOUNDARIES THIS WATCHDOG MEASURES ARE NOT KONNECTOME'S INVENTION. They are the two fault
% regimes the corpus supplies for the gate, in the Layer 8 modes volume's Entry 36, the
% mutual-inhibition flip-flop coined the Either-Or Latch: a switch can fail by flipping too readily,
% and it can fail the opposite way by settling so hard it will not leave. archetype has carried both
% by name since slice 42, with their watchdogs named - oscillation_watchdog and stuck_switch_watchdog
% - and this pack is what those two names have been standing in for.
%
% A HISTORY IS A VALUE THE WORLD CARRIES. It is threaded through the caller in the explicit-stateless
% -value discipline the eligibility-trace store, the running-average store and the per-territory
% target store already follow, and never hidden inside an engine. That is Theme One's addendum
% honoured at a new construct: a watcher holding nothing but a history can read back the current
% mode, the span measured, and both readings, WITHOUT RUNNING THE CONSTRUCT the history is about.
% The owner's standing visualization-panel request gains its third layer here - what is being watched
% about a construct, and by whom - and it gains it as a readable value rather than as a promise.

% ---------------------------------------------------------------------------
% DECISION-4, TAKEN HERE: THE WINDOW BELONGS TO THE CALLER, AND AN UNSPANNED WINDOW IS NOT CLEAN
% ---------------------------------------------------------------------------
%
% THE SLICE OWED A NUMBER AND IT PAYS THE DEBT BY REFUSING TO INVENT ONE, WHICH IS ITSELF THE
% DECISION AND IS RECORDED AS SUCH IN THE LEDGER. Two halves, and the second is the load-bearing one.
%
% FIRST HALF - THE WINDOW LENGTH IS SUPPLIED BY THE CALLER THAT OWNS THE WATCHDOG, exactly as the
% ALLOWANCE already is. Slice 42 established that shape for the allowance and gave the reason: the
% corpus supplies konnectome no number at this grain and this family does not invent numbers. The
% same reason holds here, and one measurement of it settles the matter. The corpus's only
% quantitative statement about this latch's timescales is Entry 36's own: human sleep-wake
% transitions take seconds to minutes while the states last minutes to hours. That is a claim about
% ONE latch - the sleep-wake flip-flop - and not about a gate archetype generically, and konnectome
% installs the gate archetype in places that have nothing to do with sleep. Adopting minutes-to-hours
% as a default window would put it at tens of thousands of ticks, which would make the capstone's own
% ten-tick heartbeat permanently unmeasurable, and would do it while wearing a corpus citation that
% does not cover the case. A default like that is an invented number with a borrowed warrant.
%
% SECOND HALF - AND THIS IS THE HALF WITH TEETH. A WINDOW THE HISTORY DOES NOT YET SPAN IS REPORTED
% AS NOT-YET-MEASURED, NEVER AS CLEAN AND NEVER AS ZERO. A history four ticks long, asked for flips
% over a window of twenty, could honestly answer "one flip so far" - and a supervisor comparing one
% against an allowance of three would then publish a clean bill of health for a boundary nobody has
% watched long enough to judge. That is precisely the failure the supervisor's third outcome exists
% to prevent, arriving one layer lower down, and it would defeat that outcome from underneath. So the
% short history yields no reading at all: it yields a named statement that the window is not yet
% spanned, carrying the window asked for and the span actually held, and the fault regime then flows
% through the supervisor's UNWATCHED block, which is where it belongs and which is true.
%
% WHAT DECISION-4 DOES NOT DECIDE. It does not decide any particular window for any particular
% construct: the first caller that wires a real gate to a real supervisor must choose one and say
% why, and that choice is a slice of its own. It does not decide an escalation policy - what to DO
% about a warning remains undecided, as it was left at slice 42. It does not decide that flips and
% held-ticks are the only two things worth watching; they are the two the corpus names for this one
% construct. And it does not give any other construct a fault block: the gate is still the only
% konnectome construct whose fault regimes the corpus actually supplies.

% ---------------------------------------------------------------------------
% THE HISTORY
% ---------------------------------------------------------------------------
%
% A history is a list of observation(Tick, Mode) terms held NEWEST FIRST, so that the trailing window
% - which is the only part any reading looks at - is a prefix rather than a search. The ordering is
% part of the representation and is maintained by the one predicate that may extend it.

% watchdog_history_new(-History): an empty history, which has seen nothing and measures nothing.
watchdog_history_new([]).

% watchdog_check_history(+History): refuse a hole where a history was expected.
watchdog_check_history(History) :-
    % An unbound history would be bound by the walk into whatever shape the walk happened to want.
    (   var(History)
    ->  throw(error(instantiation_error, _))
    % A history is a list, and anything else is refused before it can be walked.
    ;   must_be(list, History)
    ).

% watchdog_check_window(+Window): refuse a window that cannot measure anything.
watchdog_check_window(Window) :-
    % A window of zero ticks contains no ticks and would report every construct clean forever.
    must_be(positive_integer, Window).

% watchdog_observe(+History0, +Tick, +Mode, -History): record one construct's mode at one tick.
watchdog_observe(History0, Tick, Mode, History) :-
    % Refuse a hole where the prior history was expected, before anything is prepended to it.
    watchdog_check_history(History0),
    % A tick is an ordinal count, and an unbound or negative one is refused rather than invented.
    must_be(nonneg, Tick),
    % A mode is named by an atom, the same key shape the register and the supervisor both use.
    must_be(atom, Mode),
    % TIME DOES NOT RUN BACKWARDS, AND IT DOES NOT STAND STILL EITHER. An observation at a tick not
    % strictly later than the newest one held would either rewrite history or double-count a tick,
    % and both would corrupt every reading taken afterwards while looking like ordinary use.
    (   History0 = [observation(NewestTick, _NewestMode)|_Older],
        Tick =< NewestTick
    ->  % The refusal names the offending tick rather than silently reordering the history.
        domain_error(watchdog_advancing_tick, Tick)
    ;   % Either the history is empty or the tick is genuinely later, so the observation stands.
        true
    ),
    % Prepend the observation, which keeps the newest-first ordering the readings depend on.
    History = [observation(Tick, Mode)|History0].

% watchdog_history_observations(+History, -Count): how many observations the history holds.
watchdog_history_observations(History, Count) :-
    % Refuse a hole before counting it as an empty history, which would report a clean nothing.
    watchdog_check_history(History),
    % The count is the length of the list, which is the number of ticks actually shown to the watchdog.
    length(History, Count).

% watchdog_history_current(+History, -Tick, -Mode): the newest tick and the mode standing at it.
watchdog_history_current(History, Tick, Mode) :-
    % Refuse a hole before reading a newest observation out of it.
    watchdog_check_history(History),
    % An empty history has no current mode, and says so rather than handing back a plausible default.
    (   History = [observation(FoundTick, FoundMode)|_Older]
    ->  % Hand back the newest observation, which is the head under the newest-first ordering.
        Tick = FoundTick,
        % And the mode standing at it.
        Mode = FoundMode
    ;   % Nothing has been observed, so there is no current mode to report.
        domain_error(watchdog_non_empty_history, History)
    ).

% watchdog_history_span(+History, -Span): how many ticks the history covers, first to last inclusive.
watchdog_history_span(History, Span) :-
    % Refuse a hole before measuring a span across it.
    watchdog_check_history(History),
    % An empty history spans nothing, which is zero ticks and not one.
    (   History == []
    ->  % Nothing observed spans nothing.
        Span = 0
    ;   % The newest observation is the head under the newest-first ordering.
        History = [observation(NewestTick, _NewestMode)|_Older],
        % The oldest is the last, so read it by walking to the end of the list.
        last(History, observation(OldestTick, _OldestMode)),
        % A span is inclusive of both ends: one observation spans one tick, not zero.
        Span is NewestTick - OldestTick + 1
    ).

% watchdog_window_measured(+History, +Window): the history yet spans a window of this length.
watchdog_window_measured(History, Window) :-
    % Refuse a window that cannot measure anything before comparing a span against it.
    watchdog_check_window(Window),
    % Read how many ticks the history actually covers.
    watchdog_history_span(History, Span),
    % A window is measured only when the history reaches all the way back across it.
    Span >= Window.

% watchdog_window_ticks(+Milliseconds, -Window): read a window stated as a duration, in ticks.
watchdog_window_ticks(Milliseconds, Window) :-
    % Convert through the ONE conversion predicate DECISION-2 established, so a window stated in
    % wall-clock time is refused rather than rounded if it does not land on a tick boundary. This
    % pack states no duration of its own; it only lets a caller state one in the units the corpus
    % speaks, and converts it in the single place the convention lives.
    tick_engine_ticks_from_milliseconds(Milliseconds, Window).

% ---------------------------------------------------------------------------
% THE TRAILING WINDOW
% ---------------------------------------------------------------------------
%
% THE WINDOW IS COUNTED IN TICKS AND NOT IN OBSERVATIONS, and the difference is worth stating because
% it is the one place this pack could mislead. A history need not hold an observation for every tick;
% a caller that observes a construct every third tick has a history whose span is three times its
% length. A window of twenty ticks therefore means the last twenty TICKS, however many observations
% happen to fall inside them. The consequence, named rather than hidden: FLIPS ARE COUNTED BETWEEN
% CONSECUTIVE OBSERVATIONS, so a construct that flips and flips back between two observations shows
% no flip at all. The watchdog measures what it was shown, and a caller that wants every flip seen
% must observe every tick. That is a property of sampling and not a defect of the count.

% watchdog_within_window(+History, +Window, -Kept): the observations inside the trailing window.
watchdog_within_window(History, Window, Kept) :-
    % An empty history keeps nothing, whatever the window.
    (   History == []
    ->  % Nothing was observed, so nothing falls inside the window.
        Kept = []
    ;   % The newest tick is the window's right-hand edge, because the window trails the present.
        History = [observation(NewestTick, _NewestMode)|_Older],
        % The window's left-hand edge is inclusive, so a window of one keeps only the newest tick.
        Earliest is NewestTick - Window + 1,
        % Take observations from the newest end while they remain inside the edge, and stop at the
        % first one that does not - which is correct precisely because the list is newest-first.
        watchdog_take_within(History, Earliest, Kept)
    ).

% watchdog_take_within(+History, +Earliest, -Kept): take the newest run of in-window observations.
% An exhausted history has nothing further to take.
watchdog_take_within([], _Earliest, []).
% Each observation is kept if it lies at or after the window's left-hand edge.
watchdog_take_within([observation(Tick, Mode)|Older], Earliest, Kept) :-
    % A tick at or after the edge is inside the window, and so may be every older one after it.
    (   Tick >= Earliest
    ->  % Keep this observation and carry on into the older ones.
        Kept = [observation(Tick, Mode)|Rest],
        % The rest of the window is whatever the older observations contribute.
        watchdog_take_within(Older, Earliest, Rest)
    ;   % This observation is older than the window, and so is every one behind it, so stop here.
        Kept = []
    ).

% watchdog_flips_in_window(+History, +Window, -Flips): how many times the mode changed in the window.
watchdog_flips_in_window(History, Window, Flips) :-
    % Refuse a hole where a history was expected.
    watchdog_check_history(History),
    % Refuse a window that cannot measure anything.
    watchdog_check_window(Window),
    % Narrow the history to the trailing window before counting anything.
    watchdog_within_window(History, Window, Kept),
    % Count the adjacent pairs whose modes differ, which is what a flip IS at this grain.
    watchdog_count_flips(Kept, Flips).

% watchdog_count_flips(+Observations, -Flips): count adjacent observations whose modes differ.
% Nothing observed is nothing flipped.
watchdog_count_flips([], 0).
% Otherwise the newest observation becomes the mode each older one is compared against in turn. The
% walk is split in two so that each predicate decides on the SHAPE of its first argument alone -
% empty or not - rather than on how many elements a list happens to have, which leaves a choice point
% behind on every reading. This is the declaration-order lens's sibling: a walk that is deterministic
% only because nobody asked it for a second answer is not deterministic.
watchdog_count_flips([observation(_Tick, Mode)|Older], Flips) :-
    % Carry the newest mode backwards as the thing the next observation is compared against.
    watchdog_count_flips_behind(Older, Mode, Flips).

% watchdog_count_flips_behind(+Older, +NewerMode, -Flips): compare each older observation in turn.
% An exhausted history has nothing left to differ from.
watchdog_count_flips_behind([], _NewerMode, 0).
% Each older observation either matches the mode ahead of it or differs from it.
watchdog_count_flips_behind([observation(_Tick, Mode)|Older], NewerMode, Flips) :-
    % Count the flips further back first, comparing against THIS observation's mode.
    watchdog_count_flips_behind(Older, Mode, Behind),
    % A pair of differing modes is one flip; a pair of matching modes is none.
    (   Mode == NewerMode
    ->  % The mode held across this pair, so nothing is added.
        Flips = Behind
    ;   % The mode changed across this pair, so one flip is added.
        Flips is Behind + 1
    ).

% watchdog_ticks_held_in_window(+History, +Window, -Held): ticks the current mode has been held.
watchdog_ticks_held_in_window(History, Window, Held) :-
    % Refuse a hole where a history was expected.
    watchdog_check_history(History),
    % Refuse a window that cannot measure anything.
    watchdog_check_window(Window),
    % Narrow the history to the trailing window, so a hold is never reported longer than the window.
    watchdog_within_window(History, Window, Kept),
    % An empty window holds no mode, and reports zero ticks held rather than a mode it never saw.
    (   Kept == []
    ->  % Nothing inside the window, so nothing has been held inside it.
        Held = 0
    ;   % The newest observation carries the mode whose hold is being measured.
        Kept = [observation(NewestTick, CurrentMode)|_Older],
        % Walk back through the unbroken run of that same mode to find where the hold began.
        watchdog_run_start(Kept, CurrentMode, NewestTick, StartTick),
        % A hold is inclusive of both ends, so a mode seen at one tick only has been held one tick.
        Held is NewestTick - StartTick + 1
    ).

% watchdog_run_start(+Observations, +Mode, +SoFar, -StartTick): where the unbroken run of Mode began.
% An exhausted window ends the run at the oldest tick reached.
watchdog_run_start([], _Mode, SoFar, SoFar).
% Each observation either continues the run or ends it.
watchdog_run_start([observation(Tick, Found)|Older], Mode, SoFar, StartTick) :-
    % A matching mode continues the run, so the run's start moves back to this tick and keeps going.
    (   Found == Mode
    ->  % Carry on into the older observations with this tick as the earliest seen so far.
        watchdog_run_start(Older, Mode, Tick, StartTick)
    ;   % A different mode ends the run, and the start is wherever the run had reached.
        StartTick = SoFar
    ).

% ---------------------------------------------------------------------------
% THE READINGS - WHERE THE WATCHDOG MEETS THE WATCHER
% ---------------------------------------------------------------------------
%
% THE READINGS THIS PACK PRODUCES ARE THE SUPERVISOR'S OWN TERM SHAPE, supervisor_reading/3, and this
% pack does NOT import the supervisor to build them. That is deliberate and is recorded rather than
% assumed. The supervisor sits at layer zero as this pack does, so an import would not violate the
% layer rule - but it would make the watchdog depend on the watcher, when the honest direction of
% dependence is neither: they meet at a TERM, which is a value the world carries, in the same
% discipline as every other store in the repository. The coupling is therefore by shape, and the
% shape is pinned by a test in this pack that hands a real reading to the real supervisor.

% watchdog_gate_readings(+History, +Window, +FlipAllowance, +HoldAllowance, -Readings, -NotMeasured):
% the gate's two corpus-named boundaries, read as supervisor readings.
watchdog_gate_readings(History, Window, FlipAllowance, HoldAllowance, Readings, NotMeasured) :-
    % Refuse a hole where a history was expected, before any reading is taken from it.
    watchdog_check_history(History),
    % Refuse a window that cannot measure anything.
    watchdog_check_window(Window),
    % Judge both allowances HERE, in the one place both readings come through, rather than leaving a
    % hole to be answered later by a comparison naming nothing useful. This is the unbound-wrong-
    % judgement lens, which has now paid for a THIRTEENTH slice running.
    must_be(number, FlipAllowance),
    % The hold allowance is judged as strictly as the flip allowance, for the same reason.
    must_be(number, HoldAllowance),
    % DECISION-4'S SECOND HALF, APPLIED: a window the history does not yet span yields no reading at
    % all, so the supervisor reports the boundary UNWATCHED rather than clean.
    (   watchdog_window_measured(History, Window)
    ->  % The window is spanned, so both boundaries can honestly be read.
        watchdog_flips_in_window(History, Window, Flips),
        % And the second, measured over the same window so the two verdicts agree about when.
        watchdog_ticks_held_in_window(History, Window, Held),
        % Hand back both readings under the signatures archetype's fault block declares.
        Readings = [supervisor_reading(oscillation, Flips, FlipAllowance),
                    supervisor_reading(stuck_switch, Held, HoldAllowance)],
        % Nothing went unmeasured.
        NotMeasured = []
    ;   % The window is not yet spanned, so no reading is offered for either boundary.
        Readings = [],
        % Read the span actually held, so the statement carries what was measured and what was asked.
        watchdog_history_span(History, Span),
        % Both boundaries are named as not yet measured, carrying the window asked and the span held.
        NotMeasured = [watchdog_not_measured(oscillation, Window, Span),
                       watchdog_not_measured(stuck_switch, Window, Span)]
    ).
