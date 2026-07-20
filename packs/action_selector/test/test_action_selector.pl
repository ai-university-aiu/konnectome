% Load the action_selector module under test from the library path.
:- use_module(library(action_selector)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Open the test block for the action_selector pack.
:- begin_tests(action_selector).

% The selector releases the single strongest candidate.
test(selects_the_strongest_candidate) :-
    % Three candidates of differing salience.
    action_selector_select([action(a, 0.2), action(b, 0.9), action(c, 0.5)], Outcome),
    % The strongest, b, is released.
    assertion(Outcome == released(b)).

% The selector releases exactly one action, and never invents one (the Section A3.6 invariant).
test(releases_exactly_one_and_never_invents) :-
    % A set of candidate actions.
    Candidates = [action(a, 0.2), action(b, 0.9), action(c, 0.5)],
    % Select from them.
    action_selector_select(Candidates, Outcome),
    % Exactly one action is released.
    assertion(Outcome = released(_Name)),
    % And the released action is one of the inputs, never a fresh invention.
    assertion(action_selector_is_candidate(Outcome, Candidates)).

% With no candidates there is nothing to release, and nothing is invented.
test(no_candidates_releases_nothing) :-
    % Select from an empty candidate list.
    action_selector_select([], Outcome),
    % Nothing is released.
    assertion(Outcome == nothing),
    % And the invariant still holds trivially.
    assertion(action_selector_is_candidate(Outcome, [])).

% Ties are broken deterministically in favour of the first candidate, so selection is reproducible.
test(ties_are_broken_deterministically_first_wins) :-
    % Two equally salient candidates.
    action_selector_select([action(a, 0.5), action(b, 0.5)], Outcome),
    % The earlier candidate, a, wins the tie.
    assertion(Outcome == released(a)).

% A drive raises the salience of its action in proportion to its error.
test(drive_bias_raises_salience) :-
    % A base salience raised by a drive error of three.
    action_selector_bias(0.1, 3, Salience),
    % The biased salience is the base plus the error.
    assertion(Salience =:= 3.1).

% A pressing drive biases its action strongly enough to win over a stronger-looking rival.
test(a_pressing_drive_biases_its_action_to_win) :-
    % A drive with a large error of four biases the cool-down action.
    action_selector_bias(0.1, 4, Biased),
    % The biased action competes against a stronger-looking base action.
    Candidates = [action(rest, 0.8), action(cool_down, Biased)],
    % Select from the two.
    action_selector_select(Candidates, Outcome),
    % The drive-biased action wins.
    assertion(Outcome == released(cool_down)).

% Close the test block for the action_selector pack.
:- end_tests(action_selector).
