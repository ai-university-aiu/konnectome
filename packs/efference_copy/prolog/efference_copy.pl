% Declare this file as the 'efference_copy' module and list the predicates it exports.
:- module(efference_copy, [
    % efference_copy_channels/1: the sensory channels the forward model makes a prediction for.
    efference_copy_channels/1,
    % efference_copy_of/2: take the internal duplicate of an outgoing command.
    efference_copy_of/2,
    % efference_copy_command/2: read the command back out of a copy.
    efference_copy_command/2,
    % efference_copy_forward_model/3: the predicted sensory consequences of the copied command.
    efference_copy_forward_model/3,
    % efference_copy_actual/2: the sensory reality the body reports, on the same channels.
    efference_copy_actual/2,
    % efference_copy_residuals/3: the per-channel departure of reality from the prediction.
    efference_copy_residuals/3,
    % efference_copy_attenuated/3: the corpus's subtraction - report only what the world did.
    efference_copy_attenuated/3,
    % efference_copy_match_cue/3: the graded prediction-match CUE, which is not a verdict.
    efference_copy_match_cue/3,
    % efference_copy_agency_judgement/2: the refusal, written into the code so it cannot be forgotten.
    efference_copy_agency_judgement/2,
    % efference_copy_step/5: one closed pass - copy, predict, act, let the world act, compare.
    efference_copy_step/5,
    % efference_copy_report_cue/2: read the cue out of a step's report.
    efference_copy_report_cue/2,
    % efference_copy_report_attenuated/2: read the attenuated percepts out of a step's report.
    efference_copy_report_attenuated/2,
    % efference_copy_report_residuals/2: read the per-channel residuals out of a step's report.
    efference_copy_report_residuals/2
]).

% Import the comparator archetype, which is the one place a signed error is computed in this build.
:- use_module(library(archetype), [archetype_comparator/3]).
% Import the stand-in machine whose documented physics this pack's forward model predicts.
:- use_module(library(simulated_body), [
    simulated_body_camera/2,
    simulated_body_physical/2,
    simulated_body_enact/3,
    simulated_body_drain/3,
    simulated_body_show/4
]).
% Import the list utilities used to read and rebuild channel readings.
:- use_module(library(lists), [memberchk/2, append/3]).
% Import the type checker that refuses a hole aloud.
:- use_module(library(error), [domain_error/2]).

% ---------------------------------------------------------------------------
% WHAT THIS PACK IS
% ---------------------------------------------------------------------------
%
% This is THE_NEUROSCIENCE_OF_COGNITION_MANUSCRIPT.txt CHAPTER 63.2.1, COMPARATOR MODELS OF THE SENSE
% OF AGENCY, in the north-star directory of the Twentieth Commandment. The chapter's mechanism, in its
% own words: "When the brain issues a motor command it also generates an efference copy, an internal
% duplicate of that command, and feeds it to a forward model - a circuit that predicts what the
% sensory consequences of the movement will be. The prediction is then compared with the actual
% sensory feedback. When prediction and feedback match, the movement is tagged as self-produced, the
% resulting sensation is attenuated ... and agency is felt. When they mismatch, the action is flagged
% as externally caused."
%
% THE QUEUE CALLED THIS A WIRING SLICE AND IT WAS RIGHT ABOUT THE MECHANISM. Every part already
% existed: archetype_comparator/3 computes a signed error, body_interface_command/2 issues the
% commands, simulated_body_enact/3 carries them out, and simulated_body's own clauses state what each
% command does to the machine. NOTHING HERE IS INVENTED. The forward model is a transcription of
% simulated_body_drive/3, read out of the sibling pack rather than guessed at.
%
% AND IT WAS WRONG ABOUT THE OUTPUT, WHICH IS THIS SLICE'S FINDING. The queue asked for a
% "comparator-based SENSE OF AGENCY". THE CHAPTER THAT SUPPLIES THE COMPARATOR ALSO REFUSES THAT
% CONCLUSION, in its own closing sentence and again two sections later, and konnectome's own running
% code then reproduces the refusal from the other side. That is DECISION-13 and OBSERVATION-17 below.

% ---------------------------------------------------------------------------
% DECISION-13 - THE COMPARATOR PUBLISHES A CUE, AND REFUSES TO PUBLISH A VERDICT OF AGENCY
% ---------------------------------------------------------------------------
%
% THE CHAPTER SAYS SO ITSELF, AND IT IS THE LAST THING IT SAYS. Chapter 63.2.1's closing sentence:
% "The model is elegant and explains a lot, but it has serious critics: Shaun Gallagher has argued it
% cannot be extended to agency over thoughts without an infinite regress of intentions, and a 2019
% analysis in Neuroscience of Consciousness argued that A MERE PREDICTION MATCH IS NOT BY ITSELF
% SUFFICIENT TO GENERATE A FELT SENSE OF AGENCY."
%
% AND CHAPTER 63.2.4 STATES THE REPLACEMENT RATHER THAN LEAVING A HOLE. "This cue-integration framing
% has largely absorbed the comparator model rather than replacing it: PREDICTION IS ONE CUE AMONG
% SEVERAL, WEIGHTED MORE HEAVILY WHEN IT IS RELIABLE." Synofzik, Vosgerau and Newen's two-step account
% separates a low-level FEELING of agency from a higher-level explicit JUDGEMENT, "with each fed by a
% weighted mixture of internal sensorimotor cues and external contextual cues". Wegner's account adds
% the three conditions - a thought that PRECEDES the action, is CONSISTENT with it, and no OTHER cause
% apparent.
%
% SO KONNECTOME DECIDES: THIS PACK PUBLISHES THE PREDICTION-MATCH CUE AND STOPS THERE. It computes the
% residual, it attenuates the predicted part of the sensation, and it reports how much of the sensed
% world its own command accounts for. IT DOES NOT RETURN self_produced OR externally_caused, because
% the north star says in as many words that the quantity it holds is not sufficient to decide that.
%
% AND THE REFUSAL IS WRITTEN INTO THE CODE RATHER THAN ONLY INTO THIS COMMENT.
% efference_copy_agency_judgement/2 exists, is exported, and throws by name. That is the Sixteenth
% Commandment's strongest honest move - "REFUSE ALOUD IN THE CODE, so the impossible case throws a
% named error instead of returning a plausible answer" - and it is used here because the plausible
% answer is genuinely one line away and would pass every test in this pack.
%
% WHAT WOULD HAVE BEEN INVENTED IF IT HAD NOT REFUSED, NAMED SO THE HOLE IS VISIBLE. A MATCH
% TOLERANCE: how close a match must be before the movement counts as self-produced. NOTHING IN THE
% NORTH-STAR DIRECTORY STATES ONE. Under the Twenty-First Commandment's order of resort this is the
% THIRD PROTOCOL, REFUSAL, and it is the right answer here because the build can proceed honestly
% without the number: every consumer this pack has today wants the residual, not the verdict.
%
% WHAT DECISION-13 DOES NOT DECIDE.
%
% IT DOES NOT DECIDE THE CUE WEIGHTS. Chapter 63.2.4 says cues are "weighted more heavily when
% reliable" and states no weight. konnectome has exactly one cue, so there is nothing yet to weigh.
%
% IT DOES NOT BUILD THE SECOND CUE. Wegner's priority, consistency and exclusivity are three testable
% conditions and none is built. The naming of them here is the periodic table's declared hole.
%
% IT DOES NOT SPLIT THE FEELING FROM THE JUDGEMENT. Synofzik's two levels are one construct here.
%
% AND IT DOES NOT CLAIM THE FORWARD MODEL IS LEARNED. LAYER_10_SYSTEMS_MANUSCRIPT says of
% sensorimotor_body_loop that it differs from a closed-loop motion controller in that "ITS PLANT MODEL
% IS LEARNED and its gains are neuromodulated". KONNECTOME'S FORWARD MODEL IS STATED, NOT LEARNED - it
% is a transcription of the machine's own actuator clauses. That is an honest non-closure and is
% recorded rather than glossed: nothing here acquires its model from experience.

% ---------------------------------------------------------------------------
% OBSERVATION-17 - THE NULL COMMAND SCORES A PERFECT MATCH
% ---------------------------------------------------------------------------
%
% hold_still is a real actuator command in this build: simulated_body carries it, and
% body_interface_command/2 maps the selector's "nothing" outcome onto it. Its documented effect is
% that nothing changes but the log. SO THE FORWARD MODEL'S PREDICTION FOR IT IS THE WORLD EXACTLY AS
% IT ALREADY STANDS - and in a still world that prediction is perfect on every channel.
%
% A COMPARATOR-ONLY SENSE OF AGENCY WOULD THEREFORE AWARD MAXIMUM AUTHORSHIP FOR DOING NOTHING, and it
% would do so with a total match, the highest score the mechanism can produce. The machine would be
% most certain it was the author of the world at precisely the moment it had not acted on it.
%
% THIS IS THE 2019 CRITIQUE ARRIVING FROM THE OTHER DIRECTION, WHICH IS WHY IT IS RECORDED AS AN
% OBSERVATION RATHER THAN FIXED. The chapter argues from the psychology that a prediction match is not
% sufficient for felt agency. konnectome, having built the comparator faithfully, finds a case where
% the match is total and the authorship is vacuous - and it finds it in the ordinary operation of a
% command the build already ships, not in a contrived input.
%
% IT WOULD NOT HAVE FAILED. That is the fifth consecutive finding of this shape in this build and the
% sixth overall: a boundary that could never be crossed, a zero that reads as calm, a threshold decided
% by binary rounding, a table row that is not a transition, a clip that annihilates - and now a match
% that is perfect because nothing happened. Every test would have been green.
%
% THE CLOSER IS NAMED AND IS NOT BUILT HERE. Agency needs a cue that distinguishes "the world matched
% my prediction BECAUSE I CAUSED IT" from "the world matched my prediction BECAUSE NOTHING WAS GOING
% TO HAPPEN ANYWAY". That is Wegner's EXCLUSIVITY condition - no other cause apparent - and it is a
% second cue rather than a repair to this one. A test in this pack pins the degenerate case so that a
% later session meets a recorded finding rather than a comfortable number.

% ---------------------------------------------------------------------------
% THE CHANNELS
% ---------------------------------------------------------------------------
%
% The forward model predicts on exactly the channels the machine reports: the camera's path reading
% and the physical state's battery charge. THE LIST IS DECLARED IN ONE PLACE so a channel added to
% the body without a prediction for it is caught by a refusal rather than silently unpredicted.

% efference_copy_channels(-Channels): the sensory channels a prediction must cover, in a fixed order.
efference_copy_channels([path_ahead, battery_charge]).

% ---------------------------------------------------------------------------
% THE COPY ITSELF
% ---------------------------------------------------------------------------
%
% The copy is a DUPLICATE and not a diversion: the command still goes to the actuator unchanged, and
% the copy travels beside it. The corpus's word is "an internal duplicate of that command".

% efference_copy_of(+Command, -Copy): take the internal duplicate of an outgoing command.
efference_copy_of(Command, Copy) :-
    % An unbound command is a hole, and a hole is refused before anything is copied from it.
    (   var(Command)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % Only a command the actuators actually carry may be copied; anything else is refused by name.
    (   memberchk(Command, [steer_around, recharge, hold_still])
    ->  true
    ;   domain_error(efference_copy_command, Command)
    ),
    % The copy carries the command and nothing else.
    Copy = efference_copy(Command).

% efference_copy_command(+Copy, -Command): read the command back out of a copy.
efference_copy_command(Copy, Command) :-
    % An unbound copy is a hole.
    (   var(Copy)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % A term that is not a copy is refused aloud, naming what arrived.
    (   Copy = efference_copy(Command)
    ->  true
    ;   domain_error(efference_copy, Copy)
    ).

% ---------------------------------------------------------------------------
% THE FORWARD MODEL
% ---------------------------------------------------------------------------
%
% THIS IS A TRANSCRIPTION OF simulated_body_drive/3 AND OF NOTHING ELSE. Each clause below states what
% that pack's matching clause does, in the same words its comment uses. If the machine's physics ever
% changes, this model becomes wrong - which is exactly the relationship a forward model has to a plant,
% and is why it is written as a prediction rather than as a call into the body.

% efference_copy_forward_model(+Copy, +Body0, -Predicted): the predicted sensory consequences.
efference_copy_forward_model(Copy, Body0, Predicted) :-
    % Read the command out of the copy, refusing a hole or an impostor.
    efference_copy_command(Copy, Command),
    % The prediction starts from the world as the mind currently senses it.
    efference_copy_actual(Body0, Before),
    % And the command's own documented effect is applied to it.
    efference_copy_predict(Command, Before, Predicted).

% efference_copy_predict(+Command, +Before, -Predicted): apply one command's documented effect.
% Steering around clears a seen obstacle, so the path is predicted to read clear.
efference_copy_predict(steer_around, Before, Predicted) :-
    % Commit once the command's name matches.
    !,
    % The machine's own clause writes path_ahead as clear.
    efference_copy_put(Before, path_ahead, clear, Predicted).
% Recharging fills the battery back to its full charge, capped there.
efference_copy_predict(recharge, Before, Predicted) :-
    % Commit once the command's name matches.
    !,
    % The machine's own clause writes battery_charge as one full charge.
    efference_copy_put(Before, battery_charge, 1.0, Predicted).
% Holding still changes nothing but the log, and the log is not a sensory channel.
efference_copy_predict(hold_still, Before, Before) :-
    % Commit once the command's name matches. THIS CLAUSE IS OBSERVATION-17's whole subject: the
    % prediction for doing nothing is the world exactly as it stands, which a still world satisfies
    % perfectly.
    !.

% efference_copy_put(+Pairs0, +Key, +Value, -Pairs): replace one channel's reading, keeping the order.
efference_copy_put([], Key, _Value, _Pairs) :-
    % A channel the readings do not carry is refused rather than quietly appended.
    domain_error(efference_copy_channel, Key).
% Replace the matching channel's reading.
efference_copy_put([Key-_Old|Rest], Key, Value, [Key-Value|Rest]) :-
    % Commit once the channel matches.
    !.
% Keep a non-matching channel and continue.
efference_copy_put([Other|Rest0], Key, Value, [Other|Rest]) :-
    % Walk past the channel that is not the one being written.
    efference_copy_put(Rest0, Key, Value, Rest).

% ---------------------------------------------------------------------------
% READING SENSORY REALITY
% ---------------------------------------------------------------------------

% efference_copy_actual(+Body, -Readings): the sensory reality the body reports, channel by channel.
efference_copy_actual(Body, Readings) :-
    % The camera's readings, through the machine's own interface.
    simulated_body_camera(Body, Camera),
    % The physical state's readings, through the machine's own interface.
    simulated_body_physical(Body, Physical),
    % Both streams together are what the mind senses.
    append(Camera, Physical, Both),
    % Gather them in the declared channel order, refusing a channel the body does not report.
    efference_copy_channels(Channels),
    % Walk the declared channels and read each one.
    efference_copy_gather(Channels, Both, Readings).

% efference_copy_gather(+Channels, +Both, -Readings): read each declared channel, or refuse aloud.
efference_copy_gather([], _Both, []).
% Each declared channel must be present in what the body reports.
efference_copy_gather([Key|Rest], Both, [Key-Value|Readings]) :-
    % A declared channel the body does not report is a gap, and a gap is refused rather than filled.
    (   memberchk(Key-Value, Both)
    ->  true
    ;   domain_error(efference_copy_channel, Key)
    ),
    % Read the remaining channels.
    efference_copy_gather(Rest, Both, Readings).

% ---------------------------------------------------------------------------
% THE COMPARISON
% ---------------------------------------------------------------------------
%
% THE SIGNED ERROR IS COMPUTED BY archetype_comparator/3 AND NOWHERE ELSE, because that predicate is
% this build's single statement of what a comparator is. NOTE ITS ARGUMENT ORDER, which is a trap:
% archetype_comparator(Expected, Actual, Error) computes Actual minus Expected. The prediction is the
% expectation, so the prediction goes first.

% efference_copy_residuals(+Predicted, +Actual, -Residuals): the per-channel departure of reality.
efference_copy_residuals(Predicted, Actual, Residuals) :-
    % Refuse two reading sets that do not cover the same channels in the same order.
    efference_copy_check_aligned(Predicted, Actual),
    % Compare them channel by channel.
    efference_copy_compare(Predicted, Actual, Residuals).

% efference_copy_check_aligned(+Predicted, +Actual): the two reading sets cover the same channels.
efference_copy_check_aligned(Predicted, Actual) :-
    % The keys of the prediction.
    efference_copy_keys(Predicted, PredictedKeys),
    % The keys of the sensed reality.
    efference_copy_keys(Actual, ActualKeys),
    % A comparison across two different channel sets would compare a reading with a hole.
    (   PredictedKeys == ActualKeys
    ->  true
    ;   domain_error(efference_copy_aligned_channels, PredictedKeys-ActualKeys)
    ).

% efference_copy_keys(+Readings, -Keys): the channel names of a reading set, in order.
efference_copy_keys([], []).
% Take each channel's name.
efference_copy_keys([Key-_Value|Rest0], [Key|Rest]) :-
    % Take the remaining names.
    efference_copy_keys(Rest0, Rest).

% efference_copy_compare(+Predicted, +Actual, -Residuals): one residual per channel.
efference_copy_compare([], [], []).
% A numeric channel departs by a signed amount, computed by the comparator archetype.
efference_copy_compare([Key-Expected|PredictedRest], [Key-Got|ActualRest], [Residual|Rest]) :-
    % Both readings of a numeric channel are numbers, so the comparator archetype applies.
    number(Expected),
    number(Got),
    % Commit to the numeric reading of this channel.
    !,
    % The signed error: actual minus expected, in the one place this build computes such a thing.
    archetype_comparator(Expected, Got, Error),
    % A zero error is a match; anything else is a departure carrying its own magnitude.
    (   Error =:= 0
    ->  Residual = residual(Key, matched)
    ;   Residual = residual(Key, departed_by(Error))
    ),
    % Compare the remaining channels.
    efference_copy_compare(PredictedRest, ActualRest, Rest).
% A symbolic channel either reads as predicted or does not, and there is no magnitude to report.
efference_copy_compare([Key-Expected|PredictedRest], [Key-Got|ActualRest], [Residual|Rest]) :-
    % Commit to the symbolic reading of this channel.
    !,
    % A symbolic match is exact identity; NOTHING HERE INVENTS A DISTANCE BETWEEN TWO NAMES.
    (   Expected == Got
    ->  Residual = residual(Key, matched)
    ;   Residual = residual(Key, departed(Expected, Got))
    ),
    % Compare the remaining channels.
    efference_copy_compare(PredictedRest, ActualRest, Rest).

% ---------------------------------------------------------------------------
% ATTENUATION - REPORT ONLY WHAT THE WORLD DID
% ---------------------------------------------------------------------------
%
% THE CORPUS STATES THIS MECHANISM SUBTRACTIVELY AND KONNECTOME TAKES IT AT ITS WORD, so no attenuation
% gain has to be chosen. LAYER_06_MODES_MANUSCRIPT, the Own-Move Subtractor: "vestibular-only cells
% SUBTRACT AN EFFERENCE COPY of a self-generated head turn and REPORT ONLY WHAT THE WORLD DID."
% LAYER_09_NATURES_COGNITIVE_ARCHITECTURE_MANUSCRIPT says the same of touch: "self-touch attenuated by
% efference copy."
%
% SO THE ATTENUATED PERCEPT IS THE RESIDUAL, AND A FULLY PREDICTED CHANNEL DISAPPEARS ENTIRELY. That
% is the chapter's "which is why you cannot tickle yourself" as a property of the arithmetic rather
% than as a special case: a self-generated sensation the model predicted exactly has nothing left over
% to report. THE ATTENUATION GAIN IS NOT KONNECTOME'S INVENTION BECAUSE THERE IS NO GAIN - the corpus
% asked for a subtraction and a subtraction is what this is.

% efference_copy_attenuated(+Predicted, +Actual, -Attenuated): what is left after the copy is subtracted.
efference_copy_attenuated(Predicted, Actual, Attenuated) :-
    % Compare the two reading sets, which refuses a misaligned pair on the way in.
    efference_copy_residuals(Predicted, Actual, Residuals),
    % Keep only the channels that departed, carrying what departed on each.
    efference_copy_surviving(Residuals, Attenuated).

% efference_copy_surviving(+Residuals, -Attenuated): a matched channel is fully cancelled and drops out.
efference_copy_surviving([], []).
% A matched channel reports nothing at all - the self-generated part is gone.
efference_copy_surviving([residual(_Key, matched)|Rest0], Rest) :-
    % Commit: there is nothing left of a perfectly predicted channel to pass upward.
    !,
    % Carry on with the remaining channels.
    efference_copy_surviving(Rest0, Rest).
% A numeric channel passes on the amount by which the world departed, and only that amount.
efference_copy_surviving([residual(Key, departed_by(Error))|Rest0], [Key-Error|Rest]) :-
    % Commit to the numeric departure.
    !,
    % Carry on with the remaining channels.
    efference_copy_surviving(Rest0, Rest).
% A symbolic channel passes on what the world actually shows, since a name has no residue.
efference_copy_surviving([residual(Key, departed(_Expected, Got))|Rest0], [Key-Got|Rest]) :-
    % Carry on with the remaining channels.
    efference_copy_surviving(Rest0, Rest).

% ---------------------------------------------------------------------------
% THE CUE
% ---------------------------------------------------------------------------

% efference_copy_match_cue(+Predicted, +Actual, -Cue): the graded prediction-match cue.
efference_copy_match_cue(Predicted, Actual, Cue) :-
    % Compare the two reading sets, which refuses a misaligned pair on the way in.
    efference_copy_residuals(Predicted, Actual, Residuals),
    % Count the channels that matched and the channels that departed.
    efference_copy_tally(Residuals, 0, Matched, 0, Departed),
    % The cue carries its counts and NOT a verdict, which is DECISION-13 in one term.
    Cue = match_cue(matched(Matched), departed(Departed)).

% efference_copy_tally(+Residuals, +Matched0, -Matched, +Departed0, -Departed): count the two outcomes.
efference_copy_tally([], Matched, Matched, Departed, Departed).
% A matched channel raises the matched count.
efference_copy_tally([residual(_Key, matched)|Rest], Matched0, Matched, Departed0, Departed) :-
    % Commit to the match.
    !,
    % Raise the matched count.
    Matched1 is Matched0 + 1,
    % Count the remaining channels.
    efference_copy_tally(Rest, Matched1, Matched, Departed0, Departed).
% Any other outcome is a departure and raises the departed count.
efference_copy_tally([_Residual|Rest], Matched0, Matched, Departed0, Departed) :-
    % Raise the departed count.
    Departed1 is Departed0 + 1,
    % Count the remaining channels.
    efference_copy_tally(Rest, Matched0, Matched, Departed1, Departed).

% ---------------------------------------------------------------------------
% THE REFUSAL, WRITTEN INTO THE CODE
% ---------------------------------------------------------------------------

% efference_copy_agency_judgement(+Cue, -Verdict): DECISION-13's refusal, and it always throws.
efference_copy_agency_judgement(Cue, _Verdict) :-
    % There is a one-line plausible answer here and this predicate exists to make sure nobody writes
    % it without arguing for it first. Chapter 63.2.1: a mere prediction match is not by itself
    % sufficient to generate a felt sense of agency. Chapter 63.2.4: prediction is one cue among
    % several. konnectome holds one cue and no weights, so it has nothing to judge with.
    throw(error(efference_copy_agency_is_not_a_comparator_output(Cue),
                context(efference_copy_agency_judgement/2,
                        "DECISION-13: the comparator publishes a cue; a verdict of agency needs cue integration konnectome has not built"))).

% ---------------------------------------------------------------------------
% THE CLOSED PASS
% ---------------------------------------------------------------------------
%
% THE WORLD'S OWN ACT IS THE CALLER'S ARGUMENT AND NOTHING HERE PRODUCES IT, in the same discipline
% renewal_loop uses for its inhibition verdict and the blackboard uses for its gate verdict. The whole
% point of the comparator is to separate what the mind did from what the world did, so a pack that
% invented the world's contribution would be answering its own question.

% efference_copy_step(+Body0, +Command, +WorldEvent, -Body, -Report): one closed comparator pass.
efference_copy_step(Body0, Command, WorldEvent, Body, Report) :-
    % THE COPY IS TAKEN AT THE MOMENT THE COMMAND IS ISSUED, before anything moves.
    efference_copy_of(Command, Copy),
    % THE FORWARD MODEL PREDICTS, from the world as it stands and the command's documented effect.
    efference_copy_forward_model(Copy, Body0, Predicted),
    % ACTION OUT: the command reaches the actuator unchanged - the copy was a duplicate, not a diversion.
    simulated_body_enact(Body0, Command, Acted),
    % AND THEN THE WORLD ACTS ON ITS OWN ACCOUNT, which is the thing the comparator exists to isolate.
    efference_copy_world(WorldEvent, Acted, Body),
    % PERCEPTION IN: what the machine now reports on the declared channels.
    efference_copy_actual(Body, Actual),
    % The per-channel departure of reality from the prediction.
    efference_copy_residuals(Predicted, Actual, Residuals),
    % What survives the subtraction - only what the world did.
    efference_copy_attenuated(Predicted, Actual, Attenuated),
    % The graded cue, which is not a verdict.
    efference_copy_match_cue(Predicted, Actual, Cue),
    % One glass-box report per pass, carrying every intermediate a reader would want to check.
    Report = efference_copy_report(Copy, Predicted, Actual, Residuals, Attenuated, Cue).

% efference_copy_world(+WorldEvent, +Body0, -Body): let the world take its own turn.
% A still world does nothing, and says so by name rather than by omission.
efference_copy_world(still, Body, Body) :-
    % Commit once the event's name matches.
    !.
% Time passing drains the battery, through the machine's own physics.
efference_copy_world(drain(Amount), Body0, Body) :-
    % Commit once the event's name matches.
    !,
    % The machine's own drain, refusals and floor included.
    simulated_body_drain(Body0, Amount, Body).
% The world putting something in the path, through the machine's own camera interface.
efference_copy_world(shows(Key, Value), Body0, Body) :-
    % Commit once the event's name matches.
    !,
    % The machine's own show, which refuses an unnamed sight.
    simulated_body_show(Body0, Key, Value, Body).
% Anything else is refused by name rather than treated as a still world.
efference_copy_world(WorldEvent, _Body0, _Body) :-
    % AN UNRECOGNISED WORLD EVENT READ AS STILLNESS WOULD CREDIT THE MIND WITH A WORLD IT DID NOT
    % PREDICT, which is the unbound-wrong-judgement lens exactly.
    domain_error(efference_copy_world_event, WorldEvent).

% ---------------------------------------------------------------------------
% READING A REPORT
% ---------------------------------------------------------------------------

% efference_copy_report_cue(+Report, -Cue): read the cue out of a step's report.
efference_copy_report_cue(Report, Cue) :-
    % Open the report, refusing an impostor.
    efference_copy_open_report(Report, _Copy, _Predicted, _Actual, _Residuals, _Attenuated, Cue).

% efference_copy_report_attenuated(+Report, -Attenuated): read the attenuated percepts.
efference_copy_report_attenuated(Report, Attenuated) :-
    % Open the report, refusing an impostor.
    efference_copy_open_report(Report, _Copy, _Predicted, _Actual, _Residuals, Attenuated, _Cue).

% efference_copy_report_residuals(+Report, -Residuals): read the per-channel residuals.
efference_copy_report_residuals(Report, Residuals) :-
    % Open the report, refusing an impostor.
    efference_copy_open_report(Report, _Copy, _Predicted, _Actual, Residuals, _Attenuated, _Cue).

% efference_copy_open_report(+Report, -Copy, -Predicted, -Actual, -Residuals, -Attenuated, -Cue):
% open a report term, refusing a hole or an impostor.
efference_copy_open_report(Report, Copy, Predicted, Actual, Residuals, Attenuated, Cue) :-
    % An unbound report is a hole.
    (   var(Report)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % A term that is not a report is refused aloud, naming what arrived.
    (   Report = efference_copy_report(Copy, Predicted, Actual, Residuals, Attenuated, Cue)
    ->  true
    ;   domain_error(efference_copy_report, Report)
    ).
