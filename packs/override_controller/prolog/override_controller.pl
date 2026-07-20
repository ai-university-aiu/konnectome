% Declare this file as the 'override_controller' module and list the predicates it exports.
:- module(override_controller, [
    % override_controller_arbitrate/4: let a vital drive in distress seize control, else keep the normal action.
    override_controller_arbitrate/4,
    % override_controller_active/3: the override drives whose distress exceeds the threshold.
    override_controller_active/3,
    % override_controller_most_vital/2: the most vital (lowest-rank) drive among a set.
    override_controller_most_vital/2
]).

% Import include for selecting the drives that are in distress.
:- use_module(library(apply), [include/3]).

% The override controller is Architecture Component 7: it enforces the vitality ranking so that older,
% vital drives preempt newer deliberation. An override is override(Name, Rank, Distress, Action), where
% a LOWER Rank is MORE vital (respiration is rank zero). When a drive's Distress exceeds the threshold,
% it seizes the action selector and forces its Action; the most vital drive in distress wins. This is
% the architectural home of the fact that breathing beats deliberation, and the respiration drive can
% never be suppressed - the System's one inviolable safety property.

% override_controller_in_distress(+Threshold, +Override): the override's distress exceeds the threshold.
override_controller_in_distress(Threshold, override(_Name, _Rank, Distress, _Action)) :-
    % The drive is in distress when its distress level is above the threshold.
    Distress > Threshold.

% override_controller_active(+Overrides, +Threshold, -Active): the overrides that are in distress.
override_controller_active(Overrides, Threshold, Active) :-
    % Keep only the overrides whose distress exceeds the threshold.
    include(override_controller_in_distress(Threshold), Overrides, Active).

% override_controller_most_vital(+Overrides, -Winner): the most vital (lowest-rank) override.
override_controller_most_vital([First | Rest], Winner) :-
    % Take the first as the running most-vital, then compare the rest against it.
    override_controller_most_vital_(Rest, First, Winner).

% override_controller_most_vital_(+Rest, +RunningBest, -Winner): fold, keeping the lowest rank.
% With none left, the running most-vital is the winner.
override_controller_most_vital_([], Winner, Winner).
% Otherwise a strictly lower rank wins; an equal rank keeps the earlier drive (a stable tie-break).
override_controller_most_vital_([override(Name, Rank, Distress, Action) | Rest],
                                override(BestName, BestRank, BestDistress, BestAction), Winner) :-
    % A more vital (lower-rank) drive takes over; otherwise keep the running best.
    ( Rank < BestRank
      -> override_controller_most_vital_(Rest, override(Name, Rank, Distress, Action), Winner)
      ;  override_controller_most_vital_(Rest, override(BestName, BestRank, BestDistress, BestAction), Winner)
    ).

% override_controller_arbitrate(+Overrides, +Threshold, +NormalOutcome, -FinalOutcome): resolve control.
override_controller_arbitrate(Overrides, Threshold, NormalOutcome, FinalOutcome) :-
    % Find the vital drives currently in distress.
    override_controller_active(Overrides, Threshold, Active),
    % If none are in distress the normal action stands; otherwise the most vital seizes control.
    ( Active == []
      -> FinalOutcome = NormalOutcome
      ;  override_controller_most_vital(Active, override(_Name, _Rank, _Distress, Action)),
         FinalOutcome = released(Action)
    ).
