% Declare this file as the 'renewal_loop' module and list the predicates it exports.
:- module(renewal_loop, [
    % renewal_loop_threshold/1: the level a maintained memory must stay above.
    renewal_loop_threshold/1,
    % renewal_loop_synthesis_gain/1: the self-feeding gain, from the chapter's ENGLISH READABLE CODE.
    renewal_loop_synthesis_gain/1,
    % renewal_loop_code_sample_gain/1: the DIFFERENT gain the chapter's printed Python states - OBSERVATION-16.
    renewal_loop_code_sample_gain/1,
    % renewal_loop_degrade_rate/1: the fraction of the level lost every step to ordinary destruction.
    renewal_loop_degrade_rate/1,
    % renewal_loop_seed/1: the small below-threshold synthesis, which cannot climb back.
    renewal_loop_seed/1,
    % renewal_loop_established_level/1: the chapter's own starting level for an established memory.
    renewal_loop_established_level/1,
    % renewal_loop_new/1: a fresh loop at zero - a synapse with no durable mark.
    renewal_loop_new/1,
    % renewal_loop_established/1: a loop holding an established memory, at the chapter's own level.
    renewal_loop_established/1,
    % renewal_loop_level/2: the level the loop currently holds, as an EXACT rational.
    renewal_loop_level/2,
    % renewal_loop_maintained/1: whether the memory is still held - the level above the threshold.
    renewal_loop_maintained/1,
    % renewal_loop_step/3: one maintenance step, under a caller-supplied inhibition verdict.
    renewal_loop_step/3,
    % renewal_loop_run/3: many steps under a caller-supplied list of inhibition verdicts.
    renewal_loop_run/3,
    % renewal_loop_collapsed_level/1: the level a cut loop settles at, DERIVED and not declared.
    renewal_loop_collapsed_level/1
]).

% Import the type checker that judges a level or a verdict and refuses a hole aloud.
:- use_module(library(error), [must_be/2, domain_error/2]).

% ---------------------------------------------------------------------------
% WHAT THIS PACK IS, AND THE DECISION IT EXISTS TO MAKE
% ---------------------------------------------------------------------------
%
% This is LAYER_04_05_SLOW_VARIABLES_MANUSCRIPT.txt CHAPTER 2, THE PKM-ZETA LOOP (The Self-Feeding
% Kinase), whose ENGINEERING NOTE gives this pack its name: "The engineering name is renewal_loop, a
% per-synapse maintenance daemon that subscribes to a potentiation-and-translation signal and
% publishes a sustained weight-gain value." konnectome takes the corpus's own name rather than
% inventing one.
%
% IT IS THE DURABLE WEIGHT TIER, AND IT IS BUILT AS A PROCESS BECAUSE THE CORPUS SPENDS EIGHTEEN
% CHAPTERS ARGUING THAT A DURABLE STORE IS NOT A NUMBER. That argument is DECISION-11 and it is set
% out below in full, because konnectome's own queue had this item written down as "a second, slower
% weight" and a slice that read the queue rather than the corpus would have built exactly the thing
% the volume was assembled to refute.
%
% NOTHING IS WIRED. plasticity_engine does not consult this pack, no interface carries a durable
% mark, and the tick is untouched. This is the eligibility-trace and blackboard discipline: build the
% mechanism, prove it against the corpus's own numbers, and leave the wiring to the slice that has
% argued for it. WIRING THIS INTO THE WEIGHT IS A LARGER DECISION THAN BUILDING IT, and it is named
% at the foot of this comment rather than smuggled in here.

% ---------------------------------------------------------------------------
% DECISION-11 - THE DURABLE TIER IS A MAINTAINED PROCESS, NOT A STORED NUMBER
% ---------------------------------------------------------------------------
%
% THE CORPUS'S THESIS, STATED IN ITS OWN OPENING. The volume asks "what is the weight made of, given
% that every protein at a synapse turns over in hours to weeks while memories last for decades?" and
% answers: "machinery that stores information in self-renewing arrangements of molecules - SWITCHES
% THAT RE-MARK THEMSELVES FASTER THAN TURNOVER ERASES THEM". Its closing line: memory persists "not
% by never changing, but by RE-WRITING ITSELF FASTER THAN IT FORGETS."
%
% AND IT DRAWS THE ENGINEERING DISTINCTION EXPLICITLY, TWICE, AGAINST THE TWO ANALOGUES A BUILDER
% WOULD REACH FOR FIRST. Of the CaMKII ring: "the EEPROM cell keeps the same physical charge trap,
% whereas bistable_weight_latch KEEPS NO PHYSICAL PART AT ALL". Of this loop: "dynamic memory refresh
% copies a stored value IT READS OUT FIRST, whereas renewal_loop HAS NO SEPARATELY STORED VALUE TO
% READ: the value is the running process itself, so interrupting the refresh does not merely risk a
% bit, IT DESTROYS THE ONLY COPY."
%
% SO KONNECTOME DECIDES: A DURABLE MARK IS THE STATE OF A LOOP THAT MUST BE RUN TO PERSIST. There is
% no second weight field, no write-once number, and no "consolidated" flag. There is a level that
% decays every step and a synthesis that replaces it, and the memory is the fact that the second
% currently beats the first.
%
% THE THREE THINGS THIS BUYS, AND EACH IS A TEST IN THIS PACK'S SUITE RATHER THAN A CLAIM.
%
% FIRST, THE MARK OUTLIVES ITS OWN MATERIAL. Every unit of level present at step one is gone within a
% few steps - degrade_rate removes three tenths of it every step - and the memory is still held. That
% is the corpus's "the setting outlives every molecule that ever carried it", and it is checkable.
%
% SECOND, CUTTING THE LOOP DESTROYS THE MEMORY PERMANENTLY, AND THE PERMANENCE FALLS OUT OF THE
% MECHANISM RATHER THAN BEING ENFORCED. Below the threshold the loop synthesises only the small seed,
% and the seed is too small to climb back: the sub-threshold recurrence has a fixed point far beneath
% the threshold, so a loop that once falls below it never returns. NOTHING IN THIS PACK CHECKS FOR
% THAT OR FORBIDS RECOVERY. It is simply what the corpus's own arithmetic does, and a test asserts it.
%
% THIRD, AND THIS IS THE CONSEQUENCE THE QUEUE DID NOT KNOW IT WAS BUYING: A DURABLE TIER OF THIS
% SHAPE MUST BE MAINTAINED IN BOTH SHIFTS OF THE TWO-PROCESS GOVERNOR. An offline shift that suspends
% the refresh does not preserve the durable tier - IT ERASES IT, and permanently, by exactly the
% mechanism above. konnectome's offline_consolidation replays and raises a bound and refreshes
% nothing. THIS PACK DOES NOT WIRE ITSELF INTO EITHER SHIFT, precisely because that is now a
% decision with a consequence rather than a detail, and it is recorded in the ledger as the named
% closer of this slice.
%
% WHAT DECISION-11 DOES NOT DECIDE.
%
% IT DOES NOT DECIDE WHAT SETS THE LOOP RUNNING. The corpus's trigger is "a potentiation-and-
% translation signal"; konnectome has no such publisher, so establishment is the caller's act.
%
% IT DOES NOT DECIDE WHAT THE LEVEL MEANS FOR A WEIGHT. The corpus says the loop "publishes a
% sustained weight-gain value". Whether konnectome's weight is multiplied, offset, or gated by it is
% the wiring slice's decision and is deliberately unmade here.
%
% IT DOES NOT ADOPT THE CaMKII RING. Chapter 1's bistable_weight_latch is the same thesis in a
% stochastic form - twelve subunits, per-step probabilities, a bit held by re-stamping. konnectome
% takes Chapter 2 instead because IT IS FULLY DETERMINISTIC, so a glass-box build needs no random
% source and no seed. The ring remains unbuilt and is named here so the omission is a choice.
%
% AND IT DOES NOT DECIDE WHETHER A CONSTRUCT MAY HOLD MANY LOOPS. One loop is one durable mark; the
% corpus places one per synapse. Nothing here says how they are addressed, which waits on the naming
% and addressing facility exactly as everything else at that grain does.

% ---------------------------------------------------------------------------
% THE GRAIN - WHY THE LEVEL IS AN EXACT RATIONAL
% ---------------------------------------------------------------------------
%
% DECISION-8 CHOSE A GRAIN OF ONE HUNDRED PARTS FOR ACTIVATION, and the reason it worked is that
% every activation constant the corpus states landed exactly on a hundredth. HERE THAT IS FALSE, and
% it is false immediately rather than subtly.
%
% The recurrence multiplies the level by one plus the gain and then by one minus the degrade rate -
% by fourteen tenths and then by seven tenths, which is ninety-eight hundredths per step. Starting
% from the corpus's established level of two, the second step already lands on 192.08 hundredths.
% NO FIXED DECIMAL GRAIN SURVIVES REPEATED MULTIPLICATION BY NINETY-EIGHT HUNDREDTHS.
%
% SO THE CHOICE IS BETWEEN ROUNDING AND EXACTNESS, AND THIS PACK'S WHOLE SUBJECT IS A THRESHOLD
% CROSSING. Slice 49 met the identical shape one tier up and paid for the lesson: a threshold decided
% by bit-level drift is a threshold nobody chose. Rounding here would decide, by accumulated error,
% the very question the chapter is asking - whether the memory survives.
%
% THE LEVEL IS THEREFORE HELD AS AN EXACT RATIONAL, in SWI-Prolog's own rational arithmetic. There is
% no grain, no rounding and no drift, the sub-threshold fixed point is exact rather than approximate,
% and the comparison against the threshold is decided by the corpus's numbers alone. THIS IS
% DECISION-8'S PRINCIPLE HONOURED BY A DIFFERENT MEANS: choose the representation in the open, and
% never let the carrier decide the answer.

% renewal_loop_threshold(-Threshold): the level a maintained memory must stay above.
% The chapter's own "threshold with initial value 1.0".
renewal_loop_threshold(1).

% renewal_loop_degrade_rate(-Rate): the fraction of the level lost every step.
% The chapter's own "degrade rate with initial value 0.3", held exactly as three tenths.
renewal_loop_degrade_rate(3 rdiv 10).

% renewal_loop_seed(-Seed): the small below-threshold synthesis.
% The chapter's own "small seed value", printed in its code sample as 0.05.
renewal_loop_seed(1 rdiv 20).

% renewal_loop_established_level(-Level): the chapter's own starting level for an established memory,
% written in its code sample as "level = 2.0  # start with an established memory".
renewal_loop_established_level(2).

% ---------------------------------------------------------------------------
% OBSERVATION-16 - THE CHAPTER STATES THE GAIN TWICE AND THE TWO GIVE OPPOSITE ANSWERS
% ---------------------------------------------------------------------------
%
% THIS IS THE SECOND TIME THIS BUILD HAS MET A CHAPTER DISAGREEING WITH ITSELF ABOUT A NUMBER, and it
% is the MIRROR IMAGE of the first, which is why it is worth recording rather than merely resolving.
%
% The chapter's ENGLISH READABLE CODE says: "Create a number variable called synthesis gain with
% initial value 0.4."
% The chapter's CODE SAMPLE, eight lines later, says: "THRESH, GAIN, DEGRADE, SEED = 1.0, 0.6, 0.3,
% 0.05".
%
% THEY ARE NOT TWO PRECISIONS OF ONE VALUE. THEY ARE TWO DIFFERENT MACHINES.
%
% At a gain of four tenths the per-step multiplier is fourteen tenths times seven tenths, which is
% ninety-eight hundredths - just below one - so an established level DECAYS SLOWLY, the chapter's
% brief block drives it under the threshold, and it settles at the sub-threshold fixed point and
% never returns. THE CHAPTER'S OWN CLAIM HOLDS: "a brief block collapses it for good."
%
% At a gain of six tenths the multiplier is sixteen tenths times seven tenths, which is one hundred
% and twelve hundredths - above one - so the level GROWS WITHOUT BOUND. Run the chapter's own printed
% program and the level reaches roughly one hundred and seven after sixty steps, and the six-step
% block it stages to demonstrate fragility DOES NOT COLLAPSE ANYTHING: the level falls to about two
% and a quarter, still above the threshold, and then resumes growing. THE PRINTED PROGRAM DOES NOT
% DEMONSTRATE THE CLAIM PRINTED ABOVE IT.
%
% konnectome takes FOUR TENTHS, from the English Readable Code, on three grounds stated in the open.
% First, it is the only one of the two under which the chapter's own stated claim is true. Second, a
% maintenance loop is a LATCH and not an amplifier - the chapter's own words are "keeps itself topped
% up", and a value that grows to a hundred and seven is not topped up, it has diverged. Third, the
% corpus elsewhere insists this machinery is metabolically bounded, and an unbounded product is not.
%
% AND NOTE WHICH WAY ROUND THIS ONE FELL, BECAUSE IT IS THE REVERSE OF SLICE 49's. At slice 49 the
% chapter's runnable illustration was the legible-but-uncalibrated half and the measured table was
% right. HERE THE PRINTED CODE IS THE WRONG ONE AND THE ENGLISH PROSE IS RIGHT. So the rule that
% generalises is NOT "trust the table over the code" - it is OBSERVATION-13's actual rule, which
% survives intact: WHEN A SOURCE GIVES A QUANTITY TWICE, FIND OUT WHETHER THE TWO STATEMENTS ARE THE
% SAME KIND OF CLAIM, AND CHECK BOTH AGAINST WHAT THE SOURCE SAYS THE ANSWER IS. Here that check is
% cheap and decisive: run both and see which one does what the chapter says happens.
%
% THE REJECTED VALUE IS EXPORTED RATHER THAN DELETED, so the discrepancy is a thing a test asserts
% instead of a paragraph a reader skims.

% renewal_loop_synthesis_gain(-Gain): the gain konnectome uses, from the ENGLISH READABLE CODE.
renewal_loop_synthesis_gain(2 rdiv 5).

% renewal_loop_code_sample_gain(-Gain): the DIFFERENT gain the chapter's printed Python states.
% NOT USED BY THIS PACK. Exported so OBSERVATION-16 can be asserted rather than described.
renewal_loop_code_sample_gain(3 rdiv 5).

% ---------------------------------------------------------------------------
% THE SHAPE GUARD
% ---------------------------------------------------------------------------

% renewal_loop_check_loop(+Loop, -Level): open a loop term, refusing a hole or an impostor.
renewal_loop_check_loop(Loop, Level) :-
    % An unbound loop is a hole, and a hole is refused before anything is read out of it.
    (   var(Loop)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % A term that is not the one-field loop is refused aloud, naming what arrived.
    (   Loop = renewal_loop(Level)
    ->  true
    ;   domain_error(renewal_loop, Loop)
    ),
    % A level is a number, and a negative one is not a quantity of anything.
    (   number(Level), Level >= 0
    ->  true
    ;   domain_error(renewal_loop_level, Level)
    ).

% renewal_loop_check_inhibited(+Inhibited): refuse anything but the two verdicts, by name.
renewal_loop_check_inhibited(Inhibited) :-
    % An unbound verdict would unify with the first clause it met and silently choose a behaviour.
    % THE UNBOUND-WRONG-JUDGEMENT LENS PAYS HERE HARDEST OF ANYWHERE IN THE PACK: an unbound verdict
    % read as "not inhibited" would quietly keep a memory alive that the caller was trying to erase.
    (   var(Inhibited)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % The verdict is the caller's and it is one of exactly two words.
    (   memberchk(Inhibited, [inhibited, running])
    ->  true
    ;   domain_error(renewal_loop_inhibition, Inhibited)
    ).

% ---------------------------------------------------------------------------
% BUILDING AND READING A LOOP
% ---------------------------------------------------------------------------

% renewal_loop_new(-Loop): a fresh loop at zero - a synapse carrying no durable mark.
% The chapter's own "enzyme level with initial value 0".
renewal_loop_new(renewal_loop(0)).

% renewal_loop_established(-Loop): a loop holding an established memory, at the chapter's own level.
renewal_loop_established(renewal_loop(Level)) :-
    % Read the established level from the one place it is written.
    renewal_loop_established_level(Level).

% renewal_loop_level(+Loop, -Level): the level the loop currently holds, as an exact rational.
renewal_loop_level(Loop, Level) :-
    % Open the loop, refusing a hole or an impostor.
    renewal_loop_check_loop(Loop, Level).

% renewal_loop_maintained(+Loop): the memory is held while the level stands above the threshold.
renewal_loop_maintained(Loop) :-
    % Read the level, which judges the loop on the way in.
    renewal_loop_level(Loop, Level),
    % Read the threshold from the one place it is written.
    renewal_loop_threshold(Threshold),
    % ABOVE, not at: the chapter says "still above threshold, meaning the memory is maintained", and
    % a boundary decided by rounding is what slice 49 spent a whole slice refusing.
    Level > Threshold.

% ---------------------------------------------------------------------------
% THE MAINTENANCE STEP
% ---------------------------------------------------------------------------
%
% THE INHIBITION VERDICT IS THE CALLER'S ARGUMENT AND NOTHING HERE PRODUCES IT. The corpus's
% inhibitor is a pharmacological block; konnectome has no pharmacology and no publisher for one, so
% the verdict arrives from outside exactly as the blackboard's striatal gate verdict does. Inventing
% a source would have been inventing a mechanism the corpus does not give this chapter.

% renewal_loop_step(+Loop0, +Inhibited, -Loop): one maintenance step of the self-feeding loop.
renewal_loop_step(Loop0, Inhibited, Loop) :-
    % Open the prior loop, refusing a hole before a step is taken from it.
    renewal_loop_check_loop(Loop0, Level0),
    % Refuse a verdict that is neither of the two words, and a hole loudest of all.
    renewal_loop_check_inhibited(Inhibited),
    % Read the three constants from the one place each is written.
    renewal_loop_threshold(Threshold),
    renewal_loop_synthesis_gain(Gain),
    renewal_loop_seed(Seed),
    renewal_loop_degrade_rate(DegradeRate),
    % THE CHAPTER'S OWN THREE-WAY CHOICE, in its own order: a blocked loop makes nothing; a loop above
    % the threshold feeds itself in proportion to what it already holds; a loop below it makes only
    % the small seed, which is what makes the collapse permanent.
    (   Inhibited == inhibited
    ->  Synthesis = 0
    ;   Level0 > Threshold
    ->  Synthesis is Gain * Level0
    ;   Synthesis = Seed
    ),
    % Add what was made.
    Grown is Level0 + Synthesis,
    % And remove what ordinary destruction takes, which is a fraction of the whole.
    Level is Grown - Grown * DegradeRate,
    % Commit the advanced loop. The arithmetic is exact throughout: no rounding decides the threshold.
    Loop = renewal_loop(Level).

% renewal_loop_run(+Loop0, +Verdicts, -Loop): many steps, one caller-supplied verdict each.
renewal_loop_run(Loop0, Verdicts, Loop) :-
    % Walk the VERDICTS in the first argument, so the walk below indexes on the list and leaves no
    % choicepoint behind. Driving the recursion on the loop term instead would leave one open at
    % every step of a long run, which is a slow leak rather than a wrong answer - but a maintenance
    % daemon is exactly the thing a caller will run for thousands of steps.
    renewal_loop_run_verdicts(Verdicts, Loop0, Loop).

% renewal_loop_run_verdicts(+Verdicts, +Loop0, -Loop): the walk itself, indexed on the verdict list.
% An exhausted verdict list leaves the loop exactly where it stands.
renewal_loop_run_verdicts([], Loop, Loop) :-
    % Judge the loop even when no step is taken, so a hole cannot pass through untouched.
    renewal_loop_check_loop(Loop, _Level).
% Each verdict advances the loop by one step.
renewal_loop_run_verdicts([Inhibited|Rest], Loop0, Loop) :-
    % Take this step under this verdict.
    renewal_loop_step(Loop0, Inhibited, Loop1),
    % Take the remaining steps.
    renewal_loop_run_verdicts(Rest, Loop1, Loop).

% ---------------------------------------------------------------------------
% THE COLLAPSED LEVEL, DERIVED AND NOT DECLARED
% ---------------------------------------------------------------------------
%
% A loop that has fallen below the threshold synthesises only the seed, so its recurrence settles at
% the level where what the seed adds exactly equals what destruction takes. THAT LEVEL IS NOT A
% KONNECTOME CONSTANT AND IS NOT WRITTEN DOWN ANYWHERE - it is computed here from the seed and the
% degrade rate, so it cannot drift away from them, in the shape slice 49 used for its own derived
% step count.

% renewal_loop_collapsed_level(-Level): the exact level a cut loop settles at.
renewal_loop_collapsed_level(Level) :-
    % Read the two constants the fixed point is made of.
    renewal_loop_seed(Seed),
    renewal_loop_degrade_rate(DegradeRate),
    % At the fixed point the level is unchanged by a step: L = (L + Seed) * (1 - DegradeRate).
    % Solving gives L = Seed * (1 - DegradeRate) / DegradeRate, exactly.
    Level is Seed * (1 - DegradeRate) / DegradeRate.
