% Declare this file as the 'conflict_monitor' module and list the predicates it exports.
:- module(conflict_monitor, [
    % conflict_monitor_incompatible/2: two simultaneously active drives that propose DIFFERENT actions.
    conflict_monitor_incompatible/2,
    % conflict_monitor_conflict/3: the response conflict standing among a set of drives, at a threshold.
    conflict_monitor_conflict/3,
    % conflict_monitor_check_gain/1: refuse a gain that would open the loop or run it backwards.
    conflict_monitor_check_gain/1,
    % conflict_monitor_agency/1: this pack's agency, which is a BIAS and never a row in any table.
    conflict_monitor_agency/1,
    % conflict_monitor_inviolable_rank/1: the rank the raised threshold may never reach past.
    conflict_monitor_inviolable_rank/1,
    % conflict_monitor_raise/4: control raised by the measured conflict and the CALLER'S gain.
    conflict_monitor_raise/4,
    % conflict_monitor_effective_threshold/3: the threshold a drive of some rank actually faces.
    conflict_monitor_effective_threshold/3,
    % conflict_monitor_arbitrate/5: arbitration under a raised threshold, with the inviolable rank exempt.
    conflict_monitor_arbitrate/5,
    % conflict_monitor_step/7: one full turn of the loop - measure, raise, publish, arbitrate.
    conflict_monitor_step/7,
    % conflict_monitor_sequence/6: a run of trials, carrying control forward the way the Gratton effect needs.
    conflict_monitor_sequence/6,
    % conflict_monitor_fault_row/3: the loop's own fault regimes, declared for the supervisor to watch.
    conflict_monitor_fault_row/3,
    % conflict_monitor_faults/1: the fault block, gathered in declaration order.
    conflict_monitor_faults/1,
    % conflict_monitor_readings/4: the loop's readings, in the supervisor's own reading shape.
    conflict_monitor_readings/4
]).

% Import the type checker that refuses a hole or a wrong shape aloud.
:- use_module(library(error), [must_be/2, domain_error/2]).
% Import append for joining the two sides of the exemption back into one competition.
:- use_module(library(lists), [append/3]).
% Import the arbitrator whose competition this pack measures; the loop REUSES it and never restates it.
:- use_module(library(override_controller), [
    % override_controller_active/3: the override drives whose distress exceeds a threshold.
    override_controller_active/3,
    % override_controller_most_vital/2: the most vital (lowest-rank) drive among a set.
    override_controller_most_vital/2
]).
% Import the stabiliser, because CONTROL IS A BOUNDARY OFFSET and that is precisely what it carries.
:- use_module(library(stabiliser), [
    % stabiliser_publish/3: write a scalar bias onto the bus, as a LEVEL.
    stabiliser_publish/3,
    % stabiliser_bias/2: read the standing stability bias, ZERO by default.
    stabiliser_bias/2
]).

% ---------------------------------------------------------------------------
% WHAT THIS PACK IS, AND WHY IT IS A PACK
% ---------------------------------------------------------------------------
%
% THE NORTH STAR STATES A LOOP AND KONNECTOME HAD THREE UNJOINED PIECES OF IT. Chapter 52.2.1 gives
% Botvinick, Braver, Carter, Barch and Cohen's 2001 conflict monitoring theory in one sentence: the
% anterior cingulate "does not exert control at all - it detects response conflict, the simultaneous
% activation of incompatible responses, and passes that signal to the lateral prefrontal cortex, which
% then raises control". And it names what makes the arrangement worth building: "The elegance is that
% this closes a loop: conflict signals that control is insufficient, control is increased, conflict
% falls."
%
% konnectome has owned the pieces since slice 44 and never joined them. override_controller holds the
% competition - a set of drives, each with a distress and a proposed action, resolved against a
% threshold. stabiliser holds control - a scalar bias whose stated meaning is HOW FAR APART THE TWO
% BOUNDARIES SIT, in the units of whatever quantity the switch compares. Nothing measured the conflict,
% and nothing carried the signal from the first to the second. This pack is that wire.
%
% WHY CONTROL IS THE STABILISER'S BIAS AND NOT A NEW QUANTITY, which is the join that makes this
% wiring rather than invention. The stabiliser's own header already says a consumer may read the bias
% as "an offset on the gate's threshold". An override drive faces exactly such a threshold: it seizes
% control when its distress exceeds it. So RAISING CONTROL IS RAISING THAT BOUNDARY, and the scalar
% that raises it already exists, already travels on the bus as a level, and already has stated units.
% No second control channel was created, and DECISION-1 is inherited rather than re-opened.
%
% WHAT "CONFLICT FALLS" MEANS HERE, STATED SO THE ANALOGY CAN BE CHECKED RATHER THAN ASSUMED. In the
% biology, raised control sharpens selection toward the task-relevant response. In konnectome, a
% raised boundary means fewer drives count as being in distress at all, so fewer incompatible actions
% are simultaneously active, so the measured conflict falls. THE FUNCTION IS THE SAME AND THE MECHANISM
% IS KONNECTOME'S OWN MEDIUM, which is the Eighth Commandment's translation rule applied literally:
% analogy of function, fidelity of interface, freedom of implementation.

% ---------------------------------------------------------------------------
% DECISION-15, FIRST HALF: THE FORM OF THE CONFLICT MEASURE IS KONNECTOME'S OWN
% ---------------------------------------------------------------------------
%
% THE CHAPTER SUPPLIES THE DEFINITION AND NOT THE FORMULA, and this is stated plainly here rather than
% left for a reader to assume the corpus supplied both. What Chapter 52.2.1 states is "the simultaneous
% activation of incompatible responses". It gives no equation, and the north-star corpus was searched
% for one before this line was written.
%
% SO THE PAIRWISE FORM BELOW IS KONNECTOME'S OPERATIONALISATION OF THE CORPUS'S DEFINITION, and it is
% signed as such under the Twenty-First Commandment. Conflict is the sum, over every unordered PAIR of
% simultaneously active drives that propose DIFFERENT actions, of the product of their two distresses.
% Three properties earn it, each of which the definition demands and a simpler count would lose:
% it is ZERO when fewer than two drives are active, because one response alone is not a conflict;
% it is ZERO when every active drive proposes the SAME action, because agreement is not incompatibility;
% and it RISES with both the number of competitors and the strength of each, because "activation" is a
% quantity in the definition and not a flag.
%
% AND NOTE WHAT THE LOOP DOES NOT DEPEND ON, WHICH IS WHY THIS CHOICE IS SAFE TO MAKE. The acceptance
% test below is an INEQUALITY between two runs of the same measure, so it holds for ANY measure with
% these three properties. The form is konnectome's; the result does not rest on it.

% ---------------------------------------------------------------------------
% DECISION-15, SECOND HALF: THE GAIN IS THE CALLER'S, AND THE LOOP IS PINNED BY A COMPARISON
% ---------------------------------------------------------------------------
%
% THE OBVIOUS WAY TO CLOSE THIS LOOP IS TO WRITE DOWN HOW MUCH CONTROL A UNIT OF CONFLICT BUYS. That
% number would be konnectome's own invention sitting beside a real citation of a real chapter, which is
% this build's own name for the failure. AND THE CHAPTER REFUSES TO SUPPLY IT TWICE OVER: 52.2.1 states
% the loop's direction and no coupling, and 52.2.4 reports that three serious rivals to conflict
% monitoring now exist and "none has won" - the expected value of control account makes the allocation
% a cost-benefit calculation over the payoff of control and "the intrinsic cost of cognitive effort",
% neither of which konnectome has. A gain chosen here would be picking a winner in a live dispute.
%
% SO THE GAIN IS THE CALLER'S, which is this build's third use of the same escape and follows the house
% precedent exactly: the supervisor never invents an allowance, DECISION-4 gave the window to the
% caller, and DECISION-14 made a competence a caller-named set of edges.
%
% AND THE LOOP IS STILL FULLY TESTABLE WITHOUT IT, WHICH IS THE POINT WORTH CARRYING AWAY. The chapter
% supplies its own acceptance test and it is a COMPARISON, not a level: the Gratton effect, where
% "interference on an incongruent trial is smaller when the previous trial was also incongruent,
% because conflict on trial n recruited control that is still in place on trial n plus 1". That is an
% ablation - the same trial run twice, once with the previous trial's control carried forward and once
% without - and IT HOLDS FOR EVERY POSITIVE GAIN. The loop's correctness is monotone in a number
% konnectome therefore never has to choose. This is the ninth time this build has preferred a refusal
% or a derivation to an invented default.

% ---------------------------------------------------------------------------
% THE SAFETY PROPERTY THIS LOOP PUTS AT RISK, AND THE REFUSAL THAT ANSWERS IT
% ---------------------------------------------------------------------------
%
% CLOSING THIS LOOP CREATES A HAZARD THAT NEITHER PIECE HAD ON ITS OWN, and it was found by building
% rather than foreseen. override_controller's header states konnectome's "one inviolable safety
% property": breathing beats deliberation, and the respiration drive - rank zero - can never be
% suppressed. The loop's whole business is RAISING the threshold a drive must exceed. Run it far
% enough on a conflicted mind and the raised boundary passes above respiration's distress, at which
% point the mind stops breathing in order to stop feeling conflicted. EVERY TEST WOULD STILL BE GREEN.
%
% SO THE RAISE IS EXEMPT AT THE INVIOLABLE RANK, and the exemption is a refusal written into the code
% rather than a caution written into a comment. A drive at or beneath the inviolable rank faces the
% BASE threshold always, however much control the loop has raised; every other drive faces the raised
% one. Note that this is konnectome departing from the chapter deliberately: Botvinick's loop has no
% such exemption, because a laboratory conflict task has nothing in it that can kill the participant.
% The disagreement is recorded rather than resolved by preference, as the First Principle requires.

% conflict_monitor_agency(-Agency): this pack's agency, stated so it can be checked and not assumed.
% What it publishes is a BIAS, so it inherits the stabiliser's agency rather than minting a new one -
% it moves no construct, fires no transition, and appears in no register's transition table.
conflict_monitor_agency(broadcast_bias).

% conflict_monitor_inviolable_rank(-Rank): the rank the raised threshold may never reach past.
% ZERO, and it is override_controller's number rather than this pack's: its header names respiration
% as rank zero and as the drive that can never be suppressed. Naming it once here means the exemption
% and the safety property cannot drift apart.
conflict_monitor_inviolable_rank(0).

% conflict_monitor_incompatible(+First, +Second): two drives that propose DIFFERENT actions.
conflict_monitor_incompatible(override(_FirstName, _FirstRank, _FirstDistress, FirstAction),
                              override(_SecondName, _SecondRank, _SecondDistress, SecondAction)) :-
    % Incompatibility is a disagreement about what to do, and nothing else about the two drives.
    FirstAction \== SecondAction.

% conflict_monitor_conflict(+Overrides, +Threshold, -Conflict): the response conflict standing.
conflict_monitor_conflict(Overrides, Threshold, Conflict) :-
    % Refuse a threshold that is not a number, rather than letting the arithmetic be the first to notice.
    must_be(number, Threshold),
    % The competition is among the SIMULTANEOUSLY ACTIVE drives, which is the arbitrator's own question.
    override_controller_active(Overrides, Threshold, Active),
    % Sum the incompatible pairs, which is where the definition becomes a quantity.
    conflict_monitor_pairs(Active, Conflict).

% conflict_monitor_pairs(+Active, -Conflict): the summed product over incompatible pairs.
% With nothing active there is no conflict, which is the base case and also the honest answer.
conflict_monitor_pairs([], 0).
% With one drive active there is still no conflict, because one response alone is not a competition.
conflict_monitor_pairs([First | Rest], Conflict) :-
    % Weigh this drive against every drive after it, so each unordered pair is counted exactly once.
    conflict_monitor_against(Rest, First, Here),
    % Then weigh the rest of the set among themselves.
    conflict_monitor_pairs(Rest, There),
    % The conflict of the whole set is the conflict of its parts plus the pairs that span them.
    Conflict is Here + There.

% conflict_monitor_against(+Others, +Drive, -Sum): one drive's conflict with each drive after it.
% THE LIST LEADS THE ARGUMENTS so that first-argument indexing makes this deterministic; a measure
% that leaves a choicepoint behind would have the whole loop backtracking into arithmetic it has done.
% Against nobody, a drive is in no conflict at all.
conflict_monitor_against([], _Drive, 0).
% Against a set, add this pair's contribution to the contribution of the remainder.
conflict_monitor_against([Other | Rest], Drive, Sum) :-
    % A pair proposing the same action contributes nothing; an incompatible pair contributes the product.
    ( conflict_monitor_incompatible(Drive, Other)
      -> Drive = override(_Name, _Rank, Distress, _Action),
         Other = override(_OtherName, _OtherRank, OtherDistress, _OtherAction),
         Pair is Distress * OtherDistress
      ;  Pair = 0
    ),
    % Weigh this drive against the drives still to come.
    conflict_monitor_against(Rest, Drive, Rest0),
    % And add the two together.
    Sum is Pair + Rest0.

% conflict_monitor_check_gain(+Gain): refuse a gain that would open the loop or run it backwards.
conflict_monitor_check_gain(Gain) :-
    % Refuse a hole or a non-number aloud, at the door, rather than deep inside the arithmetic.
    must_be(number, Gain),
    % A gain of zero leaves control unraised, so the loop is not closed but merely wired; a negative
    % gain raises conflict in response to conflict, which is the runaway the chapter's loop exists to
    % prevent. Both are refused BY NAME, because a silently open loop looks exactly like a closed one.
    (   Gain > 0
    ->  true
    ;   domain_error(conflict_monitor_gain_that_closes_the_loop, Gain)
    ).

% conflict_monitor_raise(+Threshold0, +Conflict, +Gain, -Threshold): control raised by the conflict.
conflict_monitor_raise(Threshold0, Conflict, Gain, Threshold) :-
    % Refuse a base threshold that is not a number.
    must_be(number, Threshold0),
    % Refuse a gain that would not close the loop.
    conflict_monitor_check_gain(Gain),
    % Control rises by the measured conflict scaled by the CALLER'S gain, and by nothing konnectome chose.
    Threshold is Threshold0 + (Gain * Conflict).

% conflict_monitor_is_inviolable(+Rank): this rank is exempt from every raise the loop makes.
% THE RULE LIVES HERE AND NOWHERE ELSE, because a safety property stated in two places is a safety
% property that can come apart in one of them.
conflict_monitor_is_inviolable(Rank) :-
    % Read the rank the raise may never reach past.
    conflict_monitor_inviolable_rank(Inviolable),
    % A rank at or beneath it is exempt; respiration sits at zero and is therefore always exempt.
    Rank =< Inviolable.

% conflict_monitor_effective_threshold(+Rank, +Thresholds, -Effective): the threshold a rank faces.
conflict_monitor_effective_threshold(Rank, thresholds(Base, Raised), Effective) :-
    % An inviolable drive faces the BASE threshold however high control has been raised; every other
    % drive faces the raised one. This is the safety refusal, and it is arithmetic rather than advice.
    (   conflict_monitor_is_inviolable(Rank)
    ->  Effective = Base
    ;   Effective = Raised
    ).

% conflict_monitor_arbitrate(+Overrides, +Base, +Raised, +NormalOutcome, -FinalOutcome): resolve control.
conflict_monitor_arbitrate(Overrides, Base, Raised, NormalOutcome, FinalOutcome) :-
    % Split the drives by the threshold each of them actually faces, which the exemption decides.
    conflict_monitor_split(Overrides, Inviolables, Ordinaries),
    % The inviolable drives are judged at the base threshold, so a raised boundary can never mute them.
    override_controller_active(Inviolables, Base, ActiveInviolables),
    % Every other drive is judged at the raised threshold, which is what raising control DOES.
    override_controller_active(Ordinaries, Raised, ActiveOrdinaries),
    % The competition is the two sets together.
    append(ActiveInviolables, ActiveOrdinaries, Active),
    % With nobody in distress the normal action stands; otherwise the most vital drive seizes control,
    % which is override_controller's own rule, reused rather than restated.
    (   Active == []
    ->  FinalOutcome = NormalOutcome
    ;   override_controller_most_vital(Active, override(_Name, _Rank, _Distress, Action)),
        FinalOutcome = released(Action)
    ).

% conflict_monitor_split(+Overrides, -Inviolables, -Ordinaries): part the drives by the exemption.
% An empty set parts into two empty sets.
conflict_monitor_split([], [], []).
% Otherwise each drive goes to the side its rank puts it on.
conflict_monitor_split([override(Name, Rank, Distress, Action) | Rest], Inviolables, Ordinaries) :-
    % Part the remainder first, then place this drive on the side its rank chooses.
    conflict_monitor_split(Rest, RestInviolables, RestOrdinaries),
    % A rank at or beneath the inviolable one is exempt from the raise; every other rank is not.
    (   conflict_monitor_is_inviolable(Rank)
    ->  Inviolables = [override(Name, Rank, Distress, Action) | RestInviolables],
        Ordinaries = RestOrdinaries
    ;   Inviolables = RestInviolables,
        Ordinaries = [override(Name, Rank, Distress, Action) | RestOrdinaries]
    ).

% conflict_monitor_step(+Bus0, +Overrides, +Base, +Gain, +NormalOutcome, -Conflict, -Result): one turn.
conflict_monitor_step(Bus0, Overrides, Base, Gain, NormalOutcome, Conflict,
                      result(Bus, Raised, FinalOutcome)) :-
    % Read the control STANDING ON THE BUS from previous turns, which is what makes this a loop rather
    % than a single shot - the Gratton effect is entirely a claim about control that is still in place.
    stabiliser_bias(Bus0, Standing),
    % The threshold in force at the start of this turn is the base plus whatever control already stands.
    InForce is Base + Standing,
    % Measure the conflict the mind actually faces, at the threshold actually in force.
    conflict_monitor_conflict(Overrides, InForce, Conflict),
    % Raise control by that conflict and the caller's gain: this is the chapter's second clause.
    conflict_monitor_raise(InForce, Conflict, Gain, Raised),
    % Publish the raised control as a stability bias, so it stands for the next turn to read.
    NewBias is Raised - Base,
    % Write it onto the bus through the stabiliser, which is the construct that owns this scalar.
    stabiliser_publish(Bus0, NewBias, Bus),
    % And arbitrate at the raised threshold, with the inviolable rank exempt from the raise.
    conflict_monitor_arbitrate(Overrides, Base, Raised, NormalOutcome, FinalOutcome).

% conflict_monitor_sequence(+Bus0, +Trials, +Base, +Gain, -Conflicts, -Bus): a run of trials.
% An empty run measures nothing and leaves the bus exactly as it found it. The cut is here because a
% finished run has exactly one answer, and a measurement that backtracks is not a measurement.
conflict_monitor_sequence(Bus, [], _Base, _Gain, [], Bus) :- !.
% Otherwise each trial is one turn of the loop, and the bus carries control into the next.
conflict_monitor_sequence(Bus0, [Overrides | Rest], Base, Gain, [Conflict | More], Bus) :-
    % Take one turn on this trial's drives, with no normal outcome of interest to the sequence.
    conflict_monitor_step(Bus0, Overrides, Base, Gain, none, Conflict, result(Bus1, _Raised, _Outcome)),
    % Then run the remaining trials against the bus this turn left behind.
    conflict_monitor_sequence(Bus1, Rest, Base, Gain, More, Bus).

% ---------------------------------------------------------------------------
% THE THIRD PIECE, DECLARED AND NOT WATCHED - OBSERVATION-18
% ---------------------------------------------------------------------------
%
% THE GAP ANALYSIS NAMES THREE PIECES AND THIS SLICE JOINS TWO. override_controller and stabiliser are
% now a closed loop. The supervisor is the third, and its job here is the one a watchdog always has:
% to notice when the loop FAILS. Two regimes are declared below in the supervisor's own fault shape,
% and readings are built in its own reading shape.
%
% WHAT IS NOT BUILT, AND WHY IT IS A REFUSAL RATHER THAN AN OMISSION. supervisor_watch/3 judges a
% MODE REGISTER's fault block, and conflict_monitor has no mode register. Writing one would mean
% inventing this construct's modes, its per-mode transfer function and its transition table - the four
% blocks Chapter 80.3.3 names - and NONE OF THEM HAS BEEN READ FROM THE CORPUS. A register invented to
% make a watch call compile is exactly the shape this build refuses. The regimes are therefore declared
% so the supervisor can consume them the moment that register is read, and the gap is recorded as
% OBSERVATION-18 rather than papered over.

% conflict_monitor_fault_row(-Signature, -Condition, -Watchdog): one declared fault regime.
% The loop's characteristic failure, and the one the chapter's own elegance claim would deny: control
% was raised and the conflict it was raised against did not fall.
conflict_monitor_fault_row(control_without_relief, conflict_not_falling_after_control_was_raised,
                           conflict_monitor).
% And the runaway in the other direction: control that keeps rising because it never resolves anything.
conflict_monitor_fault_row(control_ratchet, control_rising_across_trials_without_conflict_falling,
                           stabiliser).

% conflict_monitor_faults(-Faults): the fault block, gathered in declaration order.
conflict_monitor_faults(Faults) :-
    % Gather both declared regimes, in the shape the supervisor judges.
    findall(fault(Signature, Condition, Watchdog),
            conflict_monitor_fault_row(Signature, Condition, Watchdog),
            Faults).

% conflict_monitor_readings(+Before, +After, +Allowance, -Readings): the loop's readings.
conflict_monitor_readings(Before, After, Allowance, Readings) :-
    % Refuse readings that are not numbers, at the door.
    must_be(number, Before),
    % The conflict standing after the raise is the measured value.
    must_be(number, After),
    % THE ALLOWANCE IS THE CALLER'S, exactly as the supervisor requires and never invents.
    must_be(number, Allowance),
    % The relief regime reads the conflict remaining; the ratchet regime reads how far control has run.
    Ratchet is After - Before,
    % Both readings are filed under this construct's own signature names.
    Readings = [supervisor_reading(control_without_relief, After, Allowance),
                supervisor_reading(control_ratchet, Ratchet, Allowance)].
