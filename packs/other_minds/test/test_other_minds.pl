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
% nested attribution inside the reused theory-of-mind runtime, where the capability was always
% whole. The CLOSURE half retells Wall-1 of the konnectome ledger as history: at Causalontology
% 3.0.0 the EXPORT of an attribution - a shareable, content-addressed record of who believes what -
% was not expressible, because the closed kind list carried no doxastic kind. That wall was hit on
% 2026-07-22, recorded as Wall-1, ROUTED through the gated change order rather than worked around,
% and CLOSED by Causalontology 4.0.0 plus causal_core 1.1.0, which added the attitude kind. Where
% a slice-11 test asserted a kind's ABSENCE, it now asserts PRESENCE and a full round trip; the one
% demonstration that remains is the one that was never a wall: an assertion still names only the
% signer, which is permanent design, because the holder now lives in the attitude kind instead.

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

% other_minds_test_twenty_one_kinds(-Kinds): the closed list of all twenty-one Causalontology 4.0.0 kinds.
other_minds_test_twenty_one_kinds([
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
    succession,
    % A holder's mental stance toward a content - the 4.0.0 arrival that closed Wall-1.
    attitude,
    % An expectation of a happening before it arrives - a 4.0.0 arrival, closing Wall-2.
    predicted_occurrence,
    % The graded gap between an expectation and what arrived - a 4.0.0 arrival, closing Wall-2.
    prediction_error
]).

% other_minds_test_ingredients(-HolderId, -MarbleId, -ContentId): the minted ingredients of the attribution.
other_minds_test_ingredients(HolderId, MarbleId, ContentId) :-
    % Mint sally, the holder of the belief, as a token_individual.
    other_minds_individual_record("agent", "sally", HolderRecord),
    % Read the holder's content-addressed identifier.
    get_dict(id, HolderRecord, HolderId),
    % Mint the marble, the subject of the believed content, as a token_individual.
    other_minds_individual_record("marble", "the_marble", MarbleRecord),
    % Read the marble's identifier.
    get_dict(id, MarbleRecord, MarbleId),
    % Mint the believed content - the marble sits at the basket - as a state_assertion.
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

% WALL-1 CLOSURE, DEMONSTRATION ONE. At 3.0.0 this test asserted a closed list of EIGHTEEN kinds
% with no doxastic kind among them - that ABSENCE was Wall-1 (2026-07-22). The wall was routed
% through the gated change order and closed by Causalontology 4.0.0 plus causal_core 1.1.0, so the
% same enumeration now counts TWENTY-ONE kinds, and the attitude kind is PRESENT with the identity
% fields the attribution always needed: the holder, the attitude type, and the content reference.
test(the_closed_kind_list_now_has_exactly_twenty_one_kinds_and_the_attitude_is_among_them) :-
    % Enumerate every kind the 4.0.0 identity table can content-address.
    findall(Kind, causal_core_identity_fields(Kind, _), Kinds),
    % Count the enumerated kinds.
    length(Kinds, KindCount),
    % There are exactly twenty-one: the list is still closed, one gated change order wider.
    assertion(KindCount == 21),
    % Fetch the expected closed list.
    other_minds_test_twenty_one_kinds(ExpectedKinds),
    % Sort the enumerated kinds into standard order for a set comparison.
    msort(Kinds, SortedKinds),
    % Sort the expected list the same way.
    msort(ExpectedKinds, SortedExpectedKinds),
    % The enumerated kinds are exactly the expected twenty-one - the eighteen plus the three arrivals.
    assertion(SortedKinds == SortedExpectedKinds),
    % The attitude kind - the doxastic kind whose absence was Wall-1 - is now among them.
    assertion(memberchk(attitude, Kinds)),
    % The predicted_occurrence kind, half of the Wall-2 closure, is among them too.
    assertion(memberchk(predicted_occurrence, Kinds)),
    % The prediction_error kind, the other half of the Wall-2 closure, is also among them.
    assertion(memberchk(prediction_error, Kinds)),
    % Asking the identity table directly for the attitude's fields now SUCCEEDS with the doxastic triple.
    assertion(causal_core_identity_fields(attitude, [holder, attitude_type, content])).

% WALL-1 CLOSURE, DEMONSTRATION TWO. At 3.0.0 this test proved content-addressing FAILED for the
% attitude record the attribution needs; under 4.0.0 and causal_core 1.1.0 the same record MINTS,
% so a TRUE belief - sally believes the marble is in the box, exactly where the world record puts
% it - is exported here as a real attitude record with a full round trip: a stable "attitude:" id,
% a deterministic re-mint, and a kind the core infers back from the record's own type field.
test(a_true_belief_now_mints_as_an_attitude_record_with_a_full_round_trip) :-
    % Mint the ingredients: the holder and the subject of the believed content.
    other_minds_test_ingredients(HolderId, MarbleId, _BasketContentId),
    % The holder minted as a token_individual - that half was always expressible.
    assertion(sub_string(HolderId, 0, _, _, "token_individual:")),
    % Mint the TRUE believed content: the marble sits at the box, matching the world record.
    other_minds_content_record(MarbleId, "location", "box", "2026-07-22T00:00:00Z", ContentRecord),
    % Read the true content's identifier.
    get_dict(id, ContentRecord, ContentId),
    % The believed content minted as a state_assertion - that half was always expressible too.
    assertion(sub_string(ContentId, 0, _, _, "state_assertion:")),
    % Mint the record 3.0.0 could not: the holder holds a believes attitude toward the content.
    other_minds_attitude_record(HolderId, "believes", ContentId, AttitudeRecord),
    % Read the attitude's content-addressed identifier.
    get_dict(id, AttitudeRecord, AttitudeId),
    % The identifier carries the attitude scheme: the record is real, shareable, content-addressed.
    assertion(sub_string(AttitudeId, 0, _, _, "attitude:")),
    % Mint the identical attribution a second time.
    other_minds_attitude_record(HolderId, "believes", ContentId, AttitudeRecordAgain),
    % Read the second identifier.
    get_dict(id, AttitudeRecordAgain, AttitudeIdAgain),
    % Content identity is deterministic: the same attribution always mints the same identifier.
    assertion(AttitudeId == AttitudeIdAgain),
    % Round trip: the core infers the attitude kind back from the record's own type field.
    assertion(causal_core_infer_kind(AttitudeRecord, attitude)),
    % Round trip: identifying the stored record again, kind inferred, reproduces the attached id.
    assertion(causal_core_identify(AttitudeRecord, _, AttitudeId)).

% WALL-1 CLOSURE, DEMONSTRATION THREE. The FALSE belief is minted while the world's actual
% state_assertion says otherwise, and both records coexist without conflict: semantics Rule 25 (the
% doxastic quarantine) rules that an attitude records the content of a holder's MIND, never a fact
% about the world, so content contradicting the actual record raises NO conflict - that mismatch
% IS the false belief, first-class and shareable. At 3.0.0 the false content could only have
% entered the commons as a graded claim of fact, poisoning it; the quarantine is what closed that.
test(the_false_belief_mints_while_the_world_record_says_otherwise_and_both_records_coexist) :-
    % Mint the ingredients: the holder, the marble, and sally's believed basket content.
    other_minds_test_ingredients(HolderId, MarbleId, BasketContentId),
    % Mint the world's ACTUAL record: the very same marble, quality, and interval - but at the box.
    other_minds_content_record(MarbleId, "location", "box", "2026-07-22T00:00:00Z", WorldRecord),
    % Read the world record's identifier.
    get_dict(id, WorldRecord, WorldContentId),
    % The believed content and the actual content are distinct records with distinct identities.
    assertion(BasketContentId \== WorldContentId),
    % Mint the FALSE belief: sally believes the basket content while the world record says the box.
    other_minds_attitude_record(HolderId, "believes", BasketContentId, FalseBeliefRecord),
    % Read the false belief's identifier.
    get_dict(id, FalseBeliefRecord, FalseBeliefId),
    % The false belief minted cleanly: contradiction with the world raises no conflict (Rule 25).
    assertion(sub_string(FalseBeliefId, 0, _, _, "attitude:")),
    % The attitude's content names the BELIEVED basket assertion, quarantined behind the holder's mind.
    assertion(get_dict(content, FalseBeliefRecord, BasketContentId)),
    % It does not name the world's box assertion: the belief never overwrites the actual record.
    assertion(\+ get_dict(content, FalseBeliefRecord, WorldContentId)),
    % Mint the identical false belief again, with the contrary world record already in existence.
    other_minds_attitude_record(HolderId, "believes", BasketContentId, FalseBeliefRecordAgain),
    % Read the re-minted identifier.
    get_dict(id, FalseBeliefRecordAgain, FalseBeliefIdAgain),
    % The world's contrary record changes nothing about the belief's identity: both simply coexist.
    assertion(FalseBeliefId == FalseBeliefIdAgain).

% WALL-1 CLOSURE, DEMONSTRATION FOUR. The NESTED attribution - konnectome believes that sally
% believes the marble is in the basket - mints as TWO attitudes: an inner attitude held by sally,
% and an outer attitude held by konnectome whose content is the INNER attitude's identifier, the
% nesting Rule 25 explicitly grants. At 3.0.0 the attribution of an attribution had no home at all.
test(the_nested_attribution_mints_as_two_attitudes_with_distinct_identities) :-
    % Mint the ingredients: sally the inner holder, the marble, and the believed basket content.
    other_minds_test_ingredients(InnerHolderId, _MarbleId, ContentId),
    % Mint konnectome, the outer holder doing the modelling, as a token_individual.
    other_minds_individual_record("agent", "konnectome", OuterHolderRecord),
    % Read the outer holder's identifier.
    get_dict(id, OuterHolderRecord, OuterHolderId),
    % The two holders are distinct individuals with distinct identities.
    assertion(InnerHolderId \== OuterHolderId),
    % Mint the two-level structure: sally believes the content, and konnectome believes that belief.
    other_minds_nested_attitude_records(OuterHolderId, InnerHolderId, ContentId, InnerRecord, OuterRecord),
    % Read the inner attitude's identifier.
    get_dict(id, InnerRecord, InnerId),
    % Read the outer attitude's identifier.
    get_dict(id, OuterRecord, OuterId),
    % Both levels minted as real attitude records.
    assertion(sub_string(InnerId, 0, _, _, "attitude:")),
    % The outer level too.
    assertion(sub_string(OuterId, 0, _, _, "attitude:")),
    % The two attitudes are distinct records with distinct identities.
    assertion(InnerId \== OuterId),
    % The inner attitude's content is the believed state_assertion: sally's belief about the marble.
    assertion(get_dict(content, InnerRecord, ContentId)),
    % The outer attitude's content is the INNER ATTITUDE'S identifier: a model of a model, exported.
    assertion(get_dict(content, OuterRecord, InnerId)),
    % The inner attitude names sally as its holder.
    assertion(get_dict(holder, InnerRecord, InnerHolderId)),
    % The outer attitude names konnectome as its holder.
    assertion(get_dict(holder, OuterRecord, OuterHolderId)).

% PERMANENT DESIGN, NOT A WALL. An assertion still records WHO SIGNS a claim (a cryptographic
% source), never WHOSE MIND HOLDS a content: its identity fields carry no holder, and a holder
% field smuggled into one is invisible to content identity. At 3.0.0 this conflation was part of
% Wall-1 because the assertion was the NEAREST kind an attribution could reach for; under 4.0.0 it
% is simply the division of labour, because the holder now lives in the attitude kind, and Rule 25
% keeps the SOURCE that signs an assertion ABOUT an attitude distinct from the attitude's HOLDER.
test(the_assertion_kind_still_names_only_the_signer_because_the_holder_now_lives_in_the_attitude) :-
    % Mint the believed content for the shaped records to be about.
    other_minds_test_ingredients(_HolderId, _MarbleId, ContentId),
    % Shape a record the old way: about a content, graded by a confidence, no explicit type.
    BeliefShapedRecord = _{about: ContentId, confidence: "0.9"},
    % Ask the core what kind this shape is.
    causal_core_infer_kind(BeliefShapedRecord, InferredKind),
    % It is still inferred to be an assertion: the 4.0.0 kinds add no shape heuristic, by design.
    assertion(InferredKind == assertion),
    % Fetch the assertion kind's complete identity-bearing field list.
    causal_core_identity_fields(assertion, AssertionFields),
    % Those fields are exactly the signing surface: the claim, its signer, its evidence, its grades, its time.
    assertion(AssertionFields == [about, source, evidence_type, evidence, strength, confidence, timestamp, evidenced_by]),
    % There is still NO holder field: an assertion names a signer, permanently.
    assertion(\+ memberchk(holder, AssertionFields)),
    % The only agent an assertion can name is its source - the cryptographic signer of the claim.
    assertion(memberchk(source, AssertionFields)),
    % Smuggle a holder field into an assertion anyway.
    AssertionWithHolder = _{type: "assertion", about: ContentId, confidence: "0.9", holder: "sally"},
    % And build the identical assertion without any holder.
    AssertionWithoutHolder = _{type: "assertion", about: ContentId, confidence: "0.9"},
    % Content-address the record that names a holder.
    causal_core_identify(AssertionWithHolder, assertion, WithHolderId),
    % Content-address the record that names none.
    causal_core_identify(AssertionWithoutHolder, assertion, WithoutHolderId),
    % The two identifiers are IDENTICAL: a holder is invisible to an assertion's content identity, still.
    assertion(WithHolderId == WithoutHolderId),
    % Fetch the attitude kind's identity-bearing field list, the holder's true home since 4.0.0.
    causal_core_identity_fields(attitude, AttitudeFields),
    % The holder is identity-bearing THERE: the division of labour that replaced the conflation.
    assertion(memberchk(holder, AttitudeFields)).

% WALL-1 CLOSURE, DEMONSTRATION FIVE. At 3.0.0 this test showed the quarantine of the runtime: the
% false belief, the search prediction, and the nested attribution all lived inside the reused
% theory-of-mind runtime while NO attribution record could leave this mind. The wall was only ever
% in the SHARING, and the sharing is what 4.0.0 closed: the trial now ends by exporting its result -
% the prediction that sally searches where SHE BELIEVES the marble is - as a real attitude record.
test(the_false_belief_trial_now_ends_by_exporting_its_prediction_as_a_shareable_attitude_record) :-
    % Build the runtime scene: the world, the attributed belief, the nested attribution.
    other_minds_test_scene,
    % Inside the runtime the capability is whole, as it always was: the false belief is held and detected.
    assertion(other_minds_false_belief(sally, object_location(marble, basket))),
    % Inside the runtime the trial's prediction fires: sally will search the basket.
    assertion(other_minds_predict_search(sally, marble, basket)),
    % Inside the runtime the nested attribution holds: konnectome models sally's model.
    assertion(other_minds_nested_believes(konnectome, sally, object_location(marble, basket))),
    % Now EXPORT the trial's result, once, from the very belief the runtime is holding.
    once(other_minds_search_prediction_export(sally, marble, "2026-07-22T00:00:00Z", Place, ExportRecord)),
    % The exported prediction is the basket - where sally believes the marble is, not where it is.
    assertion(Place == basket),
    % Read the exported record's identifier.
    get_dict(id, ExportRecord, ExportId),
    % The attribution left this mind as a real, shareable, content-addressed attitude record.
    assertion(sub_string(ExportId, 0, _, _, "attitude:")),
    % Read the exported record's holder.
    get_dict(holder, ExportRecord, ExportHolderId),
    % The holder is sally's token_individual - the modelled mind, never a signing key.
    assertion(sub_string(ExportHolderId, 0, _, _, "token_individual:")),
    % Read the exported record's content.
    get_dict(content, ExportRecord, ExportContentId),
    % The content is the believed state_assertion, quarantined behind sally's mind by Rule 25.
    assertion(sub_string(ExportContentId, 0, _, _, "state_assertion:")),
    % Read the exported record's attitude type.
    get_dict(attitude_type, ExportRecord, ExportAttitudeType),
    % The stance exported is belief: sally BELIEVES the marble is in the basket.
    assertion(ExportAttitudeType == "believes"),
    % And after the export succeeds, the runtime still holds the belief undisturbed: nothing was consumed.
    assertion(other_minds_believes(sally, object_location(marble, basket))).

% Close the test block for the other_minds pack.
:- end_tests(other_minds).
