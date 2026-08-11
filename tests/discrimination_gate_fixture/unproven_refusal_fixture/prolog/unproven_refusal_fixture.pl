% Declare this file as the 'unproven_refusal_fixture' module and list what it exports.
:- module(unproven_refusal_fixture, [
    % unproven_refusal_fixture_judge/1: a judgement carrying two refusals, one of them unproven.
    unproven_refusal_fixture_judge/1
]).

% Import the type checker that refuses a hole aloud.
:- use_module(library(error), [domain_error/2]).

% ---------------------------------------------------------------------------
% WHAT THIS FIXTURE IS, AND WHY IT IS DELIBERATELY BROKEN
% ---------------------------------------------------------------------------
%
% THIS PACK IS NOT PART OF KONNECTOME AND IS NEVER LOADED BY IT. It exists so that
% bin/check_discrimination.sh can be PROVEN ABLE TO FAIL, which is the naming
% gate's own standing rule and is doubly apt here: a gate whose entire subject is
% checks that have never said no would be a poor thing to trust without first
% watching it say no.
%
% IT CARRIES TWO NAMED REFUSALS AND EXACTLY ONE IS PROVEN. The proven one is here
% so the fixture cannot pass the gate by refusing nothing at all - a pack with no
% refusals is clean, and a fixture that was clean for that reason would prove
% nothing. The unproven one is the violation the gate must find, and its name
% says what it is.

% unproven_refusal_fixture_judge(+Thing): refuse two kinds of thing, by name.
% A thing named as impossible is refused, and a test in this fixture proves it.
unproven_refusal_fixture_judge(impossible) :-
    % Commit once the name matches, then refuse under a complaint the tests name.
    !,
    % This refusal is PROVEN by the fixture's own test, so the gate must pass it.
    domain_error(fixture_refusal_that_is_proven, impossible).
% A thing named as forgotten is refused under a complaint NO test ever names.
unproven_refusal_fixture_judge(forgotten) :-
    % Commit once the name matches.
    !,
    % THIS IS THE VIOLATION THE GATE EXISTS TO FIND. Nothing anywhere has ever made
    % this refusal fire, so nobody knows whether it can.
    domain_error(fixture_refusal_nobody_proves, forgotten).
% Anything else passes, so the fixture has a clean path as well as two refusals.
unproven_refusal_fixture_judge(_Thing).
