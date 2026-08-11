% Declare this file as the 'offline_consolidation' module and list the predicates it exports.
:- module(offline_consolidation, [
    % offline_consolidation_memory_new/1: a fresh empty memory store, nothing yet remembered.
    offline_consolidation_memory_new/1,
    % offline_consolidation_remember/3: append the day's newest activation snapshot to the store.
    offline_consolidation_remember/3,
    % offline_consolidation_interleave/2: the night's batch, the newer half alternated against the older.
    offline_consolidation_interleave/2,
    % offline_consolidation_replay_round/4: one replay pass over the interleaved store.
    offline_consolidation_replay_round/4,
    % offline_consolidation_night_step/8: one whole night tick - the replay, then the raised bound.
    offline_consolidation_night_step/8,
    % offline_consolidation_check_replay_rate/1: refuse a rate the night cannot learn at, by name.
    % (Exported in slice 38's review so the live tick can judge the night's rate on EVERY tick, waking
    % or sleeping, against this one root - rather than letting a rotten rate ride a whole day unseen.)
    offline_consolidation_check_replay_rate/1,
    % offline_consolidation_maintain_durable/2: refresh the durable marks the night is given (slice 55).
    % THE NIGHT'S THIRD JOB, and the bill DECISION-11 deliberately left unpaid. See the block below.
    offline_consolidation_maintain_durable/2,
    % offline_consolidation_competence_score/3: the measured strength of one named competence (slice 57).
    offline_consolidation_competence_score/3,
    % offline_consolidation_retention/4: how much of a competence a night left standing (slice 57).
    offline_consolidation_retention/4,
    % offline_consolidation_benefit/4: what the offline phase added to a competence (slice 57).
    offline_consolidation_benefit/4
]).

% Reuse the renewal loop: the durable tier is a MAINTAINED PROCESS (DECISION-11), so the night that
% does not run it does not preserve it - it erases it.
:- use_module(library(renewal_loop), [renewal_loop_step/3]).

% Import length and append for splitting the store into its older and newer halves.
:- use_module(library(lists), [append/3, memberchk/2]).
% Import foldl for folding one replay round over the interleaved batch.
:- use_module(library(apply), [foldl/4, maplist/3]).
% Reuse the plasticity engine: the replay strengthens through the SAME three-factor product the day
% uses, and the raised bound is the day's own slow scaling law run at the night's steeper rate.
:- use_module(library(plasticity_engine), [plasticity_engine_weight_change/5,
                                           plasticity_engine_scaling_step_territory/6]).

% The offline consolidation engine is the Layer 11 sleep-state machinery's night crew (Chapters 6
% and 7): the deep works' flagship computation, systems consolidation by INTERLEAVED REPLAY - the
% transfer of remembered patterns into the slow cortical store in a way that installs the new
% without overwriting the old - beside the night's second job, synaptic renormalisation, the slow
% homeostatic bound run at a RAISED rate while the sensory gate is closed. The problem the
% interleaving solves is catastrophic forgetting: replayed alone, the day's new patterns would keep
% only their own edges refreshed while the raised bound washed every unrefreshed old edge away;
% replayed interleaved - old against new, alternating - every edge worth keeping is refreshed
% between washes, so the night keeps what the mind learned before while installing what it learned
% today. The memory store is the hippocampal day: an oldest-first list of activation snapshots,
% each remembered by a waking tick (the spindled encoding queue of Chapter 6 in its simplest
% honest form). THE REPLAY RATE IS A DOSE PER NIGHT TICK, NOT PER MEMORY: the round shares it
% across the interleaved batch, so what the night delivers does not grow with how much the mind
% remembers. That is not a detail - it is what lets the raised bound actually BOUND, and Chapter 7
% is explicit that the night's net effect is renormalisation with targeted strengthening of the
% replayed traces, not blanket growth. Interleaving still decides WHICH edges the dose defends.
% DECLARED SIMPLIFICATIONS, per the corpus: the replay order is a deterministic
% alternation, not a shuffled sample; one replay round runs per offline tick, not per spindle; and
% replay strengthens by the day's own Hebbian product with the third factor held at one, because
% the night's low-aminergic climate is permissive rather than dopamine-driven. The engine is pure:
% it never touches the bus or the world, and the tick that owns them does the calling.

% offline_consolidation_check_snapshot(+Snapshot): refuse a snapshot no night could replay, by name.
offline_consolidation_check_snapshot(Snapshot) :-
    % Walk the snapshot, refusing an unbound tail and every malformed pair, collecting the keys in order.
    offline_consolidation_check_snapshot_pairs(Snapshot, Keys),
    % Sorting without removing duplicates puts any repeated key beside its twin.
    msort(Keys, Sorted),
    % A construct named twice would replay an ambiguous pattern, and is refused aloud by name.
    (  append(_, [Key, Key | _], Sorted)
    -> throw(error(domain_error(offline_consolidation_duplicate_snapshot_key, Key), _))
    % A snapshot naming each construct once is the pattern the night can replay.
    ;  true
    ).

% offline_consolidation_check_snapshot_pairs(+Snapshot, -Keys): walk a snapshot, refusing every wrong aloud.
offline_consolidation_check_snapshot_pairs(Snapshot, Keys) :-
    % An unbound store or tail cannot be judged and must never be walked off a cliff.
    (  var(Snapshot)
    -> throw(error(instantiation_error, _))
    % The empty snapshot carries no keys.
    ;  Snapshot == []
    -> Keys = []
    % A well-formed head is a bound Name-Activity pair whose activity is a bound number.
    ;  Snapshot = [Pair | Rest]
    -> (  nonvar(Pair), Pair = Key-Activity, nonvar(Key), number(Activity)
       % The head's key joins the collected keys.
       -> Keys = [Key | RestKeys],
          % The walk continues down the rest of the snapshot.
          offline_consolidation_check_snapshot_pairs(Rest, RestKeys)
       % A malformed pair is refused by name, never silently skipped.
       ;  throw(error(domain_error(offline_consolidation_snapshot_pair, Pair), _))
       )
    % A snapshot that is not a list at all is refused as a malformed pair of itself.
    ;  throw(error(domain_error(offline_consolidation_snapshot_pair, Snapshot), _))
    ).

% offline_consolidation_check_memories(+Memories): refuse a memory store no night could read, by name.
offline_consolidation_check_memories(Memories) :-
    % An unbound store or tail cannot be judged and must never be walked off a cliff.
    (  var(Memories)
    -> throw(error(instantiation_error, _))
    % The empty store is a quiet night, not a wrong.
    ;  Memories == []
    -> true
    % Every remembered snapshot is judged whole before any night replays it.
    ;  Memories = [Snapshot | Rest]
    -> offline_consolidation_check_snapshot(Snapshot),
       offline_consolidation_check_memories(Rest)
    % A store that is not a list at all is refused as a malformed snapshot of itself.
    ;  throw(error(domain_error(offline_consolidation_snapshot_pair, Memories), _))
    ).

% offline_consolidation_check_interfaces(+Interfaces): refuse a cortex the night cannot replay, by name.
% REVIEW FIX (unbound-wrong-judgement lens, the SIXTH slice running): the engine judged its memory
% store and its rate but judged the CORTEX not at all, so maplist bound an unbound interface store
% to the empty cortex, silently truncated a partial one to its known prefix, failed silently on a
% non-list, and read an unbound Kind as computational - four wrong answers where the sibling store
% is refused aloud. The cortex is now judged in the memory store's own shape.
offline_consolidation_check_interfaces(Interfaces) :-
    % An unbound store or tail cannot be judged and must never be bound into an invented cortex.
    (  var(Interfaces)
    -> throw(error(instantiation_error, _))
    % The empty cortex is a cortex with nothing to replay, not a wrong.
    ;  Interfaces == []
    -> true
    % Every element is judged whole before any weight moves.
    ;  Interfaces = [Interface | Rest]
    -> offline_consolidation_check_interface(Interface),
       offline_consolidation_check_interfaces(Rest)
    % A store that is not a list at all is refused as a malformed interface of itself.
    ;  throw(error(domain_error(offline_consolidation_interface, Interfaces), _))
    ).

% offline_consolidation_check_interface(+Interface): refuse one malformed edge or unknown kind, by name.
offline_consolidation_check_interface(Interface) :-
    % An unbound edge cannot be judged, and must never be silently bound by the replay below.
    (  var(Interface)
    -> throw(error(instantiation_error, _))
    % A term that is not an interface at all is refused by name, never silently skipped.
    ;  Interface \= interface(_, _, _, _, _)
    -> throw(error(domain_error(offline_consolidation_interface, Interface), _))
    ;  true
    ),
    % Unpack the edge's two ends, its weight, and its kind.
    Interface = interface(From, To, Weight, _Delay, Kind),
    % A hole at either end would be BOUND by the replay's lookup and invent a connection.
    (  ( var(From) ; var(To) )
    -> throw(error(instantiation_error, _))
    ;  true
    ),
    % A weight that is not a number cannot be strengthened, and a hole must not be bound by arithmetic.
    (  var(Weight)
    -> throw(error(instantiation_error, _))
    ;  number(Weight)
    -> true
    ;  throw(error(domain_error(offline_consolidation_interface, Interface), _))
    ),
    % An unbound kind would fall silently to the untouched branch and report a replay that never ran.
    (  var(Kind)
    -> throw(error(instantiation_error, _))
    % The connectome knows exactly two interface kinds, the same two the waking engine knows.
    ;  memberchk(Kind, [transmissive, computational])
    -> true
    % An unknown kind is refused aloud, never silently carried or dropped.
    ;  throw(error(domain_error(offline_consolidation_interface_kind, Kind), _))
    ).

% offline_consolidation_check_replay_rate(+ReplayRate): refuse a rate the night cannot learn at, by name.
offline_consolidation_check_replay_rate(ReplayRate) :-
    % An unbound rate cannot be judged, and must never be silently bound by the arithmetic below.
    (  var(ReplayRate)
    -> throw(error(instantiation_error, _))
    % The night strengthens or leaves alone: the rate is a number at or above zero.
    ;  number(ReplayRate), ReplayRate >= 0
    -> true
    % A negative rate would let the night unlearn the day, and is refused aloud.
    ;  throw(error(domain_error(offline_consolidation_replay_rate, ReplayRate), _))
    ).

% offline_consolidation_memory_new(-Memories): a fresh empty memory store.
offline_consolidation_memory_new([]).

% offline_consolidation_remember(+Memories0, +Snapshot, -Memories): append the newest snapshot last.
offline_consolidation_remember(Memories0, Snapshot, Memories) :-
    % Refuse a store the night could not later read.
    offline_consolidation_check_memories(Memories0),
    % Refuse a snapshot the night could not later replay.
    offline_consolidation_check_snapshot(Snapshot),
    % The store reads oldest first, so the day's newest memory goes to the end.
    append(Memories0, [Snapshot], Memories).

% offline_consolidation_interleave(+Memories, -Batch): the newer half alternated against the older.
offline_consolidation_interleave(Memories, Batch) :-
    % Refuse a store the night cannot read.
    offline_consolidation_check_memories(Memories),
    % Count the remembered snapshots.
    length(Memories, Count),
    % The older half takes the odd extra, as the standing cortex outweighs one day's hippocampus.
    OldCount is (Count + 1) // 2,
    % Mark off that many places at the front of the store, which reads oldest first.
    length(OldHalf, OldCount),
    % Split the store into its older front half and its newer back half.
    append(OldHalf, NewHalf, Memories),
    % Alternate the halves, the newest work first: the night serves today's learning against the past.
    offline_consolidation_alternate(NewHalf, OldHalf, Batch).

% offline_consolidation_alternate(+FirstHalf, +SecondHalf, -Batch): alternate two lists, remainder last.
% When the first half is spent, the rest of the second half closes the batch.
offline_consolidation_alternate([], SecondHalf, SecondHalf).
% Otherwise take one from the first half and swap the roles.
offline_consolidation_alternate([Head | Rest], SecondHalf, [Head | Batch]) :-
    % Swap so the second half contributes next.
    offline_consolidation_alternate(SecondHalf, Rest, Batch).

% offline_consolidation_replay_activation(+Snapshot, +Name, -Value): a remembered activity, silent if absent.
offline_consolidation_replay_activation(Snapshot, Name, Value) :-
    % REVIEW FIX (unbound-wrong-judgement lens): memberchk with an unbound key BINDS that key to the
    % snapshot's first entry and reads a remembered activity that belongs to another construct, so a
    % hole at an edge's end used to invent a connection and strengthen it. The name is judged first.
    (  var(Name)
    -> throw(error(instantiation_error, _))
    ;  true
    ),
    % Use the remembered activity if present, otherwise the construct replays as silent.
    ( memberchk(Name-Found, Snapshot) -> Value = Found ; Value = 0 ).

% offline_consolidation_replay_interface(+Snapshot, +ReplayRate, +Interface0, -Interface): replay one edge.
offline_consolidation_replay_interface(Snapshot, ReplayRate,
                                       interface(From, To, Weight0, Delay, Kind),
                                       interface(From, To, Weight, Delay, Kind)) :-
    % Only a transmissive interface learns from replay; a computational one keeps its weight.
    (  Kind == transmissive
    -> % Read the remembered pattern at the edge's two ends.
       offline_consolidation_replay_activation(Snapshot, From, Sending),
       offline_consolidation_replay_activation(Snapshot, To, Receiving),
       % The night's strengthening is the day's own three-factor product with the third factor held
       % at one: the low-aminergic climate is permissive, not dopamine-driven (Chapter 7).
       plasticity_engine_weight_change(Sending, Receiving, 1, ReplayRate, WeightChange),
       Weight is Weight0 + WeightChange
    ;  % A computational interface is untouched by replay.
       Weight = Weight0
    ).

% offline_consolidation_replay_snapshot(+ReplayRate, +Snapshot, +Interfaces0, -Interfaces): replay one pattern.
offline_consolidation_replay_snapshot(ReplayRate, Snapshot, Interfaces0, Interfaces) :-
    % Replay the remembered pattern across every edge of the cortex.
    maplist(offline_consolidation_replay_interface(Snapshot, ReplayRate), Interfaces0, Interfaces).

% offline_consolidation_replay_round(+Interfaces0, +Memories, +ReplayRate, -Interfaces): one replay pass.
offline_consolidation_replay_round(Interfaces0, Memories, ReplayRate, Interfaces) :-
    % Refuse a cortex the night cannot replay before any weight moves (the review's root fix).
    offline_consolidation_check_interfaces(Interfaces0),
    % Refuse a rate the night cannot learn at before any weight moves.
    offline_consolidation_check_replay_rate(ReplayRate),
    % Build the interleaved batch, the store judged whole on the way.
    offline_consolidation_interleave(Memories, Batch),
    % Count the patterns the night will replay this round.
    length(Batch, BatchCount),
    % REVIEW FIX (a REAL finding, and the slice's deepest): the replay dose used to be paid ONCE PER
    % REMEMBERED PATTERN, so a night's total strengthening grew with the memory store while the bound
    % stayed one fixed step - and the night that Chapter 7 specifies as NET RENORMALISATION was
    % measured multiplying the fixture's weight by ten and a half against a target of one half. The
    % rate now means what its name says: the strengthening ONE NIGHT TICK delivers, shared across the
    % batch, so the dose is invariant to how much the mind remembers and the bound can actually bound.
    % Interleaving still decides WHICH edges are refreshed - the corpus's mechanism is untouched.
    (  BatchCount > 0
    -> PerPattern is ReplayRate / BatchCount
    % An empty night pays no dose at all, and the division is never reached.
    ;  PerPattern = ReplayRate
    ),
    % Fold one replay of every batched pattern over the cortex, in the interleaved order.
    foldl(offline_consolidation_replay_snapshot(PerPattern), Batch, Interfaces0, Interfaces).

% offline_consolidation_night_step(+Interfaces0, +Memories, +ReplayRate, +Averages, +ScalingTargets,
%                                  +GlobalTarget, +OfflineScalingRate, -Interfaces): one whole night tick.
offline_consolidation_night_step(Interfaces0, Memories, ReplayRate, Averages, ScalingTargets,
                                 GlobalTarget, OfflineScalingRate, Interfaces) :-
    % FIRST the replay: the interleaved patterns refresh every edge worth keeping.
    offline_consolidation_replay_round(Interfaces0, Memories, ReplayRate, Replayed),
    % THEN the raised bound: the day's own slow scaling law at the night's steeper rate, so the
    % refreshed weights are what renormalises - the order is the mechanism, and it is pinned.
    plasticity_engine_scaling_step_territory(Replayed, Averages, ScalingTargets, GlobalTarget,
                                             OfflineScalingRate, Interfaces).

% ---------------------------------------------------------------------------
% THE NIGHT'S THIRD JOB - MAINTAINING THE DURABLE MARKS (slice 55)
% ---------------------------------------------------------------------------
%
% THIS PAYS THE BILL DECISION-11 DELIBERATELY LEFT UNPAID, AND THE BILL IS WORTH RESTATING BECAUSE IT
% IS THE SHARPEST CONSEQUENCE THIS BUILD HAS MET OF ONE OF ITS OWN DECISIONS.
%
% DECISION-11 made the durable weight tier a MAINTAINED PROCESS rather than a stored number, on the
% corpus's own insistence: renewal_loop "has no separately stored value to read: the value is the
% running process itself, so interrupting the refresh does not merely risk a bit, IT DESTROYS THE
% ONLY COPY."
%
% NOW READ THAT SENTENCE BESIDE WHAT THIS PACK DOES. The night replays and it renormalises. Those are
% its two jobs and it has had exactly two since slice 38. A DURABLE MARK PASSING THROUGH A NIGHT THAT
% DOES NOT REFRESH IT DECAYS FOR EVERY TICK OF THAT NIGHT, and if the night is long enough the mark
% falls under its threshold and, by the mechanism renewal_loop demonstrates, NEVER RETURNS.
%
% SO THE PHASE BUILT TO CONSOLIDATE MEMORY WOULD HAVE BEEN THE PHASE THAT ERASED IT - permanently,
% nightly, and silently, because nothing anywhere would have reported a loss. That is the fifth
% consecutive shape this build has found and it would have been the worst of them: not a wrong answer
% but a disappearing one, in the component whose entire purpose is to not lose things.
%
% THE FIX IS ONE PREDICATE AND IT IS DELIBERATELY NOT WIRED INTO night_step/8. Two reasons, both
% stated so the omission is a decision. FIRST, THE DURABLE TIER IS NOT WIRED TO A WEIGHT YET: there is
% no store of marks on the world for a night step to reach, so a night_step that took one would be
% taking an argument nobody can supply. SECOND, AND THE REASON THAT MATTERS: the wiring slice must
% decide what a night's maintenance costs and whether the night's raised bound and the mark's refresh
% interact, and folding it in here would settle those by default. THE CAPABILITY IS BUILT, PROVED, AND
% EXPORTED, AND THE TRAP IS NOW A TEST RATHER THAN A PARAGRAPH.
%
% SLICE 51 IS THE REASON THAT LAST SENTENCE IS PHRASED THAT WAY. Slice 51 found a watchman, a watchdog
% and the wiring between them all built, all tested, and never once called - and recorded that a
% capability nobody calls is indistinguishable from one that was never built. The guard against
% repeating that is not to wire this hastily; it is to make the ABSENCE visible. The suite therefore
% carries a test showing that a night WITHOUT maintenance destroys an established mark, beside the one
% showing that a night WITH it does not. A reader meets the trap as something that passes.

% offline_consolidation_maintain_durable(+Loops0, -Loops): refresh every durable mark by one step.
% An exhausted store leaves nothing to maintain, which is what a mind with no durable marks has.
offline_consolidation_maintain_durable([], []).
% Each mark is advanced by one uninhibited maintenance step: the night is not a block, it is a shift
% during which the loop must go on running. Passing 'running' here is the whole claim of this
% predicate - the alternative, passing 'inhibited', is precisely the erasure it exists to prevent.
offline_consolidation_maintain_durable([Loop0|Rest0], [Loop|Rest]) :-
    % Advance this mark. renewal_loop judges the loop and the verdict on the way in, so a malformed
    % store is refused there rather than being half-maintained here.
    renewal_loop_step(Loop0, running, Loop),
    % Maintain the remaining marks.
    offline_consolidation_maintain_durable(Rest0, Rest).

% ---------------------------------------------------------------------------
% THE FACULTY 13 MEASUREMENT (slice 57)
% ---------------------------------------------------------------------------
%
% LAYER_12_FACULTY_SPECIFICATION.txt, FACULTY 13, LEARNING ITSELF, states three acceptance criteria:
% "retention of old competence as new competence is added; measurable consolidation benefit from the
% offline phase; graceful lifetime accumulation."
%
% KONNECTOME HAD THE MECHANISM FOR ALL THREE AND SCORED NONE OF THEM. Interleaved replay against
% catastrophic forgetting has been in this pack since slice 38, and its tests demonstrate the effect
% qualitatively - one weight is lower than another, one edge falls under one. THAT IS A
% DEMONSTRATION AND NOT A MEASUREMENT, and the difference is the whole of why this faculty stood at
% PARTLY PASSES in the north-star gap analysis's fourteen-item audit. The three predicates below are
% the measurement, and they add NO MECHANISM WHATEVER: not one weight moves differently because they
% exist.

% ---------------------------------------------------------------------------
% DECISION-14 - A COMPETENCE IS A NAMED SET OF EDGES, AND ITS SCORE IS THEIR SUMMED WEIGHT
% ---------------------------------------------------------------------------
%
% NOTHING IN THE CORPUS SAYS WHAT A COMPETENCE IS IN KONNECTOME'S TERMS. Faculty 13 speaks of "old
% competence" and "new competence" as things a mind has and can lose, and Chapter 7's account of
% catastrophic forgetting speaks of edges being refreshed or washed away. The gap between those two
% vocabularies is real and nobody fills it, so this is a DECISION under the Sixteenth Commandment's
% repair-versus-decision line rather than a repair: no correct value is waiting to be put back.
%
% KONNECTOME CHOOSES: A COMPETENCE IS A CALLER-NAMED SET OF EDGES, AND ITS SCORE IS THE SUM OF THEIR
% WEIGHTS. Three reasons, stated so a later session can overturn them on argument rather than taste.
%
% FIRST, IT IS THE GRAIN THE MECHANISM ALREADY WORKS AT. Interleaved replay refreshes edges and the
% raised bound washes edges; a score at any other grain would be measuring something the night does
% not act on.
%
% SECOND, THE SET IS THE CALLER'S AND NOT THIS PACK'S. konnectome has no naming and addressing
% facility - OBSERVATION-11's expensive half - so nothing here can look up "the competence called
% arithmetic". Naming the edges is the caller's act, exactly as the inhibition verdict and the world
% event are elsewhere in this build. WHEN THE ADDRESSING FACILITY ARRIVES THIS SIGNATURE IS WHAT
% CHANGES, and it is written so that it can.
%
% THIRD, THE SUM AND NOT THE MEAN, because a competence that has LOST an edge should score lower and
% a mean would hide exactly that by dividing the loss away.
%
% WHAT DECISION-14 DOES NOT DECIDE.
%
% IT DOES NOT DECIDE A PASSING SCORE, AND DELIBERATELY SO - see the threshold-free rule below.
%
% IT DOES NOT DECIDE THE THIRD CRITERION. "Graceful lifetime accumulation" needs a lifetime, and
% konnectome's longest run is a capstone night. The criterion is named here as unmeasured rather than
% quietly folded into the other two.
%
% AND IT DOES NOT MAKE THE SCORE A CAPABILITY MEASURE. A summed weight is a proxy for competence, not
% competence itself; nothing here shows the mind can still DO the old thing, only that the edges it
% did it with are still standing. That is the honest limit of a measurement taken at this grain.

% ---------------------------------------------------------------------------
% AND THE RULE THAT KEEPS THE MEASUREMENT HONEST - NO THRESHOLD IS INVENTED
% ---------------------------------------------------------------------------
%
% THE OBVIOUS WAY TO MAKE A FACULTY PASS IS TO WRITE DOWN A NUMBER IT MUST BEAT, and that number
% would be konnectome's own invention wearing Layer 12's citation - which is precisely the failure
% the Sixteenth Commandment names, AN INVENTED VALUE THAT HAS LEARNED TO CITE. LAYER_12 STATES NO
% THRESHOLD FOR ANY OF ITS FOURTEEN FACULTIES.
%
% SO THE CRITERIA ARE READ AS COMPARATIVE, WHICH IS WHAT THEIR OWN WORDING SAYS. "Retention of old
% competence AS NEW COMPETENCE IS ADDED" compares a mind that added something against one that did
% not. "MEASURABLE consolidation BENEFIT FROM the offline phase" compares a competence the offline
% phase served against one it did not. EACH CRITERION SUPPLIES ITS OWN BASELINE, so the acceptance
% test is a comparison between two runs of the same machinery rather than a number anybody chose.
% Under the Twenty-First Commandment this is the SECOND PROTOCOL, DERIVATION, and it never reaches
% the fourth.
%
% THIS GENERALISES TO THE OTHER THIRTEEN FACULTIES and is the most transferable thing in this slice.
% A faculty suite that needs a threshold has usually not yet found its ablation.

% offline_consolidation_competence_score(+Interfaces, +Competence, -Score): the summed weight of a
% named set of edges - DECISION-14's measurement.
offline_consolidation_competence_score(Interfaces, Competence, Score) :-
    % Refuse a cortex the measurement cannot read, through the same root the night uses.
    offline_consolidation_check_interfaces(Interfaces),
    % An unbound competence is a hole, and a hole scored as zero would report a total loss.
    (   var(Competence)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % Sum the named edges' weights, refusing any edge the cortex does not carry.
    offline_consolidation_sum_competence(Competence, Interfaces, 0, Score).

% offline_consolidation_sum_competence(+Competence, +Interfaces, +Score0, -Score): sum the named edges.
% An exhausted competence contributes nothing further.
offline_consolidation_sum_competence([], _Interfaces, Score, Score) :-
    % Commit: an exhausted competence is never the malformed one the last clause refuses.
    !.
% Each named edge contributes its own weight, and an edge the cortex does not carry is refused.
offline_consolidation_sum_competence([From-To|Rest], Interfaces, Score0, Score) :-
    % Commit to the well-formed edge name before it is looked up, so a refusal below cannot be
    % reached by backtracking out of a genuine competence.
    !,
    % AN ABSENT EDGE IS REFUSED RATHER THAN SCORED AS ZERO, and this is the load-bearing guard of the
    % whole measurement. A competence whose edges have been deleted from the cortex is not a
    % competence that decayed to nothing - it is a caller naming something that is not there, and
    % reading the second as the first would report perfect catastrophic forgetting on a typing slip.
    (   memberchk(interface(From, To, Weight, _Delay, _Kind), Interfaces)
    ->  true
    ;   throw(error(offline_consolidation_no_such_edge(From-To),
                    context(offline_consolidation_competence_score/3,
                            "a competence names edges the cortex carries; an absent edge is a hole, not a zero")))
    ),
    % Add this edge's weight to the running score.
    Score1 is Score0 + Weight,
    % Score the remaining edges.
    offline_consolidation_sum_competence(Rest, Interfaces, Score1, Score).
% Anything that is not a list of edge names is refused by name rather than scored as empty.
offline_consolidation_sum_competence(Competence, _Interfaces, _Score0, _Score) :-
    % Refuse the malformed competence aloud.
    throw(error(offline_consolidation_malformed_competence(Competence),
                context(offline_consolidation_competence_score/3,
                        "a competence is a list of From-To edge names"))).

% offline_consolidation_retention(+Before, +After, +Competence, -Retention): FACULTY 13's first
% criterion - the fraction of a competence's score that a night left standing.
offline_consolidation_retention(Before, After, Competence, Retention) :-
    % Score the competence in the cortex as it stood before.
    offline_consolidation_competence_score(Before, Competence, ScoreBefore),
    % Score the same competence in the cortex the night handed back.
    offline_consolidation_competence_score(After, Competence, ScoreAfter),
    % A competence that scored nothing to begin with has no retention to measure, and a division by
    % zero dressed up as "nothing was retained" would be a fabricated result rather than a refusal.
    (   ScoreBefore =:= 0
    ->  throw(error(offline_consolidation_no_competence_to_retain(Competence),
                    context(offline_consolidation_retention/4,
                            "retention is measured against a competence that had a score")))
    ;   true
    ),
    % The retained fraction: what stands now over what stood before.
    Retention is ScoreAfter / ScoreBefore.

% offline_consolidation_benefit(+Without, +With, +Competence, -Benefit): FACULTY 13's second
% criterion - what the offline phase added to a competence, measured against its own ablation.
offline_consolidation_benefit(Without, With, Competence, Benefit) :-
    % Score the competence in the cortex the ablated run handed back.
    offline_consolidation_competence_score(Without, Competence, ScoreWithout),
    % Score the competence in the cortex the served run handed back.
    offline_consolidation_competence_score(With, Competence, ScoreWith),
    % The benefit is the difference, signed: a negative benefit is a real and reportable result.
    Benefit is ScoreWith - ScoreWithout.
