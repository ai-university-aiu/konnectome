% Declare this file as the 'self_provenance' module and list the predicates it exports.
:- module(self_provenance, [
    % self_provenance_source/1: konnectome's own source identity, a deterministic Ed25519-shaped public key.
    self_provenance_source/1,
    % self_provenance_evidence_grade/1: enumerate (or check) the six ordered evidence grades of the standard.
    self_provenance_evidence_grade/1,
    % self_provenance_grade_rank/2: the numeric rank of an evidence grade, strongest highest.
    self_provenance_grade_rank/2,
    % self_provenance_grade_stronger/2: true when the first evidence grade outranks the second.
    self_provenance_grade_stronger/2,
    % self_provenance_instant/3: the deterministic absolute instant of a numbered tick, for reproducible timestamps.
    self_provenance_instant/3,
    % self_provenance_assertion/5: mint a signed-shaped assertion about one of the mind's own records.
    self_provenance_assertion/5,
    % self_provenance_assertion_evidenced/6: mint an assertion that cites the particular token records grounding it.
    self_provenance_assertion_evidenced/6,
    % self_provenance_retraction/4: mint the honest exit - retract one of the mind's own prior assertions.
    self_provenance_retraction/4,
    % self_provenance_supersede/7: retract a prior assertion and restate the stance about the same content.
    self_provenance_supersede/7
]).

% Reuse PrologAI's Causalontology core to content-address and locally validate the provenance kinds; konnectome does not fork it.
:- use_module(library(causal_core), [causal_core_identify/3, causal_core_validate_semantics/3]).
% Bring in the SHA-256 primitive used to derive konnectome's deterministic public source identity.
:- use_module(library(sha), [sha_hash/3, hash_atom/2]).

% Provenance is the layer at which a mind takes RESPONSIBILITY for a thought: it does not merely HOLD a belief or a
% forecast, it ASSERTS the belief or forecast as its own, GRADES the evidence behind the assertion on the standard's
% ordered scale (intervention beats observation beats simulation beats derivation beats a human hint beats an import),
% and, when a later tick proves the assertion wrong, RETRACTS it - the honest exit. This is the metacognitive rung the
% glass-box thesis demands: a mind we can inspect must show not only what it thinks but how sure it is and why, and must
% be seen to correct itself on the record. Slice 12 left this exact gap open as an honest non-closure - konnectome minted
% attitude, predicted_occurrence, and prediction_error CONTENT records, but no konnectome assertion yet graded one of its
% own minted records. This pack closes it. It reuses the Causalontology provenance kinds through causal_core: the
% ASSERTION (about, source, evidence_type, confidence, timestamp, and the optional evidenced_by that cites the particular
% token records that are its evidence) and the RETRACTION (retracts, source, timestamp, and an advisory reason). Both are
% content-addressed exactly as the observer, other_minds, and prediction_loop records are, so a graded, self-corrected
% thought is a shareable, reproducible record another mind can read.
%
% ONE HONEST NON-CLOSURE, RECORDED HERE BY BUILDING (konnectome ledger, slice 13). The Causalontology provenance model
% signs an assertion with an Ed25519 signature over its canonical bytes; that signature is OPTIONAL to the schema and is
% NOT identity-bearing (content addressing excludes it), so the records this pack mints are fully schema-valid,
% semantically valid, content-addressed, and shareable WITHOUT it. But producing a real signature needs a PRIVATE key,
% and a private key is a secret that may never appear in konnectome's code (Specification Constraint 3). So this pack
% carries konnectome's PUBLIC source identity (a deterministic, secret-free stand-in derived by hashing the public name
% 'konnectome') and defers the cryptographic signing act to deployment, where the key-holder signs the minted bytes. This
% is neither a data-structure gap (the standard already carries the signature) nor a blocking language wall (the mind's
% cognitive act - asserting, grading, retracting - is fully realized at the record level); it is a deployment boundary,
% recorded honestly rather than papered over with a secret in the source.

% ---------------------------------------------------------------------------
% THE MIND'S OWN SOURCE IDENTITY - a deterministic, secret-free public key id
% ---------------------------------------------------------------------------

% self_provenance_source(-Source): konnectome's own source identity as an 'ed25519:<64 hex>' string.
self_provenance_source(Source) :-
    % Hash the PUBLIC name 'konnectome' to a fixed 256-bit digest; this carries no secret and never varies.
    sha_hash("konnectome", Digest, [algorithm(sha256)]),
    % Render the digest as lowercase hexadecimal, the shape an Ed25519 public key is written in.
    hash_atom(Digest, HexAtom),
    % Move from an atom to a string, the form the record fields use.
    atom_string(HexAtom, HexString),
    % Prefix the Ed25519 scheme so the identity is a well-formed source reference.
    string_concat("ed25519:", HexString, Source).

% ---------------------------------------------------------------------------
% THE EVIDENCE GRADES - the standard's ordered scale, strongest first
% ---------------------------------------------------------------------------

% self_provenance_grade_rank_(+GradeAtom, -Rank): the private rank table; a higher rank is stronger evidence.
% Acting on the world (intervention) is the strongest ground for a claim.
self_provenance_grade_rank_(intervention, 6).
% Watching the world (observation) is next, below intervention.
self_provenance_grade_rank_(observation, 5).
% A synthetic mind's own model-based or counterfactual evidence (simulation) ranks below watching.
self_provenance_grade_rank_(simulation, 4).
% Reasoning a claim out from others (derivation) ranks below a model run.
self_provenance_grade_rank_(derivation, 3).
% A human's unverified hint (human_hint) ranks below a derivation.
self_provenance_grade_rank_(human_hint, 2).
% An imported third-party claim (imported) is the weakest ground.
self_provenance_grade_rank_(imported, 1).

% self_provenance_grade_atom_(+Grade, -Atom): normalise an atom or string grade to an atom; fail on any other term.
self_provenance_grade_atom_(Grade, Atom) :-
    % An atom grade is kept; a string grade is converted; any other term (a compound, a number) fails, so it is refused cleanly rather than raising a raw type error.
    ( atom(Grade) -> Atom = Grade ; string(Grade) -> atom_string(Atom, Grade) ; fail ).

% self_provenance_evidence_grade(?Grade): enumerate the six grades, or check one, as atoms.
self_provenance_evidence_grade(Grade) :-
    % A grade is exactly one that carries a rank in the private table.
    self_provenance_grade_rank_(Grade, _).

% self_provenance_grade_rank(+Grade, -Rank): the rank of a grade, accepting a string or an atom.
self_provenance_grade_rank(Grade, Rank) :-
    % Normalise the grade to an atom, then read its rank.
    self_provenance_grade_atom_(Grade, Atom),
    % Look the atom up in the private rank table.
    self_provenance_grade_rank_(Atom, Rank).

% self_provenance_grade_stronger(+StrongerGrade, +WeakerGrade): true when the first grade outranks the second.
self_provenance_grade_stronger(StrongerGrade, WeakerGrade) :-
    % Read the rank of the candidate stronger grade.
    self_provenance_grade_rank(StrongerGrade, StrongerRank),
    % Read the rank of the candidate weaker grade.
    self_provenance_grade_rank(WeakerGrade, WeakerRank),
    % The first is stronger exactly when its rank is the greater.
    StrongerRank > WeakerRank.

% ---------------------------------------------------------------------------
% DETERMINISTIC TIMESTAMPS - one nominal second per ordinal tick, reproducibly
% ---------------------------------------------------------------------------

% self_provenance_instant(+SimulationStart, +TickNumber, -InstantString): tick N's absolute RFC 3339 instant.
self_provenance_instant(SimulationStart, TickNumber, InstantString) :-
    % Parse the simulation start, an RFC 3339 timestamp, into a POSIX second count.
    parse_time(SimulationStart, iso_8601, BaseStamp),
    % Advance the clock by one nominal second per ordinal tick, keeping whole seconds.
    Stamp is truncate(BaseStamp) + TickNumber,
    % Express that instant back in Coordinated Universal Time.
    stamp_date_time(Stamp, DateTime, 'UTC'),
    % Format it as an RFC 3339 timestamp with the mandatory trailing Z.
    format_time(string(InstantString), "%Y-%m-%dT%H:%M:%SZ", DateTime).

% ---------------------------------------------------------------------------
% VALIDATION HELPERS - refuse a malformed assertion before it is ever minted
% ---------------------------------------------------------------------------

% self_provenance_valid_grade_(+EvidenceType): succeed only for one of the six standard grades, else refuse.
self_provenance_valid_grade_(EvidenceType) :-
    % A grade that carries a rank is legal; anything else is refused with the offending value.
    ( self_provenance_grade_rank(EvidenceType, _)
    % A legal grade passes silently.
    ->  true
    % An unknown grade is a hard refusal naming the bad value.
    ;   throw(error(self_provenance_bad_grade(EvidenceType), context(self_provenance_valid_grade_/1, "evidence_type must be one of intervention, observation, simulation, derivation, human_hint, imported")))
    ).

% self_provenance_valid_confidence_(+Confidence): succeed only for a number in the closed unit interval.
self_provenance_valid_confidence_(Confidence) :-
    % Confidence must be a number lying between zero and one inclusive.
    ( number(Confidence), Confidence >= 0, Confidence =< 1
    % A well-formed confidence passes silently.
    ->  true
    % Any other value is a hard refusal naming the bad value.
    ;   throw(error(self_provenance_bad_confidence(Confidence), context(self_provenance_valid_confidence_/1, "confidence must be a number in [0,1]")))
    ).

% self_provenance_split_id_(+Id, -SchemeAtom, -HexString): decompose a 'scheme:<64 lowercase hex>' identifier, else fail.
self_provenance_split_id_(Id, SchemeAtom, HexString) :-
    % An identifier is a string.
    string(Id),
    % It splits on its single colon into exactly a scheme part and a body part; a colon-free or multi-colon string does not unify here and fails.
    split_string(Id, ":", "", [SchemeString, HexString]),
    % The scheme part is non-empty (an empty scheme like ':<hex>' is rejected).
    SchemeString \== "",
    % Read the scheme as an atom, for table lookup.
    atom_string(SchemeAtom, SchemeString),
    % The body is a 64-character digest.
    string_length(HexString, 64),
    % Read its character codes.
    string_codes(HexString, Codes),
    % Every one of which must be a lowercase hexadecimal digit.
    self_provenance_all_hex_(Codes).

% self_provenance_all_hex_(+Codes): true when every character code is a lowercase hexadecimal digit.
self_provenance_all_hex_([]).
% Each code in turn must be a hex digit, and so must the rest of the list.
self_provenance_all_hex_([Code|Rest]) :-
    % A hex digit is 0-9 or a-f in character-code terms.
    ( (Code >= 0'0, Code =< 0'9) ; (Code >= 0'a, Code =< 0'f) ),
    % Check the remaining codes the same way.
    self_provenance_all_hex_(Rest).

% self_provenance_about_scheme_(?Scheme): the seventeen content schemes an assertion's 'about' may name (assertion.schema.json).
self_provenance_about_scheme_(causal_relation_object).
% A type-level occurrent.
self_provenance_about_scheme_(occurrent).
% A continuant.
self_provenance_about_scheme_(continuant).
% A realizable (a disposition, function, or role).
self_provenance_about_scheme_(realizable).
% A stratum.
self_provenance_about_scheme_(stratum).
% A bridge.
self_provenance_about_scheme_(bridge).
% A cross-stratal seam.
self_provenance_about_scheme_(cross_stratal_seam).
% A port.
self_provenance_about_scheme_(port).
% A conduit.
self_provenance_about_scheme_(conduit).
% A quality.
self_provenance_about_scheme_(quality).
% A token individual.
self_provenance_about_scheme_(token_individual).
% A token occurrence.
self_provenance_about_scheme_(token_occurrence).
% A state assertion.
self_provenance_about_scheme_(state_assertion).
% A token causal claim.
self_provenance_about_scheme_(token_causal_claim).
% A doxastic attitude (4.0.0).
self_provenance_about_scheme_(attitude).
% A predicted occurrence (4.0.0).
self_provenance_about_scheme_(predicted_occurrence).
% A prediction error (4.0.0).
self_provenance_about_scheme_(prediction_error).

% self_provenance_evidence_scheme_(?Scheme): the three token schemes an 'evidenced_by' item may name (assertion.schema.json).
self_provenance_evidence_scheme_(token_occurrence).
% A particular token causal claim may ground a claim.
self_provenance_evidence_scheme_(token_causal_claim).
% A particular state assertion may ground a claim.
self_provenance_evidence_scheme_(state_assertion).

% self_provenance_valid_about_(+About): succeed only for a content identifier of a scheme the 'about' field allows.
self_provenance_valid_about_(About) :-
    % The subject must decompose to a well-formed identifier whose scheme is one of the allowed content schemes.
    ( self_provenance_split_id_(About, Scheme, _), self_provenance_about_scheme_(Scheme)
    % A well-formed, allowed identifier passes silently.
    ->  true
    % Anything else - malformed, empty-scheme, or a forbidden scheme such as assertion, retraction, enrichment, or succession - is a hard refusal.
    ;   throw(error(self_provenance_bad_about(About), context(self_provenance_valid_about_/1, "about must be a content identifier of an allowed scheme (not an assertion, retraction, enrichment, or succession)")))
    ).

% self_provenance_valid_evidence_item_(+Item): succeed only for a token identifier the 'evidenced_by' field allows.
self_provenance_valid_evidence_item_(Item) :-
    % Each evidence item must decompose to a well-formed identifier whose scheme is one of the three token schemes.
    ( self_provenance_split_id_(Item, Scheme, _), self_provenance_evidence_scheme_(Scheme)
    % A well-formed token identifier passes silently.
    ->  true
    % Anything else is a hard refusal - only a token_occurrence, token_causal_claim, or state_assertion may be cited as evidence.
    ;   throw(error(self_provenance_bad_evidence_item(Item), context(self_provenance_valid_evidence_item_/1, "an evidenced_by item must be a token_occurrence, token_causal_claim, or state_assertion identifier")))
    ).

% self_provenance_valid_evidence_list_(+EvidencedBy): succeed only for a non-empty list of allowed token identifiers.
self_provenance_valid_evidence_list_(EvidencedBy) :-
    % The evidence citation must be a non-empty list.
    ( is_list(EvidencedBy), EvidencedBy \== []
    % A non-empty list is then checked item by item against the allowed token schemes.
    ->  forall(member(Item, EvidencedBy), self_provenance_valid_evidence_item_(Item))
    % An absent or empty citation is a hard refusal (omit evidenced_by entirely instead).
    ;   throw(error(self_provenance_bad_evidence(EvidencedBy), context(self_provenance_valid_evidence_list_/1, "evidenced_by must be a non-empty list of token identifiers")))
    ).

% ---------------------------------------------------------------------------
% MINTING - content-address a provenance record through the reused core
% ---------------------------------------------------------------------------

% self_provenance_mint_(+Base, +Kind, -Record): validate a base record's local semantics and content-address it.
self_provenance_mint_(Base, Kind, Record) :-
    % Ask causal_core's local semantic rules to judge the record; an assertion and a retraction carry no local rule, so this is a clean parity check.
    causal_core_validate_semantics(Base, Kind, Reasons),
    % An empty reason list is a clean bill of health.
    ( Reasons == []
    % With clean semantics, minting proceeds.
    ->  true
    % Any reason is a hard refusal carrying the core's own wording.
    ;   throw(error(self_provenance_refused(Kind, Reasons), context(self_provenance_mint_/3, "causal_core refused the provenance record")))
    ),
    % Content-address the record over its identity-bearing fields for this kind.
    causal_core_identify(Base, Kind, Id),
    % Attach the identifier, yielding the complete stored record.
    put_dict(id, Base, Id, Record).

% ---------------------------------------------------------------------------
% THE ASSERTION - the mind vouches for one of its own records, with a grade
% ---------------------------------------------------------------------------

% self_provenance_assertion(+About, +EvidenceType, +Confidence, +Instant, -Record): assert about a content record.
self_provenance_assertion(About, EvidenceType, Confidence, Instant, Record) :-
    % The mind asserts under its own source identity.
    self_provenance_source(Source),
    % Refuse an evidence grade outside the standard's six.
    self_provenance_valid_grade_(EvidenceType),
    % Refuse a confidence outside the unit interval.
    self_provenance_valid_confidence_(Confidence),
    % Refuse a subject that is not a well-formed content identifier.
    self_provenance_valid_about_(About),
    % Build the assertion: what it is about, who signs it, how it was grounded, how sure, and when.
    Base = _{type: "assertion", about: About, source: Source, evidence_type: EvidenceType, confidence: Confidence, timestamp: Instant},
    % Validate and content-address it as an assertion.
    self_provenance_mint_(Base, assertion, Record).

% self_provenance_assertion_evidenced(+About, +EvidenceType, +Confidence, +EvidencedBy, +Instant, -Record): cite the evidence.
self_provenance_assertion_evidenced(About, EvidenceType, Confidence, EvidencedBy, Instant, Record) :-
    % The mind asserts under its own source identity.
    self_provenance_source(Source),
    % Refuse an evidence grade outside the standard's six.
    self_provenance_valid_grade_(EvidenceType),
    % Refuse a confidence outside the unit interval.
    self_provenance_valid_confidence_(Confidence),
    % Refuse a subject that is not a well-formed content identifier.
    self_provenance_valid_about_(About),
    % Refuse an empty or malformed evidence citation.
    self_provenance_valid_evidence_list_(EvidencedBy),
    % Build the assertion, additionally citing the particular token records that are its evidence.
    Base = _{type: "assertion", about: About, source: Source, evidence_type: EvidenceType, confidence: Confidence, timestamp: Instant, evidenced_by: EvidencedBy},
    % Validate and content-address it as an assertion.
    self_provenance_mint_(Base, assertion, Record).

% ---------------------------------------------------------------------------
% THE RETRACTION - the mind's honest exit from an assertion it now disowns
% ---------------------------------------------------------------------------

% self_provenance_retraction(+Assertion, +Reason, +Instant, -Record): retract one of the mind's own prior assertions.
self_provenance_retraction(Assertion, Reason, Instant, Record) :-
    % The mind retracts under its own source identity.
    self_provenance_source(Source),
    % Read the identifier of the assertion being withdrawn; a dict lacking one cannot be retracted and is refused, not failed silently.
    ( get_dict(id, Assertion, AssertionId) -> true ; throw(error(self_provenance_bad_assertion(Assertion), context(self_provenance_retraction/4, "the assertion to retract must carry an id and a source"))) ),
    % Read the source that signed the assertion being withdrawn; a dict lacking one cannot be retracted and is refused.
    ( get_dict(source, Assertion, AssertionSource) -> true ; throw(error(self_provenance_bad_assertion(Assertion), context(self_provenance_retraction/4, "the assertion to retract must carry an id and a source"))) ),
    % A retraction may only be signed by the retracted record's own source; konnectome holds only its own identity.
    ( AssertionSource == Source
    % A self-signed assertion may be retracted.
    ->  true
    % An assertion by a foreign source cannot be retracted here - that would be forging another mind's exit.
    ;   throw(error(self_provenance_foreign_retraction(AssertionSource), context(self_provenance_retraction/4, "a retraction's source must be the retracted assertion's own source")))
    ),
    % Build the retraction: which assertion it withdraws, who withdraws it, when, and the advisory reason.
    Base = _{type: "retraction", retracts: AssertionId, source: Source, timestamp: Instant, reason: Reason},
    % Validate and content-address it as a retraction (reason is advisory, not identity-bearing).
    self_provenance_mint_(Base, retraction, Record).

% ---------------------------------------------------------------------------
% THE SUPERSEDE - the honest exit joined to a fresh, restated stance
% ---------------------------------------------------------------------------

% self_provenance_supersede(+Assertion, +NewEvidenceType, +NewConfidence, +Reason, +Instant, -Retraction, -NewAssertion):
% retract a prior assertion and restate the mind's stance about the SAME content under a new grade and confidence.
self_provenance_supersede(Assertion, NewEvidenceType, NewConfidence, Reason, Instant, Retraction, NewAssertion) :-
    % The new stance is about the very same content the old assertion was about; a dict lacking an 'about' cannot be superseded and is refused.
    ( get_dict(about, Assertion, About) -> true ; throw(error(self_provenance_bad_assertion(Assertion), context(self_provenance_supersede/7, "the assertion to supersede must carry an about"))) ),
    % First withdraw the old assertion - the honest exit.
    self_provenance_retraction(Assertion, Reason, Instant, Retraction),
    % Then restate the stance about the same content under the new grade and confidence.
    self_provenance_assertion(About, NewEvidenceType, NewConfidence, Instant, NewAssertion).
