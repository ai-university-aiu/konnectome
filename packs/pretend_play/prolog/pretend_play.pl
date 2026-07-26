% Declare the pretend_play module and the public interface of the pretend milestone.
:- module(pretend_play, [
    % pretend_play_realities/1: the five quarantined realities of the reused imagination machinery.
    pretend_play_realities/1,
    % pretend_play_reset/0: clear the pretend machinery to a clean slate.
    pretend_play_reset/0,
    % pretend_play_transition_add/3: teach the pretend scene one what-if transition.
    pretend_play_transition_add/3,
    % pretend_play_pretend/3: roll a pretend scene forward, sealed into the imagined reality.
    pretend_play_pretend/3,
    % pretend_play_quarantined/1: a fact that is imagined and not observed.
    pretend_play_quarantined/1,
    % pretend_play_holds/2: whether a fact holds in a named reality.
    pretend_play_holds/2,
    % pretend_play_promote/3: deliberately carry a fact from one reality to another - never into observed.
    pretend_play_promote/3,
    % pretend_play_thought/3: mint the pretend relation as a content-addressed causal relation object.
    pretend_play_thought/3,
    % pretend_play_stance/3: the mind's simulation-graded stance on a pretend thought.
    pretend_play_stance/3
]).

% Reuse the imagination pack: the reality-quarantine machinery the rung's own account names.
:- use_module(library(imagination), [
    % imagination_realities/1: the five partitions - observed, desired, expected, imagined, recalled.
    imagination_realities/1,
    % imagination_reset/0: clear every reality and every transition.
    imagination_reset/0,
    % imagination_transition_add/3: record one state-action-state transition for what-if rollouts.
    imagination_transition_add/3,
    % imagination_imagine/3: roll a start state forward, sealing every visited state into imagined.
    imagination_imagine/3,
    % imagination_quarantined/1: imagined and not observed - sealed off from fact.
    imagination_quarantined/1,
    % imagination_holds/2: whether a fact holds in a named reality.
    imagination_holds/2,
    % imagination_promote/3: the deliberate, auditable crossing between realities.
    imagination_promote/3
]).
% Reuse thought combination: a pretend relation is minted like any other combined thought.
:- use_module(library(thought_combination), [
    % thought_combination_atomic/3: mint the pretend cause and effect as occurrents.
    thought_combination_atomic/3,
    % thought_combination_combine/3: combine them into a content-addressed causal relation object.
    thought_combination_combine/3
]).
% Reuse self provenance: the mind grades its pretend stances like any other stance.
:- use_module(library(self_provenance), [
    % self_provenance_assertion/5: assert about the pretend thought, graded and weighted.
    self_provenance_assertion/5
]).

% Pretend play is the second Rung Two milestone: representing a situation that is not happening,
% reasoning within it, and never confusing it for the real record. The quarantine is the reused
% imagination machinery's own: whatever a pretend rollout visits is sealed into the imagined
% reality and never touches the observed record; the only crossing between realities is a
% deliberate, auditable promotion - and this pack adds one konnectome rule on top of the reuse:
% pretend may NEVER be promoted into observed, because only the world's own reveal writes what
% was observed. At the record level, a pretend relation is minted as an ordinary type-tier
% causal relation object - a generic thought that claims no happening - and the mind's stance on
% it is graded simulation, so pretend evidence can never outrank the world's. The per-claim
% machinery suffices; no world-level reality tag is minted, and none was needed.

% pretend_play_realities(-Realities): the five quarantined realities.
pretend_play_realities(Realities) :-
    % The reused machinery names its own partitions.
    imagination_realities(Realities).

% pretend_play_reset: clear the pretend machinery to a clean slate.
pretend_play_reset :-
    % Clear every reality and every transition.
    imagination_reset.

% pretend_play_transition_add(+State, +Action, +NextState): teach the pretend scene one transition.
pretend_play_transition_add(State, Action, NextState) :-
    % One what-if step: in pretend, this action carries this state to that one.
    imagination_transition_add(State, Action, NextState).

% pretend_play_pretend(+Start, +Actions, -Trajectory): roll the pretend scene forward, quarantined.
pretend_play_pretend(Start, Actions, Trajectory) :-
    % The rollout visits its states and seals every one into the imagined reality.
    imagination_imagine(Start, Actions, Trajectory).

% pretend_play_quarantined(+Fact): the fact is imagined and never observed.
pretend_play_quarantined(Fact) :-
    % Sealed off from fact by the reused quarantine.
    imagination_quarantined(Fact).

% pretend_play_holds(+Reality, +Fact): the fact holds in the named reality.
pretend_play_holds(Reality, Fact) :-
    % Read the named reality.
    imagination_holds(Reality, Fact).

% pretend_play_promote(+FromReality, +Fact, +ToReality): the deliberate crossing - with one konnectome refusal.
pretend_play_promote(_FromReality, Fact, observed) :-
    % Pretend never becomes fact by promotion; only the world's own reveal writes the observed record.
    throw(error(pretend_play_forbidden_promotion(Fact),
                context(pretend_play_promote/3, "pretend may never be promoted into the observed record"))),
    % This clause always throws; the underscore keeps the head's shape honest.
    !.
% Any other crossing is the reused machinery's deliberate, auditable promotion.
pretend_play_promote(FromReality, Fact, ToReality) :-
    % The destination is not the observed record.
    ToReality \== observed,
    % Carry the fact across, deliberately.
    imagination_promote(FromReality, Fact, ToReality).

% pretend_play_thought(+CauseLabel, +EffectLabel, -Thought): mint the pretend relation as a combined thought.
pretend_play_thought(CauseLabel, EffectLabel, Thought) :-
    % The pretend cause is an event occurrent - a generic, not a happening.
    thought_combination_atomic(CauseLabel, "event", CauseIdentifier),
    % The pretend effect is a state occurrent - likewise a generic.
    thought_combination_atomic(EffectLabel, "state", EffectIdentifier),
    % The pretend relation is an ordinary content-addressed causal relation object.
    thought_combination_combine([CauseIdentifier], [EffectIdentifier], Thought).

% pretend_play_stance(+Thought, +Instant, -Stance): the mind's simulation-graded stance on a pretend thought.
pretend_play_stance(Thought, Instant, Stance) :-
    % Read the pretend thought's content-addressed identifier.
    get_dict(id, Thought, Identifier),
    % The stance is graded simulation with a modest confidence: pretend evidence is model-made evidence.
    self_provenance_assertion(Identifier, "simulation", 0.5, Instant, Stance).
