% Load the offline_consolidation module under test from the library path.
:- use_module(library(offline_consolidation)).
% Load the renewal loop, so the durable marks the night maintains can be built and read here.
:- use_module(library(renewal_loop)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% A small fixed cortex: one old learnable edge, one new learnable edge, and one computational edge.
offline_consolidation_test_interfaces([interface(a, b, 1.0, 1, transmissive),
                                       interface(c, d, 0.1, 1, transmissive),
                                       interface(b, d, 0.3, 1, computational)]).

% The day's averages for the cortex above: both receiving ends ran loud, above the diffuse target.
offline_consolidation_test_averages([a-0, b-1, c-0, d-1]).

% Open the test block for the offline_consolidation pack.
:- begin_tests(offline_consolidation).

% A fresh memory store starts the day with nothing remembered.
test(fresh_memory_store_is_empty) :-
    % Make a fresh memory store.
    offline_consolidation_memory_new(Memories),
    % Confirm it holds no snapshots.
    assertion(Memories == []).

% Remembering appends the newest snapshot at the end, so the store reads oldest first.
test(remember_appends_newest_last) :-
    % Start from a fresh store.
    offline_consolidation_memory_new(Memories0),
    % Remember an older pattern.
    offline_consolidation_remember(Memories0, [a-1, b-1], Memories1),
    % Remember a newer pattern.
    offline_consolidation_remember(Memories1, [c-1, d-1], Memories2),
    % Confirm the store reads oldest first, newest last.
    assertion(Memories2 == [[a-1, b-1], [c-1, d-1]]).

% An unbound memory store cannot be judged, and is refused as uninstantiated.
test(remember_refuses_unbound_store, [throws(error(instantiation_error, _))]) :-
    % Try to remember into a hole.
    offline_consolidation_remember(_Unbound, [a-1], _Memories).

% A snapshot that is not a well-formed activation store is refused by name.
test(remember_refuses_malformed_snapshot, [throws(error(domain_error(offline_consolidation_snapshot_pair, broken), _))]) :-
    % Try to remember a snapshot whose entry is not a Name-Activity pair.
    offline_consolidation_remember([], [broken], _Memories).

% A snapshot naming one construct twice would replay an ambiguous pattern, and is refused by name.
test(remember_refuses_duplicate_snapshot_key, [throws(error(domain_error(offline_consolidation_duplicate_snapshot_key, a), _))]) :-
    % Try to remember a snapshot carrying the construct a twice.
    offline_consolidation_remember([], [a-1, a-0], _Memories).

% An unbound snapshot cannot be judged, and is refused as uninstantiated (the standing house lens).
test(remember_refuses_unbound_snapshot, [throws(error(instantiation_error, _))]) :-
    % Try to remember a hole as a snapshot.
    offline_consolidation_remember([], _Unbound, _Memories).

% Interleaving an even store alternates the newer half against the older half, newest work first.
test(interleave_alternates_new_against_old) :-
    % Interleave a store of two old and two new snapshots.
    offline_consolidation_interleave([[a-1], [b-1], [c-1], [d-1]], Batch),
    % Confirm the batch alternates new, old, new, old.
    assertion(Batch == [[c-1], [a-1], [d-1], [b-1]]).

% An odd store gives the extra snapshot to the OLD half, as the cortex outweighs the day's hippocampus.
test(interleave_gives_odd_extra_to_the_old_half) :-
    % Interleave a store of three old and two new snapshots.
    offline_consolidation_interleave([[a-1], [b-1], [c-1], [d-1], [e-1]], Batch),
    % Confirm the trailing extra old snapshot closes the batch.
    assertion(Batch == [[d-1], [a-1], [e-1], [b-1], [c-1]]).

% An empty store interleaves to an empty batch: a night with nothing to consolidate is quiet, not wrong.
test(interleave_of_empty_store_is_empty) :-
    % Interleave the empty store.
    offline_consolidation_interleave([], Batch),
    % Confirm the batch is empty.
    assertion(Batch == []).

% An unbound store cannot be interleaved, and is refused as uninstantiated.
test(interleave_refuses_unbound_store, [throws(error(instantiation_error, _))]) :-
    % Try to interleave a hole.
    offline_consolidation_interleave(_Unbound, _Batch).

% A replay round over an empty store leaves every weight bit-identical.
test(replay_round_on_empty_store_changes_nothing) :-
    % Take the fixed cortex.
    offline_consolidation_test_interfaces(Interfaces0),
    % Replay a night with nothing remembered.
    offline_consolidation_replay_round(Interfaces0, [], 0.1, Interfaces),
    % Confirm the cortex stands bit-identical.
    assertion(Interfaces == Interfaces0).

% Replaying one snapshot strengthens a learnable edge by sending times receiving times the replay rate.
test(replay_strengthens_by_the_hebbian_product) :-
    % Take the fixed cortex.
    offline_consolidation_test_interfaces(Interfaces0),
    % Replay one round of a single remembered pattern lighting the old edge's two ends.
    offline_consolidation_replay_round(Interfaces0, [[a-1, b-1]], 0.1, Interfaces),
    % Read the old edge's weight after the replay.
    Interfaces = [interface(a, b, Weight, 1, transmissive) | _],
    % Confirm one replay added exactly one times one times the replay rate.
    assertion(abs(Weight - 1.1) < 1.0e-9).

% A computational interface is untouched by replay, exactly as it is untouched by waking learning.
test(replay_leaves_computational_interfaces_untouched) :-
    % Take the fixed cortex.
    offline_consolidation_test_interfaces(Interfaces0),
    % Replay a pattern lighting the computational edge's two ends.
    offline_consolidation_replay_round(Interfaces0, [[b-1, d-1]], 0.5, Interfaces),
    % Read the computational edge's weight after the replay.
    Interfaces = [_, _, interface(b, d, Weight, 1, computational)],
    % Confirm the weight stands.
    assertion(Weight =:= 0.3).

% A construct absent from a snapshot replays as silent, exactly as the waking engine reads absence.
test(replay_treats_an_absent_construct_as_silent) :-
    % Take the fixed cortex.
    offline_consolidation_test_interfaces(Interfaces0),
    % Replay a pattern that names only one end of the old edge.
    offline_consolidation_replay_round(Interfaces0, [[a-1]], 0.1, Interfaces),
    % Read the old edge's weight after the replay.
    Interfaces = [interface(a, b, Weight, 1, transmissive) | _],
    % Confirm a silent receiving end shipped no strengthening.
    assertion(Weight =:= 1.0).

% An unbound replay rate cannot be judged, and is refused as uninstantiated (the standing house lens).
test(replay_refuses_unbound_rate, [throws(error(instantiation_error, _))]) :-
    % Take the fixed cortex.
    offline_consolidation_test_interfaces(Interfaces0),
    % Try to replay under a hole of a rate.
    offline_consolidation_replay_round(Interfaces0, [[a-1, b-1]], _Rate, _Interfaces).

% A negative replay rate would let the night unlearn the day, and is refused by name.
test(replay_refuses_negative_rate, [throws(error(domain_error(offline_consolidation_replay_rate, -0.1), _))]) :-
    % Take the fixed cortex.
    offline_consolidation_test_interfaces(Interfaces0),
    % Try to replay under a negative rate.
    offline_consolidation_replay_round(Interfaces0, [[a-1, b-1]], -0.1, _Interfaces).

% The night step runs the replay FIRST and the raised bound SECOND: the refreshed weight is what renormalises.
test(night_step_replays_first_then_renormalises) :-
    % Take the fixed cortex and the day's loud averages.
    offline_consolidation_test_interfaces(Interfaces0),
    offline_consolidation_test_averages(Averages),
    % One night tick: replay one old pattern, then the bound at a raised rate of 0.2 against a target of 0.5.
    offline_consolidation_night_step(Interfaces0, [[a-1, b-1]], 0.1, Averages, [], 0.5, 0.2, Interfaces),
    % Read the old edge's weight after the night tick.
    Interfaces = [interface(a, b, Weight, 1, transmissive) | _],
    % A one-pattern batch pays the whole dose to that pattern, so the replayed weight is 1.1, and the
    % bound then scales it by 1 + 0.2 * (0.5 - 1) = 0.9, landing on 0.99. The REVERSE order would
    % give 0.9 replayed to 1.0 - so this single value pins that replay runs FIRST and the bound second.
    assertion(abs(Weight - 0.99) < 1.0e-9).

% A night with nothing remembered still renormalises: the bound is the night's second job, not a rider.
test(night_step_on_empty_store_still_applies_the_bound) :-
    % Take the fixed cortex and the day's loud averages.
    offline_consolidation_test_interfaces(Interfaces0),
    offline_consolidation_test_averages(Averages),
    % One night tick over an empty store.
    offline_consolidation_night_step(Interfaces0, [], 0.1, Averages, [], 0.5, 0.2, Interfaces),
    % Read the old edge's weight after the night tick.
    Interfaces = [interface(a, b, Weight, 1, transmissive) | _],
    % The unreplayed weight of 1.0 is scaled by 0.9.
    assertion(abs(Weight - 0.9) < 1.0e-9).

% THE CATASTROPHIC-FORGETTING REST-TWIN TELLING (the corpus's flagship law, Chapter 7): a night that
% replays the NEW memories alone lets the raised bound wash the old edge away, and its interleaved
% twin - same cortex, same nights, same bound - keeps the old edge while the new one grows.
test(interleaved_replay_defeats_catastrophic_forgetting) :-
    % Take the fixed cortex and the day's loud averages.
    offline_consolidation_test_interfaces(Interfaces0),
    offline_consolidation_test_averages(Averages),
    % The whole store: two old patterns that taught the old edge, two new patterns from today.
    OldMemories = [[a-1, b-1], [a-1, b-1]],
    NewMemories = [[c-1, d-1], [c-1, d-1]],
    append(OldMemories, NewMemories, Memories),
    % THE FORGETFUL TWIN replays the new memories alone for ten nights.
    offline_consolidation_test_nights(10, Interfaces0, NewMemories, Averages, ForgetfulInterfaces),
    % THE INTERLEAVED TWIN replays the whole interleaved store for the same ten nights.
    offline_consolidation_test_nights(10, Interfaces0, Memories, Averages, InterleavedInterfaces),
    % Read the old edge under each twin.
    ForgetfulInterfaces = [interface(a, b, ForgottenOld, 1, transmissive), interface(c, d, ForgetfulNew, 1, transmissive) | _],
    InterleavedInterfaces = [interface(a, b, KeptOld, 1, transmissive), interface(c, d, GrownNew, 1, transmissive) | _],
    % The raised bound renormalises EVERY edge each night, so both twins' old edge falls from its
    % starting one - the night's second job is real, and this telling is about what replay DEFENDS.
    % The forgetful twin, refreshing only today's edge, lets the old one wash away: it keeps barely a
    % third of what it knew. That is catastrophic forgetting, exhibited.
    assertion(ForgottenOld < 0.4),
    % The interleaved twin, refreshing old against new, DEFENDS the old edge against the same bound
    % under the same nights: it keeps nearly two thirds, and well over half again what its twin kept.
    assertion(KeptOld > 0.6),
    assertion(KeptOld > ForgottenOld * 1.5),
    % And BOTH twins installed the new edge well above its starting tenth: the old is defended by
    % sharing the night's dose with it, not by refusing to learn - the corpus's own trade-off.
    assertion(ForgetfulNew > 0.1),
    % The interleaved night installed the new without erasing the old - the law the corpus names.
    assertion(GrownNew > 0.1).

% REVIEW PIN (the slice's deepest finding). The night's replay DOSE is what one night tick delivers,
% and it must not grow with how much the mind remembers - otherwise a long day's store out-doses the
% raised bound and the night that Chapter 7 calls renormalisation becomes net potentiation. The same
% pattern remembered four times over must move the weight exactly as remembering it once does.
test(the_replay_dose_does_not_grow_with_the_memory_store) :-
    % Take the fixed cortex.
    offline_consolidation_test_interfaces(Interfaces0),
    % Replay a store holding one copy of a pattern.
    offline_consolidation_replay_round(Interfaces0, [[a-1, b-1]], 0.1, OnceInterfaces),
    % Replay a store holding four copies of the very same pattern.
    offline_consolidation_replay_round(Interfaces0, [[a-1, b-1], [a-1, b-1], [a-1, b-1], [a-1, b-1]], 0.1, FourfoldInterfaces),
    % Read both weights.
    OnceInterfaces = [interface(a, b, OnceWeight, 1, transmissive) | _],
    FourfoldInterfaces = [interface(a, b, FourfoldWeight, 1, transmissive) | _],
    % The dose is the night's, not the store's: remembering the same day four times over changes nothing.
    assertion(abs(OnceWeight - FourfoldWeight) < 1.0e-9),
    % And the dose is the rate itself: one times one times a tenth, added once.
    assertion(abs(OnceWeight - 1.1) < 1.0e-9).

% REVIEW PIN. The night's second job is real: with nothing replayed to defend it, every learnable
% weight is washed DOWN toward the target - the renormalisation the raised bound exists to deliver.
test(an_unreplayed_edge_is_renormalised_downward) :-
    % Take the fixed cortex and the day's loud averages.
    offline_consolidation_test_interfaces(Interfaces0),
    offline_consolidation_test_averages(Averages),
    % Run a night that replays a pattern touching only the NEW edge, leaving the old one undefended.
    offline_consolidation_night_step(Interfaces0, [[c-1, d-1]], 0.1, Averages, [], 0.5, 0.2, Interfaces),
    % Read the undefended old edge.
    Interfaces = [interface(a, b, Weight, 1, transmissive) | _],
    % Unrefreshed, it was scaled down from its starting one - the bound bounds.
    assertion(Weight < 1.0).

% REVIEW PIN (unbound-wrong-judgement lens, the sixth slice running). A hole at an edge's end used
% to be BOUND by the replay's own lookup to the remembered snapshot's first construct, so the night
% invented a connection that no caller declared and strengthened it. It is refused as uninstantiated.
test(an_unbound_interface_end_is_refused_as_uninstantiated, [throws(error(instantiation_error, _))]) :-
    % Replay a remembered pattern across a cortex whose edge has a hole where its sending end belongs.
    offline_consolidation_replay_round([interface(_From, b, 0.5, 1, transmissive)], [[a-1, b-1]], 0.1, _Interfaces).

% REVIEW PIN. An entirely unbound cortex used to be silently bound to the EMPTY cortex, so the night
% reported consolidating nothing at all and mutated the caller's variable to agree.
test(an_unbound_cortex_is_refused_as_uninstantiated, [throws(error(instantiation_error, _))]) :-
    % Replay across a hole where the cortex belongs.
    offline_consolidation_replay_round(_Interfaces0, [[a-1, b-1]], 0.1, _Interfaces).

% REVIEW PIN. A PARTIAL cortex used to be silently truncated to its known prefix, the unknown
% remainder declared to be nothing and the caller's tail variable bound to say so.
test(a_partial_cortex_is_refused_as_uninstantiated, [throws(error(instantiation_error, _))]) :-
    % Replay across a cortex whose tail is still a hole.
    offline_consolidation_replay_round([interface(a, b, 0.5, 1, transmissive) | _Tail], [[a-1, b-1]], 0.1, _Interfaces).

% REVIEW PIN. A cortex that is not a list at all used to FAIL SILENTLY rather than refuse by name.
test(a_non_list_cortex_is_refused_by_name,
     [throws(error(domain_error(offline_consolidation_interface, not_a_cortex), _))]) :-
    % Replay across something that is not a cortex.
    offline_consolidation_replay_round(not_a_cortex, [[a-1, b-1]], 0.1, _Interfaces).

% REVIEW PIN. An unbound interface KIND used to fall silently to the untouched branch, so the night
% reported an edge consolidated that was never replayed - the silent wrong answer the lens hunts.
test(an_unbound_interface_kind_is_refused_as_uninstantiated, [throws(error(instantiation_error, _))]) :-
    % Replay across a cortex whose edge has a hole where its kind belongs.
    offline_consolidation_replay_round([interface(a, b, 0.5, 1, _Kind)], [[a-1, b-1]], 0.1, _Interfaces).

% REVIEW PIN. An interface kind no slice has defined is refused aloud by name, never silently skipped.
test(an_unknown_interface_kind_is_refused_by_name,
     [throws(error(domain_error(offline_consolidation_interface_kind, chemical), _))]) :-
    % Replay across a cortex carrying an edge of an invented kind.
    offline_consolidation_replay_round([interface(a, b, 0.5, 1, chemical)], [[a-1, b-1]], 0.1, _Interfaces).

% Close the test block for the offline_consolidation pack.

% ---------------------------------------------------------------------------
% THE NIGHT'S THIRD JOB - MAINTAINING THE DURABLE MARKS (slice 55)
% ---------------------------------------------------------------------------

% A helper: run a whole night of N ticks over a store of durable marks, maintaining them.
offline_consolidation_test_nights(0, Loops, Loops) :- !.
offline_consolidation_test_nights(Count, Loops0, Loops) :-
    offline_consolidation_maintain_durable(Loops0, Loops1),
    Next is Count - 1,
    offline_consolidation_test_nights(Next, Loops1, Loops).

% A helper: the same night WITHOUT maintenance - the mark simply decays untouched, which is what a
% night that does not know about durable marks does to them.
offline_consolidation_test_unmaintained(0, Loops, Loops) :- !.
offline_consolidation_test_unmaintained(Count, [Loop0], Loops) :-
    % An unmaintained mark is a loop that is not run: its synthesis is blocked for the night.
    renewal_loop_step(Loop0, inhibited, Loop1),
    Next is Count - 1,
    offline_consolidation_test_unmaintained(Next, [Loop1], Loops).

% A NIGHT THAT MAINTAINS ITS DURABLE MARKS PRESERVES THEM. This is the capability, and it is the
% cheaper half of the pair below.
test(a_maintained_mark_survives_the_night) :-
    renewal_loop_established(Loop0),
    assertion(renewal_loop_maintained(Loop0)),
    % Twenty night ticks, each one maintaining the mark.
    offline_consolidation_test_nights(20, [Loop0], [Loop]),
    % The memory is still held in the morning.
    assertion(renewal_loop_maintained(Loop)).

% AND THE TEST THAT IS THE WHOLE POINT: A NIGHT THAT DOES NOT MAINTAIN THEM DESTROYS THEM, AND
% PERMANENTLY. Without this test the trap would be a paragraph in a comment; with it, a reader meets
% it as something that passes. This is slice 51's lesson applied before the mistake rather than after:
% a capability nobody calls is indistinguishable from one that was never built, so the ABSENCE is
% made visible here rather than trusted to be noticed later.
test(an_unmaintained_mark_is_destroyed_by_the_night_and_never_returns) :-
    renewal_loop_established(Loop0),
    assertion(renewal_loop_maintained(Loop0)),
    % The same twenty ticks, with the loop not run.
    offline_consolidation_test_unmaintained(20, [Loop0], [Loop]),
    % The memory is gone by morning.
    assertion(\+ renewal_loop_maintained(Loop)),
    % And a full day of maintenance afterwards cannot bring it back: the loss is permanent, which is
    % what makes the omission a trap rather than a dip.
    offline_consolidation_test_nights(500, [Loop], [Recovered]),
    assertion(\+ renewal_loop_maintained(Recovered)).

% MANY MARKS ARE MAINTAINED TOGETHER, in order, and the store keeps its shape.
test(every_mark_in_the_store_is_maintained) :-
    renewal_loop_established(Established),
    renewal_loop_new(Fresh),
    offline_consolidation_maintain_durable([Established, Fresh], Loops),
    Loops = [MaintainedEstablished, MaintainedFresh],
    % The established mark is still a memory.
    assertion(renewal_loop_maintained(MaintainedEstablished)),
    % The fresh one is not, and maintaining it does not make it one - a night does not invent memories.
    assertion(\+ renewal_loop_maintained(MaintainedFresh)).

% A MIND WITH NO DURABLE MARKS HAS NOTHING TO MAINTAIN, and that is not an error.
test(an_empty_durable_store_maintains_to_nothing) :-
    offline_consolidation_maintain_durable([], Loops),
    assertion(Loops == []).

% A MALFORMED STORE IS REFUSED BY THE RENEWAL LOOP RATHER THAN HALF-MAINTAINED HERE, so there is one
% judgement of what a durable mark is and this pack does not grow a second copy of it.
test(a_malformed_durable_store_is_refused,
     throws(error(domain_error(renewal_loop, not_a_loop), _))) :-
    offline_consolidation_maintain_durable([not_a_loop], _Loops).

% ---------------------------------------------------------------------------
% FACULTY 13, LEARNING ITSELF - THE SCORED ACCEPTANCE TESTS (slice 57)
% ---------------------------------------------------------------------------
%
% LAYER_12_FACULTY_SPECIFICATION.txt, Faculty 13: "retention of old competence as new competence is
% added; measurable consolidation benefit from the offline phase; graceful lifetime accumulation."
% The first two are scored here against their own ablations, so NO PASSING THRESHOLD IS INVENTED.

% THE FIRST CRITERION, SCORED. The mind learns a new competence. The old one is retained BETTER when
% the night interleaves it than when the night replays only the new - which is catastrophic
% forgetting measured rather than demonstrated.
test(faculty_thirteen_old_competence_is_retained_better_when_the_night_interleaves_it) :-
    % The cortex before either night: an established old competence and a fresh new one.
    offline_consolidation_test_interfaces(Before),
    offline_consolidation_test_averages(Averages),
    % THE SERVED RUN: the night remembers the old day and the new day, and interleaves them.
    offline_consolidation_night_step(Before, [[a-1, b-1], [c-1, d-1]], 0.1, Averages, [], 0.5, 0.2,
                                     Interleaved),
    % THE ABLATED RUN: the identical night, remembering only the new day.
    offline_consolidation_night_step(Before, [[c-1, d-1]], 0.1, Averages, [], 0.5, 0.2, NewOnly),
    % Score how much of the OLD competence each night left standing.
    offline_consolidation_retention(Before, Interleaved, [a-b], InterleavedRetention),
    offline_consolidation_retention(Before, NewOnly, [a-b], AblatedRetention),
    % THE CRITERION, AND IT NEEDS NO THRESHOLD: interleaving retains strictly more of the old.
    assertion(InterleavedRetention > AblatedRetention),
    % The exact figures, so the test is glass-box rather than merely comparative. A two-pattern batch
    % pays half the dose to each, so the old edge is replayed from 1.0 to 1.05 and the bound scales
    % it by 0.9 to 0.945. Unreplayed, it is only scaled: 0.9.
    assertion(abs(InterleavedRetention - 0.945) < 1.0e-9),
    assertion(abs(AblatedRetention - 0.9) < 1.0e-9),
    % AND THE NEW COMPETENCE IS REALLY INSTALLED IN BOTH, so the retention above is not bought by
    % failing to learn the new thing at all - which is the way this test would otherwise pass wrongly.
    offline_consolidation_competence_score(Before, [c-d], NewBefore),
    offline_consolidation_competence_score(Interleaved, [c-d], NewAfter),
    assertion(NewAfter > NewBefore).

% THE SECOND CRITERION, SCORED. The offline phase's benefit to a competence is measured against the
% same night with that competence absent from the store - the ablation the criterion's own wording
% asks for, since "benefit FROM the offline phase" is a comparison and not a level.
test(faculty_thirteen_the_offline_phase_delivers_a_measurable_benefit) :-
    % The cortex before either night.
    offline_consolidation_test_interfaces(Before),
    offline_consolidation_test_averages(Averages),
    % THE SERVED RUN: the night remembers the new competence's day among the others.
    offline_consolidation_night_step(Before, [[a-1, b-1], [c-1, d-1]], 0.1, Averages, [], 0.5, 0.2,
                                     Served),
    % THE ABLATED RUN: the identical night, which never replays the new competence.
    offline_consolidation_night_step(Before, [[a-1, b-1]], 0.1, Averages, [], 0.5, 0.2, Unserved),
    % Score what the offline phase added to the new competence.
    offline_consolidation_benefit(Unserved, Served, [c-d], Benefit),
    % THE CRITERION: the benefit is positive, and it is measurable rather than asserted.
    assertion(Benefit > 0),
    % The exact figure: replayed from 0.1 to 0.15 and bounded to 0.135, against 0.1 bounded to 0.09.
    assertion(abs(Benefit - 0.045) < 1.0e-9).

% AND THE HONEST HALF OF THE SECOND CRITERION, PINNED SO NOBODY QUOTES THE BENEFIT WITHOUT IT. The
% night's benefit is RELATIVE and not absolute: measured against no night at all, the old competence's
% score FALLS, because renormalisation is the night's other job. Chapter 7 says exactly this - the
% night's net effect is renormalisation WITH targeted strengthening of the replayed traces, not
% blanket growth - so a benefit reported as an absolute gain would be reporting a machine konnectome
% does not have.
test(faculty_thirteen_the_nights_benefit_is_relative_and_never_absolute) :-
    offline_consolidation_test_interfaces(Before),
    offline_consolidation_test_averages(Averages),
    % A night that serves the old competence as well as it can be served.
    offline_consolidation_night_step(Before, [[a-1, b-1]], 0.1, Averages, [], 0.5, 0.2, After),
    % Against no night at all, the old competence still ends the night lower than it began.
    offline_consolidation_retention(Before, After, [a-b], Retention),
    assertion(Retention < 1.0),
    % Replayed at the full dose to 1.1 and bounded by 0.9, which is 0.99.
    assertion(abs(Retention - 0.99) < 1.0e-9).

% ---------------------------------------------------------------------------
% THE MEASUREMENT'S OWN REFUSALS (slice 57)
% ---------------------------------------------------------------------------

% A competence naming an edge the cortex does not carry is refused rather than scored as zero, which
% is the guard that keeps a typing slip from reporting perfect catastrophic forgetting.
test(a_competence_naming_an_absent_edge_is_refused,
     throws(error(offline_consolidation_no_such_edge(x-y), _))) :-
    offline_consolidation_test_interfaces(Interfaces),
    offline_consolidation_competence_score(Interfaces, [x-y], _Score).

% A competence that scored nothing has no retention to measure, and the division is refused rather
% than dressed up as a total loss.
test(a_competence_with_no_score_has_no_retention,
     throws(error(offline_consolidation_no_competence_to_retain(_Competence), _))) :-
    Empty = [interface(a, b, 0, 1, transmissive)],
    offline_consolidation_retention(Empty, Empty, [a-b], _Retention).

% An unbound competence is a hole, and a hole scored as zero would report a total loss.
test(an_unbound_competence_is_refused,
     throws(error(instantiation_error, _))) :-
    offline_consolidation_test_interfaces(Interfaces),
    offline_consolidation_competence_score(Interfaces, _Hole, _Score).

% A competence that is not a list of edge names is refused by name rather than scored as empty.
test(a_malformed_competence_is_refused,
     throws(error(offline_consolidation_malformed_competence(_What), _))) :-
    offline_consolidation_test_interfaces(Interfaces),
    offline_consolidation_competence_score(Interfaces, [not_an_edge_name], _Score).

:- end_tests(offline_consolidation).

% offline_consolidation_test_nights(+Count, +Interfaces0, +Memories, +Averages, -Interfaces): run Count night ticks.
offline_consolidation_test_nights(0, Interfaces, _Memories, _Averages, Interfaces) :-
    % No nights remain, so the cortex stands as it is.
    !.
offline_consolidation_test_nights(Count, Interfaces0, Memories, Averages, Interfaces) :-
    % One whole night tick: interleaved replay at a tenth, then the raised bound of 0.2 toward the diffuse half.
    offline_consolidation_night_step(Interfaces0, Memories, 0.1, Averages, [], 0.5, 0.2, Interfaces1),
    % Count this night down.
    NextCount is Count - 1,
    % Continue through the remaining nights.
    offline_consolidation_test_nights(NextCount, Interfaces1, Memories, Averages, Interfaces).
