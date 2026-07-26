% Load the module under test from the library path.
:- use_module(library(cause_and_effect)).
% Load the Prolog Unit test framework.
:- use_module(library(plunit)).
% Load thought combination so the tests can mint causal records independently of the module under test.
:- use_module(library(thought_combination), [
    % thought_combination_atomic/3: mint an event as a content-addressed occurrent.
    thought_combination_atomic/3,
    % thought_combination_combine/3: mint a genuine cause-and-effect record.
    thought_combination_combine/3,
    % thought_combination_id/2: read a causal record's identifier.
    thought_combination_id/2
]).

% cause_and_effect_test_instant(-Instant): the fixed instant, so every minted record is deterministic.
cause_and_effect_test_instant("2026-07-26T00:00:00Z").

% Open the cause_and_effect test block.
:- begin_tests(cause_and_effect).

% A genuine cause is recognised BY ITS RECORD: the sun heats the stone, and the reason
% given is the causal record's own identifier - the glass box names its evidence.
test(direct_cause_is_found_with_its_record_as_reason) :-
    % The sun shining, minted as an event.
    thought_combination_atomic("the_sun_shines", "event", Sun),
    % The stone warming, minted as an event.
    thought_combination_atomic("the_stone_warms", "event", Stone),
    % The genuine causal record: shining causes warming.
    thought_combination_combine([Sun], [Stone], Cro),
    % Read the record's identifier.
    thought_combination_id(Cro, CroId),
    % Ask whether the shining causes the warming.
    cause_and_effect_discriminate([Cro], Sun, Stone, Finding),
    % The finding is a genuine cause, justified by exactly that record.
    assertion(Finding == genuine_cause([CroId])).

% A cause reaches through a small event chain: fire heats the pot, the pot heats the water.
test(chained_cause_is_found_through_the_middle_event) :-
    % The fire burning.
    thought_combination_atomic("the_fire_burns", "event", Fire),
    % The pot heating.
    thought_combination_atomic("the_pot_heats", "event", Pot),
    % The water warming.
    thought_combination_atomic("the_water_warms", "event", Water),
    % Fire heats pot.
    thought_combination_combine([Fire], [Pot], First),
    % Pot heats water.
    thought_combination_combine([Pot], [Water], Second),
    % Read both record identifiers.
    thought_combination_id(First, FirstId),
    % The second link's identifier.
    thought_combination_id(Second, SecondId),
    % Ask whether the fire causes the water to warm.
    cause_and_effect_discriminate([First, Second], Fire, Water, Finding),
    % The finding is a genuine cause carried by the two-link chain, in order.
    assertion(Finding == genuine_cause([FirstId, SecondId])).

% Mere co-occurrence is NOT causation: the rooster crows and the sun rises together
% every morning, but no causal record links them - and the mind says so.
test(co_occurrence_without_a_record_is_not_causation) :-
    % The rooster crowing.
    thought_combination_atomic("the_rooster_crows", "event", Rooster),
    % The sun rising.
    thought_combination_atomic("the_sun_rises", "event", Sunrise),
    % No causal record links them, however often they are seen together.
    cause_and_effect_discriminate([], Rooster, Sunrise, Finding),
    % The honest finding: co-occurrence only, no causation shown.
    assertion(Finding == co_occurrence_only).

% Direction matters: if the record says A causes B, then asked whether B causes A,
% the mind reports the reverse - it never silently flips a cause around.
test(reversed_direction_is_reported_as_reverse_cause) :-
    % The sun shining.
    thought_combination_atomic("the_sun_shines", "event", Sun),
    % The stone warming.
    thought_combination_atomic("the_stone_warms", "event", Stone),
    % The record: shining causes warming.
    thought_combination_combine([Sun], [Stone], Cro),
    % Read the record's identifier.
    thought_combination_id(Cro, CroId),
    % Ask the question backwards: does the warming cause the shining?
    cause_and_effect_discriminate([Cro], Stone, Sun, Finding),
    % The finding names the true direction instead.
    assertion(Finding == reverse_cause([CroId])).

% A cycle of causal records terminates: the search is guarded and still answers.
test(cyclic_causal_records_still_terminate) :-
    % A first event.
    thought_combination_atomic("the_wheel_turns", "event", Wheel),
    % A second event.
    thought_combination_atomic("the_belt_moves", "event", Belt),
    % An unrelated third event.
    thought_combination_atomic("the_bird_sings", "event", Bird),
    % Wheel drives belt.
    thought_combination_combine([Wheel], [Belt], Forward),
    % Belt drives wheel - a causal loop.
    thought_combination_combine([Belt], [Wheel], Back),
    % Ask about an event outside the loop; the guarded search must terminate and answer honestly.
    cause_and_effect_discriminate([Forward, Back], Wheel, Bird, Finding),
    % No path reaches the bird's song.
    assertion(Finding == co_occurrence_only).

% A causal record that is not a record at all is refused by name, never silently skipped.
test(malformed_causal_record_is_refused, [throws(error(cause_and_effect_malformed_record(_), _))]) :-
    % Two real events.
    thought_combination_atomic("the_sun_shines", "event", Sun),
    % The second event.
    thought_combination_atomic("the_stone_warms", "event", Stone),
    % The supposed record is free text, not a minted causal record.
    cause_and_effect_discriminate(["not_a_record"], Sun, Stone, _Finding).

% A record whose causes are not a list of minted events is refused by name, never searched over.
test(record_with_unminted_causes_is_refused, [throws(error(cause_and_effect_malformed_record(_), _))]) :-
    % Two real events.
    thought_combination_atomic("the_sun_shines", "event", Sun),
    % The second event.
    thought_combination_atomic("the_stone_warms", "event", Stone),
    % The record's causes are free text where minted event identifiers belong.
    cause_and_effect_discriminate([_{id: "causal_relation_object:invented", causes: "not a list", effects: [Stone]}], Sun, Stone, _Finding).

% A record carrying an unbound cause is refused by name - an unbound cause would unify with any
% question asked and mint a genuine-cause verdict out of nothing.
test(record_with_unbound_cause_is_refused, [throws(error(cause_and_effect_malformed_record(_), _))]) :-
    % Two real events.
    thought_combination_atomic("the_sun_shines", "event", Sun),
    % The second event.
    thought_combination_atomic("the_stone_warms", "event", Stone),
    % The record's cause is an unbound variable.
    cause_and_effect_discriminate([_{id: "causal_relation_object:invented", causes: [_Anything], effects: [Stone]}], Sun, Stone, _Finding).

% A FORGED record - well-shaped, but never minted, its identifier hand-written - is refused by
% name. Causation is answered by the record, so a look-alike that no minting produced is no evidence.
test(forged_causal_record_is_refused, [throws(error(cause_and_effect_unminted_record(_), _))]) :-
    % Two real events.
    thought_combination_atomic("the_sun_shines", "event", Sun),
    % The second event.
    thought_combination_atomic("the_stone_warms", "event", Stone),
    % The dict carries the right shape and real events, but its identifier is invented, not derived.
    cause_and_effect_discriminate([_{id: "causal_relation_object:hand_written", causes: [Sun], effects: [Stone]}], Sun, Stone, _Finding).

% A record that honestly says an event causes itself is honoured, not denied by the loop guard.
test(self_causation_record_is_honoured) :-
    % One real event.
    thought_combination_atomic("the_wheel_turns", "event", Wheel),
    % A record stating the event causes itself.
    thought_combination_combine([Wheel], [Wheel], Cro),
    % Read the record's identifier.
    thought_combination_id(Cro, CroId),
    % Ask whether the event causes itself.
    cause_and_effect_discriminate([Cro], Wheel, Wheel, Finding),
    % The record carries the question's event on both sides, so the finding says so.
    assertion(Finding == genuine_cause([CroId])).

% A question about something that is not an event is refused by name.
test(non_event_is_refused, [throws(error(cause_and_effect_not_an_event(_), _))]) :-
    % The first argument is free text, not a minted event.
    cause_and_effect_discriminate([], "not_an_event", "also_not_an_event", _Finding).

% Means-end planning, exactly as the book states it: compose a short action sequence
% that reaches a given goal state - each step named, justified, and watchable.
test(single_step_plan_reaches_the_goal) :-
    % One known action: striking the match turns the room from dark to lit.
    Actions = [action(strike_the_match, dark, lit)],
    % Plan from the dark room to the lit room.
    cause_and_effect_plan(Actions, dark, lit, Plan),
    % The plan is the single justified step.
    assertion(Plan == [step(apply_action, strike_the_match, from(dark), to(lit))]).

% A longer plan chains means to end, and the shortest sequence is found.
test(multi_step_plan_chains_means_to_end) :-
    % The known actions of a small world.
    Actions = [
        % Gather wood: bare camp to stocked camp.
        action(gather_wood, bare, stocked),
        % Light the fire: stocked camp to warm camp.
        action(light_the_fire, stocked, warm),
        % Cook the meal: warm camp to fed camp.
        action(cook_the_meal, warm, fed)
    ],
    % Plan from the bare camp to the fed camp.
    cause_and_effect_plan(Actions, bare, fed, Plan),
    % Three steps, in means-end order, each justified by its states.
    assertion(Plan == [
        step(apply_action, gather_wood, from(bare), to(stocked)),
        step(apply_action, light_the_fire, from(stocked), to(warm)),
        step(apply_action, cook_the_meal, from(warm), to(fed))
    ]).

% The shortest plan wins: a direct road beats a detour.
test(shortest_plan_is_chosen) :-
    % Two roads to the goal: a two-step detour and a one-step direct road.
    Actions = [
        % The detour, first leg.
        action(walk_to_the_bridge, home, bridge),
        % The detour, second leg.
        action(cross_the_bridge, bridge, market),
        % The direct road.
        action(take_the_ferry, home, market)
    ],
    % Plan from home to the market.
    cause_and_effect_plan(Actions, home, market, Plan),
    % The one-step ferry road is chosen.
    assertion(Plan == [step(apply_action, take_the_ferry, from(home), to(market))]).

% A goal already at hand needs no action at all - the empty plan, honestly.
test(goal_already_reached_plans_nothing) :-
    % Plan from the goal to itself.
    cause_and_effect_plan([action(anything, here, there)], there, there, Plan),
    % Nothing needs doing.
    assertion(Plan == []).

% An unreachable goal fails cleanly - the planner never invents a road.
test(unreachable_goal_fails_cleanly, [fail]) :-
    % The only action leads away from the goal.
    cause_and_effect_plan([action(walk_away, home, forest)], home, moon, _Plan).

% A malformed action is refused by name, never silently skipped.
test(malformed_action_is_refused, [throws(error(cause_and_effect_malformed_action(_), _))]) :-
    % The second term is not an action/3.
    cause_and_effect_plan([action(walk, a, b), teleport(b, c)], a, c, _Plan).

% An unbound start state is refused by name - otherwise the planner would invent a start of
% its own and answer a question nobody asked.
test(unbound_start_state_is_refused, [throws(error(cause_and_effect_malformed_state(_), _))]) :-
    % The start state is an unbound variable.
    cause_and_effect_plan([action(walk, home, forest)], _Start, forest, _Plan).

% A goal state that is not a named atom is refused by name.
test(malformed_goal_state_is_refused, [throws(error(cause_and_effect_malformed_state(_), _))]) :-
    % The goal is free text where a named state belongs.
    cause_and_effect_plan([action(walk, home, forest)], home, "forest", _Plan).

% A plan the mind commits to is owned on the record as the standard's own intends attitude.
test(plan_is_owned_as_an_intends_attitude) :-
    % The fixed instant stamps the record.
    cause_and_effect_test_instant(Instant),
    % A two-step plan worth committing to.
    cause_and_effect_plan([action(gather_wood, bare, stocked), action(light_the_fire, stocked, warm)], bare, warm, Plan),
    % Own the plan as an intention.
    cause_and_effect_intend(Plan, "warm_the_camp", Instant, Record),
    % The attitude is the standard's own intends.
    get_dict(attitude_type, Record, AttitudeType),
    % A committed plan is intended.
    assertion(AttitudeType == "intends").

% An empty plan is nothing to commit to, and intending it is refused by name.
test(empty_plan_intention_is_refused, [throws(error(cause_and_effect_empty_intention, _))]) :-
    % The fixed instant stamps the attempt.
    cause_and_effect_test_instant(Instant),
    % There is no step to intend.
    cause_and_effect_intend([], "do_nothing", Instant, _Record).

% A plan holding something that is not a step at all is refused by name, never failed silently.
test(malformed_plan_step_is_refused, [throws(error(cause_and_effect_malformed_step(_), _))]) :-
    % The fixed instant stamps the attempt.
    cause_and_effect_test_instant(Instant),
    % The supposed plan holds a bare atom where a justified step belongs.
    cause_and_effect_intend([totally_not_a_step], "some_goal", Instant, _Record).

% A step whose justification slots are junk is refused by name - a step must say which states
% it leaves and reaches, or it justifies nothing.
test(unjustified_plan_step_is_refused, [throws(error(cause_and_effect_malformed_step(_), _))]) :-
    % The fixed instant stamps the attempt.
    cause_and_effect_test_instant(Instant),
    % The step carries garbage where its from-state and to-state belong.
    cause_and_effect_intend([step(apply_action, walk, garbage, junk)], "some_goal", Instant, _Record).

% The mind's stance on its own plan is graded derivation - a plan is reasoned, not observed.
test(intention_stance_is_graded_derivation) :-
    % The fixed instant stamps the record.
    cause_and_effect_test_instant(Instant),
    % A one-step plan.
    cause_and_effect_plan([action(strike_the_match, dark, lit)], dark, lit, Plan),
    % Own the plan as an intention.
    cause_and_effect_intend(Plan, "light_the_room", Instant, Record),
    % The mind grades its own intention.
    cause_and_effect_stance(Record, Instant, Stance),
    % The stance is graded derivation: means-end reasoning produced it.
    get_dict(evidence_type, Stance, Grade),
    % The grade is derivation.
    assertion(Grade == "derivation"),
    % The stance is about the intention it grades.
    get_dict(about, Stance, About),
    % Read the intention's identifier.
    get_dict(id, Record, RecordIdentifier),
    % The stance names the intention, byte for byte.
    assertion(About == RecordIdentifier).

% The owned intention is content-addressed: the same plan, committed twice, mints the same identifier.
test(owned_intention_is_reproducible) :-
    % The fixed instant stamps both committals.
    cause_and_effect_test_instant(Instant),
    % The same one-step plan, twice.
    cause_and_effect_plan([action(strike_the_match, dark, lit)], dark, lit, Plan),
    % Commit it once.
    cause_and_effect_intend(Plan, "light_the_room", Instant, First),
    % Commit the byte-identical plan again.
    cause_and_effect_intend(Plan, "light_the_room", Instant, Second),
    % Read the first identifier.
    get_dict(id, First, FirstIdentifier),
    % Read the second identifier.
    get_dict(id, Second, SecondIdentifier),
    % Content-addressing makes the two identifiers identical.
    assertion(FirstIdentifier == SecondIdentifier).

% Close the cause_and_effect test block.
:- end_tests(cause_and_effect).
