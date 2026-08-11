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
    % conflict_monitor_fault_row/2: the corpus's own boundary signatures, for the supervisor to watch.
    conflict_monitor_fault_row/2,
    % conflict_monitor_faults/1: the fault block, gathered in the corpus's declaration order.
    conflict_monitor_faults/1,
    % conflict_monitor_watchdogs/1: the watchdogs the corpus offers to both signatures together.
    conflict_monitor_watchdogs/1,
    % conflict_monitor_readings/4: the loop's readings, in the supervisor's own reading shape.
    conflict_monitor_readings/4,
    % conflict_monitor_register_source/1: the region whose register block this pack borrows, DECISION-16.
    conflict_monitor_register_source/1,
    % conflict_monitor_entries/1: the register block - the corpus's four modes for this construct.
    conflict_monitor_entries/1,
    % conflict_monitor_rule/2: the per-mode transfer function, one row per register entry.
    conflict_monitor_rule/2,
    % conflict_monitor_transfers/1: the transfer block, parallel to the register.
    conflict_monitor_transfers/1,
    % conflict_monitor_transfer/2: the rule that holds while a mode is current, looked up THROUGH the automaton.
    conflict_monitor_transfer/2,
    % conflict_monitor_transition/5: one row of the corpus's transition table.
    conflict_monitor_transition/5,
    % conflict_monitor_transitions/1: the transition table block.
    conflict_monitor_transitions/1,
    % conflict_monitor_automaton/1: the whole hybrid automaton, judged as it is built.
    conflict_monitor_automaton/1,
    % conflict_monitor_watch/2: the supervisor judges this construct's fault block. OBSERVATION-18's closer.
    conflict_monitor_watch/2
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
% Import the register constructor, which judges all four blocks before an automaton exists.
:- use_module(library(mode_register), [
    % mode_register_new/6: build the hybrid automaton and judge every block of it.
    mode_register_new/6,
    % mode_register_transfer/3: the rule that holds while a mode is current.
    mode_register_transfer/3
]).
% Import the supervisor, which is the loop's THIRD PIECE and the one slice 58 could not reach.
:- use_module(library(supervisor), [
    % supervisor_watch/3: judge a fault block against the watchdogs' readings.
    supervisor_watch/3
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
% THE MODE REGISTER - OBSERVATION-18'S CLOSER, AND IT WAS A READ RATHER THAN AN INVENTION
% ---------------------------------------------------------------------------
%
% SLICE 58 DECLARED TWO FAULT REGIMES OF ITS OWN NAMING AND REFUSED TO CALL THE SUPERVISOR, because
% supervisor_watch/3 judges a MODE REGISTER's fault block and this construct had none. Writing one
% then would have meant inventing this construct's modes, its per-mode transfer function and its
% transition table, and a register invented to make a call compile is the shape this build refuses.
% OBSERVATION-18 named its closer as a corpus read. THE READ IS DONE AND NOTHING NEEDED INVENTING:
% all four of the blocks Chapter 80.3.3 requires are stated, together, in the corpus's own words.
%
% THEY ARE IN LAYER_09_MODES_MANUSCRIPT.txt UNDER THE ANTERIOR CINGULATE CORTEX, whose framing
% sentence is: "The anterior cingulate cortex is a comparator that notices when something is going
% wrong, so its modes are monitoring, alarm, and effort mobilisation, and with the anterior insula it
% anchors the salience network." Four register entries, four transfer functions, four transition
% rows and a fault block follow it.
%
% AND THE SEARCH THAT WOULD HAVE GOT THIS WRONG IS RECORDED, BECAUSE IT WAS THE OBVIOUS MOVE. The
% current literature on cognitive control converges immediately on Braver's dual mechanisms
% framework - PROACTIVE control, anticipatory and sustained, against REACTIVE control, transient and
% stimulus-driven - and konnectome's own corpus carries it at Chapter 52.3.3, which calls them "two
% temporal modes". A builder looking for this construct's modes finds those two first, and they are
% the WRONG REGISTER: proactive and reactive are postures of the LATERAL PREFRONTAL CORTEX, the
% region that RECEIVES the conflict signal and holds the goal. Chapter 52.2.1 is explicit that the
% cingulate "does not exert control at all". THOSE TWO MODES BELONG TO THIS CONSTRUCT'S CONSUMER AND
% NOT TO THIS CONSTRUCT, and a register built from them would have looked entirely defensible.

% ---------------------------------------------------------------------------
% DECISION-16: A REGION-GRAIN REGISTER MAY BE ADOPTED BY THE CONSTRUCT THAT REALIZES THAT REGION'S
% FUNCTION, AND THE BORROWING IS STATED ON THE PACK'S FACE
% ---------------------------------------------------------------------------
%
% THE REGISTER READ ABOVE IS A REGION'S AND KONNECTOME HAS NO REGIONS. Layer 9's registers describe
% seventy-seven named anatomical individuals; konnectome has packs, and the region grain is exactly
% what OBSERVATION-11's expensive half is still missing. So adopting this block is a real question
% the corpus does not settle, and it is taken here as a decision rather than slipped in as a
% transcription.
%
% KONNECTOME ADOPTS IT, FOR THE EIGHTH COMMANDMENT'S OWN STATED REASON: ANALOGY OF FUNCTION, FIDELITY
% OF INTERFACE, FREEDOM OF IMPLEMENTATION. This pack realizes the function the corpus attributes to
% that region - it is a comparator that notices when something is going wrong - and the register is
% a statement about that FUNCTION rather than about the tissue. Refusing it until a region-grain
% construct exists would have left a construct whose modes are known sitting modeless for the sake
% of a grain distinction the corpus itself does not make when it writes the block.
%
% WHAT THE DECISION DOES NOT DECIDE, AND THE LIMIT IS THE POINT. It does not promote this pack to a
% region, it does not create a region grain, and it does not license reading Layer 9 registers into
% packs generally. THE TEST IT SETS IS NARROW: a construct may adopt a region's register when the
% construct realizes that region's stated function AND THERE IS EXACTLY ONE OF IT - which is
% DECISION-9's singleton rule arriving from a second direction. There is one conflict monitor.
%
% AND THE BORROWING IS DECLARED RATHER THAN GLOSSED, which is the condition attached to the grant:
% conflict_monitor_register_source/1 below names the region whose block this is, so no later reader
% can mistake a borrowed register for one konnectome derived from its own construct.

% conflict_monitor_register_source(-Region): the region whose register block this pack borrows.
% Named as a fact rather than as a comment, because a comment is not readable by a test and this
% claim is exactly the one a later session would otherwise lose.
conflict_monitor_register_source(anterior_cingulate_cortex).

% ---------------------------------------------------------------------------
% THE REGISTER BLOCK - FOUR MODES, ALL FOUR THE CORPUS'S OWN
% ---------------------------------------------------------------------------
%
% THE CORPUS SUPPLIES BOTH A FORMAL NAME AND A COINED NAME FOR EVERY ENTRY, which is precisely the
% three-field shape slice 39's mode_entry already carries. Nothing is renamed and nothing is dropped.
% Two of the four are modes THIS MACHINE CANNOT YET ENTER, and they are declared anyway, on slice 46's
% precedent: that register names all four sleep sub-modes though the machine can reach only one,
% because a register is a statement of what the construct HAS, not of what today's caller uses.

% The Watchtower. Ongoing surveillance for response conflict and error.
conflict_monitor_entry(conflict_monitoring, 'The Watchtower',
                       'ongoing surveillance for response conflict and error').
% The Struck Bell. Phasic firing on error, physical pain, and social rejection.
conflict_monitor_entry(error_and_pain_alarm, 'The Struck Bell',
                       'phasic firing on error, physical pain, and social rejection').
% The Taskmaster. Recruitment of executive control and adjustment of effort after conflict.
conflict_monitor_entry(effort_allocation, 'The Taskmaster',
                       'recruitment of executive control and adjustment of effort after conflict').
% The Quiet Post. Disengaged rest with reduced monitoring load.
conflict_monitor_entry(task_negative_idle, 'The Quiet Post',
                       'disengaged rest with reduced monitoring load').

% conflict_monitor_entries(-Entries): the register block, in the corpus's own order.
conflict_monitor_entries(Entries) :-
    % Gather the four entries in declaration order, which is the corpus's order.
    findall(mode_entry(Formal, Coined, Gloss),
            conflict_monitor_entry(Formal, Coined, Gloss),
            Entries).

% ---------------------------------------------------------------------------
% THE PER-MODE TRANSFER FUNCTIONS
% ---------------------------------------------------------------------------
%
% EACH POSTURE CARRIES TWO FIELDS - WHAT THE CONSTRUCT IS DOING, AND WHAT IT PUTS OUT - because that
% is the distinction the corpus's four sentences actually draw. Note that the corpus tags each of
% them with a CONFIDENCE grade, and that mode_entry has no field for one: slice 39 deferred the
% per-mode confidence tag by name and it is still deferred, so the grades are recorded in the
% comments below and are NOT silently dropped without saying so.

% "Tracks the degree of response conflict and feeds a graded control-demand signal to the
% dorsolateral prefrontal cortex" - high confidence. THIS IS THE MODE SLICE 58 BUILT.
conflict_monitor_rule(conflict_monitoring, conflict_monitor_posture(measuring, graded_control_demand)).
% "Fires on errors and on the affective dimension of pain, the same circuitry activated by social
% rejection" - high confidence.
conflict_monitor_rule(error_and_pain_alarm, conflict_monitor_posture(phasic_firing, alarm_signal)).
% "Allocates effort and biases premotor and supplementary-motor responses, norepinephrine raising
% urgency" - moderate to high confidence.
conflict_monitor_rule(effort_allocation, conflict_monitor_posture(allocating, response_bias)).
% "Monitoring output falls at rest" - moderate confidence.
conflict_monitor_rule(task_negative_idle, conflict_monitor_posture(resting, reduced_output)).

% conflict_monitor_transfers(-Transfers): the transfer block, parallel to the register.
conflict_monitor_transfers(Transfers) :-
    % Gather one row per mode, in the register's own order, so the two blocks cannot drift apart.
    findall(transfer(Formal, Rule),
            conflict_monitor_rule(Formal, Rule),
            Transfers).

% conflict_monitor_transfer(+Mode, -Rule): the rule that holds while Mode is current.
conflict_monitor_transfer(Mode, Rule) :-
    % Look the rule up THROUGH the built automaton rather than off the clause above, so this lookup
    % inherits mode_register's refusals - an unbound key and an undeclared mode are both refused there.
    conflict_monitor_automaton(Automaton),
    % Look the mode up under the shared checker.
    mode_register_transfer(Automaton, Mode, Rule).

% ---------------------------------------------------------------------------
% THE TRANSITION TABLE - AND THE ROW THAT NAMES NO DEPARTURE
% ---------------------------------------------------------------------------
%
% THE CORPUS GIVES FOUR ROWS AND KONNECTOME'S TABLE HOLDS NINE, AND THE EXPANSION IS STATED HERE
% RATHER THAN LEFT TO BE NOTICED. Three of the corpus's four rows name a class of departure rather
% than one mode - "to Struck Bell" with no departure at all, "idle to monitoring OR alarm", and
% "active modes to Quiet Post". A four-field row cannot hold a class, so each is written out as the
% rows it names.
%
% AND THIS IS THE MIRROR OF OBSERVATION-14 RATHER THAN A REPEAT OF IT, WHICH IS WHY THE ANSWER IS
% DIFFERENT. Slice 50 met a row that named NO DESTINATION and refused to write it, because inventing
% a destination - a self-loop - would have answered "a transition happened and landed home" to a
% question whose true answer is that no transition happens. These rows name a DESTINATION and leave
% the DEPARTURE open, which is the opposite case: the arrival is stated and the expansion adds no
% claim the corpus did not make. Writing "from each of the others" is transcription; writing "to the
% mode you are already in" would have been invention.
%
% ONE ROW IS DELIBERATELY EXCLUDED FROM THE EXPANSION. The alarm's departure set does NOT include the
% alarm itself, because "to Struck Bell" describes an arrival and a construct already in that mode
% does not arrive at it. That exclusion is the same reasoning as slice 50's refusal, applied to keep
% the expansion honest rather than complete.
%
% AND ONE AGENCY NAMES A PUBLISHER KONNECTOME DOES NOT HAVE. The idle-to-active rows are driven by
% the anterior insula, which konnectome has not built. The rows are declared with their agency filled
% and NOTHING FIRES THEM, which is the register saying what the construct has rather than what
% today's machine can reach - and it is preferable to quietly re-attributing the trigger to something
% konnectome does happen to own.

% Row one, and it is the loop slice 58 already built without knowing it had a register.
conflict_monitor_transition(rising_response_conflict, conflict_monitoring, effort_allocation,
                            hundreds_of_milliseconds, self_selected).
% Rows two, three and four: "committed error or pain or rejection - to Struck Bell", from each of the
% three modes that can arrive there.
conflict_monitor_transition(committed_error_or_pain_or_rejection, conflict_monitoring,
                            error_and_pain_alarm, hundreds_of_milliseconds, thrown_from_above).
% The same arrival, departing the effort mode.
conflict_monitor_transition(committed_error_or_pain_or_rejection, effort_allocation,
                            error_and_pain_alarm, hundreds_of_milliseconds, thrown_from_above).
% The same arrival, departing rest.
conflict_monitor_transition(committed_error_or_pain_or_rejection, task_negative_idle,
                            error_and_pain_alarm, hundreds_of_milliseconds, thrown_from_above).
% Rows five and six: "salience detection by anterior insula - idle to monitoring or alarm - seconds".
conflict_monitor_transition(salience_detection_by_anterior_insula, task_negative_idle,
                            conflict_monitoring, seconds, thrown_from_above).
% The other arrival the same trigger may reach.
conflict_monitor_transition(salience_detection_by_anterior_insula, task_negative_idle,
                            error_and_pain_alarm, seconds, thrown_from_above).
% Rows seven, eight and nine: "task offset - active modes to Quiet Post - seconds", one per active mode.
conflict_monitor_transition(task_offset, conflict_monitoring, task_negative_idle, seconds,
                            self_selected).
% The same departure from the alarm.
conflict_monitor_transition(task_offset, error_and_pain_alarm, task_negative_idle, seconds,
                            self_selected).
% And from the effort mode.
conflict_monitor_transition(task_offset, effort_allocation, task_negative_idle, seconds,
                            self_selected).

% conflict_monitor_transitions(-Transitions): the transition table block.
conflict_monitor_transitions(Transitions) :-
    % Gather the rows in declaration order, which is the corpus's order.
    findall(transition(Trigger, From, To, Timescale, Agency),
            conflict_monitor_transition(Trigger, From, To, Timescale, Agency),
            Transitions).

% ---------------------------------------------------------------------------
% THE FAULT BLOCK - AND THE CORRECTION IT FORCES ON SLICE 58
% ---------------------------------------------------------------------------
%
% SLICE 58 DECLARED TWO FAULT REGIMES OF KONNECTOME'S OWN NAMING - control_without_relief and
% control_ratchet - derived from the loop's logic rather than from any source. THE CORPUS NAMES THE
% SAME TWO SHAPES IN ITS OWN VOCABULARY, and under DECISION-7 the corpus's name is the one that is
% used, so the rows are REPOINTED here. That is a repair and not a decision: a source says what the
% answer should be and the code said something else.
%
% THE INDEPENDENT AGREEMENT IS WORTH RECORDING RATHER THAN QUIETLY OVERWRITING. Slice 58 reasoned
% from the loop that its characteristic failure is control raised without conflict falling. The
% corpus's warning condition, written from clinical observation, is "chronically elevated conflict".
% Those are the same claim reached from two directions, and the agreement is the reason to trust the
% repointing rather than to argue with it.
%
% THE CORPUS OFFERS ONE WARNING CONDITION AND ONE WATCHDOG LIST TO BOTH SIGNATURES TOGETHER, and they
% are not paired off. This follows slice 50's handling of exactly the same shape: both rows carry the
% same warning and the same list, because splitting them would be konnectome deciding which watchdog
% catches which fault, and the corpus does not decide that.

% conflict_monitor_watchdogs(-Watchdogs): "dopaminergic and noradrenergic tone calibrate the alarm
% threshold", offered to both signatures together.
conflict_monitor_watchdogs([dopaminergic_tone, noradrenergic_tone]).

% conflict_monitor_warning(-Condition): the one warning condition the corpus states, in its words.
conflict_monitor_warning(chronically_elevated_conflict_or_pain_affect_signalling).

% conflict_monitor_fault_row(-Signature, -Gloss): the corpus's boundary signatures.
% The first: "pathological error-related hyperactivity (as in obsessive-compulsive checking)".
conflict_monitor_fault_row(error_related_hyperactivity, obsessive_compulsive_checking).
% The second: "or cingulate seizure leaves the admitted set".
conflict_monitor_fault_row(cingulate_seizure, departure_from_the_admitted_set).

% conflict_monitor_faults(-Faults): the fault regimes and watchdogs block.
conflict_monitor_faults(Faults) :-
    % Read the watchdog list once, from the one place it is written.
    conflict_monitor_watchdogs(Watchdogs),
    % And the single warning condition the corpus offers to both.
    conflict_monitor_warning(Warning),
    % Build one three-field fault entry per boundary signature, both carrying the shared pair.
    findall(fault(Signature, Warning, Watchdogs),
            conflict_monitor_fault_row(Signature, _Gloss),
            Faults).

% ---------------------------------------------------------------------------
% THE AUTOMATON
% ---------------------------------------------------------------------------
%
% THE CURRENT MODE IS THE WATCHTOWER, AND IT IS A STARTING POSITION RATHER THAN A DEFAULT. slice 39's
% checker refuses an automaton whose current mode is not in its register, so the slot cannot be
% omitted and something has to be written. The corpus states no resting mode for this construct - it
% states an IDLE mode, which is a different claim, being where the construct goes at task offset
% rather than where it starts. What is written here is the corpus's FIRST ENTRY, which is where the
% block starts reading, and that is a weaker warrant than a stated default and is recorded as weaker.
% It is also checkable rather than asserted: NOTHING IN THIS PACK READS THE SLOT.

% conflict_monitor_automaton(-Automaton): the whole hybrid automaton, judged as it is built.
conflict_monitor_automaton(Automaton) :-
    % Read the four blocks from the four places they are written.
    conflict_monitor_entries(Entries),
    % The per-mode transfer functions.
    conflict_monitor_transfers(Transfers),
    % The transition table.
    conflict_monitor_transitions(Transitions),
    % And the fault block.
    conflict_monitor_faults(Faults),
    % Build it through slice 39's constructor, which judges every block before handing the term back.
    mode_register_new(conflict_monitoring, Entries, Transfers, Transitions, Faults, Automaton).

% ---------------------------------------------------------------------------
% THE THIRD PIECE, NOW JOINED - OBSERVATION-18 CLOSED
% ---------------------------------------------------------------------------
%
% THE GAP ANALYSIS NAMED THREE PIECES AND SLICE 58 JOINED TWO. The supervisor is the third, and its
% job is the one a watchdog always has: to notice when the loop FAILS. It can now be called, because
% the register it judges against exists.
%
% AND THE HONEST HALF IS WHAT THE WATCH REPORTS UNWATCHED. konnectome can measure one of the two
% boundary signatures and not the other: it knows whether conflict fell after control was raised, and
% it has nothing whatever that could detect a cingulate seizure. Under DECISION-4 an unmeasured
% regime is reported NOT AS CLEAN BUT AS UNWATCHED, so a caller supplying only the reading konnectome
% can take gets back one judged regime and one named as unwatched. THAT IS THE CORRECT ANSWER AND NOT
% A SHORTFALL, and it is the first time in this build that the supervisor's clean-versus-unwatched
% distinction has separated two regimes of the SAME construct.

% conflict_monitor_readings(+Before, +After, +Allowance, -Readings): the loop's readings.
conflict_monitor_readings(Before, After, Allowance, Readings) :-
    % Refuse readings that are not numbers, at the door.
    must_be(number, Before),
    % The conflict standing after the raise is the measured value.
    must_be(number, After),
    % THE ALLOWANCE IS THE CALLER'S, exactly as the supervisor requires and never invents.
    must_be(number, Allowance),
    % Only ONE regime is measurable here, and it is filed under the CORPUS'S signature name rather
    % than under slice 58's. The seizure regime gets no reading, so the supervisor reports it
    % unwatched rather than clean - which is true, and is the point.
    Readings = [supervisor_reading(error_related_hyperactivity, After, Allowance)].

% conflict_monitor_watch(+Readings, -Report): the supervisor judges this construct's fault block.
conflict_monitor_watch(Readings, Report) :-
    % Build the automaton, so the supervisor judges the REAL fault block rather than a fixture.
    conflict_monitor_automaton(Automaton),
    % And the supervisor publishes warnings, clean regimes and unwatched ones apart.
    supervisor_watch(Automaton, Readings, Report).
