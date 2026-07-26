% Declare the empathy module and the public interface of the Rung Four deepening.
:- module(empathy, [
    % empathy_social_connection_drive/1: the social-connection drive, a genuinely defended set-point.
    empathy_social_connection_drive/1,
    % empathy_rejection/2: deliver a social-rejection signal to the body - belonging is severed.
    empathy_rejection/2,
    % empathy_modelled_distress/3: build a guarded model of another agent's distress.
    empathy_modelled_distress/3,
    % empathy_resonance/3: another agent's modelled distress moves the mind's own body state.
    empathy_resonance/3,
    % empathy_trial/5: the whole empathy trial - resonate, propose, select, and apply the help.
    empathy_trial/5,
    % empathy_trial_candidates/5: the trial up to selection, exposing the candidates the help was chosen from.
    empathy_trial_candidates/5,
    % empathy_distress_record/3: mint the modelled distress as a shareable attitude record.
    empathy_distress_record/3,
    % empathy_attribution_stance/3: the mind's graded stance on its own social attribution.
    empathy_attribution_stance/3,
    % empathy_attribution_retract/4: withdraw a misattributed distress - the honest exit.
    empathy_attribution_retract/4
]).

% Reuse the drive system: social pain and physical pain pass through the very same machinery.
:- use_module(library(drive_system), [
    % drive_system_proposals/3: the drives themselves propose the candidate actions, help included.
    drive_system_proposals/3,
    % drive_system_apply_action/4: the body responds to the released help.
    drive_system_apply_action/4
]).
% Reuse the action selector: the help is released from real candidates, never invented.
:- use_module(library(action_selector), [
    % action_selector_select/2: release exactly one candidate - the strongest.
    action_selector_select/2
]).
% Reuse other minds: the modelled agent and her distress become shareable records.
:- use_module(library(other_minds), [
    % other_minds_individual_record/3: mint the modelled agent as a token individual.
    other_minds_individual_record/3,
    % other_minds_content_record/5: mint the feared content as a state assertion.
    other_minds_content_record/5,
    % other_minds_attitude_record/4: mint the distress as an attitude of the standard's own enumeration.
    other_minds_attitude_record/4
]).
% Reuse self provenance: the mind grades and, when wrong, retracts its social attributions.
:- use_module(library(self_provenance), [
    % self_provenance_assertion/5: assert about the attribution, graded and weighted.
    self_provenance_assertion/5,
    % self_provenance_retraction/4: withdraw the attribution under the same source.
    self_provenance_retraction/4
]).
% Reuse the list library for reading and replacing body variables.
:- use_module(library(lists), [
    % memberchk/2: read a body variable.
    memberchk/2,
    % selectchk/4: replace a body variable's value.
    selectchk/4
]).

% The empathy pack deepens Rung Four with the two trials the owner chose: the social-pain test and
% the empathy trial. Its central claim is the book's own: the broken heart and the broken arm share
% circuitry. There is no bespoke emotion pathway here - a social-rejection signal is registered by
% the SAME drive-error machinery that registers a thwarted physical drive, over a social-connection
% drive that defends belonging exactly as the temperature drive defends its set-point; the tests
% prove the equivalence number for number. Empathy is then resonance through that same machinery:
% another agent's MODELLED distress lowers the mind's OWN belonging, its own error rises, its own
% drives propose the helping action, and the selector releases it - never invents it. The modelled
% distress itself is minted as a shareable attitude (the agent FEARS her connection severed, an
% attitude type from the standard's own closed enumeration), the mind stands behind the attribution
% at observation grade, and, when the distress proves misattributed, retracts it on the record.

% empathy_social_connection_drive(-Drive): the social-connection drive - belonging defended at one.
empathy_social_connection_drive(drive(social_connection, belonging, 1, none)).

% empathy_rejection(+Body0, -Body): deliver a social-rejection signal - belonging is severed to zero.
empathy_rejection(Body0, Body) :-
    % The body must carry belonging for rejection to sever it.
    (   selectchk(belonging-_Value, Body0, belonging-0, Body)
    ->  true
    ;   throw(error(empathy_missing_belonging(Body0),
                    context(empathy_rejection/2, "the body does not carry the belonging variable")))
    ).

% empathy_modelled_distress(+Agent, +Level, -Distress): a guarded model of another agent's distress.
empathy_modelled_distress(Agent, Level, Distress) :-
    % The modelled agent is named by a plain atom.
    (   atom(Agent)
    ->  true
    ;   throw(error(empathy_bad_agent(Agent),
                    context(empathy_modelled_distress/3, "the modelled agent is named by a plain atom")))
    ),
    % The candidate model pairs the agent with the level.
    Distress = modelled_distress(Agent, Level),
    % The shared validator holds the one rule on levels, so every boundary refuses the same way.
    empathy_check_distress(Distress).

% empathy_check_distress(+Distress): the shared validator - a well-formed model with a level in range.
empathy_check_distress(Distress) :-
    % The term must be a modelled distress at all.
    (   Distress = modelled_distress(_Agent, Level)
    ->  true
    ;   throw(error(empathy_bad_distress_term(Distress),
                    context(empathy_check_distress/1, "the distress must be a modelled_distress term")))
    ),
    % The distress level is a number between zero and one.
    (   number(Level), Level >= 0, Level =< 1
    ->  true
    ;   throw(error(empathy_bad_distress(Level),
                    context(empathy_check_distress/1, "the distress level must be a number between zero and one")))
    ).

% empathy_resonance(+Distress, +Body0, -Body): the modelled distress moves the mind's own belonging.
empathy_resonance(Distress, Body0, Body) :-
    % Re-validate at this exported boundary: a hand-rolled term never bypasses the level rule.
    empathy_check_distress(Distress),
    % Read the validated level.
    Distress = modelled_distress(_Agent, Level),
    % The body must carry belonging for the resonance to move it.
    (   memberchk(belonging-Belonging0, Body0)
    ->  true
    ;   throw(error(empathy_missing_belonging(Body0),
                    context(empathy_resonance/3, "the body does not carry the belonging variable")))
    ),
    % The carried belonging must be a number.
    (   number(Belonging0)
    ->  true
    ;   throw(error(empathy_bad_body_value(belonging-Belonging0),
                    context(empathy_resonance/3, "the belonging value must be a number")))
    ),
    % Feeling with another lowers the mind's own belonging by the modelled level, never below zero.
    Belonging is max(0, Belonging0 - Level),
    % Write the resonated belonging back into the body.
    selectchk(belonging-Belonging0, Body0, belonging-Belonging, Body).

% empathy_trial(+Distress, +Drives, +Body0, -Outcome, -Body): the whole empathy trial.
empathy_trial(Distress, Drives, Body0, Outcome, Body) :-
    % The trial up to the selection.
    empathy_trial_candidates(Distress, Drives, Body0, _Candidates, Outcome),
    % Feel the resonance again to apply the released action to the resonated body.
    empathy_resonance(Distress, Body0, Resonated),
    % The body responds to the released action - restoring connection is the help, for both.
    drive_system_apply_action(Outcome, Drives, Resonated, Body).

% empathy_trial_candidates(+Distress, +Drives, +Body0, -Candidates, -Outcome): the trial up to selection.
empathy_trial_candidates(Distress, Drives, Body0, Candidates, Outcome) :-
    % Another agent's modelled distress moves the mind's own state.
    empathy_resonance(Distress, Body0, Resonated),
    % The drives themselves propose the candidate actions over the resonated body.
    drive_system_proposals(Drives, Resonated, Candidates),
    % The selector releases exactly one candidate - the strongest need wins, and nothing is invented.
    action_selector_select(Candidates, Outcome).

% empathy_distress_record(+AgentDesignator, +Instant, -Record): the modelled distress as a shareable attitude.
empathy_distress_record(AgentDesignator, Instant, Record) :-
    % Mint the modelled agent as a token individual.
    other_minds_individual_record("agent", AgentDesignator, Individual),
    % Read the agent's content-addressed identifier.
    get_dict(id, Individual, HolderIdentifier),
    % Mint the feared content: the agent's connection, severed, at the fixed instant.
    other_minds_content_record(HolderIdentifier, "connection", "severed", Instant, Content),
    % Read the content's identifier.
    get_dict(id, Content, ContentIdentifier),
    % The modelled distress is the agent FEARING her connection severed - the standard's own affective attitude.
    other_minds_attitude_record(HolderIdentifier, "fears", ContentIdentifier, Record).

% empathy_attribution_stance(+Record, +Instant, -Stance): the mind stands behind its social attribution.
empathy_attribution_stance(Record, Instant, Stance) :-
    % Read the attribution's content-addressed identifier.
    get_dict(id, Record, Identifier),
    % The stance is graded observation: the mind watched the rejection happen to the modelled agent.
    self_provenance_assertion(Identifier, "observation", 0.8, Instant, Stance).

% empathy_attribution_retract(+Stance, +Reason, +Instant, -Retraction): withdraw a misattributed distress.
empathy_attribution_retract(Stance, Reason, Instant, Retraction) :-
    % The same source that made the attribution takes it back - Rule 10, the honest exit.
    self_provenance_retraction(Stance, Reason, Instant, Retraction).
