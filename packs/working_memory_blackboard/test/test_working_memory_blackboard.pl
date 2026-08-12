% Load the working_memory_blackboard module under test from the library path.
:- use_module(library(working_memory_blackboard)).
% Load the scheduler, so the tick restatements can be checked against the one conversion they use.
:- use_module(library(tick_engine)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Load fold and lambda support, used to take many maintenance steps in one line.
:- use_module(library(apply), [foldl/4]).
% Load list membership, used to walk the decades of the tick in DECISION-23's uniqueness test.
:- use_module(library(lists), [member/2]).
:- use_module(library(yall)).

% Open the test block for the working_memory_blackboard pack.
:- begin_tests(working_memory_blackboard).

% ---------------------------------------------------------------------------
% THE CORPUS'S CONSTANTS, EXACTLY AS THE CHAPTER WRITES THEM
% ---------------------------------------------------------------------------

% The capacity is the corpus's four items on one shared surface.
test(capacity_is_the_corpus_four) :-
    % Read the declared capacity.
    working_memory_blackboard_capacity(Capacity),
    % Confirm it is the chapter's four.
    assertion(Capacity =:= 4).

% The three activation constants are the chapter's own decimals and nothing else.
test(activation_constants_are_the_corpus_decimals) :-
    % Read the per-step leakage.
    working_memory_blackboard_decay_decimal(Decay),
    % Read the collapse threshold.
    working_memory_blackboard_collapse_decimal(Collapse),
    % Read full activation.
    working_memory_blackboard_full_decimal(Full),
    % Confirm each is the chapter's number.
    assertion(Decay =:= 0.05),
    assertion(Collapse =:= 0.2),
    assertion(Full =:= 1.0).

% ---------------------------------------------------------------------------
% DECISION-8, THE ACTIVATION GRAIN
% ---------------------------------------------------------------------------

% The grain is one hundred parts to the unit activation.
test(grain_is_one_hundred_parts) :-
    % Read the declared grain.
    working_memory_blackboard_parts_per_unit(Parts),
    % Confirm it is a hundred.
    assertion(Parts =:= 100).

% Every one of the corpus's three activation constants lands exactly on a part.
test(every_corpus_constant_lands_on_a_part) :-
    % The leakage is five parts.
    working_memory_blackboard_parts_from_decimal(0.05, Decay),
    % The collapse threshold is twenty parts.
    working_memory_blackboard_parts_from_decimal(0.2, Collapse),
    % Full activation is a hundred parts.
    working_memory_blackboard_parts_from_decimal(1.0, Full),
    % Confirm the three conversions.
    assertion(Decay =:= 5),
    assertion(Collapse =:= 20),
    assertion(Full =:= 100).

% A decimal finer than the grain is refused aloud rather than rounded into a part.
test(finer_than_the_grain_is_refused,
     throws(error(domain_error(whole_part_activation, 0.003), _))) :-
    % Three thousandths does not land on a part, and rounding it would invent a number.
    working_memory_blackboard_parts_from_decimal(0.003, _).

% An unbound decimal is refused aloud rather than invented.
test(unbound_decimal_is_refused, throws(error(instantiation_error, _))) :-
    % A hole here would invent both a decimal and a part count for it.
    working_memory_blackboard_parts_from_decimal(_, _).

% An activation outside the range from empty to full is refused by name.
test(out_of_range_decimal_is_refused,
     throws(error(domain_error(working_memory_blackboard_activation_decimal, 1.5), _))) :-
    % No slot can stand above full activation.
    working_memory_blackboard_parts_from_decimal(1.5, _).

% A part count reads back as the decimal the corpus would write.
test(parts_read_back_as_a_decimal) :-
    % Read twenty parts back.
    working_memory_blackboard_decimal_from_parts(20, Decimal),
    % Confirm it is the chapter's two tenths.
    assertion(Decimal =:= 0.2).

% THE FLOAT ARTEFACT THE GRAIN EXISTS TO DEFEAT, asserted so the reason is on the record.
test(exact_parts_and_drifting_floats_disagree_at_the_threshold) :-
    % Take a full slot down by five hundredths sixteen times in binary floating point.
    foldl([_, Accumulator0, Accumulator]>>(Accumulator is Accumulator0 - 0.05),
          [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16], 1.0, Drifted),
    % The float has fallen below the threshold, so it would collapse this step.
    assertion(Drifted < 0.2),
    % Exactly, the same sixteen steps leave the slot standing ON the threshold, in parts.
    working_memory_blackboard_parts_from_decimal(1.0, Full),
    working_memory_blackboard_parts_from_decimal(0.05, Decay),
    working_memory_blackboard_parts_from_decimal(0.2, Collapse),
    Exact is Full - 16 * Decay,
    % Confirm the exact value is the threshold itself, which has not fallen below anything.
    assertion(Exact =:= Collapse).

% ---------------------------------------------------------------------------
% THE CORPUS'S TIME CONSTANTS, RESTATED IN TICKS BY DECISION-2
% ---------------------------------------------------------------------------

% The admission window is the corpus's hundred to three hundred milliseconds, in ticks.
test(admission_window_in_ticks) :-
    % Read the restated window.
    working_memory_blackboard_admission_ticks(Low, High),
    % Confirm ten and thirty ticks, which is what DECISION-2's hundred ticks a second makes them.
    assertion(Low =:= 10),
    assertion(High =:= 30).

% The unrehearsed fade is the corpus's two to twenty seconds, in ticks.
test(unrehearsed_fade_in_ticks) :-
    % Read the restated fade.
    working_memory_blackboard_unrehearsed_decay_ticks(Low, High),
    % Confirm two hundred and two thousand ticks.
    assertion(Low =:= 200),
    assertion(High =:= 2000).

% The task-switch wipe bound is the corpus's one second, in ticks.
test(wipe_bound_in_ticks) :-
    % Read the restated bound.
    working_memory_blackboard_wipe_ticks(Ticks),
    % Confirm one hundred ticks.
    assertion(Ticks =:= 100).

% Every restatement goes through the scheduler's one conversion rather than a tick literal.
test(tick_restatements_agree_with_the_one_conversion) :-
    % Convert the corpus's own milliseconds independently.
    tick_engine_ticks_from_milliseconds(100, AdmissionLow),
    tick_engine_ticks_from_milliseconds(20000, FadeHigh),
    % Read the pack's restatements.
    working_memory_blackboard_admission_ticks(PackAdmissionLow, _),
    working_memory_blackboard_unrehearsed_decay_ticks(_, PackFadeHigh),
    % Confirm the pack restates nothing of its own.
    assertion(PackAdmissionLow =:= AdmissionLow),
    assertion(PackFadeHigh =:= FadeHigh).

% ---------------------------------------------------------------------------
% THE RATE REFUSAL - THE CHAPTER DISAGREES WITH ITSELF AND KONNECTOME REPORTS IT
% ---------------------------------------------------------------------------

% A full slot survives seventeen unrehearsed steps, which is DERIVED and never declared.
test(seventeen_unrehearsed_steps_to_collapse) :-
    % Read the derived survival count.
    working_memory_blackboard_steps_to_collapse(Steps),
    % Confirm seventeen, which is the count the corpus's constants imply and nobody chose.
    assertion(Steps =:= 17).

% THE DISCREPANCY ITSELF, asserted so it is reported upward rather than absorbed.
test(the_step_rate_is_not_the_chapters_own_seconds) :-
    % The survival count in steps, from the chapter's CODE SAMPLE constants.
    working_memory_blackboard_steps_to_collapse(Steps),
    % The chapter's TIME CONSTANTS field states the same fade in seconds, restated in ticks.
    working_memory_blackboard_unrehearsed_decay_ticks(FadeLow, _FadeHigh),
    % Confirm the two are nowhere near each other, which is why no step-per-tick binding is declared.
    assertion(Steps < FadeLow).

% ---------------------------------------------------------------------------
% THE EMPTY BOARD
% ---------------------------------------------------------------------------

% A fresh board holds nothing.
test(fresh_board_is_empty) :-
    % Make a fresh board.
    working_memory_blackboard_new(Board),
    % Read its slots and its occupancy.
    working_memory_blackboard_slots(Board, Items),
    working_memory_blackboard_occupancy(Board, Count),
    % Confirm the surface is blank.
    assertion(Items == []),
    assertion(Count =:= 0).

% ---------------------------------------------------------------------------
% ADMISSION THROUGH THE STRIATAL GATE
% ---------------------------------------------------------------------------

% An open gate admits an item at full activation.
test(open_gate_admits_at_full) :-
    % Start from an empty board.
    working_memory_blackboard_new(Board0),
    % Offer an item through an open gate.
    working_memory_blackboard_admit(Board0, seven, open, Board),
    % Read the admitted item's activation.
    working_memory_blackboard_activation(Board, seven, Parts),
    % Confirm it stands at full.
    working_memory_blackboard_parts_from_decimal(1.0, Full),
    assertion(Parts =:= Full).

% A closed gate discards the distractor and leaves the board unchanged.
test(closed_gate_discards_the_distractor) :-
    % Start from a board holding one item.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    % Offer a distractor through a closed gate.
    working_memory_blackboard_admit(Board1, advert_jingle, closed, Board2),
    % Confirm the board is exactly what it was.
    assertion(Board2 == Board1),
    % Confirm the distractor never reached the surface.
    working_memory_blackboard_slots(Board2, Items),
    assertion(Items == [seven]).

% The board fills to the corpus's capacity in admission order.
test(board_fills_to_capacity_in_admission_order) :-
    % Admit the chapter's own four digits in order.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    working_memory_blackboard_admit(Board1, four, open, Board2),
    working_memory_blackboard_admit(Board2, one, open, Board3),
    working_memory_blackboard_admit(Board3, nine, open, Board4),
    % Read the slots.
    working_memory_blackboard_slots(Board4, Items),
    % Confirm all four are held, oldest first.
    assertion(Items == [seven, four, one, nine]),
    % Confirm the surface is full.
    working_memory_blackboard_occupancy(Board4, Count),
    working_memory_blackboard_capacity(Capacity),
    assertion(Count =:= Capacity).

% Re-offering a held item UPDATES it and evicts nothing, per the chapter's own prose.
test(re_offering_a_held_item_updates_rather_than_evicts) :-
    % Fill the surface.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    working_memory_blackboard_admit(Board1, four, open, Board2),
    working_memory_blackboard_admit(Board2, one, open, Board3),
    working_memory_blackboard_admit(Board3, nine, open, Board4),
    % Let the board decay so the first item is no longer at full.
    working_memory_blackboard_step(Board4, none, Board5),
    working_memory_blackboard_step(Board5, none, Board6),
    % Re-offer an item already held, through an open gate, onto a FULL surface.
    working_memory_blackboard_admit(Board6, seven, open, Board7),
    % Confirm nothing was evicted: all four are still on the surface, in their admission order.
    working_memory_blackboard_slots(Board7, Items),
    assertion(Items == [seven, four, one, nine]),
    % Confirm the re-offered item was restored to full.
    working_memory_blackboard_activation(Board7, seven, Parts),
    working_memory_blackboard_parts_from_decimal(1.0, Full),
    assertion(Parts =:= Full).

% A full surface evicts the weakest slot to make room for a new item.
test(full_surface_evicts_the_weakest) :-
    % Fill the surface, then refresh three of the four so the fourth is strictly weakest.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    working_memory_blackboard_admit(Board1, four, open, Board2),
    working_memory_blackboard_admit(Board2, one, open, Board3),
    working_memory_blackboard_admit(Board3, nine, open, Board4),
    % One maintenance step leaks every slot equally.
    working_memory_blackboard_step(Board4, none, Board5),
    % Re-offering three of them puts them back at full, leaving one below.
    working_memory_blackboard_admit(Board5, seven, open, Board6),
    working_memory_blackboard_admit(Board6, four, open, Board7),
    working_memory_blackboard_admit(Board7, nine, open, Board8),
    % Offer a fifth item onto the full surface.
    working_memory_blackboard_admit(Board8, five, open, Board9),
    % Confirm the weakest slot left and the new item took its place at the end of the order.
    working_memory_blackboard_slots(Board9, Items),
    assertion(Items == [seven, four, nine, five]).

% AN EVICTION TIE IS BROKEN IN THE OPEN: the earliest-admitted of the equally weak leaves.
test(eviction_tie_takes_the_earliest_admitted) :-
    % Fill the surface, so all four stand at exactly the same activation.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    working_memory_blackboard_admit(Board1, four, open, Board2),
    working_memory_blackboard_admit(Board2, one, open, Board3),
    working_memory_blackboard_admit(Board3, nine, open, Board4),
    % Offer a fifth item onto a surface whose four slots are all equally weak.
    working_memory_blackboard_admit(Board4, five, open, Board5),
    % Confirm the FIRST-admitted slot is the one that left, not an arbitrary one.
    working_memory_blackboard_slots(Board5, Items),
    assertion(Items == [four, one, nine, five]).

% An eviction is DETERMINISTIC rather than merely correct on its first answer.
test(eviction_is_deterministic) :-
    % Fill the surface so every slot is tied on activation.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    working_memory_blackboard_admit(Board1, four, open, Board2),
    working_memory_blackboard_admit(Board2, one, open, Board3),
    working_memory_blackboard_admit(Board3, nine, open, Board4),
    % Collect every answer the admission can give.
    findall(Board, working_memory_blackboard_admit(Board4, five, open, Board), Answers),
    % Confirm there is exactly one, so no choice point was left behind on a tie.
    assertion(Answers = [_]).

% ---------------------------------------------------------------------------
% THE MAINTENANCE STEP
% ---------------------------------------------------------------------------

% A maintenance step leaks every slot by the corpus's decay amount.
test(step_leaks_every_slot) :-
    % Admit two items at full.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    working_memory_blackboard_admit(Board1, four, open, Board2),
    % Take one maintenance step with nothing rehearsed.
    working_memory_blackboard_step(Board2, none, Board3),
    % Read both activations.
    working_memory_blackboard_activation(Board3, seven, Seven),
    working_memory_blackboard_activation(Board3, four, Four),
    % Confirm both have leaked by exactly the decay amount.
    working_memory_blackboard_parts_from_decimal(1.0, Full),
    working_memory_blackboard_parts_from_decimal(0.05, Decay),
    Expected is Full - Decay,
    assertion(Seven =:= Expected),
    assertion(Four =:= Expected).

% A rehearsed slot is restored to full, which is the attentional refresh.
test(rehearsal_restores_to_full) :-
    % Admit one item and leak it several times.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    working_memory_blackboard_step(Board1, none, Board2),
    working_memory_blackboard_step(Board2, none, Board3),
    % Rehearse it on the next step.
    working_memory_blackboard_step(Board3, seven, Board4),
    % Confirm it is back at full.
    working_memory_blackboard_activation(Board4, seven, Parts),
    working_memory_blackboard_parts_from_decimal(1.0, Full),
    assertion(Parts =:= Full).

% An unrehearsed slot survives sixteen steps and collapses on the seventeenth.
test(unrehearsed_slot_collapses_on_the_seventeenth_step) :-
    % Admit one item at full.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    % Take sixteen maintenance steps with nothing rehearsed.
    foldl([_, In, Out]>>working_memory_blackboard_step(In, none, Out),
          [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16], Board1, Board17),
    % Confirm the slot is still held, standing exactly on the threshold.
    working_memory_blackboard_slots(Board17, Held),
    assertion(Held == [seven]),
    working_memory_blackboard_activation(Board17, seven, Parts),
    working_memory_blackboard_parts_from_decimal(0.2, Collapse),
    assertion(Parts =:= Collapse),
    % Take one more step.
    working_memory_blackboard_step(Board17, none, Board18),
    % Confirm the attractor has collapsed and the slot is gone.
    working_memory_blackboard_slots(Board18, Gone),
    assertion(Gone == []).

% REHEARSAL RESCUES A SLOT THE SAME STEP THAT WOULD HAVE COLLAPSED IT - the declared order.
test(rehearsal_rescues_a_collapsing_slot) :-
    % Admit one item and take it down to the threshold.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    foldl([_, In, Out]>>working_memory_blackboard_step(In, none, Out),
          [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16], Board1, Board17),
    % The next step's leakage alone would take it below the threshold, so rehearse it instead.
    working_memory_blackboard_step(Board17, seven, Board18),
    % Confirm the refresh came before the collapse check, so the slot survives at full.
    working_memory_blackboard_activation(Board18, seven, Parts),
    working_memory_blackboard_parts_from_decimal(1.0, Full),
    assertion(Parts =:= Full).

% A collapse removes only the collapsed slot and keeps the rest in admission order.
test(collapse_keeps_the_survivors_in_order) :-
    % Admit one item, leak it to the edge, then admit two more at full.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    foldl([_, In, Out]>>working_memory_blackboard_step(In, none, Out),
          [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16], Board1, Board17),
    working_memory_blackboard_admit(Board17, four, open, Board18),
    working_memory_blackboard_admit(Board18, one, open, Board19),
    % One more step collapses the oldest and leaks the other two.
    working_memory_blackboard_step(Board19, none, Board20),
    % Confirm the survivors are the two newer items, still oldest first.
    working_memory_blackboard_slots(Board20, Items),
    assertion(Items == [four, one]).

% ---------------------------------------------------------------------------
% THE WIPE
% ---------------------------------------------------------------------------

% The next task wipes the whole surface.
test(wipe_erases_the_whole_surface) :-
    % Fill the surface.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    working_memory_blackboard_admit(Board1, four, open, Board2),
    % Wipe it.
    working_memory_blackboard_wipe(Board2, Board3),
    % Confirm nothing survives the task switch.
    working_memory_blackboard_slots(Board3, Items),
    assertion(Items == []).

% ---------------------------------------------------------------------------
% READING THE BOARD - AN ABSENT SLOT IS NOT A ZERO
% ---------------------------------------------------------------------------

% An item the board does not hold is refused aloud rather than read as a plausible zero.
test(absent_slot_is_refused_not_zeroed,
     throws(error(existence_error(working_memory_blackboard_slot, never_admitted), _))) :-
    % Start from a board holding something else entirely.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    % Read an item that was never admitted.
    working_memory_blackboard_activation(Board1, never_admitted, _).

% A collapsed slot and a never-admitted slot are refused the same way, and neither reads as zero.
test(collapsed_slot_is_refused_too,
     throws(error(existence_error(working_memory_blackboard_slot, seven), _))) :-
    % Admit an item and let it collapse.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    foldl([_, In, Out]>>working_memory_blackboard_step(In, none, Out),
          [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17], Board1, Board18),
    % Read the collapsed item.
    working_memory_blackboard_activation(Board18, seven, _).

% ---------------------------------------------------------------------------
% THE REFUSAL PERIMETER
% ---------------------------------------------------------------------------

% An unbound board is refused aloud rather than bound to the empty board.
test(unbound_board_is_refused, throws(error(instantiation_error, _))) :-
    % A hole here would unify with the empty board and answer as if nothing were held.
    working_memory_blackboard_slots(_, _).

% An unbound item is refused rather than bound to whichever slot is listed first.
test(unbound_item_is_refused, throws(error(instantiation_error, _))) :-
    % Build a board with two slots, so a hole would have a first row to bind to.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    working_memory_blackboard_admit(Board1, four, open, Board2),
    % Read an unbound item.
    working_memory_blackboard_activation(Board2, _, _).

% An unbound gate verdict is refused rather than opening the gate by accident.
test(unbound_gate_is_refused, throws(error(instantiation_error, _))) :-
    % Offer an item through a gate whose verdict nobody gave.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, _, _).

% A gate verdict the striatum never gives is refused by name.
test(unknown_gate_verdict_is_refused,
     throws(error(domain_error(working_memory_blackboard_gate, maybe), _))) :-
    % There are exactly two verdicts and this is not one of them.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, maybe, _).

% An unbound rehearsal target is refused rather than rehearsing whatever is listed first.
test(unbound_rehearsal_target_is_refused, throws(error(instantiation_error, _))) :-
    % Build a board with a first row for a hole to bind to.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    % Take a step with an unbound target.
    working_memory_blackboard_step(Board1, _, _).

% A rehearsal aimed at a slot the board does not hold is refused rather than doing nothing.
test(rehearsing_an_absent_slot_is_refused,
     throws(error(existence_error(working_memory_blackboard_slot, never_admitted), _))) :-
    % Build a board holding something else.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    % Rehearse an item that is not on the surface.
    working_memory_blackboard_step(Board1, never_admitted, _).

% The explicit absence rehearses nothing and is not a refusal.
test(explicit_no_rehearsal_is_accepted) :-
    % Take a step with the explicit no-rehearsal target.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, seven, open, Board1),
    working_memory_blackboard_step(Board1, none, Board2),
    % Confirm the slot leaked rather than being refreshed.
    working_memory_blackboard_activation(Board2, seven, Parts),
    working_memory_blackboard_parts_from_decimal(1.0, Full),
    assertion(Parts < Full).

% This pack's word for no rehearsal may not also be the name of a slot.
test(the_absence_word_may_not_name_a_slot,
     throws(error(domain_error(working_memory_blackboard_item, none), _))) :-
    % Offering an item called none would make the absence and a slot indistinguishable.
    working_memory_blackboard_new(Board0),
    working_memory_blackboard_admit(Board0, none, open, _).

% A board that is not a list is refused aloud rather than walked.
test(non_list_board_is_refused, throws(error(type_error(list, seven), _))) :-
    % A board is a list of slots and nothing else.
    working_memory_blackboard_slots(seven, _).

% A term on a board that is not a slot is refused by name.
test(malformed_slot_is_refused,
     throws(error(domain_error(working_memory_blackboard_slot, seven), _))) :-
    % A bare atom is not an item-and-activation pair.
    working_memory_blackboard_slots([seven], _).

% Two slots for one item are refused rather than answered first-one-wins.
test(duplicate_item_is_refused,
     throws(error(domain_error(working_memory_blackboard_duplicate_item, seven), _))) :-
    % One thought held twice would be evicted once and read once.
    working_memory_blackboard_slots([seven-100, seven-50], _).

% A board wider than the shared surface is refused rather than quietly trimmed.
test(over_capacity_board_is_refused,
     throws(error(domain_error(working_memory_blackboard_capacity, 5), _))) :-
    % Five slots on a four-slot surface was built by something other than this pack's admission.
    working_memory_blackboard_slots([a-100, b-100, c-100, d-100, e-100], _).

% An activation held as a decimal has skipped the one conversion and is refused.
test(decimal_activation_on_a_board_is_refused,
     throws(error(type_error(integer, 0.5), _))) :-
    % Activations are held as whole parts, so a board carrying a decimal is malformed.
    working_memory_blackboard_slots([seven-0.5], _).

% An activation no slot could reach is refused by name.
test(impossible_activation_is_refused,
     throws(error(domain_error(working_memory_blackboard_activation_parts, 250), _))) :-
    % No slot stands above full activation.
    working_memory_blackboard_slots([seven-250], _).

% =============================================================================
% DECISION-23 - THE MAINTENANCE PERIOD, AND WHAT IT HAS TO LAND INSIDE
% =============================================================================

% The maintenance period is one nominal second, which is a hundred ticks under DECISION-2.
test(the_maintenance_period_is_one_nominal_second) :-
    % Read the period konnectome chose, computed through the scheduler's one conversion.
    working_memory_blackboard_step_ticks(Period),
    % A nominal second is a hundred ticks, so one step per second is a step per hundred ticks.
    assertion(Period =:= 100).

% THE WHOLE WARRANT OF DECISION-23, ASSERTED RATHER THAN ARGUED IN PROSE ALONE. The period is chosen
% so the lifetime it implies lands inside the corpus's own measured window, and this test is what a
% later session meets if anybody ever restates the tick, the decay, the threshold or the period.
test(the_implied_lifetime_lands_inside_the_corpus_measured_window) :-
    % Read the lifetime the period and the corpus's constants imply, computed and never written down.
    working_memory_blackboard_unrehearsed_life_ticks(Life),
    % Read the corpus's own measured window, restated in ticks through the one conversion.
    working_memory_blackboard_unrehearsed_decay_ticks(Low, High),
    % The implied lifetime is at or above the window's floor, which one step per tick badly missed.
    assertion(Life >= Low),
    % And at or below its ceiling, which is the half a slower period would have missed.
    assertion(Life =< High).

% THE UNIQUENESS ARGUMENT ITSELF: exactly one decade of the tick lands inside that window, which is
% the reason this period and not one of the hundred and five other whole periods that also land.
test(exactly_one_decade_of_the_tick_lands_inside_the_window) :-
    % Read how many unrehearsed steps a full slot survives, DERIVED from the corpus's constants.
    working_memory_blackboard_steps_to_collapse(Steps),
    % Read the corpus's measured window in ticks.
    working_memory_blackboard_unrehearsed_decay_ticks(Low, High),
    % Collect every decade of the tick whose implied lifetime falls inside that window.
    findall(Decade,
            ( member(Decade, [1, 10, 100, 1000]),
              Life is Steps * Decade,
              Life >= Low,
              Life =< High
            ),
            Landing),
    % Exactly one decade qualifies, and it is the period DECISION-23 chose.
    assertion(Landing == [100]).

% The corpus's gloss is NOT matched, and konnectome says so in a test rather than only in a comment.
test(the_chapters_ten_second_gloss_is_knowingly_not_matched) :-
    % Read the lifetime konnectome's own period implies.
    working_memory_blackboard_unrehearsed_life_ticks(Life),
    % Ten nominal seconds is a thousand ticks, which is the chapter's prose summary of the same fade.
    assertion(Life =\= 1000),
    % konnectome takes the chapter's MEASUREMENT field over its prose summary, and lands above it.
    assertion(Life > 1000).

% Close the test block for the working_memory_blackboard pack.
:- end_tests(working_memory_blackboard).
