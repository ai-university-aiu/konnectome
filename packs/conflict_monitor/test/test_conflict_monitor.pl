% Load the pack under test.
:- use_module(library(conflict_monitor)).
% Load the stabiliser, because the loop's control travels as its bias and the tests read it back.
:- use_module(library(stabiliser), [stabiliser_bias/2]).
% Load the bus constructor, so a run starts from an empty channel rather than from a fixture.
:- use_module(library(neuromodulator_bus), [neuromodulator_bus_new/1]).

% Open the test block for the conflict monitor.
:- begin_tests(conflict_monitor).

% ---------------------------------------------------------------------------
% THE MEASURE - what the corpus's definition demands of it
% ---------------------------------------------------------------------------

% Nothing active is no conflict, which is the honest answer and not merely the base case.
test(no_drives_active_is_no_conflict) :-
    % Two drives, neither of them distressed enough to be active.
    Overrides = [override(hunger, 3, 0.1, eat), override(thirst, 4, 0.2, drink)],
    % Measure at a threshold above both.
    conflict_monitor_conflict(Overrides, 0.5, Conflict),
    % No response is active, so no responses are in competition.
    assertion(Conflict =:= 0).

% One response alone is not a competition, however strongly it is activated.
test(one_drive_active_is_no_conflict) :-
    % One strongly distressed drive and one quiet one.
    Overrides = [override(hunger, 3, 0.9, eat), override(thirst, 4, 0.2, drink)],
    % Measure at a threshold only the first clears.
    conflict_monitor_conflict(Overrides, 0.5, Conflict),
    % A single active response has nothing to be incompatible with.
    assertion(Conflict =:= 0).

% AGREEMENT IS NOT INCOMPATIBILITY, which is the half of the definition a mere count would lose.
test(active_drives_proposing_the_same_action_are_not_in_conflict) :-
    % Two strongly distressed drives that want the SAME thing done.
    Overrides = [override(hunger, 3, 0.9, approach), override(thirst, 4, 0.8, approach)],
    % Measure at a threshold both clear.
    conflict_monitor_conflict(Overrides, 0.5, Conflict),
    % Simultaneous activation of COMPATIBLE responses is not conflict.
    assertion(Conflict =:= 0).

% Two active drives proposing different actions are the smallest real conflict.
test(two_incompatible_active_drives_are_in_conflict) :-
    % Two strongly distressed drives that want different things done.
    Overrides = [override(hunger, 3, 0.9, approach), override(fear, 4, 0.8, withdraw)],
    % Measure at a threshold both clear.
    conflict_monitor_conflict(Overrides, 0.5, Conflict),
    % The pair contributes the product of its two activations.
    assertion(abs(Conflict - 0.72) < 1.0e-9).

% Conflict rises with the NUMBER of competitors, because each new pair adds to the sum.
test(conflict_rises_with_the_number_of_competitors) :-
    % Two incompatible drives.
    Two = [override(hunger, 3, 0.9, approach), override(fear, 4, 0.8, withdraw)],
    % The same two, plus a third proposing something else again.
    Three = [override(hunger, 3, 0.9, approach), override(fear, 4, 0.8, withdraw),
             override(fatigue, 5, 0.7, rest)],
    % Measure both at the same threshold.
    conflict_monitor_conflict(Two, 0.5, TwoWay),
    % And the larger competition.
    conflict_monitor_conflict(Three, 0.5, ThreeWay),
    % A third incompatible response makes the competition strictly harder.
    assertion(ThreeWay > TwoWay).

% Conflict rises with the STRENGTH of the competitors, because activation is a quantity.
test(conflict_rises_with_the_strength_of_the_competitors) :-
    % Two incompatible drives, weakly activated.
    Weak = [override(hunger, 3, 0.6, approach), override(fear, 4, 0.6, withdraw)],
    % The same competition, strongly activated.
    Strong = [override(hunger, 3, 0.9, approach), override(fear, 4, 0.9, withdraw)],
    % Measure the weak competition.
    conflict_monitor_conflict(Weak, 0.5, WeakConflict),
    % And the strong one.
    conflict_monitor_conflict(Strong, 0.5, StrongConflict),
    % The same two responses in stronger competition is more conflict, not the same conflict.
    assertion(StrongConflict > WeakConflict).

% ---------------------------------------------------------------------------
% THE LOOP - the chapter's own acceptance test, which is a comparison
% ---------------------------------------------------------------------------

% THE HEADLINE. THE GRATTON EFFECT: conflict on a trial is SMALLER when the previous trial was also
% conflicted, because the control that trial recruited is still in place. This is the chapter's own
% test of the loop, and it is an ABLATION - the identical trial run twice, once with the previous
% trial's control carried forward and once without.
test(the_gratton_inequality_holds) :-
    % An incongruent trial: three drives, all active, all proposing different actions.
    Incongruent = [override(hunger, 3, 0.9, approach), override(fear, 4, 0.8, withdraw),
                   override(fatigue, 5, 0.7, rest)],
    % A congruent trial: the same activations, but every drive proposing the SAME action.
    Congruent = [override(hunger, 3, 0.9, approach), override(fear, 4, 0.8, approach),
                 override(fatigue, 5, 0.7, approach)],
    % Start from an empty bus, so no control stands before the run begins.
    neuromodulator_bus_new(Bus),
    % Run the incongruent trial after an incongruent one.
    conflict_monitor_sequence(Bus, [Incongruent, Incongruent], 0.5, 0.15, [_First, AfterConflict], _B1),
    % Run the SAME trial after a congruent one, which recruited no control.
    conflict_monitor_sequence(Bus, [Congruent, Incongruent], 0.5, 0.15, [_Zero, AfterCalm], _B2),
    % The ablated run - no control carried in - meets the full conflict.
    assertion(abs(AfterCalm - 1.91) < 1.0e-9),
    % The run that carried control forward meets strictly less of it. THIS IS THE LOOP CLOSING.
    assertion(AfterConflict < AfterCalm).

% AND THE INEQUALITY DOES NOT REST ON THE GAIN, which is why konnectome never has to choose one.
test(the_gratton_inequality_holds_for_every_positive_gain) :-
    % The same incongruent trial as above.
    Incongruent = [override(hunger, 3, 0.9, approach), override(fear, 4, 0.8, withdraw),
                   override(fatigue, 5, 0.7, rest)],
    % And the same congruent one.
    Congruent = [override(hunger, 3, 0.9, approach), override(fear, 4, 0.8, approach),
                 override(fatigue, 5, 0.7, approach)],
    % Four gains spanning two orders of magnitude, none of them konnectome's choice.
    forall(member(Gain, [0.15, 0.3, 1.0, 5.0]),
           % Under each gain in turn, the comparison must come out the same way.
           test_conflict_monitor_gratton_under(Incongruent, Congruent, Gain)).

% test_conflict_monitor_gratton_under(+Incongruent, +Congruent, +Gain): the comparison at one gain.
test_conflict_monitor_gratton_under(Incongruent, Congruent, Gain) :-
    % Start each condition from an empty bus.
    neuromodulator_bus_new(Bus),
    % The conflicted history.
    conflict_monitor_sequence(Bus, [Incongruent, Incongruent], 0.5, Gain, [_A, AfterConflict], _B1),
    % The calm history, which is the ablation.
    conflict_monitor_sequence(Bus, [Congruent, Incongruent], 0.5, Gain, [_C, AfterCalm], _B2),
    % Whatever the gain, carrying control forward leaves strictly less conflict to meet.
    assertion(AfterConflict < AfterCalm).

% A conflicted turn leaves control STANDING ON THE BUS, which is what makes the next turn easier.
test(a_conflicted_turn_raises_the_standing_control) :-
    % An incongruent trial.
    Incongruent = [override(hunger, 3, 0.9, approach), override(fear, 4, 0.8, withdraw)],
    % Start from an empty bus, where no control stands.
    neuromodulator_bus_new(Bus0),
    % Read the bias before the turn.
    stabiliser_bias(Bus0, Before),
    % Take one turn of the loop.
    conflict_monitor_step(Bus0, Incongruent, 0.5, 1.0, deliberate, _Conflict, result(Bus, _R, _O)),
    % Read the bias the turn left behind.
    stabiliser_bias(Bus, After),
    % Control stood at nothing and now stands at something.
    assertion(Before =:= 0),
    % The loop published its raise through the stabiliser, which is the construct that owns this scalar.
    assertion(After > 0).

% An UNCONFLICTED turn raises nothing, because there was no insufficiency to signal.
test(a_calm_turn_raises_no_control) :-
    % A congruent trial: two active drives that agree.
    Congruent = [override(hunger, 3, 0.9, approach), override(thirst, 4, 0.8, approach)],
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Take one turn.
    conflict_monitor_step(Bus0, Congruent, 0.5, 1.0, deliberate, Conflict, result(Bus, _R, _O)),
    % There was no conflict to answer.
    assertion(Conflict =:= 0),
    % So control stands exactly where it stood.
    stabiliser_bias(Bus, After),
    % Nothing was raised, which is the loop declining to act rather than the loop failing.
    assertion(After =:= 0).

% ---------------------------------------------------------------------------
% THE SAFETY PROPERTY - the hazard closing the loop creates
% ---------------------------------------------------------------------------

% THE INVIOLABLE DRIVE SURVIVES A RAISE THAT WOULD OTHERWISE MUTE IT. Breathing beats deliberation,
% and it still beats deliberation after the loop has raised control far above respiration's distress.
test(a_raised_threshold_can_never_suppress_the_inviolable_drive) :-
    % Respiration at rank zero, and an ordinary drive competing more strongly than it.
    Overrides = [override(respiration, 0, 0.9, breathe), override(curiosity, 5, 0.95, explore)],
    % Arbitrate with control raised absurdly high - far above every distress present.
    conflict_monitor_arbitrate(Overrides, 0.5, 100, deliberate, Final),
    % The raise muted the ordinary drive, and respiration still seizes control.
    assertion(Final == released(breathe)).

% AND THE EXEMPTION IS DOING REAL WORK, pinned by the counterfactual so the test above is not vacuous.
test(the_same_drive_at_an_ordinary_rank_is_muted_by_the_same_raise) :-
    % The identical distress and action, but at an ordinary rank rather than the inviolable one.
    Overrides = [override(respiration, 5, 0.9, breathe), override(curiosity, 6, 0.95, explore)],
    % Arbitrate under the identical raise.
    conflict_monitor_arbitrate(Overrides, 0.5, 100, deliberate, Final),
    % With no exemption to protect it, the raise mutes it and the normal action stands.
    assertion(Final == deliberate).

% The inviolable rank is override_controller's number and not this pack's invention.
test(the_inviolable_rank_is_the_rank_respiration_occupies) :-
    % Read the rank the exemption turns on.
    conflict_monitor_inviolable_rank(Rank),
    % override_controller's header states that respiration is rank zero and can never be suppressed.
    assertion(Rank == 0).

% An inviolable rank faces the base threshold; an ordinary rank faces the raised one.
test(the_effective_threshold_depends_on_the_rank) :-
    % The inviolable rank faces the base.
    conflict_monitor_effective_threshold(0, thresholds(0.5, 9.0), Inviolable),
    % An ordinary rank faces the raise.
    conflict_monitor_effective_threshold(4, thresholds(0.5, 9.0), Ordinary),
    % The exemption is the whole difference between the two.
    assertion(Inviolable =:= 0.5),
    % And the ordinary drive carries the full weight of the raised control.
    assertion(Ordinary =:= 9.0).

% ---------------------------------------------------------------------------
% THE REFUSALS - a silently open loop looks exactly like a closed one
% ---------------------------------------------------------------------------

% A gain of zero leaves the loop wired but never closed, and is refused BY NAME.
test(a_gain_of_zero_is_refused_by_name) :-
    % Attempt to raise control with a gain that raises nothing.
    catch(conflict_monitor_check_gain(0), Error, true),
    % The refusal names the thing that is missing rather than failing silently.
    assertion(Error = error(domain_error(conflict_monitor_gain_that_closes_the_loop, 0), _)).

% A negative gain answers conflict with more conflict, which is the runaway the loop exists to prevent.
test(a_negative_gain_is_refused_by_name) :-
    % Attempt to raise control with a gain that would reverse the loop.
    catch(conflict_monitor_check_gain(-1.0), Error, true),
    % Refused by name, at the door.
    assertion(Error = error(domain_error(conflict_monitor_gain_that_closes_the_loop, -1.0), _)).

% A gain that is not a number at all is refused as a type error before any arithmetic runs.
test(a_gain_that_is_not_a_number_is_refused) :-
    % Attempt to raise control with an atom.
    catch(conflict_monitor_check_gain(high), Error, true),
    % The type checker refuses it aloud.
    assertion(Error = error(type_error(number, high), _)).

% An unbound threshold is a hole, and a hole is refused rather than measured.
test(an_unbound_threshold_is_refused) :-
    % Attempt to measure conflict against a threshold nobody supplied.
    catch(conflict_monitor_conflict([], _Hole, _Conflict), Error, true),
    % The type checker refuses the hole by name.
    assertion(Error = error(instantiation_error, _)).

% A positive gain is accepted, so the refusals above are refusing something and not everything.
test(a_positive_gain_is_accepted) :-
    % A gain that genuinely closes the loop.
    conflict_monitor_check_gain(0.15),
    % Acceptance is the absence of a refusal.
    assertion(true).

% ---------------------------------------------------------------------------
% THE THIRD PIECE - declared for the supervisor, and honestly not yet watched
% ---------------------------------------------------------------------------

% The loop declares its own fault regimes in the supervisor's own fault shape.
test(the_loop_declares_its_fault_regimes) :-
    % Gather the fault block.
    conflict_monitor_faults(Faults),
    % Both declared regimes are present, in the shape the supervisor judges.
    assertion(Faults == [fault(control_without_relief,
                               conflict_not_falling_after_control_was_raised, conflict_monitor),
                         fault(control_ratchet,
                               control_rising_across_trials_without_conflict_falling, stabiliser)]).

% The readings are built in the supervisor's own reading shape, with the allowance the CALLER supplies.
test(the_readings_carry_the_callers_allowance) :-
    % Conflict fell from a high value to a lower one, against an allowance nobody in this pack chose.
    conflict_monitor_readings(1.91, 0.72, 0.5, Readings),
    % Destructure OUTSIDE the assertion, because assertion/1 undoes whatever its goal binds.
    Readings = [supervisor_reading(control_without_relief, Standing, ReliefAllowance),
                supervisor_reading(control_ratchet, Ratchet, RatchetAllowance)],
    % The relief regime reads the conflict still standing after the raise.
    assertion(Standing =:= 0.72),
    % And the ratchet regime reads how far conflict moved, which is negative when the loop worked.
    assertion(Ratchet < 0),
    % Both readings carry the caller's allowance, which this pack never invents.
    assertion(ReliefAllowance =:= 0.5),
    % The same allowance reaches the second regime unchanged.
    assertion(RatchetAllowance =:= 0.5).

% An allowance the caller did not supply is refused, exactly as the supervisor requires.
test(a_missing_allowance_is_refused) :-
    % Attempt to build readings without an allowance.
    catch(conflict_monitor_readings(1.0, 0.5, _Hole, _Readings), Error, true),
    % Refused as a hole rather than filled in with a number this pack invented.
    assertion(Error = error(instantiation_error, _)).

% ---------------------------------------------------------------------------
% THE AGENCY - what this pack is, stated so it can be checked
% ---------------------------------------------------------------------------

% The pack's agency is a BIAS, inherited from the stabiliser rather than minted here.
test(the_agency_is_a_bias_and_not_a_new_kind_of_thing) :-
    % Read the declared agency.
    conflict_monitor_agency(Agency),
    % It is the stabiliser's agency, because what this loop publishes is the stabiliser's scalar.
    assertion(Agency == broadcast_bias).

% Close the test block.
:- end_tests(conflict_monitor).
