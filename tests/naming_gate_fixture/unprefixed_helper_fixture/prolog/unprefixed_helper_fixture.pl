% Declare the fixture module: a DELIBERATE naming-gate violation, kept so the gate
% can be proven able to fail (bin/check_pack_naming.sh --self-test). This pack is
% NOT on the library path (it lives under tests/, not packs/) and is never loaded.
:- module(unprefixed_helper_fixture, [
    % unprefixed_helper_fixture_double/2: the properly-prefixed public predicate.
    unprefixed_helper_fixture_double/2
]).

% unprefixed_helper_fixture_double(+Number, -Doubled): double a number through the helper.
unprefixed_helper_fixture_double(Number, Doubled) :-
    % Delegate to the deliberately unprefixed helper below.
    numlist_or_empty(Number, Doubled).

% numlist_or_empty(+Number, -Doubled): THE DELIBERATE VIOLATION - an unprefixed
% helper bearing no known terse stem, the exact shape slice 22 proved the old
% cluster checks could not see. The self-test requires the gate to catch this.
numlist_or_empty(Number, Doubled) :-
    % Double the number, so the fixture is a real, loadable module.
    Doubled is Number * 2.
