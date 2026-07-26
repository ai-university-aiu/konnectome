% Load the module under test from the library path.
:- use_module(library(situation_appraisal)).
% Load the Prolog Unit test framework.
:- use_module(library(plunit)).
% Load the drive system so the tests can check the appraisal against the error independently.
:- use_module(library(drive_system), [
    % drive_system_error/3: re-derive the set-point error the appraisal claims to read.
    drive_system_error/3
]).

% situation_appraisal_test_instant(-Instant): the fixed instant, so every minted record is deterministic.
situation_appraisal_test_instant("2026-07-26T00:00:00Z").

% situation_appraisal_test_drive(-Drive): the temperature drive defending thirty-seven, as elsewhere in the mind.
situation_appraisal_test_drive(drive(temperature, temperature, 37, none)).

% Open the situation_appraisal test block.
:- begin_tests(situation_appraisal).

% A situation exactly at the set-point is appraised as satisfying.
test(met_set_point_is_satisfying) :-
    % The temperature drive defends thirty-seven.
    situation_appraisal_test_drive(Drive),
    % A body sitting at the set-point.
    situation_appraisal_appraise(Drive, [temperature-37], Appraisal),
    % The valence is satisfaction.
    situation_appraisal_valence(Appraisal, Valence),
    % The met set-point reads as satisfied.
    assertion(Valence == satisfied),
    % The appraisal carries a zero magnitude.
    assertion(Appraisal == appraisal(satisfied, 0)).

% A situation away from the set-point is appraised as a threat.
test(violated_set_point_is_threatening) :-
    % The temperature drive defends thirty-seven.
    situation_appraisal_test_drive(Drive),
    % A body three degrees too warm.
    situation_appraisal_appraise(Drive, [temperature-40], Appraisal),
    % The valence is a threat.
    situation_appraisal_valence(Appraisal, Valence),
    % The violated set-point reads as threatened.
    assertion(Valence == threatened),
    % The magnitude is the set-point error itself.
    assertion(Appraisal == appraisal(threatened, 3)).

% The appraisal's magnitude is exactly the drive's own error - the appraisal invents no new number.
test(appraisal_magnitude_is_the_drive_error) :-
    % The temperature drive defends thirty-seven.
    situation_appraisal_test_drive(Drive),
    % Appraise a too-warm body.
    situation_appraisal_appraise(Drive, [temperature-41], appraisal(_, Magnitude)),
    % Read the drive's error over the same body, independently.
    drive_system_error(Drive, [temperature-41], Error),
    % The appraisal's magnitude is the drive's own error, number for number.
    assertion(Magnitude =:= Error).

% A situation that moves the body toward its set-point is appraised good.
test(situation_toward_the_set_point_is_good) :-
    % The temperature drive defends thirty-seven.
    situation_appraisal_test_drive(Drive),
    % From a too-warm body to the set-point.
    situation_appraisal_appraise_change(Drive, [temperature-40], [temperature-37], Appraisal),
    % The valence is good.
    situation_appraisal_valence(Appraisal, Valence),
    % Serving the goal reads as good.
    assertion(Valence == good),
    % The magnitude is the whole error it relieved.
    assertion(Appraisal == appraisal(good, 3)).

% A situation that moves the body away from its set-point is appraised bad.
test(situation_away_from_the_set_point_is_bad) :-
    % The temperature drive defends thirty-seven.
    situation_appraisal_test_drive(Drive),
    % From the set-point out to a too-warm body.
    situation_appraisal_appraise_change(Drive, [temperature-37], [temperature-40], Appraisal),
    % The valence is bad.
    situation_appraisal_valence(Appraisal, Valence),
    % Harming the goal reads as bad.
    assertion(Valence == bad),
    % The magnitude is the whole error it caused.
    assertion(Appraisal == appraisal(bad, 3)).

% A situation that leaves the goal's error unchanged is appraised neutral.
test(situation_with_no_effect_is_neutral) :-
    % The temperature drive defends thirty-seven.
    situation_appraisal_test_drive(Drive),
    % Two equally-distant bodies leave the error unchanged.
    situation_appraisal_appraise_change(Drive, [temperature-39], [temperature-35], Appraisal),
    % The valence is neutral.
    situation_appraisal_valence(Appraisal, Valence),
    % No change to the goal reads as neither good nor bad.
    assertion(Valence == neutral),
    % The magnitude is zero.
    assertion(Appraisal == appraisal(neutral, 0)).

% A threatening appraisal is owned as the standard's fears attitude.
test(threat_is_owned_as_a_fears_attitude) :-
    % The fixed instant stamps the record.
    situation_appraisal_test_instant(Instant),
    % Own a threat to the warmth goal on the record.
    situation_appraisal_record("the_room_grew_hot", threatened, Instant, Record),
    % The attitude is the standard's own fears.
    get_dict(attitude_type, Record, AttitudeType),
    % A threat is feared.
    assertion(AttitudeType == "fears").

% A good appraisal is owned as the standard's desires attitude.
test(good_is_owned_as_a_desires_attitude) :-
    % The fixed instant stamps the record.
    situation_appraisal_test_instant(Instant),
    % Own a good turn for the warmth goal on the record.
    situation_appraisal_record("the_room_cooled", good, Instant, Record),
    % The attitude is the standard's own desires.
    get_dict(attitude_type, Record, AttitudeType),
    % A good situation is desired.
    assertion(AttitudeType == "desires").

% The owned appraisal is content-addressed: the same appraisal, told twice, mints the same identifier.
test(owned_appraisal_is_reproducible) :-
    % The fixed instant stamps both tellings.
    situation_appraisal_test_instant(Instant),
    % Mint the appraisal once.
    situation_appraisal_record("the_room_grew_hot", threatened, Instant, First),
    % Mint the byte-identical appraisal again.
    situation_appraisal_record("the_room_grew_hot", threatened, Instant, Second),
    % Read the first identifier.
    get_dict(id, First, FirstIdentifier),
    % Read the second identifier.
    get_dict(id, Second, SecondIdentifier),
    % Content-addressing makes the two identifiers identical.
    assertion(FirstIdentifier == SecondIdentifier).

% Two float situations equidistant on opposite sides of the set-point leave the goal unchanged: neutral, not a rounding-noise good or bad.
test(equidistant_float_change_is_neutral) :-
    % A drive defending a set-point that the float bodies straddle exactly.
    Drive = drive(temperature, temperature, 3, none),
    % Before and after sit 3.48 from the set-point on opposite sides - mathematically no change.
    situation_appraisal_appraise_change(Drive, [temperature-6.48], [temperature-(-0.48)], Appraisal),
    % Read the valence.
    situation_appraisal_valence(Appraisal, Valence),
    % A change that is only floating-point residue is read as no change at all.
    assertion(Valence == neutral).

% That same rounding-noise change is refused as an attitude, never minted as a false good or bad.
test(equidistant_float_change_is_unrecordable, throws(error(situation_appraisal_unrecordable_valence(neutral), _))) :-
    % A drive whose set-point the float bodies straddle exactly.
    Drive = drive(temperature, temperature, 3, none),
    % The fixed instant stamps the attempt.
    situation_appraisal_test_instant(Instant),
    % The equidistant change appraises neutral.
    situation_appraisal_appraise_change(Drive, [temperature-6.48], [temperature-(-0.48)], appraisal(Valence, _)),
    % And a neutral appraisal cannot be owned as an attitude - the refusal must fire, not a false mint.
    situation_appraisal_record("the_equidistant_shift", Valence, Instant, _Record).

% A neutral valence has no affective home and is refused as an attitude.
test(neutral_valence_is_unrecordable, throws(error(situation_appraisal_unrecordable_valence(neutral), _))) :-
    % The fixed instant stamps the attempt.
    situation_appraisal_test_instant(Instant),
    % A neutral appraisal cannot be forced into the standard's affective enumeration.
    situation_appraisal_record("the_room_was_unchanged", neutral, Instant, _Record).

% The mind stands behind its appraisal on observation evidence.
test(stance_is_graded_observation) :-
    % The fixed instant stamps the stance.
    situation_appraisal_test_instant(Instant),
    % Own a threat on the record.
    situation_appraisal_record("the_room_grew_hot", threatened, Instant, Record),
    % The mind grades its own appraisal.
    situation_appraisal_stance(Record, Instant, Stance),
    % The stance is graded observation - the mind read its own true state to appraise.
    get_dict(evidence_type, Stance, Grade),
    % The grade is observation.
    assertion(Grade == "observation"),
    % The stance is about the appraisal it grades.
    get_dict(about, Stance, About),
    % Read the appraisal's identifier.
    get_dict(id, Record, RecordIdentifier),
    % The stance names the appraisal, byte for byte.
    assertion(About == RecordIdentifier).

% A mistaken appraisal is withdrawn under the same source - the honest exit.
test(mistaken_appraisal_is_retracted) :-
    % The fixed instant stamps the stance and its withdrawal.
    situation_appraisal_test_instant(Instant),
    % Own a threat on the record.
    situation_appraisal_record("the_room_grew_hot", threatened, Instant, Record),
    % Stand behind it.
    situation_appraisal_stance(Record, Instant, Stance),
    % The threat turns out to be nothing, so the appraisal is withdrawn.
    situation_appraisal_retract(Stance, "the reading was a fault; the room was fine", Instant, Retraction),
    % The withdrawal targets the very stance it takes back.
    get_dict(retracts, Retraction, Retracts),
    % Read the stance's identifier.
    get_dict(id, Stance, StanceIdentifier),
    % The retraction names the stance, byte for byte.
    assertion(Retracts == StanceIdentifier).

% Close the situation_appraisal test block.
:- end_tests(situation_appraisal).
