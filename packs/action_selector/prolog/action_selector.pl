% Declare this file as the 'action_selector' module and list the predicates it exports.
:- module(action_selector, [
    % action_selector_select/2: release exactly one candidate action, or nothing when there are none.
    action_selector_select/2,
    % action_selector_best/2: the single strongest candidate action.
    action_selector_best/2,
    % action_selector_is_candidate/2: check the never-invent invariant - the outcome came from the inputs.
    action_selector_is_candidate/2,
    % action_selector_bias/3: raise a candidate's salience in proportion to a pressing drive's error.
    action_selector_bias/3
]).

% Import membership for the never-invent invariant check.
:- use_module(library(lists), [memberchk/2]).

% The action selector is Architecture Component 6: the referee of the federation. It receives
% candidate actions, each written action(Name, Salience), and RELEASES EXACTLY ONE - the strongest -
% while suppressing the rest. Its one inviolable invariant (Section A3.6) is that it never invents an
% action: its output is always one of its inputs. A selector that begins to generate is the
% homunculus creeping back in, so the invariant is enforced in code and checkable by
% action_selector_is_candidate/2. Ties are broken in favour of the first candidate, so selection is
% deterministic and reproducible.

% action_selector_best(+Candidates, -Best): the single strongest candidate action.
action_selector_best([First | Rest], Best) :-
    % Take the first candidate as the running best, then compare the rest against it.
    action_selector_best_(Rest, First, Best).

% action_selector_best_(+Rest, +RunningBest, -Best): fold the candidates, keeping the strongest.
% With no candidates left, the running best is the strongest.
action_selector_best_([], Best, Best).
% Otherwise compare the next candidate's salience against the running best.
action_selector_best_([action(Name, Salience) | Rest], action(BestName, BestSalience), Best) :-
    % A strictly greater salience wins; an equal salience keeps the earlier candidate (a stable tie-break).
    ( Salience > BestSalience
      -> action_selector_best_(Rest, action(Name, Salience), Best)
      ;  action_selector_best_(Rest, action(BestName, BestSalience), Best)
    ).

% action_selector_select(+Candidates, -Outcome): release exactly one action, or nothing.
% With no candidates there is nothing to release.
action_selector_select([], nothing).
% With candidates, release the single strongest one.
action_selector_select([First | Rest], released(Name)) :-
    % Find the strongest candidate and release its name.
    action_selector_best([First | Rest], action(Name, _Salience)).

% action_selector_is_candidate(+Outcome, +Candidates): the never-invent invariant holds for this outcome.
% Releasing nothing trivially invents nothing.
action_selector_is_candidate(nothing, _Candidates).
% A released action must be the name of one of the candidates, never a fresh invention.
action_selector_is_candidate(released(Name), Candidates) :-
    % Confirm the released name appears among the candidate actions.
    memberchk(action(Name, _Salience), Candidates).

% action_selector_bias(+BaseSalience, +DriveError, -Salience): a pressing drive raises its action's salience.
action_selector_bias(BaseSalience, DriveError, Salience) :-
    % Add the drive's error to the base salience, so a hungrier drive biases selection more.
    Salience is BaseSalience + DriveError.
