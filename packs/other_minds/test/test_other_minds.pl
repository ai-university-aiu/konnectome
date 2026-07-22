% Load the other_minds module under test from the library path.
:- use_module(library(other_minds)).
% Reuse PrologAI's Causalontology core to content-address a record; konnectome does not fork it.
:- use_module(library(causal_core), [
    % causal_core_identity_fields/2: the closed table of identity-bearing fields, one row per kind.
    causal_core_identity_fields/2,
    % causal_core_identify/3: content-address a record as its kind scheme plus a SHA-256 digest.
    causal_core_identify/3,
    % causal_core_infer_kind/2: infer a dict's kind from its type field or, failing that, its shape.
    causal_core_infer_kind/2
]).
% Import membership checking for the kind-list demonstrations.
:- use_module(library(lists), [memberchk/2]).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% This suite has two halves. The RUNTIME half exercises the classic false-belief trial and the
% nested attribution inside the reused theory-of-mind runtime, where the capability is whole. The
% WALL half is Wall-1 of the konnectome ledger: four demonstrations that mechanically show the
% EXPORT of an attribution - a shareable, signed, evidence-graded, content-addressed record of who
% believes what - is not expressible in Causalontology 3.0.0, because its closed kind list carries
% no doxastic kind and its closest kind, the assertion, names only the cryptographic signer, never
% the believing holder. Every demonstration ASSERTS the failure it claims, so a green suite is
% itself the proof that the wall is real.

% other_minds_test_scene/0: the classic false-belief scene, deterministic on every run.
other_minds_test_scene :-
    % Start from a clean runtime.
    other_minds_reset,
    % The world as konnectome records it: the marble is actually in the box (it was moved).
    other_minds_world_fact_add(object_location(marble, box)),
    % Sally saw the marble in the basket and did not see the move, so sally believes the basket.
    other_minds_belief_attribute(sally, object_location(marble, basket)),
    % Konnectome also models sally's mind: konnectome believes that sally believes the basket.
    other_minds_nested_attribute(konnectome, sally, object_location(marble, basket)).

% other_minds_test_eighteen_kinds(-Kinds): the closed list of all eighteen Causalontology 3.0.0 kinds.
other_minds_test_eighteen_kinds([
    % A repeatable type of happening.
    occurrent,
    % The reified cause-and-effect record.
    causal_relation_object,
    % A thing that persists through time.
    continuant,
    % A disposition, role, or function a bearer can realize.
    realizable,
    % A level of organisation with its own scheme and unit.
    stratum,
    % A coarse-to-fine mapping between occurrents.
    bridge,
    % A causal seam that crosses between strata.
    cross_stratal_seam,
    % A point of interaction a bearer offers.
    port,
    % A channel that carries occurrents between ports.
    conduit,
    % A measurable property with a datatype and unit.
    quality,
    % One particular individual instantiating a continuant.
    token_individual,
    % One particular happening instantiating an occurrent.
    token_occurrence,
    % A statement that a subject's quality has a value over an interval.
    state_assertion,
    % One particular cause-and-effect episode that actually happened.
    token_causal_claim,
    % A signed, evidence-graded claim by a cryptographic source.
    assertion,
    % An additive annotation attached to an existing record.
    enrichment,
    % A signed withdrawal of an earlier record.
    retraction,
    % A signed replacement chain from one record to its successor.
    succession
]).

% other_minds_test_ingredients(-HolderId, -ContentId): the expressible ingredients of the attribution.
other_minds_test_ingredients(HolderId, ContentId) :-
    % Mint sally, the holder of the belief, as a token_individual - fully expressible today.
    other_minds_individual_record("agent", "sally", HolderRecord),
    % Read the holder's content-addressed identifier.
    get_dict(id, HolderRecord, HolderId),
    % Mint the marble, the subject of the believed content, as a token_individual.
    other_minds_individual_record("marble", "the_marble", MarbleRecord),
    % Read the marble's identifier.
    get_dict(id, MarbleRecord, MarbleId),
    % Mint the believed content - the marble sits at the basket - as a state_assertion, also expressible.
    other_minds_content_record(MarbleId, "location", "basket", "2026-07-22T00:00:00Z", ContentRecord),
    % Read the content's identifier.
    get_dict(id, ContentRecord, ContentId).

% Open the test block for the other_minds pack.
:- begin_tests(other_minds).

% The runtime holds a world record and an attributed belief that genuinely diverge.
test(the_world_record_and_the_attributed_belief_diverge_between_box_and_basket) :-
    % Build the false-belief scene.
    other_minds_test_scene,
    % Konnectome's own record: the marble is in the box.
    assertion(other_minds_world_fact(object_location(marble, box))),
    % Sally's attributed belief: the marble is in the basket.
    assertion(other_minds_believes(sally, object_location(marble, basket))),
    % Sally is not modelled as believing the box - her mind is not a copy of the world.
    assertion(\+ other_minds_believes(sally, object_location(marble, box))).

% The runtime detects sally's belief as FALSE: held by her, contradicted by the world record.
test(sally_holds_a_false_belief_that_the_world_record_contradicts) :-
    % Build the false-belief scene.
    other_minds_test_scene,
    % Sally's basket belief is a false belief.
    assertion(other_minds_false_belief(sally, object_location(marble, basket))),
    % The box location is not a false belief of sally's, because she does not hold it at all.
    assertion(\+ other_minds_false_belief(sally, object_location(marble, box))).

% The classic trial's prediction: sally will look where SHE believes the marble is, not where it is.
test(sally_will_search_the_basket_where_she_believes_the_marble_is_not_the_box_where_it_is) :-
    % Build the false-belief scene.
    other_minds_test_scene,
    % Predicted search location: the basket, the place sally believes.
    assertion(other_minds_predict_search(sally, marble, basket)),
    % Not predicted: the box, the place the marble actually is.
    assertion(\+ other_minds_predict_search(sally, marble, box)).

% The nested attribution holds: konnectome models sally's model of the marble.
test(konnectome_holds_a_nested_model_of_sally_believing_the_basket) :-
    % Build the false-belief scene.
    other_minds_test_scene,
    % Konnectome believes that sally believes the marble is in the basket.
    assertion(other_minds_nested_believes(konnectome, sally, object_location(marble, basket))),
    % Konnectome does not model sally as believing the box.
    assertion(\+ other_minds_nested_believes(konnectome, sally, object_location(marble, box))).

% WALL DEMONSTRATION ONE. The 3.0.0 kind list is CLOSED at eighteen and contains no doxastic kind -
% no attitude, no belief, no desire, no intention - so no belief attribution can be content-addressed,
% and a record that cannot be content-addressed cannot enter the shared commons.
test(the_closed_kind_list_has_exactly_eighteen_kinds_and_no_doxastic_kind_is_among_them) :-
    % Enumerate every kind the 3.0.0 identity table can content-address.
    findall(Kind, causal_core_identity_fields(Kind, _), Kinds),
    % Count the enumerated kinds.
    length(Kinds, KindCount),
    % There are exactly eighteen: the list is closed.
    assertion(KindCount == 18),
    % Fetch the expected closed list.
    other_minds_test_eighteen_kinds(ExpectedKinds),
    % Sort the enumerated kinds into standard order for a set comparison.
    msort(Kinds, SortedKinds),
    % Sort the expected list the same way.
    msort(ExpectedKinds, SortedExpectedKinds),
    % The enumerated kinds are exactly the expected eighteen - no more, no fewer, no doxastic addition.
    assertion(SortedKinds == SortedExpectedKinds),
    % No attitude kind is among them.
    assertion(\+ memberchk(attitude, Kinds)),
    % No belief kind is among them.
    assertion(\+ memberchk(belief, Kinds)),
    % No desire kind is among them.
    assertion(\+ memberchk(desire, Kinds)),
    % No intention kind is among them.
    assertion(\+ memberchk(intention, Kinds)),
    % Asking the identity table directly for an attitude's fields fails outright: no such row exists.
    assertion(\+ causal_core_identity_fields(attitude, _)).

% WALL DEMONSTRATION TWO. Every INGREDIENT of the attribution content-addresses cleanly, but the
% attitude record that would JOIN them - sally (the holder) believes the content - cannot be
% content-addressed at all, so it can never be shared, signed, or evidence-graded.
test(content_addressing_fails_for_the_attitude_record_the_attribution_needs) :-
    % Mint the expressible ingredients: the holder and the believed content.
    other_minds_test_ingredients(HolderId, ContentId),
    % The holder minted cleanly as a token_individual - that half is expressible today.
    assertion(sub_string(HolderId, 0, _, _, "token_individual:")),
    % The believed content minted cleanly as a state_assertion - that half is expressible too.
    assertion(sub_string(ContentId, 0, _, _, "state_assertion:")),
    % Assemble the record the attribution needs: the holder holds a believes attitude toward the content.
    AttitudeRecord = _{type: "attitude", holder: HolderId, attitude_type: "believes", content: ContentId},
    % Content-addressing it as an attitude FAILS: no identity fields exist for that kind.
    assertion(\+ causal_core_identify(AttitudeRecord, attitude, _)),
    % Letting the core infer the kind from the record's own type field fails the same way.
    assertion(\+ causal_core_identify(AttitudeRecord, _, _)).

% WALL DEMONSTRATION THREE. The closest existing kind CONFLATES belief with signed assertion. A
% belief-attribution-shaped dict is INFERRED to be an assertion - but an assertion records WHO SIGNS
% a claim of fact (a cryptographic source), not WHOSE MIND HOLDS a possibly-false content: its
% identity fields carry no holder at all, so the holder cannot be separated from the signer, the
% content would enter the commons as a graded claim of fact (poisoning it when the belief is false),
% and - the 4.0.0 review records - an assertion cannot be about another agent's mental state and
% cannot nest, so the attribution of an attribution has no home either.
test(the_closest_existing_kind_conflates_the_believing_holder_with_the_signing_source) :-
    % Mint the expressible believed content to be about.
    other_minds_test_ingredients(_HolderId, ContentId),
    % Shape the attribution the only way 3.0.0 leaves open: about a content, graded by a confidence, no type.
    BeliefShapedRecord = _{about: ContentId, confidence: "0.9"},
    % Ask the core what kind this shape is.
    causal_core_infer_kind(BeliefShapedRecord, InferredKind),
    % It is MISINFERRED to be an assertion: a signed claim of fact, not a held and possibly-false belief.
    assertion(InferredKind == assertion),
    % Fetch the assertion kind's complete identity-bearing field list.
    causal_core_identity_fields(assertion, AssertionFields),
    % Those fields are exactly the signing surface: the claim, its signer, its evidence, its grades, its time.
    assertion(AssertionFields == [about, source, evidence_type, evidence, strength, confidence, timestamp, evidenced_by]),
    % There is NO holder field: the mind that holds the belief cannot be named anywhere in the record.
    assertion(\+ memberchk(holder, AssertionFields)),
    % The only agent an assertion can name is its source - the cryptographic signer of the claim.
    assertion(memberchk(source, AssertionFields)),
    % Push the conflation to its sharpest mechanical point: add a holder field to an assertion anyway.
    AssertionWithHolder = _{type: "assertion", about: ContentId, confidence: "0.9", holder: "sally"},
    % And build the identical assertion without any holder.
    AssertionWithoutHolder = _{type: "assertion", about: ContentId, confidence: "0.9"},
    % Content-address the record that names a holder.
    causal_core_identify(AssertionWithHolder, assertion, WithHolderId),
    % Content-address the record that names none.
    causal_core_identify(AssertionWithoutHolder, assertion, WithoutHolderId),
    % The two identifiers are IDENTICAL: whose mind holds the belief is invisible to content identity.
    assertion(WithHolderId == WithoutHolderId).

% WALL DEMONSTRATION FOUR. The runtime-only quarantine IS the gap: the false belief, the search
% prediction, and the nested attribution all live happily inside the reused theory-of-mind runtime,
% while the very same attribution has no exportable record - the consumer-versus-ontology line
% exactly, where the capability exists inside one mind's runtime and the wall is only in SHARING it.
test(the_false_belief_lives_in_the_runtime_while_no_attribution_record_can_be_exported) :-
    % Build the runtime scene: the world, the attributed belief, the nested attribution.
    other_minds_test_scene,
    % INSIDE the runtime the capability is whole: the false belief is held and detected.
    assertion(other_minds_false_belief(sally, object_location(marble, basket))),
    % Inside the runtime the trial's prediction fires: sally will search the basket.
    assertion(other_minds_predict_search(sally, marble, basket)),
    % Inside the runtime the nested attribution holds: konnectome models sally's model.
    assertion(other_minds_nested_believes(konnectome, sally, object_location(marble, basket))),
    % Now try to EXPORT the very attribution the runtime is holding, from its expressible ingredients.
    other_minds_test_ingredients(HolderId, ContentId),
    % The export record it needs is the attitude joining the holder to the believed content.
    AttitudeRecord = _{type: "attitude", holder: HolderId, attitude_type: "believes", content: ContentId},
    % No content address exists for it, so nothing of the attribution can leave this mind.
    assertion(\+ causal_core_identify(AttitudeRecord, attitude, _)),
    % And yet, after the export fails, the runtime still holds the belief undisturbed: the wall is only in sharing.
    assertion(other_minds_believes(sally, object_location(marble, basket))).

% Close the test block for the other_minds pack.
:- end_tests(other_minds).
