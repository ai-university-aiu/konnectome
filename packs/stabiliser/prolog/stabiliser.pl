% Declare this file as the 'stabiliser' module and list the predicates it exports.
:- module(stabiliser, [
    % stabiliser_bias_key/1: the one bus key the stability bias travels under, named once.
    stabiliser_bias_key/1,
    % stabiliser_agency/1: the stabiliser's agency, which is a BIAS and never a row in any table.
    stabiliser_agency/1,
    % stabiliser_governed_grains/1: WHICH GRAINS this scalar governs - the two-grain question, decided.
    stabiliser_governed_grains/1,
    % stabiliser_check_grain/1: the grain decision made a refusal rather than a comment.
    stabiliser_check_grain/1,
    % stabiliser_check_bias/1: refuse a hole, a non-number, or a band that would invert.
    stabiliser_check_bias/1,
    % stabiliser_publish/3: the stabiliser writes its scalar onto the bus, as a LEVEL.
    stabiliser_publish/3,
    % stabiliser_bias/2: read the standing stability bias, ZERO by default.
    stabiliser_bias/2,
    % stabiliser_band/4: the two boundaries a midpoint and a bias imply, which a switch compares against.
    stabiliser_band/4,
    % stabiliser_governor_parameters/4: the two-process governor's parameter block, its band now DERIVED.
    stabiliser_governor_parameters/4,
    % stabiliser_default_midpoint/1: the midpoint that restates the governor's own two constants.
    stabiliser_default_midpoint/1,
    % stabiliser_default_bias/1: the half-width that restates the governor's own two constants.
    stabiliser_default_bias/1
]).

% Import the type checker that refuses a hole or a wrong shape aloud.
:- use_module(library(error), [must_be/2, domain_error/2]).
% Import membership for the governed-grain roster check.
:- use_module(library(lists), [memberchk/2]).
% Import the bus, because a bias travels as a LEVEL on the channel konnectome already has.
:- use_module(library(neuromodulator_bus), [
    % neuromodulator_bus_broadcast/4: a source writes a modulator's level for everyone to read.
    neuromodulator_bus_broadcast/4,
    % neuromodulator_bus_level/3: read one modulator's current level, zero when nobody has written.
    neuromodulator_bus_level/3
]).

% ---------------------------------------------------------------------------
% WHAT THIS PACK IS, AND WHY IT IS A PACK (the design authority, Part Nine slice six)
% ---------------------------------------------------------------------------
%
% THE CORPUS IS EXPLICIT THAT HYSTERESIS IS NOT PART OF THE SWITCH. The Layer 11 reading states it in
% one sentence - "this is a stabiliser, not a switch, so it has no poles of its own" - and says the
% stabiliser publishes a SCALAR STABILITY BIAS onto the configuration bus. konnectome's hysteresis
% has until now been two constants sitting inside the two-process governor's parameter block, and a
% symmetric single threshold inside the gate. Both are the stickiness buried in the switch, which is
% the arrangement the corpus names and rejects.
%
% WHAT A STABILITY BIAS IS, in one sentence a beginner can hold: it is HOW FAR APART THE TWO
% BOUNDARIES SIT. A switch with a bias of zero has one boundary and flips the moment its drive
% crosses it, in either direction. A switch with a positive bias has two boundaries - a higher one to
% turn on and a lower one to turn off - so a drive hovering in the middle cannot chatter the state.
% The corpus's words for the same thing at the cell grain are plainer still: switching on takes more
% input than keeping it on, and that is the defining hysteresis.
%
% ITS UNITS ARE THE UNITS OF WHATEVER IT STEADIES, and this is stated because a scalar with no stated
% units is an invitation to misuse. The bias is HALF THE WIDTH OF THE HYSTERESIS BAND, expressed in
% the units of the quantity that switch compares. A gate comparing a switching drive reads it as an
% offset on the gate's threshold; a governor comparing a sleep-pressure balance reads it as the half
% width of its band about a midpoint. One meaning, two consumers, no conversion.
%
% THE STABILISER INHERITS DECISION-1 AND DOES NOT RE-OPEN IT. A hysteresis scalar is a BIAS, and
% DECISION-1 settled that bias travels as a LEVEL on the existing channel and never as a thrown mode.
% Since slice 41 the bus has offered two shapes to anything that publishes, and they are not the same
% thing, so this pack states its choice rather than leaving it to be inferred: THE STABILITY BIAS IS
% BROADCAST AS A LEVEL, under a plain-atom modulator key, exactly as every chemical level has been
% broadcast since slice 4.
%
% AND ITS AGENCY IS NOT AN AGENCY IN ANY TRANSITION TABLE, which is the sharpest way to say what a
% bias is. Since slice 40 a construct is moved only by a row of its own register's transition table,
% and each row names the AGENCY that moves it - today self_selected and broadcast_thrown. THE
% STABILISER MOVES NOTHING. It does not fire a transition, it does not appear in a table, and no
% construct changes mode because the stabiliser published. What it changes is WHERE A BOUNDARY SITS,
% after which the construct's own row fires, or does not, by its own rule. Its agency is therefore
% broadcast_bias, and the test suite pins that this name appears in no transition table in the
% repository - a negative pinned rather than merely intended.

% stabiliser_bias_key(-Key): the one bus key the stability bias travels under.
% It is a PLAIN ATOM, so it uses the bus's oldest and simplest key shape: a level, like every
% chemical level. Naming it here rather than writing the atom at each site means the key cannot drift.
stabiliser_bias_key(stability_bias).

% stabiliser_agency(-Agency): the stabiliser's agency, stated so it can be checked and not assumed.
stabiliser_agency(broadcast_bias).

% ---------------------------------------------------------------------------
% DECISION-3: WHICH GRAINS THE PUBLISHED SCALAR GOVERNS
% ---------------------------------------------------------------------------
%
% THE CORPUS ANSWERS THE HYSTERESIS QUESTION DIFFERENTLY AT TWO GRAINS, and the version 2 analysis
% named this the sharpest ambiguity in its visit. At the CONSTRUCT grain the Layer 11 reading puts
% the stickiness OUTSIDE the switch: a stabiliser with no poles of its own, publishing a scalar. At
% the MOTIF grain, Layer 8 Chapter 16 gives winner-take-all's transfer function as a hysteretic max
% operation with an explicitly hysteretic Commitment Mode - stickiness INSIDE the motif, part of the
% transfer function itself. BOTH ARE LITERAL AND NEITHER IS A MISREADING.
%
% KONNECTOME'S DECISION, AND IT IS KONNECTOME'S OWN: THE PUBLISHED SCALAR GOVERNS THE CONSTRUCT GRAIN
% ONLY. The motif grain keeps its own internal hysteresis when it is built, and this bias does not
% reach it.
%
% THE REASONS, none of them the corpus's. FIRST, THE TWO READINGS ARE NOT IN CONFLICT ONCE THE GRAIN
% IS NAMED: a scalar published to steady a whole configuration and a hysteresis written into one
% motif's transfer function are different mechanisms doing similar work at different scales, and
% collapsing them would force konnectome to pick a winner where the corpus supplies two. SECOND, A
% BIAS THAT REACHED INSIDE A TRANSFER FUNCTION WOULD MAKE A MOTIF'S OWN LAW DEPEND ON A GLOBAL VALUE,
% which is the coupling the whole build has spent slices avoiding: a transfer function is what a
% construct IS while a mode holds, and a global channel must not be able to rewrite it. THIRD, IT IS
% THE REVERSIBLE CHOICE: the motif catalogue is unbuilt, so a later slice that finds a genuine need
% can extend the roster of governed grains, whereas a scalar already reaching everywhere could not be
% withdrawn from the motif grain without breaking whatever had come to depend on it.
%
% WHAT DECISION-3 DOES NOT DECIDE. It does not decide what the motif grain's hysteresis SHOULD be -
% that belongs to the motif catalogue family, which must decide it as konnectome's own. It does not
% decide the region or system grains, neither of which has a construct that could hold a register
% yet. And it does not decide whether a second, differently-scoped stabiliser may exist later; it
% decides only what THIS scalar reaches.

% stabiliser_governed_grains(-Grains): the grains this published scalar governs, as a list.
stabiliser_governed_grains([construct_grain]).

% stabiliser_check_grain(+Grain): the grain decision made a refusal that fires, not a comment.
stabiliser_check_grain(Grain) :-
    % A hole cannot be judged, and must never be bound to the one governed grain by accident.
    must_be(atom, Grain),
    % Read the roster rather than restating it, so the decision lives in exactly one place.
    stabiliser_governed_grains(Grains),
    % A grain outside the roster is refused ALOUD, naming itself, rather than quietly steadied.
    (   memberchk(Grain, Grains)
    ->  true
    ;   domain_error(stabiliser_governed_grain, Grain)
    ).

% stabiliser_check_bias(+Bias): refuse a bias no switch could honour.
stabiliser_check_bias(Bias) :-
    % A hole would be bound by the arithmetic below and would invent a band; refuse it aloud first.
    must_be(number, Bias),
    % A NEGATIVE BIAS INVERTS THE BAND, putting the turn-on boundary below the turn-off boundary,
    % which is a switch that chatters by construction. The two-process governor has refused exactly
    % this since it was built; the refusal moves here with the band, and keeps its shape.
    (   Bias >= 0
    ->  true
    ;   domain_error(stabiliser_bias, Bias)
    ).

% stabiliser_publish(+Bus0, +Bias, -Bus): the stabiliser writes its scalar onto the bus.
stabiliser_publish(Bus0, Bias, Bus) :-
    % Refuse a bias no switch could honour before anything is written where everyone can read it.
    stabiliser_check_bias(Bias),
    % Read the key from its one home.
    stabiliser_bias_key(Key),
    % Broadcast it as a LEVEL, per DECISION-1: a bias travels on the channel konnectome already has.
    neuromodulator_bus_broadcast(Bus0, Key, Bias, Bus).

% stabiliser_bias(+Bus, -Bias): read the standing stability bias, ZERO by default.
% THE DEFAULT IS THE POINT OF THIS PREDICATE. A bus nobody has published to reads back zero, and a
% bias of zero is a band of no width - one boundary, the symmetric toggle konnectome has always had.
% So every switch in the repository can consult the stabiliser without any of them changing
% behaviour until something actually publishes, which is what made this slice safe to build.
stabiliser_bias(Bus, Bias) :-
    % Read the key from its one home.
    stabiliser_bias_key(Key),
    % The bus's own read already answers zero for a modulator nobody has written.
    neuromodulator_bus_level(Bus, Key, Bias).

% stabiliser_band(+Midpoint, +Bias, -UpperBoundary, -LowerBoundary): the two boundaries a band implies.
stabiliser_band(Midpoint, Bias, UpperBoundary, LowerBoundary) :-
    % A hole for the midpoint would invent the band's position; refuse it aloud.
    must_be(number, Midpoint),
    % A hole or a negative for the bias would invent or invert the band's width; refuse it aloud.
    stabiliser_check_bias(Bias),
    % The upper boundary is the one a rising quantity must reach.
    UpperBoundary is Midpoint + Bias,
    % The lower boundary is the one a falling quantity must reach, and at a bias of zero they coincide.
    LowerBoundary is Midpoint - Bias.

% THE GOVERNOR'S TWO CONSTANTS, NOW DERIVED RATHER THAN DECLARED.
%
% The two-process governor has carried a sleep threshold of sixteen and a wake threshold of two since
% it was built, sitting inside its own parameter block - which is exactly the arrangement the design
% authority filed as a real, small, high-value gap. They are NOT REPLACED BY DIFFERENT NUMBERS here,
% because different numbers would be konnectome inventing where it had no need to. They are restated
% as what they always were: a band about a midpoint. Sixteen and two are a midpoint of NINE and a
% half-width of SEVEN, and the test suite proves the derivation reproduces the original pair exactly.
% NOTHING IN THE RUNNING MACHINE MOVES; what moves is where the band is written down, from a constant
% inside the switch to a scalar the stabiliser owns and can modulate.

% stabiliser_default_midpoint(-Midpoint): the midpoint of the governor's own long-standing band.
stabiliser_default_midpoint(9).

% stabiliser_default_bias(-Bias): the half-width of the governor's own long-standing band.
stabiliser_default_bias(7).

% stabiliser_governor_parameters(+Base, +Midpoint, +Bias, -Parameters): a governor block with a derived band.
stabiliser_governor_parameters(Base, Midpoint, Bias, Parameters) :-
    % A hole for the base block cannot be judged and must never be bound into an invented day.
    must_be(compound, Base),
    % The base block carries the governor's six whole-word parameters in their fixed places.
    (   Base = two_process_parameters(Rise, Discharge, DayLength, Amplitude, _OldSleep, _OldWake)
    ->  true
    ;   % A block of any other shape is refused by the governor's own name, not quietly reshaped.
        domain_error(two_process_governor_parameters, Base)
    ),
    % Derive the band's two boundaries from the midpoint and the published bias.
    stabiliser_band(Midpoint, Bias, SleepThreshold, WakeThreshold),
    % Rebuild the block with the derived band in place of the two constants that used to sit there.
    Parameters = two_process_parameters(Rise, Discharge, DayLength, Amplitude, SleepThreshold, WakeThreshold).
