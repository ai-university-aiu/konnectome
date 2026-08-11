% Load the symbol_exchange module under test from the library path.
:- use_module(library(symbol_exchange)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Load the two_process_governor module, used to boot the fixture world's night watchman.
:- use_module(library(two_process_governor), [two_process_governor_new/1]).
% Reuse the language pack so recognition can be checked against the word bank directly.
:- use_module(library(language), [
    % language_word_trace/3: confirm a heard word really entered the word bank.
    language_word_trace/3
]).

% A fixed simulation start, so the fixture world is deterministic.
symbol_exchange_test_simulation_start("2026-07-26T00:00:00Z").

% symbol_exchange_test_world(-World): the boot world the grounding run lives in - too warm, one drive, one interface.
symbol_exchange_test_world(World) :-
    % The fixed simulation start stamps the run.
    symbol_exchange_test_simulation_start(Start),
    % The default two-process governor: the slice-37 tick requires a watchman, who holds this short run online.
    two_process_governor_new(Governor),
    % The same small world the capstone boots: a too-warm body, a temperature drive defending
    % thirty-seven, and the learning body's stores at zero with the scaling bound armed at rest.
    World = world{
        tick: 0,
        body: [temperature-40],
        drives: [drive(temperature, temperature, 37, none)],
        bus: [],
        constructs: [construct(a, source), construct(b, relay(1))],
        activations: [a-1, b-0],
        interfaces: [interface(a, b, 0.5, 1, transmissive)],
        traces: [(a-b)-0],
        averages: [a-0, b-0],
        fading_factor: 0.6,
        smoothing_factor: 0.2,
        scaling_target: 0.5,
        scaling_targets: [],
        scaling_rate: 0.0,
        overrides: [override(respiration, 0, 0.0, breathe)],
        override_threshold: 0.5,
        % SLICE 72: the conflict loop's caller-supplied coupling gain (DECISION-15's own worked
        % figure; the loop's acceptance test holds for every positive gain and picks none of them).
        conflict_gain: 0.15,
        learning_rate: 0.1,
        % The day's memory store starts empty; every online tick remembers its pattern (slice 38).
        memories: [],
        % The night's replay strengthening rate.
        replay_rate: 0.1,
        % The night's raised scaling bound, at or above the day's rate as the tick demands.
        offline_scaling_rate: 0.0,
        governor: Governor,
        simulation_start: Start
    }.

% symbol_exchange_test_groundings(-Groundings): the standard two-word vocabulary for the fixtures.
symbol_exchange_test_groundings([grounding(warm, in_deficit), grounding(settled, satisfied)]).

% Open the test block for the symbol_exchange pack.
:- begin_tests(symbol_exchange).

% The inner conditions a word may be grounded in form a small closed vocabulary.
test(conditions_are_a_closed_vocabulary) :-
    % Ask for the conditions.
    symbol_exchange_conditions(Conditions),
    % Exactly the two: a drive in deficit, and a drive satisfied.
    assertion(Conditions == [in_deficit, satisfied]).

% A too-warm body reads as the drive in deficit.
test(condition_reads_the_deficit) :-
    % The drive defends thirty-seven and the body sits at forty.
    symbol_exchange_condition([drive(temperature, temperature, 37, none)], [temperature-40], Condition),
    % The mind is in deficit.
    assertion(Condition == in_deficit).

% A body at its set-point reads as the drive satisfied.
test(condition_reads_the_satisfaction) :-
    % The drive defends thirty-seven and the body sits at thirty-seven.
    symbol_exchange_condition([drive(temperature, temperature, 37, none)], [temperature-37], Condition),
    % The mind is satisfied.
    assertion(Condition == satisfied).

% Living the boot world for ten ticks experiences both conditions: the deficit at boot, the satisfaction later.
test(run_experiences_both_conditions) :-
    % Boot the fixture world.
    symbol_exchange_test_world(World),
    % Live ten ticks and collect every condition passed through.
    symbol_exchange_experienced(World, 10, Experienced),
    % Both conditions were lived.
    assertion(Experienced == [in_deficit, satisfied]).

% A word grounds in a condition the mind has lived.
test(grounding_succeeds_for_a_lived_condition) :-
    % Ground the word warm in the lived deficit.
    symbol_exchange_ground(warm, in_deficit, [in_deficit, satisfied], Grounding),
    % The grounding pairs the word with the condition.
    assertion(Grounding == grounding(warm, in_deficit)).

% A word may not ground in a condition the mind has never lived - grounding comes from experience.
test(grounding_refuses_an_unlived_condition, throws(error(symbol_exchange_unlived_condition(_), _))) :-
    % The run only ever lived satisfaction, so the deficit cannot ground a word.
    symbol_exchange_ground(warm, in_deficit, [satisfied], _Grounding).

% A word may not ground in a condition outside the closed vocabulary.
test(grounding_refuses_an_unknown_condition, throws(error(symbol_exchange_bad_condition(_), _))) :-
    % Freezing is not a condition this mind has words for.
    symbol_exchange_ground(cold, freezing, [in_deficit, satisfied], _Grounding).

% The standard vocabulary is built from a lived run: warm for the deficit, settled for the satisfaction.
test(vocabulary_is_built_from_the_lived_run) :-
    % Boot the fixture world.
    symbol_exchange_test_world(World),
    % Build the vocabulary from ten lived ticks.
    symbol_exchange_vocabulary(World, 10, Groundings),
    % The two words ground in the two lived conditions.
    assertion(Groundings == [grounding(warm, in_deficit), grounding(settled, satisfied)]).

% Production: given its current condition, the mind produces the grounded word for it - both directions of the vocabulary.
test(production_finds_the_word_for_the_condition) :-
    % The standard vocabulary.
    symbol_exchange_test_groundings(Groundings),
    % In deficit, the mind produces warm.
    symbol_exchange_produce(Groundings, in_deficit, DeficitWord),
    % Satisfied, the mind produces settled.
    symbol_exchange_produce(Groundings, satisfied, SatisfiedWord),
    % Each condition finds its own word.
    assertion(DeficitWord == warm),
    % And the words differ.
    assertion(SatisfiedWord == settled).

% Production refuses a condition no word is grounded in.
test(production_refuses_an_ungrounded_condition, throws(error(symbol_exchange_no_word_for_condition(_), _))) :-
    % An empty vocabulary has no word for anything.
    symbol_exchange_produce([], in_deficit, _Word).

% Recognition: hearing a grounded word finds its condition, and the hearing leaves a trace in the word bank.
test(recognition_hears_the_word_and_finds_the_condition) :-
    % The standard vocabulary.
    symbol_exchange_test_groundings(Groundings),
    % Hear and recognize the word warm.
    symbol_exchange_recognize(Groundings, warm, Condition),
    % The word names the deficit.
    assertion(Condition == in_deficit),
    % And the hearing changed the mind's state: the word bank carries the trace.
    assertion(language_word_trace(warm, _, _)).

% Recognition refuses a word the mind has never grounded.
test(recognition_refuses_an_ungrounded_word, throws(error(symbol_exchange_unknown_word(_), _))) :-
    % The standard vocabulary.
    symbol_exchange_test_groundings(Groundings),
    % Banana was never grounded in anything.
    symbol_exchange_recognize(Groundings, banana, _Condition).

% A drive whose monitored variable is absent from the body is refused by name, never a silent failure
% (found by the pre-merge adversarial review: the condition reader failed silently on a missing variable).
test(condition_refuses_a_missing_body_variable, throws(error(symbol_exchange_missing_variable(_), _))) :-
    % The hunger drive watches glucose, but the body carries only temperature.
    symbol_exchange_condition([drive(hunger, glucose, 5, none)], [temperature-40], _Condition).

% A body value that is not a number is refused by name, never as a raw arithmetic error
% (found by the same review: a wordy value leaked a bare type error from the arithmetic depths).
test(condition_refuses_a_wordy_body_value, throws(error(symbol_exchange_bad_body_value(_), _))) :-
    % The body says the temperature is hot, which is a word, not a number.
    symbol_exchange_condition([drive(temperature, temperature, 37, none)], [temperature-hot], _Condition).

% A drive term of the wrong shape is refused by name, never a silent failure
% (the one small hole the build log's ninth chapter recorded as awaiting its named refusal - now closed).
test(condition_refuses_a_malformed_drive_term, throws(error(symbol_exchange_bad_drive(_), _))) :-
    % A bare atom is not a drive term.
    symbol_exchange_condition([hunger], [temperature-40], _Condition).

% Heard words that are not a list are refused by name, never a silent failure.
test(reply_refuses_words_that_are_not_a_list, throws(error(symbol_exchange_bad_words(_), _))) :-
    % The standard vocabulary.
    symbol_exchange_test_groundings(Groundings),
    % A bare word is not a list of words.
    symbol_exchange_reply(Groundings, [drive(temperature, temperature, 37, none)], [temperature-40], not_a_list, _Reply).

% The reply validates the mind's state BEFORE it listens, so a mind that cannot answer never mutates the word bank
% (found by the same review: the old order heard the words first, leaving a trace of a conversation that never happened).
test(reply_validates_before_it_hears) :-
    % The standard vocabulary.
    symbol_exchange_test_groundings(Groundings),
    % A drive whose variable the body does not carry: the reply must refuse by name.
    catch(symbol_exchange_reply(Groundings, [drive(hunger, glucose, 5, none)], [temperature-40], [zebra_word], _Reply),
          % The named refusal is the expected outcome.
          error(symbol_exchange_missing_variable(_), _),
          % The refusal is what we wanted.
          true),
    % And the never-heard word left no trace: the word bank was not mutated by the failed exchange.
    assertion(\+ language_word_trace(zebra_word, _, _)).

% The pilot property: the same heard words draw DIFFERENT replies when the drive is in deficit and when it is satisfied.
test(reply_differs_by_drive_state) :-
    % The standard vocabulary.
    symbol_exchange_test_groundings(Groundings),
    % The same incoming words in both worlds.
    HeardWords = [how, are, you],
    % Asked while the body is too warm.
    symbol_exchange_reply(Groundings, [drive(temperature, temperature, 37, none)], [temperature-40], HeardWords, DeficitReply),
    % Asked while the body sits at its set-point.
    symbol_exchange_reply(Groundings, [drive(temperature, temperature, 37, none)], [temperature-37], HeardWords, SatisfiedReply),
    % The deficit colours the words: the mind names its state and the state it seeks.
    assertion(DeficitReply == [warm, settled]),
    % Satisfaction speaks in one settled word.
    assertion(SatisfiedReply == [settled]),
    % The mood really did colour the words.
    assertion(DeficitReply \== SatisfiedReply).

% The reply is deterministic: the same world and words draw the same reply.
test(reply_is_deterministic) :-
    % The standard vocabulary.
    symbol_exchange_test_groundings(Groundings),
    % Ask once.
    symbol_exchange_reply(Groundings, [drive(temperature, temperature, 37, none)], [temperature-40], [hello], First),
    % Ask again.
    symbol_exchange_reply(Groundings, [drive(temperature, temperature, 37, none)], [temperature-40], [hello], Second),
    % The two replies are identical.
    assertion(First == Second).

% ---------------------------------------------------------------------------
% The named refusals, each shown able to fire.
% ---------------------------------------------------------------------------

% Reading a condition refuses a mind with no drives at all, because a condition is read from a drive,
% and a mind with none has nothing to be in deficit or satisfied about - silence there would be a lie.
test(condition_refuses_a_mind_with_no_drives,
     throws(error(symbol_exchange_no_drive, _))) :-
    % An empty drive list has no first drive to read a condition from.
    symbol_exchange_condition([], [temperature-40], _Condition).

% Grounding refuses a word that is not a plain atom, because a word is the thing the mind will later
% say and hear, and a compound or a number cannot travel through the word bank as a word.
test(grounding_refuses_a_word_that_is_not_an_atom,
     throws(error(symbol_exchange_bad_word(_Offending), _))) :-
    % A number is not a word this mind can say.
    symbol_exchange_ground(7, in_deficit, [in_deficit, satisfied], _Grounding).

% Living a run refuses a tick count that is not a whole non-negative number of ticks, because a run of
% minus one ticks is not a shorter run - it is a request the loop cannot honour and must not pretend to.
test(experienced_refuses_a_negative_tick_count,
     throws(error(symbol_exchange_bad_ticks(_Count), _))) :-
    % The fixture boot world.
    symbol_exchange_test_world(World),
    % Minus one tick is not a number of ticks anything can be lived through.
    symbol_exchange_experienced(World, -1, _Conditions).

% Close the test block for the symbol_exchange pack.
:- end_tests(symbol_exchange).
