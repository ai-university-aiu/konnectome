% Declare this file as the 'running_prediction' module and list the predicates it exports.
:- module(running_prediction, [
    % running_prediction_lag_milliseconds/1: the corpus's own feedback lag, in the corpus's own unit.
    running_prediction_lag_milliseconds/1,
    % running_prediction_lag_ticks/1: that same lag DERIVED into ticks, never written down as ticks.
    running_prediction_lag_ticks/1,
    % running_prediction_new/1: an empty carrier, holding nothing and due nothing.
    running_prediction_new/1,
    % running_prediction_retain/6: hold one tick's prediction until the reading it waits for arrives.
    running_prediction_retain/6,
    % running_prediction_holding/2: everything the carrier is holding, in issue order.
    running_prediction_holding/2,
    % running_prediction_due_tick/2: the tick at which a prediction issued at a given tick comes due.
    running_prediction_due_tick/2,
    % running_prediction_release/5: release what is due now, and name what went stale unconsumed.
    running_prediction_release/5,
    % running_prediction_released_issued_at/2: the tick a released prediction was issued at.
    running_prediction_released_issued_at/2,
    % running_prediction_released_predictions/3: the command's prediction and the null command's.
    running_prediction_released_predictions/3
]).

% Import the scheduler, because the lag is DERIVED through its one conversion and nowhere else.
:- use_module(library(tick_engine), [
    % tick_engine_ticks_from_milliseconds/2: the single place a duration becomes a tick count.
    tick_engine_ticks_from_milliseconds/2
]).
% Import the copy this carrier retains, so a term that is not a copy never enters the carrier.
:- use_module(library(efference_copy), [
    % efference_copy_command/2: read the command back out of a copy, refusing an impostor.
    efference_copy_command/2
]).
% Import the list utilities used to walk the retained predictions.
:- use_module(library(lists), [last/2]).
% Import the type checker that judges a store or a key and refuses a hole aloud.
:- use_module(library(error), [must_be/2, domain_error/2]).

% ---------------------------------------------------------------------------
% WHAT THIS PACK IS, AND THE OBSTACLE IT WAS BUILT AGAINST TURNED OUT TO BE MISSTATED
% ---------------------------------------------------------------------------
%
% THE SENTENCE FIVE HAND-OFFS CARRIED, AND IT IS FALSE AS WRITTEN: "NO CONSTRUCT IN THIS BUILD CARRIES
% ANYTHING ACROSS A TICK." It is false of the hold construct, whose own mode gloss reads "keeps its own
% current value unchanged FROM ONE TICK TO THE NEXT". It is false of the copy construct, which reads
% another construct's previous value and is a one-tick delay by construction. It is false of
% connection_graph's DELAY LINES, which are a purpose-built first-in-first-out buffer of values in
% transit, built and tested since slice 12 and unwired. And it is false of the RUNNING LOOP: the
% cognitive cycle threads eligibility traces every tick so that "a reward one tick late finds the trace
% that earned it", and the two-process governor's selection is made on one tick and read as the opening
% state of the NEXT.
%
% SO THE THING THAT WAS BLOCKING TWO ITEMS FOR FIVE SESSIONS WAS A CLAIM NOBODY HAD TESTED, WHICH IS
% THIS SESSION'S OWN FINDING ARRIVING A THIRD TIME. A test everything passes tells nothing apart; a
% rule everything fails tells nothing apart; AND A CLAIM NOTHING CHECKS IS THE SAME DEFECT AT THE SCALE
% OF A SENTENCE. It sat in six documents and in one source comment, it was quoted approvingly, it was
% used to defer work, and it had never once been held against the code it described.
%
% WHAT THE TRUE OBSTACLE IS, STATED NARROWLY SO IT CAN BE CHECKED. The tick engine gives each construct
% EXACTLY ONE SLOT PER TICK and that slot holds that construct's own committed value. A value computed
% inside a pass and not returned as some construct's next value is discarded when the pass closes. So
% the build can carry a READING and has nowhere to park a PREDICTION ABOUT A DIFFERENT QUANTITY. That
% is a storage-shape limitation and not a temporal one, and it is what this pack supplies.
%
% AND THE SECOND HALF OF THE TRUE OBSTACLE IS ONE MISSING ARGUMENT. body_interface_sense_act_step/7
% senses from Body0 before enacting on Body0, so the only reading that reflects a command is the one
% taken at the NEXT call - and body_interface_survival_ticks/7 threads Body, Drives and Bus and has no
% fourth slot to thread a prediction in. This pack is the thing that would go in that slot.

% ---------------------------------------------------------------------------
% WHAT THE CORPUS SAYS, AND IT NAMES THIS CONSTRUCT RATHER THAN LEAVING IT TO BE INVENTED
% ---------------------------------------------------------------------------
%
% LAYER_10_SYSTEMS_MANUSCRIPT.txt names the carrier and gives it an anatomical home: "The deep
% cerebellar nuclei, chiefly the dentate for the newest lobes, are the sole output and HOLD THE RUNNING
% PREDICTION." This pack takes its name from that sentence.
%
% THE_NEUROSCIENCE_OF_COGNITION_MANUSCRIPT.txt Chapter 51.2.3 supplies the verb: "Whenever a motor
% command is sent out, AN INTERNAL COPY IS RETAINED, called an efference copy." Retained, not merely
% duplicated - the corpus's own word for storage.
%
% AND CHAPTER 51.2.1 STATES WHAT THE CARRIER IS FOR: "Its purpose is to DEFEAT DELAY: sensory feedback
% from the hand takes on the order of 100 MILLISECONDS to become usable, which is an eternity for a
% fast reach, so the controller works from A PREDICTED PRESENT RATHER THAN A REPORTED PAST."
%
% THE LAG IS THE CORPUS'S NUMBER AND THE TICK COUNT IS A DERIVATION, WHICH IS THE SECOND PROTOCOL AND
% NOT THE LAST RESORT. The corpus states 100 milliseconds, twice, in two documents. DECISION-2 fixed
% one hundred ticks to the nominal second. 100 milliseconds is therefore TEN TICKS EXACTLY, computed
% below through tick_engine_ticks_from_milliseconds/2 rather than written down as ten - so it can never
% drift from the convention it is made of, and so a later session that restates the tick rate moves
% this lag with it. THE NUMBER TEN APPEARS NOWHERE IN THIS PACK.
%
% WHAT THE CORPUS DOES NOT SETTLE, AND THIS PACK THEREFORE DOES NOT BUILD. It does not say how the
% prediction and the delayed sensory evidence should be WEIGHTED against each other - Chapter 51.2.1
% says the combination is "formally like a Kalman filter" and states no reliability. That is a fusion
% rule and it needs numbers nothing has supplied, so this pack RELEASES the prediction and compares
% nothing: the comparison belongs to the comparator, which already exists, and the weighting belongs to
% a decision nobody has argued yet. THE CARRIER CARRIES. It does not judge.

% ---------------------------------------------------------------------------
% THE LAG
% ---------------------------------------------------------------------------

% running_prediction_lag_milliseconds(-Milliseconds): the corpus's feedback lag, in the corpus's unit.
running_prediction_lag_milliseconds(100).

% running_prediction_lag_ticks(-Ticks): the same lag as a whole number of ticks, DERIVED.
running_prediction_lag_ticks(Ticks) :-
    % Read the corpus's duration from the one place this pack states it.
    running_prediction_lag_milliseconds(Milliseconds),
    % Convert through the scheduler's single conversion, which REFUSES a duration that does not land
    % exactly on a tick boundary rather than rounding it - so if a later session restates the tick
    % rate to something this lag does not divide into, this predicate throws instead of lying.
    tick_engine_ticks_from_milliseconds(Milliseconds, Ticks).

% ---------------------------------------------------------------------------
% THE CARRIER
% ---------------------------------------------------------------------------
%
% THE CARRIER HOLDS BOTH PREDICTIONS AND THE REASON IS THAT BOTH ARE FACTS ABOUT THE MOMENT OF ISSUE.
% What the command predicted, and what the mind would have predicted had it done nothing, are BOTH
% computed from the world as it stood when the command went out. Recomputing the null prediction at
% release time would compute it from a world the command has already changed, which would answer a
% different question - and would answer it plausibly, which is worse.

% running_prediction_new(-Carrier): an empty carrier, holding nothing.
running_prediction_new(running_prediction_carrier([])).

% running_prediction_shape(+Carrier, -Retained): open a carrier, refusing a hole or an impostor.
running_prediction_shape(Carrier, Retained) :-
    % An unbound carrier is a hole, and a hole would unify with the empty carrier and read as empty.
    (   var(Carrier)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % A term that is not a carrier is refused aloud, naming what arrived.
    (   Carrier = running_prediction_carrier(Retained)
    ->  true
    ;   domain_error(running_prediction_carrier, Carrier)
    ),
    % The held store is judged as a store, so a hole inside a well-shaped carrier is caught too.
    must_be(list, Retained).

% running_prediction_holding(+Carrier, -Retained): everything the carrier holds, in issue order.
% NOTE THE NAME. The accessor is HOLDING and the data term it hands back is RETAINED, deliberately
% spelled differently, because a predicate and a term sharing a name is legal in Prolog and is exactly
% the kind of collision this build spent a page resolving over the word REGISTER.
running_prediction_holding(Carrier, Retained) :-
    % Open the carrier, refusing a hole or an impostor.
    running_prediction_shape(Carrier, Retained).

% running_prediction_retain(+Carrier0, +Tick, +Copy, +Predicted, +NullPredicted, -Carrier):
% hold one tick's prediction until the reading it is waiting for arrives.
running_prediction_retain(Carrier0, Tick, Copy, Predicted, NullPredicted, Carrier) :-
    % Open the carrier, refusing a hole or an impostor.
    running_prediction_shape(Carrier0, Retained0),
    % A tick is a whole non-negative count; an unbound one would be bound by the ordering check below.
    must_be(nonneg, Tick),
    % Only a real efference copy may be retained, judged by the copy pack's own guard rather than by a
    % second opinion here - so this carrier never becomes an authority on what a copy is.
    efference_copy_command(Copy, _Command),
    % Both predictions are reading sets and are judged as stores before either is stored.
    must_be(list, Predicted),
    % The null prediction is judged as strictly as the other; a hole in it would make exclusivity a guess.
    must_be(list, NullPredicted),
    % TIME DOES NOT RUN BACKWARDS IN A CARRIER, and a retention at or before the newest one already
    % held is refused rather than sorted into place. Sorting would accept a caller that had lost track
    % of its own clock and would hand it a plausible ordering back.
    running_prediction_check_later(Retained0, Tick),
    % Hold it at the back, so the store stays in issue order and the front is always the oldest.
    running_prediction_append(Retained0, running_prediction_retained(Tick, Copy, Predicted, NullPredicted), Retained),
    % Hand back the carrier holding it.
    Carrier = running_prediction_carrier(Retained).

% running_prediction_append(+Retained0, +Entry, -Retained): put one entry at the back of the held store.
% An exhausted store takes the entry as its only member.
running_prediction_append([], Entry, [Entry]).
% Walk past a held entry, keeping it in place, with the list first so the walk is indexed and clean.
running_prediction_append([Held|Rest0], Entry, [Held|Rest]) :-
    % Put the entry at the back of what remains.
    running_prediction_append(Rest0, Entry, Rest).

% running_prediction_check_later(+Retained, +Tick): a new retention must be strictly later than the last.
running_prediction_check_later(Retained, Tick) :-
    % An empty carrier accepts any tick; there is nothing for it to be later than.
    (   Retained == []
    ->  true
    % Otherwise the newest held entry is at the back, and the new tick must be strictly after it.
    ;   last(Retained, running_prediction_retained(Newest, _Copy, _Predicted, _NullPredicted)),
        % Refuse a tick that does not advance, naming both ticks so the caller can see its own error.
        (   Tick > Newest
        ->  true
        ;   domain_error(running_prediction_advancing_tick, Tick-Newest)
        )
    ).

% ---------------------------------------------------------------------------
% WHEN A PREDICTION COMES DUE
% ---------------------------------------------------------------------------

% running_prediction_due_tick(+IssuedAt, -DueAt): when the reading a prediction waits for arrives.
running_prediction_due_tick(IssuedAt, DueAt) :-
    % A tick is a whole non-negative count.
    must_be(nonneg, IssuedAt),
    % The lag, derived rather than written down.
    running_prediction_lag_ticks(Lag),
    % The reading that reflects this command arrives one full lag after the command went out.
    DueAt is IssuedAt + Lag.

% ---------------------------------------------------------------------------
% RELEASE, AND THE THIRD OUTCOME
% ---------------------------------------------------------------------------
%
% THREE OUTCOMES, NOT TWO, ON THE SUPERVISOR'S OWN PRECEDENT. A retained prediction is RELEASED (its
% reading has arrived), STILL WAITING (its reading has not), or STALE (its moment passed and nobody
% released it). The third is the one a two-outcome design would lose, and losing it is how a build
% comes to believe that a carrier which quietly dropped a prediction had nothing to carry. A STALE
% prediction is named and handed back, not deleted in silence.

% running_prediction_release(+Carrier0, +Tick, -Released, -Stale, -Carrier): release what is due now.
running_prediction_release(Carrier0, Tick, Released, Stale, Carrier) :-
    % Open the carrier, refusing a hole or an impostor.
    running_prediction_shape(Carrier0, Retained0),
    % A tick is a whole non-negative count; an unbound one would compare confidently against every entry.
    must_be(nonneg, Tick),
    % Sort every held prediction into released, stale, or still waiting, judging each as it is read.
    running_prediction_sort(Retained0, Tick, Released, Stale, Waiting),
    % The carrier keeps only what is still waiting; released and stale predictions have left it.
    Carrier = running_prediction_carrier(Waiting).

% running_prediction_sort(+Retained, +Tick, -Released, -Stale, -Waiting): sort the held store.
% An exhausted store releases nothing, stales nothing, and waits for nothing.
running_prediction_sort([], _Tick, [], [], []).
% Each held prediction is due now, overdue, or not yet due.
running_prediction_sort([Entry|Rest], Tick, Released, Stale, Waiting) :-
    % Refuse anything that is not a retained prediction, naming what arrived.
    (   Entry = running_prediction_retained(IssuedAt, _Copy, _Predicted, _NullPredicted)
    ->  true
    ;   domain_error(running_prediction_retained, Entry)
    ),
    % When this prediction's reading arrives, computed rather than stored.
    running_prediction_due_tick(IssuedAt, DueAt),
    % Sort this one, then sort the rest.
    (   DueAt =:= Tick
    ->  % Its reading has arrived, so it is released, carrying everything it was holding.
        Released = [running_prediction_released(IssuedAt, Entry)|MoreReleased],
        % A released prediction is not stale and is no longer waiting.
        Stale = MoreStale,
        % And it leaves the carrier.
        Waiting = MoreWaiting
    ;   DueAt < Tick
    ->  % Its moment passed and nobody took it. THAT IS REPORTED, BY NAME, AND NOT DROPPED.
        Released = MoreReleased,
        % The stale entry carries the tick it came due at, so a caller can see how far behind it is.
        Stale = [running_prediction_stale(IssuedAt, DueAt)|MoreStale],
        % And it leaves the carrier, because holding it forever would make every later release stale too.
        Waiting = MoreWaiting
    ;   % Its reading has not arrived yet, so it stays exactly where it is.
        Released = MoreReleased,
        % It is not stale.
        Stale = MoreStale,
        % And it is still held.
        Waiting = [Entry|MoreWaiting]
    ),
    % Sort the remaining held predictions.
    running_prediction_sort(Rest, Tick, MoreReleased, MoreStale, MoreWaiting).

% ---------------------------------------------------------------------------
% READING A RELEASED PREDICTION
% ---------------------------------------------------------------------------

% running_prediction_released_issued_at(+Released, -IssuedAt): the tick it was issued at.
running_prediction_released_issued_at(Released, IssuedAt) :-
    % Open the released term, refusing a hole or an impostor.
    running_prediction_open_released(Released, IssuedAt, _Copy, _Predicted, _NullPredicted).

% running_prediction_released_predictions(+Released, -Predicted, -NullPredicted): both predictions.
running_prediction_released_predictions(Released, Predicted, NullPredicted) :-
    % Open the released term, refusing a hole or an impostor.
    running_prediction_open_released(Released, _IssuedAt, _Copy, Predicted, NullPredicted).

% running_prediction_open_released(+Released, -IssuedAt, -Copy, -Predicted, -NullPredicted): open one.
running_prediction_open_released(Released, IssuedAt, Copy, Predicted, NullPredicted) :-
    % An unbound release is a hole.
    (   var(Released)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % A term that is not a release is refused aloud, naming what arrived.
    (   Released = running_prediction_released(IssuedAt,
            running_prediction_retained(IssuedAt, Copy, Predicted, NullPredicted))
    ->  true
    ;   domain_error(running_prediction_released, Released)
    ).
