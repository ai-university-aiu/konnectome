% Load the fixture module under test from the library path.
:- use_module(library(unproven_refusal_fixture)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Open the test block for the fixture.
:- begin_tests(unproven_refusal_fixture).

% ONE OF THE FIXTURE'S TWO REFUSALS IS PROVEN HERE, and the other deliberately is
% not. That asymmetry is the whole fixture: the gate must pass the first and catch
% the second, so its self-test can assert that exactly one violation is reported.
test(the_proven_refusal_fires,
     throws(error(domain_error(fixture_refusal_that_is_proven, impossible), _))) :-
    unproven_refusal_fixture_judge(impossible).

% A thing the fixture does not refuse passes, so the fixture has a clean path too.
test(an_ordinary_thing_is_not_refused) :-
    unproven_refusal_fixture_judge(ordinary).

% Close the test block for the fixture.
:- end_tests(unproven_refusal_fixture).
