% Load the renewal_loop module under test from the library path.
:- use_module(library(renewal_loop)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Load list utilities used to build runs of verdicts.
:- use_module(library(lists), [append/3]).

% Open the test block for the renewal_loop pack.
:- begin_tests(renewal_loop).

% A helper: a run of N steps under one repeated verdict.
renewal_loop_test_verdicts(0, _Verdict, []) :- !.
renewal_loop_test_verdicts(Count, Verdict, [Verdict|Rest]) :-
    Next is Count - 1,
    renewal_loop_test_verdicts(Next, Verdict, Rest).

% ---------------------------------------------------------------------------
% THE CHAPTER'S CONSTANTS, EXACTLY AS THE CHAPTER WRITES THEM
% ---------------------------------------------------------------------------

% The threshold, the degrade rate and the seed are the chapter's own numbers.
test(the_constants_are_the_chapters_own) :-
    renewal_loop_threshold(Threshold),
    assertion(Threshold =:= 1),
    renewal_loop_degrade_rate(DegradeRate),
    assertion(DegradeRate =:= 3 rdiv 10),
    renewal_loop_seed(Seed),
    assertion(Seed =:= 1 rdiv 20),
    renewal_loop_established_level(Established),
    assertion(Established =:= 2).

% ---------------------------------------------------------------------------
% OBSERVATION-16 - THE CHAPTER STATES THE GAIN TWICE AND THE TWO ARE DIFFERENT MACHINES
% ---------------------------------------------------------------------------

% The two stated gains are different values, and konnectome takes the English Readable Code's.
test(the_chapter_states_two_different_gains) :-
    renewal_loop_synthesis_gain(Used),
    renewal_loop_code_sample_gain(Printed),
    % Four tenths, from the prose.
    assertion(Used =:= 2 rdiv 5),
    % Six tenths, from the printed Python.
    assertion(Printed =:= 3 rdiv 5),
    % And they are not two precisions of one value.
    assertion(Used =\= Printed).

% THE DISCREPANCY IS ASSERTED AS BEHAVIOUR RATHER THAN AS A NUMBER, which is the whole point: the two
% gains sit either side of the line between a latch and an amplifier.
test(the_two_gains_fall_either_side_of_stability) :-
    renewal_loop_synthesis_gain(Used),
    renewal_loop_code_sample_gain(Printed),
    renewal_loop_degrade_rate(DegradeRate),
    % The per-step multiplier above threshold is (1 + gain) * (1 - degrade rate).
    UsedMultiplier is (1 + Used) * (1 - DegradeRate),
    PrintedMultiplier is (1 + Printed) * (1 - DegradeRate),
    % konnectome's gain gives a multiplier BELOW one: an established level decays slowly, so a block
    % can drive it under the threshold. That is the machine the chapter describes in prose.
    assertion(UsedMultiplier < 1),
    % The printed gain gives a multiplier ABOVE one: the level grows without bound and no brief block
    % can collapse it. That machine cannot demonstrate the claim printed above it.
    assertion(PrintedMultiplier > 1).

% ---------------------------------------------------------------------------
% DECISION-11 - THE MARK OUTLIVES ITS OWN MATERIAL
% ---------------------------------------------------------------------------

% AN ESTABLISHED MEMORY IS MAINTAINED ACROSS A RUN IN WHICH ITS ENTIRE CONTENTS ARE REPLACED MANY
% TIMES OVER. This is the corpus's "the setting outlives every molecule that ever carried it", and it
% is the reason a durable tier can be a process at all.
test(the_memory_survives_total_turnover_of_its_own_material) :-
    renewal_loop_established(Loop0),
    % The memory is held at the start.
    assertion(renewal_loop_maintained(Loop0)),
    % Twenty uninterrupted steps. Three tenths of the level is destroyed EVERY step, so after twenty
    % steps the fraction of the original material remaining is under a thousandth of a per cent.
    renewal_loop_test_verdicts(20, running, Verdicts),
    renewal_loop_run(Loop0, Verdicts, Loop),
    % And the memory is still held.
    assertion(renewal_loop_maintained(Loop)).

% The level really does fall over that run - it is a latch that is losing ground, not a store sitting
% still. Stating this keeps the test above from passing for the wrong reason.
test(the_maintained_level_decays_while_still_being_held) :-
    renewal_loop_established(Loop0),
    renewal_loop_level(Loop0, Level0),
    renewal_loop_test_verdicts(20, running, Verdicts),
    renewal_loop_run(Loop0, Verdicts, Loop),
    renewal_loop_level(Loop, Level),
    % Lower than it started.
    assertion(Level < Level0),
    % And still above the threshold.
    renewal_loop_threshold(Threshold),
    assertion(Level > Threshold).

% ---------------------------------------------------------------------------
% DECISION-11 - CUTTING THE LOOP DESTROYS THE MEMORY, AND PERMANENTLY
% ---------------------------------------------------------------------------

% A BRIEF BLOCK COLLAPSES AN ESTABLISHED MEMORY. The chapter's own claim, in its own words: "cutting
% the loop for even a short window collapses the value permanently."
test(a_brief_block_collapses_an_established_memory) :-
    renewal_loop_established(Loop0),
    % Run for a while, then block for six steps - the chapter's own staging.
    renewal_loop_test_verdicts(20, running, Before),
    renewal_loop_test_verdicts(6, inhibited, Block),
    append(Before, Block, Verdicts),
    renewal_loop_run(Loop0, Verdicts, Loop),
    % The memory is gone.
    assertion(\+ renewal_loop_maintained(Loop)).

% AND IT NEVER COMES BACK, WHICH IS THE HALF THAT MAKES IT A MEMORY RATHER THAN A DIP. Nothing in the
% pack forbids recovery; the seed is simply too small to climb back, so permanence falls out of the
% corpus's own arithmetic rather than being enforced by a guard.
test(a_collapsed_memory_never_returns_however_long_it_runs) :-
    renewal_loop_established(Loop0),
    renewal_loop_test_verdicts(20, running, Before),
    renewal_loop_test_verdicts(6, inhibited, Block),
    append(Before, Block, Cut),
    renewal_loop_run(Loop0, Cut, Collapsed),
    assertion(\+ renewal_loop_maintained(Collapsed)),
    % Now run it, uninhibited, for far longer than it ever ran while alive.
    renewal_loop_test_verdicts(500, running, LongRun),
    renewal_loop_run(Collapsed, LongRun, Loop),
    % Still gone.
    assertion(\+ renewal_loop_maintained(Loop)).

% THE COLLAPSED LEVEL IS THE EXACT FIXED POINT, DERIVED FROM THE SEED AND THE DEGRADE RATE. A long
% run settles precisely there - not near it, on it - which is what exact arithmetic buys.
test(a_cut_loop_settles_exactly_on_the_derived_fixed_point) :-
    % The fixed point, computed from the two constants it is made of.
    renewal_loop_collapsed_level(FixedPoint),
    % Seed times one minus the degrade rate, over the degrade rate: a twentieth times seven tenths,
    % over three tenths, which is seven sixtieths exactly.
    assertion(FixedPoint =:= 7 rdiv 60),
    % A loop standing exactly on the fixed point does not move.
    Loop0 = renewal_loop(FixedPoint),
    renewal_loop_step(Loop0, running, Loop),
    renewal_loop_level(Loop, Level),
    assertion(Level =:= FixedPoint).

% A FRESH LOOP NEVER STARTS ITSELF, which is the same fact from the other end: a synapse with no
% durable mark does not acquire one by being left alone.
test(a_fresh_loop_never_establishes_itself) :-
    renewal_loop_new(Loop0),
    assertion(\+ renewal_loop_maintained(Loop0)),
    renewal_loop_test_verdicts(1000, running, Verdicts),
    renewal_loop_run(Loop0, Verdicts, Loop),
    % A thousand steps later it is still not a memory.
    assertion(\+ renewal_loop_maintained(Loop)),
    % It has climbed only to the fixed point, and no further.
    renewal_loop_collapsed_level(FixedPoint),
    renewal_loop_level(Loop, Level),
    assertion(Level =< FixedPoint).

% ---------------------------------------------------------------------------
% THE GRAIN - THE ARITHMETIC IS EXACT AND NO ROUNDING DECIDES THE THRESHOLD
% ---------------------------------------------------------------------------

% THE LEVEL IS HELD AS AN EXACT RATIONAL, NEVER A FLOAT. Slice 49 lost a slot one step early to
% binary drift; this pack cannot, because nothing here is ever approximated.
test(the_level_is_exact_and_never_a_float) :-
    renewal_loop_established(Loop0),
    renewal_loop_test_verdicts(30, running, Verdicts),
    renewal_loop_run(Loop0, Verdicts, Loop),
    renewal_loop_level(Loop, Level),
    % A float would have crept in by now if any step had approximated.
    assertion(rational(Level)),
    assertion(\+ float(Level)).

% THE EXACT VALUE AFTER TWO STEPS IS CHECKABLE BY HAND, which is what glass-box means here.
% From two: (2 + 0.4*2) * 0.7 = 2.8 * 0.7 = 49/25. Then (49/25 * 1.4) * 0.7 = 2401/1250.
test(the_first_two_steps_land_on_their_exact_values) :-
    renewal_loop_established(Loop0),
    renewal_loop_step(Loop0, running, Loop1),
    renewal_loop_level(Loop1, Level1),
    assertion(Level1 =:= 49 rdiv 25),
    renewal_loop_step(Loop1, running, Loop2),
    renewal_loop_level(Loop2, Level2),
    assertion(Level2 =:= 2401 rdiv 1250).

% ---------------------------------------------------------------------------
% THE REFUSALS
% ---------------------------------------------------------------------------

% An unbound loop is refused rather than stepped from whatever it unifies with.
test(an_unbound_loop_is_refused,
     throws(error(instantiation_error, _))) :-
    renewal_loop_step(_Hole, running, _Loop).

% AN UNBOUND INHIBITION VERDICT IS REFUSED LOUDEST OF ALL, because read as "running" it would keep a
% memory alive that the caller was trying to erase - and nothing downstream would ever know.
test(an_unbound_inhibition_verdict_is_refused,
     throws(error(instantiation_error, _))) :-
    renewal_loop_established(Loop0),
    renewal_loop_step(Loop0, _Hole, _Loop).

% A verdict that is neither of the two words is refused by name, never read as one of them.
test(a_foreign_inhibition_verdict_is_refused,
     throws(error(domain_error(renewal_loop_inhibition, maybe), _))) :-
    renewal_loop_established(Loop0),
    renewal_loop_step(Loop0, maybe, _Loop).

% A term that is not a loop is refused aloud, naming what arrived.
test(a_term_that_is_not_a_loop_is_refused,
     throws(error(domain_error(renewal_loop, some_other_thing), _))) :-
    renewal_loop_step(some_other_thing, running, _Loop).

% A negative level is not a quantity of anything and is refused.
test(a_negative_level_is_refused,
     throws(error(domain_error(renewal_loop_level, -1), _))) :-
    renewal_loop_step(renewal_loop(-1), running, _Loop).

% Close the test block for the renewal_loop pack.
:- end_tests(renewal_loop).
