% Declare this file as the 'apparent_causation' module and list the predicates it exports.
:- module(apparent_causation, [
    % apparent_causation_conditions/1: the three conditions the corpus names, in the corpus's order.
    apparent_causation_conditions/1,
    % apparent_causation_null_command/1: the build's own name for doing nothing.
    apparent_causation_null_command/1,
    % apparent_causation_priority/4: did the thought precede the action, in a recorded order of events.
    apparent_causation_priority/4,
    % apparent_causation_consistency/2: was the thought consistent with what the action produced.
    apparent_causation_consistency/2,
    % apparent_causation_exclusivity/3: is any other cause apparent - OBSERVATION-17's closer.
    apparent_causation_exclusivity/3,
    % apparent_causation_authorship/2: the corpus's conjunction, and nothing more than it.
    apparent_causation_authorship/2,
    % apparent_causation_of_step/4: one closed pass over an efference copy step.
    apparent_causation_of_step/4,
    % apparent_causation_of_released/4: the carried form, in which PRIORITY can actually fail.
    apparent_causation_of_released/4,
    % apparent_causation_judgement_conditions/2: read the three conditions out of a judgement.
    apparent_causation_judgement_conditions/2,
    % apparent_causation_judgement_verdict/2: read the authorship verdict out of a judgement.
    apparent_causation_judgement_verdict/2
]).

% Import the comparator pack whose cue this pack reads, and whose degenerate case it closes.
:- use_module(library(efference_copy), [
    % efference_copy_of/2: take the internal duplicate of an outgoing command.
    efference_copy_of/2,
    % efference_copy_forward_model/3: the predicted sensory consequences of a copied command.
    efference_copy_forward_model/3,
    % efference_copy_step/5: one closed comparator pass.
    efference_copy_step/5,
    % efference_copy_report_cue/2: read the graded match cue out of a step's report.
    efference_copy_report_cue/2,
    % efference_copy_match_cue/3: the graded cue, computed from a prediction and a reading directly.
    efference_copy_match_cue/3
]).
% Import the carrier that holds a prediction across the sensory lag, which is what makes the carried
% form below possible - and which is what OBSERVATION-20 said priority was waiting for.
:- use_module(library(running_prediction), [
    % running_prediction_released_issued_at/2: the tick a released prediction was issued at.
    running_prediction_released_issued_at/2,
    % running_prediction_released_predictions/3: the command's prediction and the null command's.
    running_prediction_released_predictions/3
]).
% Import the list utilities used to walk a recorded order of events.
:- use_module(library(lists), [memberchk/2]).
% Import the type checker that refuses a hole aloud.
:- use_module(library(error), [must_be/2, domain_error/2, existence_error/2]).

% ---------------------------------------------------------------------------
% WHAT THIS PACK IS
% ---------------------------------------------------------------------------
%
% This is THE_NEUROSCIENCE_OF_COGNITION_MANUSCRIPT.txt CHAPTER 63.2.4, VOLITION AS A GRADED AND
% RECONSTRUCTED ATTRIBUTION, in the north-star directory of the Twentieth Commandment. The chapter's
% mechanism, in its own words: "Daniel Wegner's theory of apparent mental causation, set out in his
% 2002 book The Illusion of Conscious Will, holds that we infer authorship when A THOUGHT PRECEDES AN
% ACTION, IS CONSISTENT WITH IT, AND NO OTHER CAUSE IS APPARENT - which means agency can be
% manufactured by arranging those conditions artificially, and can be missing when they are absent
% even for actions we really did perform."
%
% THREE CONDITIONS, NAMED, IN ONE SENTENCE: PRIORITY, CONSISTENCY, EXCLUSIVITY. konnectome did not
% have to search for them and did not search for them. Under the Twenty-Second Commandment's FIRST
% step the corpus was read beneath the finding, and under its SECOND step - if the corpus settles it,
% build it in the same act - this pack is that act.
%
% AND THIS PACK IS OBSERVATION-17'S NAMED CLOSER, WRITTEN BY THE OBSERVATION ITSELF. Slice 56 recorded
% that the comparator awards a perfect match to hold_still in a still world, so a comparator-only
% sense of agency would report maximum authorship for doing nothing. It named what would close it:
% "Agency needs a cue that distinguishes 'the world matched my prediction BECAUSE I CAUSED IT' from
% 'the world matched my prediction because NOTHING WAS GOING TO HAPPEN ANYWAY'. That is Wegner's
% EXCLUSIVITY condition and it is a second mechanism." It is built below, as a second pack rather than
% as a repair to the first, exactly as the observation said it should be.
%
% THERE IS NOT ONE NUMBER IN THIS PACK, WHICH IS WORTH STATING RATHER THAN LEAVING TO BE NOTICED. No
% threshold, no weight, no tolerance and no gain. Every one of the three conditions is a comparison
% between two things konnectome already holds, and the verdict is the corpus's own conjunction. The
% Twenty-First Commandment's order of resort never reaches past its FIRST protocol here.

% ---------------------------------------------------------------------------
% DECISION-18 - THE THREE CONDITIONS, READ INTO KONNECTOME'S OWN TERMS
% ---------------------------------------------------------------------------
%
% THE CORPUS STATES THE CONDITIONS IN THE VOCABULARY OF A PERSON AND KONNECTOME HAS TO STATE THEM IN
% THE VOCABULARY OF A RUNNING MACHINE. That translation is konnectome's own and is signed here rather
% than left to look like the chapter's, which is the Twenty-First Commandment's whole condition.
%
% PRIORITY - "a thought precedes an action" - IS READ AS A STRICT ORDER OVER RECORDED EVENTS. The
% thought must appear in the recorded order of a pass, the action must appear in it, and the thought's
% position must be strictly earlier. Nothing is inferred from an event nobody recorded: a thought or an
% action absent from the order is REFUSED ALOUD rather than treated as absent-and-therefore-later.
%
% CONSISTENCY - "is consistent with it" - IS READ AS THE COMPARATOR'S OWN CUE WITH NO DEPARTURES. The
% efference copy pack already publishes match_cue(matched(M), departed(D)), and consistency holds when
% D is zero: every channel the mind predicted read as the mind predicted. THE ZERO IS NOT A THRESHOLD
% KONNECTOME CHOSE. It is the absence of departure, and a tolerance - how much departure still counts
% as consistent - is precisely the number DECISION-13 refused to invent and this slice does not invent
% either.
%
% EXCLUSIVITY - "and no other cause is apparent" - IS READ AS DIFFERENCE-MAKING AGAINST THE NULL
% COMMAND, AND THIS IS THE LOAD-BEARING HALF OF THE DECISION. The rival cause konnectome's degenerate
% case actually has is THE WORLD'S OWN PERSISTENCE: when the command's forward model predicts exactly
% the world that already stands, the standing world is a fully sufficient explanation of what follows,
% it is apparent to the mind because the mind is looking straight at it, and the command explains
% nothing that the world was not going to do by itself. So exclusivity holds when the command's
% prediction DIFFERS from the null command's prediction, and fails when it does not.
%
% WHAT THAT BUYS, IN THE EXACT TERMS OBSERVATION-17 PINNED. hold_still's forward model IS the world as
% it stands, by the transcription of the machine's own clause, so hold_still can never be exclusive in
% any world at all. The steer that clears a real obstacle predicts a path the standing world does not
% show, so it is. THE TWO CUES THAT SLICE 56 PROVED IDENTICAL ARE NOW DIFFERENT TERMS, and a test in
% this pack asserts that as a term inequality rather than as a paragraph.
%
% AND IT CATCHES A CASE NOBODY ASKED IT TO, WHICH IS THE EVIDENCE THAT THE READING IS DOING WORK
% RATHER THAN FITTING THE ONE EXAMPLE IT WAS BUILT FROM. A steer_around issued at an ALREADY CLEAR
% path is not the null command and would pass any test that only banned hold_still - and it is not
% exclusive either, correctly, because it too predicts the world that already stands. The rule is
% about the difference the command makes and not about the command's name.
%
% WHAT DECISION-18 DOES NOT DECIDE.
%
% IT DOES NOT WEIGH THE CUES. Chapter 63.2.4 says prediction is "one cue among several, weighted more
% heavily when it is reliable" and states no weight. This pack holds three conditions and combines
% them by the corpus's own CONJUNCTION - "when a thought precedes an action, IS consistent with it,
% AND no other cause is apparent" - which is a transcription and not a weighting. A weighted mixture
% is a different construct and needs numbers nothing has supplied.
%
% IT DOES NOT SPLIT THE FEELING FROM THE JUDGEMENT. Synofzik, Vosgerau and Newen's two levels remain
% one construct here, exactly as DECISION-13 left them.
%
% IT DOES NOT WITHDRAW DECISION-13. The comparator still publishes a cue and still refuses a verdict:
% efference_copy_agency_judgement/2 throws today as it threw at slice 56. What has changed is that a
% verdict is now reachable from THREE conditions rather than from the match alone, which is the thing
% the chapter said the match alone could not support.
%
% AND IT DOES NOT CLAIM THE WORLD'S CONTRIBUTION IS OBSERVABLE FROM INSIDE. The world event remains
% the caller's argument, as it is in the comparator pack. Every condition above is computed from what
% the mind itself holds - its own command, its own forward model, and its own sensed readings - and
% nothing here reaches for a fact the mind would have no way to know.

% ---------------------------------------------------------------------------
% OBSERVATION-20 - PRIORITY IS FREE INSIDE A SINGLE PASS, SO THE CONJUNCTION RESTS ON TWO CONDITIONS
% ---------------------------------------------------------------------------
%
% RECORDED HERE BECAUSE IT IS THE SORT OF THING THAT READS AS A CONDITION PASSING WHEN IT IS A
% CONDITION THAT CANNOT FAIL. Inside one efference copy pass the copy is taken BEFORE the command
% reaches the actuator - that ordering is structural, it is the point of an efference copy, and
% apparent_causation_of_step/4 therefore records an order in which the thought always precedes the
% action. Priority is met in every pass this build can currently run.
%
% A CONDITION THAT CANNOT FAIL CARRIES NO INFORMATION, and the honest reading is that konnectome's
% authorship verdict rests on two conditions with a third standing beside it looking like a third.
% This is the same family as slice 47's boundary that could never be crossed, and it is the ninth
% finding of the would-not-have-failed shape in this build.
%
% WHAT WOULD MAKE PRIORITY REAL, NAMED SO THE HOLE IS VISIBLE. Priority becomes informative the moment
% a thought can arrive from somewhere OTHER than the command path - a thought formed on one tick and an
% action issued on another. Priority is therefore built and exported as a GENERAL predicate over a
% recorded order rather than as a constant, so that it is ready on the day an order with a real choice
% in it exists, and it is exercised in this pack's tests against orders that DO have a choice in them.
%
% AND THAT DAY WAS SLICE 67, ONE SLICE LATER, BECAUSE THE OBSTACLE TURNED OUT NOT TO BE THERE. This
% comment used to end by citing the standing obstacle - "no construct in this build carries anything
% across a tick" - as the reason priority could not be made real. THAT SENTENCE WAS FALSE and had been
% false for the whole of its life: the hold construct's own mode gloss says it keeps its value "from one
% tick to the next", the copy construct is a one-tick delay by construction, connection_graph's delay
% lines are a purpose-built tick-crossing buffer, and the running cognitive cycle threads eligibility
% traces and reads the governor's selection on the tick after it was written. Five hand-offs carried the
% claim and nothing ever checked it.
%
% SO OBSERVATION-20 IS CLOSED FOR THE CARRIED FORM AND STANDS FOR THIS ONE. apparent_causation_of_step/4,
% below, is a SINGLE CLOSED PASS and its priority still cannot fail, structurally, for the reason given
% above - that is correct behaviour for a single pass and is not a defect to repair. What was missing was
% a SECOND entry point, over a prediction retained across the lag, where the thought's tick and the
% action's tick are two different facts that a caller can get wrong. That is
% apparent_causation_of_released/4, and in it priority discriminates.

% ---------------------------------------------------------------------------
% THE THREE CONDITIONS, NAMED
% ---------------------------------------------------------------------------

% apparent_causation_conditions(-Conditions): the three conditions, in the corpus's own order.
apparent_causation_conditions([priority, consistency, exclusivity]).

% apparent_causation_null_command(-Command): the build's own name for doing nothing.
% hold_still is not this pack's invention: simulated_body carries it, body_interface_command/2 maps
% the selector's "nothing" outcome onto it, and its documented effect is that nothing changes but the
% log. The null command is READ OUT OF THE BUILD rather than declared here.
apparent_causation_null_command(hold_still).

% ---------------------------------------------------------------------------
% PRIORITY - THE THOUGHT PRECEDES THE ACTION
% ---------------------------------------------------------------------------

% apparent_causation_priority(+Order, +Thought, +Action, -Condition): did the thought come first.
apparent_causation_priority(Order, Thought, Action, Condition) :-
    % Judge the recorded order's shape, so a hole is never walked as an empty history.
    must_be(list, Order),
    % AN EVENT NAME NEED NOT BE AN ATOM AND THE GUARD IS THEREFORE ABOUT HOLES RATHER THAN ABOUT TYPE.
    % What must be refused is an UNBOUND event, which the position lookup would bind to whichever event
    % was recorded first, answering confidently about a thought nobody named. A compound event name is
    % legitimate and is what the carried pass uses, so that two events on one tick are one term.
    apparent_causation_check_event(Thought),
    % The action is judged in the same breath and for the same reason.
    apparent_causation_check_event(Action),
    % Find where the thought stands in the record, refusing a thought nobody recorded.
    apparent_causation_position(Order, Thought, ThoughtAt),
    % Find where the action stands in the record, refusing an action nobody recorded.
    apparent_causation_position(Order, Action, ActionAt),
    % STRICTLY earlier: an event cannot precede itself, and two events at one position are not an order.
    (   ThoughtAt < ActionAt
    ->  Condition = priority(met)
    ;   Condition = priority(not_met(thought_did_not_precede_action(Thought, Action)))
    ).

% apparent_causation_check_event(+Event): refuse a hole where an event name belongs.
apparent_causation_check_event(Event) :-
    % A PARTIAL TERM IS A HOLE TOO, which is why this is a groundness check and not a var check: an
    % event named thought_at(_) would unify with any thought_at whatever and report a confident order.
    (   ground(Event)
    ->  true
    ;   throw(error(instantiation_error, _))
    ).

% apparent_causation_position(+Order, +Event, -Position): where a recorded event stands, from zero.
apparent_causation_position(Order, Event, Position) :-
    % An event that was never recorded is refused rather than treated as late, absent, or harmless.
    (   memberchk(Event, Order)
    ->  true
    ;   existence_error(apparent_causation_recorded_event, Event)
    ),
    % Walk the record from its front, counting, with the list first so the walk is indexed and clean.
    apparent_causation_walk(Order, Event, 0, Position).

% apparent_causation_walk(+Order, +Event, +Position0, -Position): count events up to the named one.
% The event standing at the front of what remains is the one being counted to.
apparent_causation_walk([Event|_Rest], Event, Position, Position) :-
    % Commit to the first occurrence, so a repeated event is read at its EARLIEST position.
    !.
% Any other event at the front is stepped past, raising the count by one.
apparent_causation_walk([_Other|Rest], Event, Position0, Position) :-
    % Raise the count for the event just stepped past.
    Position1 is Position0 + 1,
    % Count through the remaining record.
    apparent_causation_walk(Rest, Event, Position1, Position).

% ---------------------------------------------------------------------------
% CONSISTENCY - THE THOUGHT IS CONSISTENT WITH THE ACTION
% ---------------------------------------------------------------------------

% apparent_causation_consistency(+MatchCue, -Condition): read the comparator's own cue.
apparent_causation_consistency(MatchCue, Condition) :-
    % An unbound cue is a hole, and a hole is refused before a consistency is read out of it.
    (   var(MatchCue)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % A term that is not the comparator's cue is refused aloud, naming what arrived.
    (   MatchCue = match_cue(matched(Matched), departed(Departed))
    ->  true
    ;   domain_error(apparent_causation_match_cue, MatchCue)
    ),
    % Both counts are judged here, in the one place a cue comes through, rather than at the comparison.
    must_be(integer, Matched),
    % The departed count is judged as strictly as the matched one; a hole in either makes this a guess.
    must_be(integer, Departed),
    % NO DEPARTURE IS CONSISTENCY, and how much departure is still consistent is the tolerance
    % DECISION-13 refused to invent. This slice does not invent it either.
    (   Departed =:= 0
    ->  Condition = consistency(met)
    ;   Condition = consistency(not_met(channels_departed(Departed)))
    ).

% ---------------------------------------------------------------------------
% EXCLUSIVITY - NO OTHER CAUSE IS APPARENT
% ---------------------------------------------------------------------------

% apparent_causation_exclusivity(+Predicted, +NullPredicted, -Condition): did the command make a
% difference to what was going to happen anyway.
apparent_causation_exclusivity(Predicted, NullPredicted, Condition) :-
    % An unbound prediction is a hole, and two holes would unify and report a confident non-exclusivity.
    (   var(Predicted)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % The null command's prediction is judged in the same breath and for the same reason.
    (   var(NullPredicted)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % Both are reading sets and are judged as stores before either is compared with the other.
    must_be(list, Predicted),
    % The same judgement for the second reading set, in the same place.
    must_be(list, NullPredicted),
    % IDENTICAL PREDICTIONS MEAN THE STANDING WORLD ALREADY EXPLAINS EVERYTHING THE COMMAND PREDICTED,
    % and a sufficient rival cause the mind is looking straight at is an apparent one.
    (   Predicted == NullPredicted
    ->  Condition = exclusivity(not_met(command_predicts_no_difference(Predicted)))
    ;   Condition = exclusivity(met)
    ).

% ---------------------------------------------------------------------------
% THE CORPUS'S CONJUNCTION, AND NOTHING MORE THAN IT
% ---------------------------------------------------------------------------

% apparent_causation_authorship(+Conditions, -Verdict): authorship is inferred when all three hold.
apparent_causation_authorship(Conditions, Verdict) :-
    % Judge the store's shape, so a hole is never walked as a set of conditions that all held.
    must_be(list, Conditions),
    % Every one of the three conditions must be present, in the corpus's order, and judged as read.
    apparent_causation_conditions(Named),
    % Refuse a set that does not carry exactly the three conditions the corpus names.
    apparent_causation_check_named(Named, Conditions),
    % Gather whichever of them were not met, keeping the reason each carries.
    apparent_causation_unmet(Conditions, Unmet),
    % THE CORPUS JOINS ITS THREE CONDITIONS WITH "AND", so konnectome joins them with a conjunction.
    (   Unmet == []
    ->  Verdict = authorship_inferred
    ;   Verdict = authorship_not_inferred(Unmet)
    ).

% apparent_causation_check_named(+Named, +Conditions): each named condition must be present, once.
% An exhausted list of names has been fully accounted for.
apparent_causation_check_named([], _Conditions).
% Each named condition must appear in the set, carrying either a met or a not_met reading.
apparent_causation_check_named([Name|Rest], Conditions) :-
    % Build the shape this condition arrives in - its own name over one reading, whatever that reading
    % says. THE READING IS DELIBERATELY NOT JUDGED HERE: this check asks only whether the condition is
    % PRESENT, and the walk below asks whether what it says can be read. Judging both in one place
    % would make an unreadable condition indistinguishable from an absent one, which are different
    % faults with different repairs.
    Shape =.. [Name, _Reading],
    % A condition absent from the set is refused aloud: a missing condition is not a met one.
    (   memberchk(Shape, Conditions)
    ->  true
    ;   existence_error(apparent_causation_condition, Name)
    ),
    % Account for the remaining named conditions.
    apparent_causation_check_named(Rest, Conditions).

% apparent_causation_unmet(+Conditions, -Unmet): the conditions that were not met, reasons and all.
% An exhausted set leaves nothing unmet.
apparent_causation_unmet([], []).
% A condition carrying a not_met reading joins the unmet list, reason included.
apparent_causation_unmet([Condition|Rest], Unmet) :-
    % A condition is a one-field term whose field is the reading; anything else is refused aloud.
    (   Condition =.. [_Name, Reading]
    ->  true
    ;   domain_error(apparent_causation_condition, Condition)
    ),
    % Sort this condition into the unmet list or past it, then account for the rest.
    (   Reading = not_met(_Why)
    ->  Unmet = [Condition|MoreUnmet]
    ;   Reading == met
    ->  Unmet = MoreUnmet
    ;   domain_error(apparent_causation_condition_reading, Reading)
    ),
    % Account for the remaining conditions.
    apparent_causation_unmet(Rest, MoreUnmet).

% ---------------------------------------------------------------------------
% THE CLOSED PASS
% ---------------------------------------------------------------------------
%
% PRIORITY IS FREE IN THIS PREDICATE BY DESIGN AND THAT IS NOT THE DEFECT - see the carried pass below,
% which is where priority discriminates. A single closed pass takes the copy before it sends the
% command; there is no other order it could record without lying about what it did.
%
% THE ORDER OF EVENTS THIS PASS RECORDS IS KONNECTOME'S OWN STEP ORDER AND NOT A CLAIM ABOUT MINDS.
% efference_copy_step/5 takes the copy, predicts, enacts, lets the world act, and senses - in that
% order, in that predicate, checkable by reading it. The record below states that order and nothing
% else, which is why priority reads as met in every pass and why OBSERVATION-20 says so out loud.

% apparent_causation_of_step(+Body0, +Command, +WorldEvent, -Judgement): one closed pass.
apparent_causation_of_step(Body0, Command, WorldEvent, Judgement) :-
    % Take the copy of the command the mind is issuing - the thought, in the corpus's vocabulary.
    efference_copy_of(Command, Copy),
    % The command's own forward model, from the world as it stands.
    efference_copy_forward_model(Copy, Body0, Predicted),
    % The null command's forward model, from the SAME world, which is what would have happened anyway.
    apparent_causation_null_command(Null),
    % Take a copy of the null command too, so its prediction comes through the same door as the other.
    efference_copy_of(Null, NullCopy),
    % The world the mind would be looking at had it done nothing at all.
    efference_copy_forward_model(NullCopy, Body0, NullPredicted),
    % Run the comparator pass itself, which is where the world takes its own turn.
    efference_copy_step(Body0, Command, WorldEvent, _Body, Report),
    % Read the graded match cue back out of the comparator's report.
    efference_copy_report_cue(Report, MatchCue),
    % PRIORITY, against this build's own recorded step order.
    apparent_causation_priority([thought_of_command, action_issued, world_acted, world_sensed],
                                thought_of_command, action_issued, Priority),
    % CONSISTENCY, against the comparator's own cue.
    apparent_causation_consistency(MatchCue, Consistency),
    % EXCLUSIVITY, against the world that was going to stand there anyway.
    apparent_causation_exclusivity(Predicted, NullPredicted, Exclusivity),
    % The three conditions, in the corpus's own order.
    Conditions = [Priority, Consistency, Exclusivity],
    % And the corpus's conjunction over them.
    apparent_causation_authorship(Conditions, Verdict),
    % One glass-box judgement per pass, carrying the conditions beside the verdict they produced.
    Judgement = apparent_causation_judgement(Conditions, Verdict).

% ---------------------------------------------------------------------------
% THE CARRIED PASS, IN WHICH PRIORITY CAN FAIL (slice 67)
% ---------------------------------------------------------------------------
%
% THE DIFFERENCE BETWEEN THIS AND THE CLOSED PASS IS ENTIRELY IN WHERE THE TWO TICKS COME FROM. In a
% closed pass the copy is taken and the command sent inside one predicate, so the ordering is
% structural and priority is free. Here the thought was retained by running_prediction at the tick it
% was ISSUED, and the action is being judged at the tick the reading ARRIVED - two facts, held apart by
% the sensory lag, and a caller that has lost track of its own clock can present them in the wrong
% order. PRIORITY IS THE CONDITION THAT CATCHES THAT, and it is the only place in this build where it
% catches anything.
%
% THE ACTUAL READING IS THE CALLER'S ARGUMENT, in the same discipline the comparator uses for the
% world's own act. This pack does not sense.

% apparent_causation_of_released(+Released, +ActionTick, +Actual, -Judgement): the carried pass.
apparent_causation_of_released(Released, ActionTick, Actual, Judgement) :-
    % Read the tick the thought was issued at, refusing a hole or an impostor release.
    running_prediction_released_issued_at(Released, ThoughtTick),
    % Read both predictions the carrier held from the moment of issue.
    running_prediction_released_predictions(Released, Predicted, NullPredicted),
    % The tick the reading arrived at is judged as strictly as the one the carrier supplied.
    must_be(nonneg, ActionTick),
    % PRIORITY, AND HERE IT IS A FACT RATHER THAN A STRUCTURE. The recorded order is built from the two
    % ticks, so a thought that did not precede its action produces a failing condition and not a
    % contradiction in terms.
    apparent_causation_carried_order(ThoughtTick, ActionTick, Order, Thought, Action),
    % Judge it through the same general predicate the closed pass uses; there is one priority rule.
    apparent_causation_priority(Order, Thought, Action, Priority),
    % CONSISTENCY, against the reading that actually arrived, through the comparator's own cue.
    efference_copy_match_cue(Predicted, Actual, MatchCue),
    % Judge it through the same general predicate the closed pass uses.
    apparent_causation_consistency(MatchCue, Consistency),
    % EXCLUSIVITY, against the world that was going to stand there anyway - both predictions having been
    % computed at the moment of issue, which is why the carrier holds both rather than recomputing one.
    apparent_causation_exclusivity(Predicted, NullPredicted, Exclusivity),
    % The three conditions, in the corpus's own order.
    Conditions = [Priority, Consistency, Exclusivity],
    % And the corpus's conjunction over them.
    apparent_causation_authorship(Conditions, Verdict),
    % One glass-box judgement, the same shape the closed pass produces.
    Judgement = apparent_causation_judgement(Conditions, Verdict).

% apparent_causation_carried_order(+ThoughtTick, +ActionTick, -Order, -Thought, -Action): build a
% recorded order from two ticks, naming each event for the tick it happened on.
apparent_causation_carried_order(ThoughtTick, ActionTick, Order, Thought, Action) :-
    % EACH EVENT IS NAMED FOR ITS TICK AND FOR NOTHING ELSE, which is the load-bearing choice here.
    % Naming them thought_at(T) and action_at(T) would have been the obvious move and would have been
    % wrong: two such names are distinct terms even when the ticks are equal, so a thought simultaneous
    % with its action would have read as preceding it. Naming both by the tick alone makes two events on
    % ONE tick the SAME term, and "nothing precedes itself" then does real work rather than being a
    % curiosity carried over from the closed pass.
    Thought =.. [tick, ThoughtTick],
    % The action's event name is built the same way, from its own tick.
    Action =.. [tick, ActionTick],
    % The record runs earliest first, which is what an order IS; the two ticks decide which that is.
    % NOTE WHAT HAPPENS WHEN THE TWO TICKS ARE EQUAL. The two event names become the same term, the
    % record holds it twice, and priority fails on the rule that nothing precedes itself - which is the
    % honest answer, because a thought simultaneous with its action is not evidence of authorship under
    % a condition whose whole name is PRIORITY.
    (   ThoughtTick =< ActionTick
    ->  Order = [Thought, Action]
    ;   Order = [Action, Thought]
    ).

% ---------------------------------------------------------------------------
% READING A JUDGEMENT
% ---------------------------------------------------------------------------

% apparent_causation_judgement_conditions(+Judgement, -Conditions): the three conditions.
apparent_causation_judgement_conditions(Judgement, Conditions) :-
    % Open the judgement, refusing a hole or an impostor.
    apparent_causation_open(Judgement, Conditions, _Verdict).

% apparent_causation_judgement_verdict(+Judgement, -Verdict): the authorship verdict.
apparent_causation_judgement_verdict(Judgement, Verdict) :-
    % Open the judgement, refusing a hole or an impostor.
    apparent_causation_open(Judgement, _Conditions, Verdict).

% apparent_causation_open(+Judgement, -Conditions, -Verdict): open a judgement term.
apparent_causation_open(Judgement, Conditions, Verdict) :-
    % An unbound judgement is a hole.
    (   var(Judgement)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % A term that is not a judgement is refused aloud, naming what arrived.
    (   Judgement = apparent_causation_judgement(Conditions, Verdict)
    ->  true
    ;   domain_error(apparent_causation_judgement, Judgement)
    ).
