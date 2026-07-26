% Declare the situation_appraisal module and the public interface of the appraisal pilot.
:- module(situation_appraisal, [
    % situation_appraisal_appraise/3: appraise a situation against one drive's defended set-point.
    situation_appraisal_appraise/3,
    % situation_appraisal_appraise_change/4: appraise what a situation does to a goal - good, bad, or neither.
    situation_appraisal_appraise_change/4,
    % situation_appraisal_valence/2: read the valence out of an appraisal term.
    situation_appraisal_valence/2,
    % situation_appraisal_record/4: own the appraisal on the record as an attitude of the standard's enumeration.
    situation_appraisal_record/4,
    % situation_appraisal_stance/3: the mind's graded stance on its own appraisal.
    situation_appraisal_stance/3,
    % situation_appraisal_retract/4: withdraw an appraisal the world proved wrong - the honest exit.
    situation_appraisal_retract/4
]).

% Reuse the drive system: an appraisal is nothing but the drives' own set-point error, read as good or bad.
:- use_module(library(drive_system), [
    % drive_system_error/3: one drive's current error, the distance from its set-point.
    drive_system_error/3
]).
% Reuse other minds: the same record family that minted a modelled belief mints an owned appraisal.
:- use_module(library(other_minds), [
    % other_minds_individual_record/3: mint the appraising mind as a token individual.
    other_minds_individual_record/3,
    % other_minds_content_record/5: mint the situation and its valence as a state assertion.
    other_minds_content_record/5,
    % other_minds_attitude_record/4: mint the appraisal as an attitude of the standard's own enumeration.
    other_minds_attitude_record/4
]).
% Reuse self provenance: the mind grades its appraisal and, when the world corrects it, takes it back.
:- use_module(library(self_provenance), [
    % self_provenance_assertion/5: assert about the appraisal, graded and weighted.
    self_provenance_assertion/5,
    % self_provenance_retraction/4: withdraw the appraisal under the same source.
    self_provenance_retraction/4
]).

% The situation_appraisal pack realizes the first of Rung Four's two remaining pilots: appraisal, a
% situation judged good or bad for the mind's OWN goals. It invents no emotion pathway. The book's
% claim is that the mind has the machinery of feeling by construction - drives that can be met or
% thwarted - so appraisal here is exactly the drive system's own set-point error, read through a
% valence: a situation that violates a defended set-point is a THREAT the mind fears; one that meets
% or advances it is GOOD. The ONE konnectome rule this pack adds is that reading: the map from a
% signed error, or a change in error, to a valence. The durable appraisal is owned on the record as
% an attitude of the standard's own closed enumeration - the same record family other_minds and
% empathy already use - graded through self_provenance and, like every honest claim, retractable
% when the world proves it wrong.
%
% AN HONEST COMPROMISE, STATED PLAINLY. The book names two appraisal affects: fear at a threat, and
% satisfaction at a met goal. The closed attitude enumeration (believes, desires, intends, knows,
% expects, fears) carries FEARS exactly - the clean fit empathy also uses - but it has NO word for
% satisfaction or contentment. So a met or goal-serving situation is approximated here as one the
% mind DESIRES to keep: not a perfect fit (desire is a wanting, and a met set-point is already had),
% but the nearest home the frozen enumeration offers. This gap is recorded as an OBSERVATION in the
% ledger, not forced silently: a future Causalontology enumeration could add a contentment attitude,
% and until then only the SHARED record approximates - the valence itself is computed exactly. This
% is a wording compromise inside an existing kind, not a new kind: nothing in a cousin is edited,
% and there is no eleventh component for emotion.

% situation_appraisal_appraise(+Drive, +Body, -Appraisal): appraise a situation against a defended set-point.
situation_appraisal_appraise(Drive, Body, Appraisal) :-
    % Read how far the situation stands from the drive's set-point.
    drive_system_error(Drive, Body, Error),
    % A situation exactly at the set-point is satisfying; any distance from it is a threat.
    situation_appraisal_error_valence(Error, Valence),
    % The appraisal carries its valence and the magnitude that justifies it.
    Appraisal = appraisal(Valence, Error).

% situation_appraisal_error_valence(+Error, -Valence): a met set-point is satisfying, a violated one threatening.
situation_appraisal_error_valence(Error, satisfied) :-
    % No distance from the set-point means the goal is met.
    Error =:= 0,
    % A met goal is a satisfying situation.
    !.
% Any non-zero distance from the set-point is a threat to the goal.
situation_appraisal_error_valence(_Error, threatened).

% situation_appraisal_appraise_change(+Drive, +BodyBefore, +BodyAfter, -Appraisal): appraise a situation's effect on a goal.
situation_appraisal_appraise_change(Drive, BodyBefore, BodyAfter, Appraisal) :-
    % The goal's error before the situation.
    drive_system_error(Drive, BodyBefore, ErrorBefore),
    % The goal's error after the situation.
    drive_system_error(Drive, BodyAfter, ErrorAfter),
    % A situation that lowers the error serves the goal; one that raises it harms the goal.
    Change is ErrorBefore - ErrorAfter,
    % Read the change as good, bad, or neither.
    situation_appraisal_change_valence(Change, Valence),
    % The magnitude of the effect, whichever way it went.
    Magnitude is abs(Change),
    % The appraisal carries its valence and the size of the effect.
    Appraisal = appraisal(Valence, Magnitude).

% situation_appraisal_change_valence(+Change, -Valence): error fell (good), rose (bad), or held (neutral).
situation_appraisal_change_valence(Change, good) :-
    % The situation reduced the distance to the set-point.
    Change > 0,
    % Serving the goal is good.
    !.
% A situation that raised the error harmed the goal.
situation_appraisal_change_valence(Change, bad) :-
    % The situation increased the distance to the set-point.
    Change < 0,
    % Harming the goal is bad.
    !.
% A situation that left the error unchanged is neither good nor bad.
situation_appraisal_change_valence(_Change, neutral).

% situation_appraisal_valence(+Appraisal, -Valence): read the valence out of an appraisal term.
situation_appraisal_valence(appraisal(Valence, _Magnitude), Valence).

% situation_appraisal_record(+SituationDesignator, +Valence, +Instant, -Record): own the appraisal as an attitude.
situation_appraisal_record(SituationDesignator, Valence, Instant, Record) :-
    % A valence the standard's enumeration can carry becomes an attitude the mind holds.
    situation_appraisal_attitude_of(Valence, AttitudeType),
    % The appraising mind is minted as a token individual - the holder of its own appraisal.
    other_minds_individual_record("agent", "konnectome", Individual),
    % Read the appraising mind's content-addressed identifier.
    get_dict(id, Individual, HolderIdentifier),
    % The valence names the value the state assertion carries, in the standard's string form.
    atom_string(Valence, ValenceText),
    % The appraised situation and its valence are minted as a state assertion.
    other_minds_content_record(HolderIdentifier, SituationDesignator, ValenceText, Instant, Content),
    % Read the content's identifier.
    get_dict(id, Content, ContentIdentifier),
    % The appraisal is the mind holding the standard's own attitude toward the situation.
    other_minds_attitude_record(HolderIdentifier, AttitudeType, ContentIdentifier, Record).

% situation_appraisal_attitude_of(+Valence, -AttitudeType): the closed enumeration's home for each valence.
situation_appraisal_attitude_of(threatened, "fears") :-
    % A threat to a set-point is feared.
    !.
% A bad turn for the goal is feared, the same way a threat is.
situation_appraisal_attitude_of(bad, "fears") :-
    % A situation that harmed the goal is feared.
    !.
% A met set-point has no dedicated home in the closed enumeration; it is approximated as a desire to keep it.
situation_appraisal_attitude_of(satisfied, "desires") :-
    % Satisfaction has no attitude of its own; the nearest fit is a wanting to keep the met goal (see the header note).
    !.
% A good turn for the goal is a situation the mind wants more of.
situation_appraisal_attitude_of(good, "desires") :-
    % A situation that served the goal is desired.
    !.
% A valence with no affective home - neutral, or anything unrecognised - cannot be owned as an attitude.
situation_appraisal_attitude_of(Valence, _AttitudeType) :-
    % Refuse to force a neutral or unknown valence into the standard's affective enumeration.
    throw(error(situation_appraisal_unrecordable_valence(Valence),
                context(situation_appraisal_record/4, "only a good or bad valence is owned as an attitude"))).

% situation_appraisal_stance(+Record, +Instant, -Stance): the mind stands behind its appraisal.
% The observation grade fits an appraisal of an ACTUAL, present situation - the mind read its own
% true set-point error. An appraisal of a merely projected or counterfactual situation would be
% simulation-graded evidence; this pilot grades the situations it actually lived, at observation.
situation_appraisal_stance(Record, Instant, Stance) :-
    % Read the appraisal's content-addressed identifier.
    get_dict(id, Record, Identifier),
    % The stance is graded observation: the mind read its own true set-point error to appraise.
    self_provenance_assertion(Identifier, "observation", 0.8, Instant, Stance).

% situation_appraisal_retract(+Stance, +Reason, +Instant, -Retraction): withdraw a mistaken appraisal.
situation_appraisal_retract(Stance, Reason, Instant, Retraction) :-
    % The same source that appraised takes it back - Rule 10, the honest exit.
    self_provenance_retraction(Stance, Reason, Instant, Retraction).
