% Declare this file as the 'working_memory_blackboard' module and list the predicates it exports.
:- module(working_memory_blackboard, [
    % working_memory_blackboard_capacity/1: the corpus's capacity, four items on one shared surface.
    working_memory_blackboard_capacity/1,
    % working_memory_blackboard_decay_decimal/1: the corpus's per-step leakage, written as the corpus writes it.
    working_memory_blackboard_decay_decimal/1,
    % working_memory_blackboard_collapse_decimal/1: the corpus's collapse threshold, written as the corpus writes it.
    working_memory_blackboard_collapse_decimal/1,
    % working_memory_blackboard_full_decimal/1: the corpus's full activation, what admission and rehearsal set.
    working_memory_blackboard_full_decimal/1,
    % working_memory_blackboard_parts_per_unit/1: THE ACTIVATION GRAIN, one hundred parts to the unit.
    working_memory_blackboard_parts_per_unit/1,
    % working_memory_blackboard_parts_from_decimal/2: convert a corpus decimal to parts, refusing anything that does not land.
    working_memory_blackboard_parts_from_decimal/2,
    % working_memory_blackboard_decimal_from_parts/2: read a part count back as the decimal the corpus would write.
    working_memory_blackboard_decimal_from_parts/2,
    % working_memory_blackboard_new/1: a fresh empty board.
    working_memory_blackboard_new/1,
    % working_memory_blackboard_step/3: one maintenance step - decay every slot, refresh the rehearsed one, drop the collapsed.
    working_memory_blackboard_step/3,
    % working_memory_blackboard_admit/4: offer one item to the gate, admitting, updating, evicting or discarding.
    working_memory_blackboard_admit/4,
    % working_memory_blackboard_wipe/2: erase the whole surface, as the next task does.
    working_memory_blackboard_wipe/2,
    % working_memory_blackboard_slots/2: the items currently held, in admission order.
    working_memory_blackboard_slots/2,
    % working_memory_blackboard_occupancy/2: how many of the capacity's slots are in use.
    working_memory_blackboard_occupancy/2,
    % working_memory_blackboard_activation/3: the activation of one held item, refusing an item the board does not hold.
    working_memory_blackboard_activation/3,
    % working_memory_blackboard_admission_ticks/2: the corpus's admission window, restated in ticks by DECISION-2.
    working_memory_blackboard_admission_ticks/2,
    % working_memory_blackboard_unrehearsed_decay_ticks/2: the corpus's unrehearsed fade, restated in ticks by DECISION-2.
    working_memory_blackboard_unrehearsed_decay_ticks/2,
    % working_memory_blackboard_wipe_ticks/1: the corpus's task-switch wipe bound, restated in ticks by DECISION-2.
    working_memory_blackboard_wipe_ticks/1,
    % working_memory_blackboard_steps_to_collapse/1: how many unrehearsed steps a full slot survives, DERIVED and not declared.
    working_memory_blackboard_steps_to_collapse/1,
    % working_memory_blackboard_step_ticks/1: THE MAINTENANCE PERIOD, konnectome's own choice under DECISION-23.
    working_memory_blackboard_step_ticks/1,
    % working_memory_blackboard_unrehearsed_life_ticks/1: the lifetime that period and the corpus's constants imply.
    working_memory_blackboard_unrehearsed_life_ticks/1
]).

% Import list reading and building for slot lookup, ordering and eviction.
:- use_module(library(lists), [member/2, memberchk/2, append/3, nth0/3, min_list/2]).
% Import maplist for judging and advancing every slot together.
:- use_module(library(apply), [maplist/2, maplist/3]).
% Reuse the scheduler's ONE duration conversion so no wall-clock constant is restated here.
:- use_module(library(tick_engine), [tick_engine_ticks_from_milliseconds/2]).

% The working memory blackboard is LAYER_10_SYSTEMS_MANUSCRIPT.txt Chapter 16, THE WORKING MEMORY
% SYSTEM (Prefrontal-Parietal Persistent-Activity Circuit) (The Present-Thought Blackboard), built at
% the depth the motif-and-workspace design authority's Part B6 item 3 specifies. The chapter's own
% gloss is the whole design in three words: PRESENT names the tense, so this store holds only the
% current few seconds of thought; THOUGHT names the clientele, so every reasoning step rents space
% here; and BLACKBOARD names the mechanism - "a small erasable surface, written by attention, read by
% everything, wiped by the next task".
%
% NOT ONE CONSTANT IN THIS PACK IS KONNECTOME'S INVENTION. Capacity four, decay five hundredths per
% step, collapse below two tenths, and rehearsal restoring to one are the chapter's own numbers, from
% its ENGLISH READABLE CODE block and its CODE SAMPLE. The wall-clock durations are the chapter's
% TIME CONSTANTS field, and they are restated in ticks through the SINGLE conversion DECISION-2
% established, never rewritten as tick literals here.
%
% THE CONTENTS ARE EPHEMERAL BY DEFINITION AND THAT IS THE POINT, stated three times in one chapter:
% "Nothing is written to a synapse; the memory is the activity, and when the activity stops, the
% number is gone"; "The contents are not learned at all - that is the point"; and "The only memory in
% the book that exists as ongoing electricity rather than changed synapses". A board is therefore an
% EXPLICIT STATELESS VALUE THE WORLD CARRIES, in the eligibility-trace store's discipline: decaying,
% externally readable, deliberately unrecorded. Nothing in this pack mints a record, and nothing in
% this pack asserts a clause.
%
% THE GATING POLICY IS HELD CONSTANT IN THIS SLICE, per B5.9 and B4's second caution. The chapter says
% the contents are not learned but the GATING POLICY is, by striatal reinforcement, so one module
% holds the one thing that must never be recorded beside the one thing that eventually must be. This
% slice takes the gate verdict as an argument from its caller and learns nothing, so the durable half
% is not begun by accident. The rehearsal target is caller-supplied for the same reason.
%
% WHAT SLICE 49 DELIBERATELY DID NOT DO, AND WHAT SLICE 74 HAS SINCE DONE. Slice 49 did not wire the
% board into cognitive_cycle_step/3 and did not bind a maintenance step to a tick, and it recorded the
% second omission as OBSERVATION-13, the RATE REFUSAL. SLICE 74 CLOSES BOTH, TOGETHER, because
% OBSERVATION-13's own closer says they must close together: the slice that wires the board into the
% tick is the slice that must declare the rate in the open. The period is DECISION-23 and it is
% written below, in the place the refusal used to stand, with the refusal's reasoning kept rather than
% deleted - a settled question should still show what it was.
%
% WHAT IS STILL NOT DONE HERE, and neither is an oversight. This pack does not decide which gate is
% which - dopamine gates admission here, attention gates ignition at the workspace, and B1's second
% refinement warns that collapsing them is easy and expensive. And the GATING POLICY is still held
% constant and the REHEARSAL TARGET is still caller-supplied, because attention still has no publisher
% in konnectome; that is B6 item 5, and it is queued rather than guessed at here.

% =============================================================================
% THE ACTIVATION GRAIN - DECISION-8
% =============================================================================
%
% The corpus states activations as DECIMALS - a slot is admitted at 1, leaks 0.05 a step, and
% collapses below 0.2 - and a machine must hold those somehow. Binary floating point is a
% representation choice like any other, and it is a choice with a consequence nobody would have
% chosen: subtracting 0.05 from 1.0 sixteen times in IEEE doubles gives 0.19999999999999968 rather
% than 0.2, so a slot standing EXACTLY on the threshold is judged to have fallen below it, and
% collapses one step early. The corpus's own printed Python does exactly that. The chapter's ENGLISH
% READABLE CODE says "If an item's activation falls below 0.2", and at exactly two tenths an
% activation has not fallen below anything. THE ONE-STEP DIFFERENCE IS DECIDED BY BIT-LEVEL DRIFT
% RATHER THAN BY ANYTHING ANYBODY CHOSE, which is the failure shape this repository keeps finding:
% the ones that look like success.
%
% WHAT IS DECLARED: ONE HUNDRED PARTS TO THE UNIT ACTIVATION, so the corpus's 1 is a hundred parts,
% its 0.05 is five parts, and its 0.2 is twenty parts, and every activation this pack holds is a whole
% number of parts. THIS IS KONNECTOME'S OWN DECISION AND MUST NEVER BE PRESENTED AS THE CORPUS'S.
%
% THE THREE REASONS ARE DECISION-2'S THREE REASONS, AND DELIBERATELY SO, because this is the same
% question one grain down. FIRST, IT MAKES EVERY CORPUS CONSTANT A WHOLE NUMBER OF PARTS: one is a
% hundred, five hundredths is five, two tenths is twenty. SECOND, IT IS THE COARSEST GRAIN THAT
% ACHIEVES THE FIRST, and coarsest is the honest choice rather than the convenient one: the corpus
% states these quantities to a hundredth, so a finer grain would claim a precision the source does not
% have. THIRD, IT COSTS NOTHING AND IS THEREFORE REVERSIBLE: every decimal this pack ever reads passes
% through the ONE conversion below, so a session that must restate the grain has exactly one predicate
% to change.
%
% THE REFUSAL IS THE LOAD-BEARING HALF, as it was for DECISION-2. A DECIMAL THAT IS NOT A WHOLE NUMBER
% OF PARTS IS REFUSED ALOUD: domain_error(whole_part_activation, Decimal), never rounded. Rounding is
% how invented numbers enter a careful build - a caller offers three thousandths, is handed nothing
% without being told, and a number that was the corpus's has quietly become konnectome's.

% working_memory_blackboard_parts_per_unit(-Parts): THE GRAIN, stated once and read everywhere.
working_memory_blackboard_parts_per_unit(100).

% working_memory_blackboard_parts_from_decimal(+Decimal, -Parts): convert a corpus decimal to parts.
working_memory_blackboard_parts_from_decimal(Decimal, Parts) :-
    % Refuse an unbound decimal aloud; a hole here would invent both a decimal and a part count for it.
    (   var(Decimal)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % Refuse anything that is not a number aloud rather than letting arithmetic decide what it meant.
    (   number(Decimal)
    ->  true
    ;   throw(error(type_error(number, Decimal), _))
    ),
    % An activation lies between empty and full, so a decimal outside that range is refused by name.
    (   Decimal >= 0, Decimal =< 1
    ->  true
    ;   throw(error(domain_error(working_memory_blackboard_activation_decimal, Decimal), _))
    ),
    % Read the grain from its one home rather than restating the number here.
    working_memory_blackboard_parts_per_unit(PartsPerUnit),
    % Scale the decimal into parts, and round only to shake off the float's own dust before judging it.
    Scaled is Decimal * PartsPerUnit,
    % The nearest whole part is the candidate answer, and the next line decides whether it is the answer.
    Candidate is round(Scaled),
    % A decimal lands on a part exactly when the scaled value and the nearest whole part agree to a millionth.
    Difference is abs(Scaled - Candidate),
    % A decimal that does not land on a part is refused aloud rather than rounded into one.
    (   Difference < 0.000001
    ->  Parts = Candidate
    ;   throw(error(domain_error(whole_part_activation, Decimal), _))
    ).

% working_memory_blackboard_decimal_from_parts(+Parts, -Decimal): read a part count back as a decimal.
working_memory_blackboard_decimal_from_parts(Parts, Decimal) :-
    % Refuse an unbound part count aloud, for the same reason the forward direction does.
    (   var(Parts)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % Refuse a part count that is not a whole number of parts, since parts are the pack's whole unit.
    (   integer(Parts)
    ->  true
    ;   throw(error(type_error(integer, Parts), _))
    ),
    % Read the grain from its one home.
    working_memory_blackboard_parts_per_unit(PartsPerUnit),
    % Every part count is expressible as a decimal, so this direction never refuses.
    Decimal is Parts / PartsPerUnit.

% =============================================================================
% THE CORPUS'S CONSTANTS, WRITTEN AS THE CORPUS WRITES THEM
% =============================================================================

% working_memory_blackboard_capacity(-Items): the surface holds four items (Chapter 16, CAPACITY AND LIMITS).
working_memory_blackboard_capacity(4).

% working_memory_blackboard_decay_decimal(-Decimal): a slot leaks five hundredths a step (Chapter 16's code).
working_memory_blackboard_decay_decimal(0.05).

% working_memory_blackboard_collapse_decimal(-Decimal): below two tenths the attractor collapses (Chapter 16's code).
working_memory_blackboard_collapse_decimal(0.2).

% working_memory_blackboard_full_decimal(-Decimal): admission and rehearsal set a slot to one (Chapter 16's code).
working_memory_blackboard_full_decimal(1.0).

% working_memory_blackboard_decay_parts(-Parts): the leakage in the grain the board actually holds.
working_memory_blackboard_decay_parts(Parts) :-
    % Read the corpus's decimal from its one home rather than writing five here.
    working_memory_blackboard_decay_decimal(Decimal),
    % Convert it through the one conversion, so the corpus's number stays the corpus's.
    working_memory_blackboard_parts_from_decimal(Decimal, Parts).

% working_memory_blackboard_collapse_parts(-Parts): the collapse threshold in the board's own grain.
working_memory_blackboard_collapse_parts(Parts) :-
    % Read the corpus's decimal from its one home.
    working_memory_blackboard_collapse_decimal(Decimal),
    % Convert it through the one conversion.
    working_memory_blackboard_parts_from_decimal(Decimal, Parts).

% working_memory_blackboard_full_parts(-Parts): full activation in the board's own grain.
working_memory_blackboard_full_parts(Parts) :-
    % Read the corpus's decimal from its one home.
    working_memory_blackboard_full_decimal(Decimal),
    % Convert it through the one conversion.
    working_memory_blackboard_parts_from_decimal(Decimal, Parts).

% =============================================================================
% THE CORPUS'S TIME CONSTANTS, RESTATED IN TICKS - AND THE MAINTENANCE PERIOD
% =============================================================================
%
% Chapter 16's TIME CONSTANTS field gives item admission at 100 to 300 milliseconds, unrehearsed decay
% at 2 to 20 seconds, and a wipe on task switch under 1 second. Under DECISION-2 every one of those is
% a whole number of ticks, and each is computed here through the scheduler's one conversion rather
% than written down as a tick literal, so a session that restates the rate restates these with it.
%
% THE RATE REFUSAL THAT STOOD HERE FROM SLICE 49 TO SLICE 74, KEPT BECAUSE A SETTLED QUESTION SHOULD
% STILL SHOW WHAT IT WAS. There was deliberately no predicate in this pack binding a maintenance step
% to a tick. The obvious wiring - one step per tick - is wrong against the chapter's own numbers and
% would be wrong SILENTLY. A full slot leaking five parts a step survives seventeen steps before it
% falls below twenty parts; at one step per tick that is one hundred and seventy nominal milliseconds,
% while the same chapter's TIME CONSTANTS field says unrehearsed content fades in two to twenty
% SECONDS. That is a factor of between twelve and one hundred and eighteen, and it is a disagreement
% INSIDE ONE CHAPTER rather than between the corpus and konnectome: the CODE SAMPLE is an illustration
% whose step is unitless, and the TIME CONSTANTS field is a measurement in seconds, and the chapter
% never claims the two describe the same rate. konnectome REPORTED THAT UPWARD as OBSERVATION-13
% rather than absorbing it, and named the closer: the slice that wires this board into the tick must
% decide the step rate in the open, as a decision of konnectome's own.
%
% =============================================================================
% DECISION-23 - THE MAINTENANCE PERIOD IS ONE STEP PER NOMINAL SECOND
% =============================================================================
%
% SLICE 74 IS THAT SLICE, AND THIS IS THAT DECISION. ONE MAINTENANCE STEP EVERY ONE NOMINAL SECOND -
% one hundred ticks under DECISION-2, read through the scheduler's one conversion below and never
% written here as a tick literal. THIS IS KONNECTOME'S OWN CHOICE AND MUST NEVER BE PRESENTED AS THE
% CORPUS'S. The corpus states a LIFETIME and never a step rate; the rate below is what konnectome
% chose in order to honour that lifetime, and the paragraphs that follow are the whole of its warrant.
%
% THE ORDER OF RESORT WAS FOLLOWED AND IS RECORDED, per the Twenty-First Commandment. FIRST, THE
% CORPUS WAS READ BENEATH THE FINDING rather than around it: Chapter 16 states the unrehearsed
% lifetime THREE times, not twice as OBSERVATION-13 recorded - "unrehearsed decay 2 to 20 seconds" in
% TIME CONSTANTS, seventeen unitless steps implied by the CODE SAMPLE's constants, and "holding about
% four things for about TEN SECONDS" in WHAT MAKES IT UNMISTAKABLE. The third statement was found by
% this slice and is new to the record. Nowhere does the chapter state a maintenance step rate, and
% probes of Layers 9 and 11 for an update or refresh rate returned nothing when slice 62 ran them.
% SECOND, DERIVATION WAS TRIED BEFORE ANY VALUE WAS CHOSEN, which is the Second Protocol and is the
% step this decision would have preferred to stop at. A period follows from a lifetime by division:
% the corpus's own lifetime, divided by the seventeen steps this pack already DERIVES, is the period.
% IT DOES NOT LAND. Two seconds over seventeen steps is 11.76 ticks, twenty seconds is 117.6, and the
% chapter's own "about ten seconds" is 58.8 - not one of the three is a whole number of ticks, and
% this pack refuses a rounded quantity by name everywhere else, so it will not accept one here.
% DERIVATION THEREFORE NARROWS THE ANSWER WITHOUT SETTLING IT, and what it narrows to is stated as a
% range rather than hidden: any whole period from 12 to 117 ticks lands the derived lifetime inside
% the chapter's own measured window. THIRD, REFUSAL WAS RECONSIDERED AND DECLINED, because it had
% already been taken once and the build cannot honour a lifetime it will not time. A board maintained
% at no rate is a board not in the loop, which is the state slice 49 left and the state this slice
% exists to leave behind.
%
% SO A VALUE IS CHOSEN, AND HERE IS WHY THIS ONE. ONE STEP PER NOMINAL SECOND IS THE ONLY DECADE OF
% KONNECTOME'S OWN TICK THAT LANDS INSIDE THE CORPUS'S MEASURED WINDOW. At one tick per step the
% lifetime is 0.17 seconds and the window's floor is missed by a factor of twelve; at ten ticks it is
% 1.7 seconds and the floor is still missed, by eighteen hundredths; at one hundred ticks it is
% SEVENTEEN SECONDS and lands; at a thousand ticks it is 170 seconds and the ceiling is missed by a
% factor of eight and a half. Exactly one decade qualifies. That is a uniqueness argument over a scale
% konnectome already owns rather than a preference among equals, and it is the reason this number and
% not one of the hundred and five other whole periods that also land.
%
% AND IT INTRODUCES NO NEW CONSTANT ANYWHERE. One hundred ticks to the nominal second is DECISION-2,
% declared twenty-five slices before this question was asked, and it is read below through the same
% single conversion that already restates this chapter's four wall-clock constants. A session that
% ever restates the tick restates this period with it, automatically, because nothing here is written
% down twice.
%
% WHAT THIS DECISION KNOWINGLY DOES NOT MATCH, SAID ALOUD RATHER THAN LEFT FOR A READER TO COMPUTE.
% Seventeen seconds is not "about ten seconds"; it is one and seven tenths of it. konnectome takes the
% chapter's RANGE over the chapter's GLOSS, and the reason is OBSERVATION-13'S OWN TRANSFERABLE RULE
% APPLIED TO OBSERVATION-13'S OWN SUBJECT: a chapter's fields are different kinds of claim, and the
% range sits in TIME CONSTANTS, which is the chapter's measurement field, while the gloss sits in WHAT
% MAKES IT UNMISTAKABLE, which is its prose summary. A period fitted to the gloss instead would be
% fifty-nine ticks, whose entire warrant is that it makes an arithmetic come out - a number with no
% home in any convention, chosen to hit a summary, which is the exact shape of an invented value that
% has learned to cite.
%
% WHAT IT DOES NOT DECIDE, so that a later session inherits no more than was chosen. It does not
% decide that the CODE SAMPLE's seventeen steps are right; they remain the illustration's, DERIVED
% here and not declared, and a chapter that restated its constants would move this lifetime with them.
% It does not decide a rate for anything else in konnectome - the traces, the averages, the bus and
% the body all still move once per tick and none of them was touched. It does not decide who
% REHEARSES: the target is still the caller's, because attention still has no publisher. And it does
% not close OBSERVATION-13's finding ABOUT THE CORPUS, which stands unchanged and is now three
% statements rather than two: what closes is konnectome's side of it.

% working_memory_blackboard_step_ticks(-Ticks): THE MAINTENANCE PERIOD, one nominal second (DECISION-23).
working_memory_blackboard_step_ticks(Ticks) :-
    % One nominal second is a thousand milliseconds, converted through the scheduler's one conversion.
    tick_engine_ticks_from_milliseconds(1000, Ticks).

% working_memory_blackboard_unrehearsed_life_ticks(-Ticks): the lifetime the period and the constants imply.
working_memory_blackboard_unrehearsed_life_ticks(Ticks) :-
    % Read how many unrehearsed steps a full slot survives, DERIVED from the corpus's own constants.
    working_memory_blackboard_steps_to_collapse(Steps),
    % Read the period one of those steps takes, which is konnectome's own choice above.
    working_memory_blackboard_step_ticks(Period),
    % The lifetime is simply the survived steps at that period, computed rather than written down.
    Ticks is Steps * Period.

% working_memory_blackboard_admission_ticks(-Low, -High): the admission window, 100 to 300 milliseconds.
working_memory_blackboard_admission_ticks(Low, High) :-
    % Convert the corpus's lower bound through the scheduler's one conversion.
    tick_engine_ticks_from_milliseconds(100, Low),
    % Convert the corpus's upper bound the same way.
    tick_engine_ticks_from_milliseconds(300, High).

% working_memory_blackboard_unrehearsed_decay_ticks(-Low, -High): unrehearsed fade, 2 to 20 seconds.
working_memory_blackboard_unrehearsed_decay_ticks(Low, High) :-
    % Two seconds is two thousand milliseconds, converted rather than written as a tick count.
    tick_engine_ticks_from_milliseconds(2000, Low),
    % Twenty seconds is twenty thousand milliseconds, converted the same way.
    tick_engine_ticks_from_milliseconds(20000, High).

% working_memory_blackboard_wipe_ticks(-Ticks): the task-switch wipe bound, under one second.
working_memory_blackboard_wipe_ticks(Ticks) :-
    % One second is a thousand milliseconds, converted through the scheduler's one conversion.
    tick_engine_ticks_from_milliseconds(1000, Ticks).

% working_memory_blackboard_steps_to_collapse(-Steps): how many unrehearsed steps a full slot survives.
working_memory_blackboard_steps_to_collapse(Steps) :-
    % Read full activation in parts from its one home.
    working_memory_blackboard_full_parts(Full),
    % Read the leakage per step in parts from its one home.
    working_memory_blackboard_decay_parts(Decay),
    % Read the collapse threshold in parts from its one home.
    working_memory_blackboard_collapse_parts(Collapse),
    % A slot survives while it stands at or above the threshold, so count the steps that take it below.
    Steps is (Full - Collapse) // Decay + 1.

% =============================================================================
% THE REFUSAL PERIMETER
% =============================================================================
%
% In the house voice of slice 27, every wrong is refused aloud through one shared perimeter, and the
% unbound-wrong-judgement lens pays for a SEVENTEENTH SLICE RUNNING: an unbound board, item, gate
% verdict or rehearsal target would each have been bound to whatever the first clause listed, and a
% board is exactly the shape - a keyed list of plain facts - that binds a hole to its first row.

% working_memory_blackboard_check_item(+Item): refuse anything that cannot be a slot's name, by name.
working_memory_blackboard_check_item(Item) :-
    % An unbound item cannot be judged, and must never be silently bound to whatever the board lists first.
    (   var(Item)
    ->  throw(error(instantiation_error, _))
    % A partially bound item would key a slot on a hole, so only a ground term may name one.
    ;   \+ ground(Item)
    ->  throw(error(instantiation_error, _))
    % The atom none is this pack's word for NO REHEARSAL, so it may not also be the name of a slot.
    ;   Item == none
    ->  throw(error(domain_error(working_memory_blackboard_item, none), _))
    % Anything else that is ground names a slot; the board holds contents in their native codes.
    ;   true
    ).

% working_memory_blackboard_check_gate(+Gate): refuse a gate verdict the striatum never gives, by name.
working_memory_blackboard_check_gate(Gate) :-
    % An unbound verdict cannot be judged, and a hole here would open the gate by accident.
    (   var(Gate)
    ->  throw(error(instantiation_error, _))
    % The basal-ganglia gate is the explicit admission control and it has exactly two verdicts.
    ;   memberchk(Gate, [open, closed])
    ->  true
    % Anything else is refused aloud rather than read as one verdict or the other.
    ;   throw(error(domain_error(working_memory_blackboard_gate, Gate), _))
    ).

% working_memory_blackboard_check_slot(+Slot): refuse anything that is not a well-formed slot, by name.
working_memory_blackboard_check_slot(Slot) :-
    % An unbound slot cannot be judged, so it is refused as uninstantiated rather than silently bound.
    (   var(Slot)
    ->  throw(error(instantiation_error, _))
    % A term that is not an item-and-activation pair is refused by name, never silently skipped.
    ;   Slot \= _-_
    ->  throw(error(domain_error(working_memory_blackboard_slot, Slot), _))
    % A well-shaped slot still needs its item and its activation judged.
    ;   Slot = Item-Parts,
        % The item must be a ground name that is not this pack's word for no rehearsal.
        working_memory_blackboard_check_item(Item),
        % The activation must be a whole number of parts inside the grain's own range.
        working_memory_blackboard_check_parts(Parts)
    ).

% working_memory_blackboard_check_parts(+Parts): refuse an activation outside the grain's range, by name.
working_memory_blackboard_check_parts(Parts) :-
    % An unbound activation cannot be judged, and a hole here would be bound by the first comparison.
    (   var(Parts)
    ->  throw(error(instantiation_error, _))
    % Activations are held as whole parts, so a decimal on a board has skipped the one conversion.
    ;   \+ integer(Parts)
    ->  throw(error(type_error(integer, Parts), _))
    % A slot stands somewhere between empty and full, and nowhere else.
    ;   working_memory_blackboard_full_parts(Full),
        Parts >= 0,
        Parts =< Full
    ->  true
    % Anything else is refused aloud rather than carried as an activation nothing could reach.
    ;   throw(error(domain_error(working_memory_blackboard_activation_parts, Parts), _))
    ).

% working_memory_blackboard_check_board(+Board): the shared perimeter every board-taking predicate crosses.
working_memory_blackboard_check_board(Board) :-
    % An unbound board cannot be judged, and would otherwise be bound to the empty board by unification.
    (   var(Board)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % A board that is not a proper list is refused aloud rather than walked until it runs out.
    (   is_list(Board)
    ->  true
    ;   throw(error(type_error(list, Board), _))
    ),
    % Every element must be a well-formed slot naming a ground item at a whole activation.
    maplist(working_memory_blackboard_check_slot, Board),
    % Two slots for one item would let one thought be held twice and evicted once, so they are refused.
    working_memory_blackboard_check_no_duplicate(Board),
    % A board holding more than the capacity has been built by something other than this pack's admission.
    working_memory_blackboard_check_capacity(Board).

% working_memory_blackboard_check_no_duplicate(+Board): refuse a repeated item on one board, by name.
working_memory_blackboard_check_no_duplicate(Board) :-
    % Collect the item name of every slot, in the board's own order.
    findall(Item, member(Item-_, Board), Items),
    % Sorting without removing duplicates puts any repeated item beside its twin.
    msort(Items, Sorted),
    % A repeated item is refused aloud, never answered by a first-one-wins shrug.
    (   append(_, [Item, Item | _], Sorted)
    ->  throw(error(domain_error(working_memory_blackboard_duplicate_item, Item), _))
    ;   true
    ).

% working_memory_blackboard_check_capacity(+Board): refuse a board wider than the shared surface, by name.
working_memory_blackboard_check_capacity(Board) :-
    % Count the slots the board is carrying.
    length(Board, Held),
    % Read the corpus's capacity from its one home.
    working_memory_blackboard_capacity(Capacity),
    % A board wider than the surface is refused aloud rather than quietly trimmed to fit.
    (   Held =< Capacity
    ->  true
    ;   throw(error(domain_error(working_memory_blackboard_capacity, Held), _))
    ).

% =============================================================================
% THE BOARD
% =============================================================================
%
% A board is a list of Item-Parts pairs held in ADMISSION ORDER, oldest first. The order is part of
% the value and not an accident of how it was built, because eviction takes the WEAKEST slot and two
% slots can be equally weak - and the declaration-order lens, which has now paid at clause selection
% twice, says that a keyed read over a list of plain facts is exactly the shape that answers a tie
% with whichever row happens to be first. THIS PACK DECIDES THE TIE IN THE OPEN: among equally weak
% slots the EARLIEST-ADMITTED is evicted, which is what the corpus's own code does, since Python's
% minimum over a dictionary returns the first key in insertion order. A test asserts the tie-break
% rather than merely asserting that some slot was evicted.

% working_memory_blackboard_new(-Board): a fresh empty board, the surface before anything is written.
working_memory_blackboard_new([]).

% working_memory_blackboard_slots(+Board, -Items): the items currently held, in admission order.
working_memory_blackboard_slots(Board, Items) :-
    % Judge the board before reading it, so a malformed board is refused rather than half-read.
    working_memory_blackboard_check_board(Board),
    % Take the item name of each slot, keeping the board's admission order.
    findall(Item, member(Item-_, Board), Items).

% working_memory_blackboard_occupancy(+Board, -Count): how many of the capacity's slots are in use.
working_memory_blackboard_occupancy(Board, Count) :-
    % Judge the board before counting it.
    working_memory_blackboard_check_board(Board),
    % The occupancy is simply the number of slots the board carries.
    length(Board, Count).

% working_memory_blackboard_activation(+Board, +Item, -Parts): the activation of one held item.
%
% AN ITEM THE BOARD DOES NOT HOLD IS REFUSED ALOUD RATHER THAN READ AS ZERO, and this is a deliberate
% divergence from the neuromodulator bus's own kindness one slice earlier. The bus answers an unheard
% channel with zero, and slice 48 found that a caller reading a channel by the wrong name is told in
% perfect silence that the level is baseline. Here the same shape would be worse: an absent slot and a
% collapsed slot are DIFFERENT FACTS - the first means the thought was never admitted, the second
% means it was and has faded - and a zero would make them one answer. So the board says so instead.
working_memory_blackboard_activation(Board, Item, Parts) :-
    % Judge the board before reading it.
    working_memory_blackboard_check_board(Board),
    % Judge the item, so an unbound item is refused rather than bound to whatever slot is listed first.
    working_memory_blackboard_check_item(Item),
    % Read the slot if the board holds it, and refuse aloud if it does not.
    (   memberchk(Item-Held, Board)
    ->  Parts = Held
    ;   throw(error(existence_error(working_memory_blackboard_slot, Item), _))
    ).

% working_memory_blackboard_wipe(+Board0, -Board): erase the whole surface, as the next task does.
working_memory_blackboard_wipe(Board0, Board) :-
    % Judge the incoming board, so a wipe cannot be used to launder a malformed one into a clean one.
    working_memory_blackboard_check_board(Board0),
    % The blackboard is "wiped by the next task", and a wiped surface is the empty board.
    working_memory_blackboard_new(Board).

% =============================================================================
% THE MAINTENANCE STEP
% =============================================================================
%
% The chapter states the step twice and the two statements DISAGREE ABOUT ORDER, so konnectome must
% choose and say which. Its ENGLISH READABLE CODE reduces each activation, then removes what has
% fallen below the threshold, then restores a rehearsed item; its CODE SAMPLE reduces, then restores a
% rehearsed item, THEN removes what has fallen below. The difference is visible in exactly one case: a
% slot that this step's leakage would carry below the threshold, and that this step also rehearses.
%
% THIS PACK TAKES THE CODE SAMPLE'S ORDER - REHEARSAL BEFORE COLLAPSE - FOR TWO STATED REASONS. First,
% the chapter calls rehearsal the "attentional refresh" and the whole point of a refresh is to keep
% content alive; an order in which rehearsal can never rescue a nearly-collapsed slot makes rehearsal
% useless in precisely the case it exists for. Second, under the other order a rehearsal target could
% be removed halfway through the step, so a caller naming a slot that was demonstrably present would
% be answered with a refusal it could not have avoided.

% working_memory_blackboard_step(+Board0, +RehearsalTarget, -Board): one maintenance step.
%
% THE REHEARSAL TARGET IS CALLER-SUPPLIED, per B5.9: the chapter's prose says the blackboard is
% "written by attention" while its code takes the target as an argument from outside, and attention has
% no publisher in konnectome yet, so this slice keeps the caller's argument and does not invent one.
% The atom none is the explicit no-rehearsal target - an ABSENCE THAT MUST BE STATED rather than an
% unbound argument that would be bound by the first slot on the board.
working_memory_blackboard_step(Board0, RehearsalTarget, Board) :-
    % Judge the incoming board before advancing it.
    working_memory_blackboard_check_board(Board0),
    % Judge the rehearsal target, which is either the explicit absence or a ground item name.
    working_memory_blackboard_check_rehearsal_target(Board0, RehearsalTarget),
    % Read the leakage, in parts, from its one home.
    working_memory_blackboard_decay_parts(Decay),
    % Read full activation, in parts, from its one home.
    working_memory_blackboard_full_parts(Full),
    % Read the collapse threshold, in parts, from its one home.
    working_memory_blackboard_collapse_parts(Collapse),
    % Leak every slot by the decay amount, then refresh the rehearsed one to full.
    maplist(working_memory_blackboard_leak_slot(Decay, Full, RehearsalTarget), Board0, Leaked),
    % Drop every slot that has fallen below the threshold, because the attractor has collapsed.
    working_memory_blackboard_drop_collapsed(Leaked, Collapse, Board).

% working_memory_blackboard_check_rehearsal_target(+Board, +Target): judge the caller's rehearsal target.
working_memory_blackboard_check_rehearsal_target(_Board, Target) :-
    % An unbound target is refused aloud, never bound to whichever slot the board happens to list first.
    var(Target),
    !,
    % Name the wrong rather than answering with a rehearsal the caller did not ask for.
    throw(error(instantiation_error, _)).
working_memory_blackboard_check_rehearsal_target(_Board, none) :-
    % The explicit absence is a legitimate target and means this step rehearses nothing.
    !.
working_memory_blackboard_check_rehearsal_target(Board, Target) :-
    % Any other target must be a ground item name before the board is searched for it.
    working_memory_blackboard_check_item(Target),
    % A rehearsal aimed at a slot the board does not hold is refused aloud rather than doing nothing.
    (   memberchk(Target-_, Board)
    ->  true
    ;   throw(error(existence_error(working_memory_blackboard_slot, Target), _))
    ).

% working_memory_blackboard_leak_slot(+Decay, +Full, +Target, +Slot0, -Slot): leak one slot, then refresh it.
working_memory_blackboard_leak_slot(Decay, Full, Target, Item-Parts0, Item-Parts) :-
    % Reduce the activation by the decay amount, and never below an empty slot.
    Leaked is max(0, Parts0 - Decay),
    % A rehearsed slot is restored to full, which is the attentional refresh the chapter names.
    (   Item == Target
    ->  Parts = Full
    ;   Parts = Leaked
    ).

% working_memory_blackboard_drop_collapsed(+Slots, +Collapse, -Kept): remove every collapsed slot.
working_memory_blackboard_drop_collapsed([], _Collapse, []).
working_memory_blackboard_drop_collapsed([Item-Parts | Rest0], Collapse, Kept) :-
    % Advance the rest of the board first, so the surviving order is the admission order.
    working_memory_blackboard_drop_collapsed(Rest0, Collapse, Rest),
    % A slot standing at or above the threshold has not fallen below it, and survives the step.
    (   Parts >= Collapse
    ->  Kept = [Item-Parts | Rest]
    ;   Kept = Rest
    ).

% =============================================================================
% THE GATE, THE ADMISSION, AND THE EVICTION
% =============================================================================

% working_memory_blackboard_admit(+Board0, +Item, +Gate, -Board): offer one item to the striatal gate.
%
% FOUR OUTCOMES, AND THE THIRD IS THE ONE THE CODE SAMPLE GETS WRONG. A closed gate DISCARDS the item,
% which is how a distractor is refused. An open gate onto a board that already holds the item UPDATES
% it to full and evicts nothing - the chapter's own chain-of-stations sentence names the gate as
% "deciding, under dopamine, which items are admitted OR UPDATED", while its Python would evict a
% rival to make room for an item already present. An open gate onto a board with a free slot ADMITS at
% full activation. An open gate onto a full board EVICTS THE WEAKEST and admits.
working_memory_blackboard_admit(Board0, Item, Gate, Board) :-
    % Judge the incoming board before changing it.
    working_memory_blackboard_check_board(Board0),
    % Judge the item, so an unbound item is refused rather than admitted as a hole.
    working_memory_blackboard_check_item(Item),
    % Judge the gate verdict, so an unbound verdict cannot open the gate by accident.
    working_memory_blackboard_check_gate(Gate),
    % Read full activation, in parts, from its one home.
    working_memory_blackboard_full_parts(Full),
    % Read the capacity from its one home.
    working_memory_blackboard_capacity(Capacity),
    % Count what the surface is already carrying.
    length(Board0, Held),
    % Decide the outcome among the four the chapter describes.
    (   Gate == closed
    ->  % The gate is shut, so the distractor is discarded and the board is unchanged.
        Board = Board0
    ;   memberchk(Item-_, Board0)
    ->  % The item is already held, so this is an update to full rather than a new admission.
        working_memory_blackboard_refresh(Board0, Item, Full, Board)
    ;   Held < Capacity
    ->  % There is room on the shared surface, so the item is admitted at full activation.
        append(Board0, [Item-Full], Board)
    ;   % The surface is full, so the weakest slot leaves and the new item takes its place.
        working_memory_blackboard_evict_weakest(Board0, Board1),
        append(Board1, [Item-Full], Board)
    ).

% working_memory_blackboard_refresh(+Board0, +Item, +Full, -Board): set one held item back to full.
working_memory_blackboard_refresh([], _Item, _Full, []).
working_memory_blackboard_refresh([Held-Parts0 | Rest0], Item, Full, [Held-Parts | Rest]) :-
    % The named item is restored to full, and its position in the admission order is kept.
    (   Held == Item
    ->  Parts = Full
    ;   Parts = Parts0
    ),
    % Carry the rest of the board through unchanged.
    working_memory_blackboard_refresh(Rest0, Item, Full, Rest).

% working_memory_blackboard_evict_weakest(+Board0, -Board): remove the weakest slot, earliest first on a tie.
working_memory_blackboard_evict_weakest(Board0, Board) :-
    % Find the lowest activation any slot on the board is standing at.
    findall(Parts, member(_-Parts, Board0), Activations),
    % The minimum of that list is the weakest activation, and possibly several slots share it.
    min_list(Activations, Weakest),
    % Take the FIRST slot standing at that activation, which is the earliest-admitted of the tied ones.
    nth0(Index, Board0, _-Weakest),
    % Commit to that first answer, so a tie is broken deterministically rather than on backtracking.
    !,
    % Rebuild the board without the evicted slot, leaving every other slot in its admission order.
    working_memory_blackboard_delete_at(Board0, Index, Board).

% working_memory_blackboard_delete_at(+List, +Index, -Rest): the list without the element at one position.
working_memory_blackboard_delete_at(List, Index, Rest) :-
    % Split the list at the index, so the head is everything before the evicted slot.
    length(Before, Index),
    % The tail begins with the evicted slot itself, which is dropped from the rebuilt board.
    append(Before, [_ | After], List),
    % The board is what came before the evicted slot followed by what came after it.
    append(Before, After, Rest).
