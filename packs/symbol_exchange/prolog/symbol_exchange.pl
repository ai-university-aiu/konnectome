% Declare the symbol_exchange module and the public interface of the language beginnings.
:- module(symbol_exchange, [
    % symbol_exchange_conditions/1: the closed vocabulary of inner conditions a word may be grounded in.
    symbol_exchange_conditions/1,
    % symbol_exchange_condition/3: read the mind's current condition from its drives and body.
    symbol_exchange_condition/3,
    % symbol_exchange_experienced/3: live the world for some ticks and collect every condition passed through.
    symbol_exchange_experienced/3,
    % symbol_exchange_ground/4: ground a word in a condition the mind has lived.
    symbol_exchange_ground/4,
    % symbol_exchange_vocabulary/3: build the standard two-word vocabulary from a lived run.
    symbol_exchange_vocabulary/3,
    % symbol_exchange_produce/3: produce the grounded word for a condition - the speaking direction.
    symbol_exchange_produce/3,
    % symbol_exchange_recognize/3: hear a word and find the condition it names - the hearing direction.
    symbol_exchange_recognize/3,
    % symbol_exchange_reply/5: hear words and reply from the mind's own drive state.
    symbol_exchange_reply/5
]).

% Reuse the cognitive cycle: the grounding run is a real run of the whole mind.
:- use_module(library(cognitive_cycle), [
    % cognitive_cycle_step/3: one whole tick, so the run's conditions can be collected tick by tick.
    cognitive_cycle_step/3
]).
% Reuse the drive system: a condition is read from a drive's own error.
:- use_module(library(drive_system), [
    % drive_system_error/3: the drive's distance from its set-point.
    drive_system_error/3
]).
% Reuse the language pack: hearing a word writes it into the reused word bank.
:- use_module(library(language), [
    % language_hear/2: consume incoming words, changing the mind's language state.
    language_hear/2
]).
% Reuse the list library for membership checks over groundings and conditions.
:- use_module(library(lists), [
    % memberchk/2: find a grounding or a condition in a list.
    memberchk/2
]).

% The symbol exchange is konnectome's first step onto Rung Two: words grounded in the mind's own
% lived experience, used in both directions, and replies coloured by the drives. A word here is not
% a token looked up in a table: it may only be grounded in a condition the mind has actually lived
% through a real run of the whole cognitive cycle, and the reply to incoming words is composed from
% the mind's current drive state - so the same question draws different words from a mind in deficit
% than from a mind at its set-point. The speech is childlike by design: the rung's own account says
% early symbolic machinery is simple, and that the simplicity is a feature of honesty, not a defect.

% symbol_exchange_conditions(-Conditions): the closed vocabulary of inner conditions.
symbol_exchange_conditions([in_deficit, satisfied]).

% symbol_exchange_condition(+Drives, +Body, -Condition): the mind's current condition, read from its first drive.
symbol_exchange_condition([Drive|_], Body, Condition) :-
    % Read the drive's monitored variable from the drive term itself.
    Drive = drive(_Name, Variable, _SetPoint, _Previous),
    % The body must actually carry the monitored variable - a silent miss is refused by name.
    (   memberchk(Variable-Value, Body)
    ->  true
    ;   throw(error(symbol_exchange_missing_variable(Variable),
                    context(symbol_exchange_condition/3, "the body does not carry the drive's monitored variable")))
    ),
    % The carried value must be a number - a wordy value is refused by name, never as a raw arithmetic error.
    (   number(Value)
    ->  true
    ;   throw(error(symbol_exchange_bad_body_value(Variable-Value),
                    context(symbol_exchange_condition/3, "the monitored variable's value must be a number")))
    ),
    % The drive's error is its distance from the set-point.
    drive_system_error(Drive, Body, Error),
    % A positive error is a deficit; a zero error is satisfaction.
    (   Error > 0
    ->  Condition = in_deficit
    ;   Condition = satisfied
    ),
    % One reading is enough.
    !.
% A mind with no drive has no condition to read.
symbol_exchange_condition([], _Body, _Condition) :-
    % Refuse with a named, inspectable error.
    throw(error(symbol_exchange_no_drive,
                context(symbol_exchange_condition/3, "a condition is read from the first drive, and there is none"))).

% symbol_exchange_experienced(+World0, +NumTicks, -Conditions): the distinct conditions a run lives through.
symbol_exchange_experienced(World0, NumTicks, Conditions) :-
    % The tick count must be a whole number of ticks.
    (   integer(NumTicks), NumTicks >= 0
    ->  true
    ;   throw(error(symbol_exchange_bad_ticks(NumTicks),
                    context(symbol_exchange_experienced/3, "the tick count must be a non-negative integer")))
    ),
    % The boot condition is lived before any tick.
    get_dict(drives, World0, Drives0),
    % Read the boot body.
    get_dict(body, World0, Body0),
    % Read the boot condition.
    symbol_exchange_condition(Drives0, Body0, First),
    % Live the remaining ticks, collecting each condition.
    symbol_exchange_experienced_loop(World0, NumTicks, [First], Collected),
    % Distinct conditions only, in the vocabulary's own order.
    sort(Collected, Conditions).

% symbol_exchange_experienced_loop(+World, +TicksLeft, +Acc, -Collected): step and collect until the ticks run out.
symbol_exchange_experienced_loop(_World, 0, Collected, Collected) :-
    % The run is over; the collection is complete, with no way back.
    !.
% One more tick: step the whole mind, read the new condition, and continue.
symbol_exchange_experienced_loop(World, TicksLeft, Acc, Collected) :-
    % There are ticks left to live.
    TicksLeft > 0,
    % Live one whole tick, exactly once.
    once(cognitive_cycle_step(World, NextWorld, _Summary)),
    % Read the new drives.
    get_dict(drives, NextWorld, Drives),
    % Read the new body.
    get_dict(body, NextWorld, Body),
    % Read the condition the mind now lives in.
    symbol_exchange_condition(Drives, Body, Condition),
    % One tick fewer remains.
    NextTicksLeft is TicksLeft - 1,
    % Continue collecting.
    symbol_exchange_experienced_loop(NextWorld, NextTicksLeft, [Condition|Acc], Collected).

% symbol_exchange_ground(+Word, +Condition, +Experienced, -Grounding): ground a word in a lived condition.
symbol_exchange_ground(Word, Condition, Experienced, Grounding) :-
    % A word is a plain atom.
    (   atom(Word)
    ->  true
    ;   throw(error(symbol_exchange_bad_word(Word),
                    context(symbol_exchange_ground/4, "a word is a plain atom")))
    ),
    % The condition must belong to the closed vocabulary.
    symbol_exchange_conditions(Conditions),
    % An unknown condition is refused.
    (   memberchk(Condition, Conditions)
    ->  true
    ;   throw(error(symbol_exchange_bad_condition(Condition),
                    context(symbol_exchange_ground/4, "the condition is not one of the closed vocabulary")))
    ),
    % The condition must have been lived: grounding comes from experience, never from a table.
    (   memberchk(Condition, Experienced)
    ->  true
    ;   throw(error(symbol_exchange_unlived_condition(Condition),
                    context(symbol_exchange_ground/4, "a word may only be grounded in a condition the mind has lived")))
    ),
    % The grounding pairs the word with its lived condition.
    Grounding = grounding(Word, Condition).

% symbol_exchange_vocabulary(+World0, +NumTicks, -Groundings): the standard vocabulary from a lived run.
symbol_exchange_vocabulary(World0, NumTicks, [DeficitGrounding, SatisfiedGrounding]) :-
    % Live the run and collect its conditions.
    symbol_exchange_experienced(World0, NumTicks, Experienced),
    % Ground the word warm in the lived deficit.
    symbol_exchange_ground(warm, in_deficit, Experienced, DeficitGrounding),
    % Ground the word settled in the lived satisfaction.
    symbol_exchange_ground(settled, satisfied, Experienced, SatisfiedGrounding).

% symbol_exchange_produce(+Groundings, +Condition, -Word): the speaking direction - the word for a condition.
symbol_exchange_produce(Groundings, Condition, Word) :-
    % Find the grounding that pairs a word with this condition.
    (   memberchk(grounding(Word, Condition), Groundings)
    ->  true
    ;   throw(error(symbol_exchange_no_word_for_condition(Condition),
                    context(symbol_exchange_produce/3, "no word is grounded in this condition")))
    ).

% symbol_exchange_recognize(+Groundings, +Word, -Condition): the hearing direction - hear a word, find its condition.
symbol_exchange_recognize(Groundings, Word, Condition) :-
    % Hearing the word changes the mind's language state through the reused word bank, exactly once.
    once(language_hear([Word], _TraceIdentifiers)),
    % Find the condition the word is grounded in.
    (   memberchk(grounding(Word, Condition), Groundings)
    ->  true
    ;   throw(error(symbol_exchange_unknown_word(Word),
                    context(symbol_exchange_recognize/3, "the mind has not grounded this word in any condition")))
    ).

% symbol_exchange_reply(+Groundings, +Drives, +Body, +HeardWords, -ReplyWords): hear, then reply from the inside out.
symbol_exchange_reply(Groundings, Drives, Body, HeardWords, ReplyWords) :-
    % The heard words must be a list of words - anything else is refused by name.
    (   is_list(HeardWords)
    ->  true
    ;   throw(error(symbol_exchange_bad_words(HeardWords),
                    context(symbol_exchange_reply/5, "the heard words must be a list")))
    ),
    % Read the mind's own condition FIRST, so a mind that cannot answer never mutates the word bank by listening.
    symbol_exchange_condition(Drives, Body, Condition),
    % The incoming words arrive through the reused word bank, changing the mind's language state, exactly once.
    once(language_hear(HeardWords, _TraceIdentifiers)),
    % A mind in deficit names its state and the state it seeks; a satisfied mind speaks one settled word.
    (   Condition == in_deficit
    ->  symbol_exchange_produce(Groundings, in_deficit, StateWord),
        % The word for the state the drive defends.
        symbol_exchange_produce(Groundings, satisfied, SoughtWord),
        % The childlike two-word reply: what I am, what I seek.
        ReplyWords = [StateWord, SoughtWord]
    ;   symbol_exchange_produce(Groundings, satisfied, SettledWord),
        % The one-word reply of a mind at its set-point.
        ReplyWords = [SettledWord]
    ).
