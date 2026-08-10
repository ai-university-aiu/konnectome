% Declare this file as the 'mode_register' module and list the predicates it exports.
:- module(mode_register, [
    % mode_register_new/6: build one construct's hybrid automaton, checking every block.
    mode_register_new/6,
    % mode_register_check/1: judge a hybrid automaton's four blocks, refusing aloud by name.
    mode_register_check/1,
    % mode_register_current/2: the mode the construct is in right now.
    mode_register_current/2,
    % mode_register_entries/2: the mode register block itself, entry by entry.
    mode_register_entries/2,
    % mode_register_modes/2: the formal names of every mode the register holds.
    mode_register_modes/2,
    % mode_register_size/2: how many modes the register holds - itself a statement.
    mode_register_size/2,
    % mode_register_transfer/3: the rule that holds while a named mode is current.
    mode_register_transfer/3,
    % mode_register_current_rule/2: the rule that holds right now.
    mode_register_current_rule/2,
    % mode_register_transitions/2: the transition table block.
    mode_register_transitions/2,
    % mode_register_faults/2: the fault regimes and watchdogs block.
    mode_register_faults/2,
    % mode_register_of_construct_kind/2: the canonical register for a konnectome construct kind.
    mode_register_of_construct_kind/2,
    % mode_register_construct_rule/2: the rule an engine should apply, read through the register.
    mode_register_construct_rule/2
]).

% Import the list utilities used for membership, sorting and length checks.
:- use_module(library(lists), [memberchk/2, member/2]).
% Import the type checker that judges a store's shape and refuses a hole aloud.
:- use_module(library(error), [must_be/2, domain_error/2, existence_error/2, type_error/2]).

% ---------------------------------------------------------------------------
% THE FORMALISM (the design authority, Parts One and Two)
% ---------------------------------------------------------------------------
%
% The guiding corpus does not ask konnectome to invent a mode register; it hands one over, in the
% same words, beside every layer. STATE is the continuous instantaneous condition; MODE is the
% discrete operating regime; and the formalism is the HYBRID AUTOMATON - a mode register, per-mode
% transfer functions, a transition table, and fault watchdogs - under the admission rule that a
% regime enters the register only if the healthy system uses it. konnectome names the term what the
% corpus names it:
%
%     hybrid_automaton(CurrentMode, Register, Transfers, Transitions, Faults)
%
% CurrentMode  - the atom naming the mode the construct is in right now; the index into the register.
% Register     - the list of mode_entry(FormalName, CoinedName, Gloss) terms. Three fields and no
%                more: the rule is NOT here, the parameters are NOT here, and the entry and exit
%                conditions are NOT here. Keeping them out is what makes the register readable as a
%                list of what a construct can BE.
% Transfers    - the parallel block of transfer(FormalName, Rule) terms, one per register entry,
%                carrying the input-to-output law that holds while that mode is current. konnectome's
%                Rule is its existing construct kind term, which is where its parameters already live.
% Transitions  - the table of transition(Trigger, FromMode, ToMode, Timescale, Agency) rows. Agency
%                is the corpus's answer to who governs the machine and is never omitted. Guards are
%                deliberately not a column; the corpus folds them into the trigger clause.
% Faults       - the block of fault(BoundarySignature, WarningCondition, Watchdog) terms. Faults are
%                WATCHED, never admitted as modes.
%
% A REGISTER OF ONE IS FIRST-CLASS, NOT DEGENERATE. The corpus says so in as many words, three
% separate times, and states the interpretation directly: the length of a register is a statement of
% what the system trusts the component to decide. konnectome's existing single-rule constructs are
% therefore not a debt to be repaid but faithful models of mode-poor components, and this slice
% re-expresses them as registers of one WITHOUT CHANGING A SINGLE NUMBER.
%
% Two fields the corpus carries and this slice does NOT, declared here so the gap is a decision and
% not an oversight: the per-mode CONFIDENCE tag, which the design authority's Part Nine defers by
% name, and the per-mode ADMITTED-AS-FAULT flag, which belongs with the supervisor channel that does
% not exist yet. Both enter with the slices that need them.

% ---------------------------------------------------------------------------
% THE SHAPE GUARD
% ---------------------------------------------------------------------------

% mode_register_shape(+Automaton, -Current, -Register, -Transfers, -Transitions, -Faults): open a term.
mode_register_shape(Automaton, Current, Register, Transfers, Transitions, Faults) :-
    % An unbound automaton is a hole, and a hole is refused before anything is read out of it.
    (   var(Automaton)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % A term that is not the hybrid automaton is refused aloud, naming what arrived.
    (   Automaton = hybrid_automaton(Current, Register, Transfers, Transitions, Faults)
    ->  true
    ;   domain_error(hybrid_automaton, Automaton)
    ).

% ---------------------------------------------------------------------------
% THE CONSTRUCTOR AND THE CHECKER
% ---------------------------------------------------------------------------

% mode_register_new(+Current, +Register, +Transfers, +Transitions, +Faults, -Automaton): build and judge.
mode_register_new(Current, Register, Transfers, Transitions, Faults, Automaton) :-
    % Assemble the four blocks and the current-mode slot into the corpus's own term.
    Automaton = hybrid_automaton(Current, Register, Transfers, Transitions, Faults),
    % Judge every block before the term is handed back, so an invalid automaton never exists.
    mode_register_check(Automaton).

% mode_register_check(+Automaton): judge all four blocks, refusing every fault aloud and by name.
mode_register_check(Automaton) :-
    % Open the automaton, refusing a hole or an impostor term.
    mode_register_shape(Automaton, Current, Register, Transfers, Transitions, Faults),
    % Judge the register block and read back the formal names it declares.
    mode_register_check_register(Register, Names),
    % Judge the current-mode slot against the names the register declares.
    mode_register_check_current(Current, Names),
    % Judge the transfer block against those same names, in one place, so the two cannot drift apart.
    mode_register_check_transfers(Transfers, Names),
    % Judge the transition table's rows and endpoints against those same names.
    mode_register_check_transitions(Transitions, Names),
    % Judge the fault block's rows.
    mode_register_check_faults(Faults).

% mode_register_check_store(+Store): refuse a hole, a partial list, or a non-list, all the same way.
mode_register_check_store(Store) :-
    % An unbound or partial list is refused as an instantiation fault; a non-list as a type fault.
    must_be(list, Store).

% mode_register_check_register(+Register, -Names): judge the register block, returning its names.
mode_register_check_register(Register, Names) :-
    % Judge the store's shape first, so a hole can never be read as an empty register.
    mode_register_check_store(Register),
    % A register of zero is not a register: the corpus records none of zero at any grain.
    (   Register == []
    ->  domain_error(non_empty_mode_register, [])
    ;   true
    ),
    % Read the formal name out of every entry, refusing any entry that is not a mode entry.
    mode_register_entry_names(Register, Names),
    % Two entries may not share a name, or the transfer lookup would be ambiguous.
    mode_register_check_distinct(Names, distinct_mode_names).

% mode_register_entry_names(+Register, -Names): the formal name of every entry, judged as it is read.
% An exhausted register yields no more names.
mode_register_entry_names([], []).
% Each entry must be a mode entry of three fields whose formal name is an atom.
mode_register_entry_names([Entry|Rest], [Name|Names]) :-
    % Refuse anything that is not the corpus's three-field entry, naming what arrived.
    (   Entry = mode_entry(Name, _Coined, _Gloss)
    ->  true
    ;   domain_error(mode_entry, Entry)
    ),
    % A mode is named by an atom, so a register can never be keyed on a number or a compound.
    must_be(atom, Name),
    % Read the names out of the remaining entries.
    mode_register_entry_names(Rest, Names).

% mode_register_check_distinct(+Names, +Complaint): refuse a repeated name under the given complaint.
mode_register_check_distinct(Names, Complaint) :-
    % Sort the names while keeping duplicates, so a repeat is visible as a length difference.
    msort(Names, Sorted),
    % Sort them again while dropping duplicates.
    sort(Names, Unique),
    % A shorter unique list means a name was declared twice; refuse it, showing the offending list.
    (   length(Sorted, Count), length(Unique, Count)
    ->  true
    ;   domain_error(Complaint, Sorted)
    ).

% mode_register_check_current(+Current, +Names): the construct must stand in a mode it actually has.
mode_register_check_current(Current, Names) :-
    % An unbound current mode is refused, because a membership check would bind it to the first entry.
    must_be(atom, Current),
    % A mode absent from the register is refused aloud by name.
    (   memberchk(Current, Names)
    ->  true
    ;   existence_error(mode_entry, Current)
    ).

% mode_register_check_transfers(+Transfers, +Names): judge the per-mode transfer function block.
mode_register_check_transfers(Transfers, Names) :-
    % Judge this store exactly as the register store was judged; every store is judged the same way.
    mode_register_check_store(Transfers),
    % Read the mode name out of every transfer row, refusing any row that is not a transfer.
    mode_register_transfer_names(Transfers, TransferNames),
    % A rule for a mode the register never declared is refused aloud by name.
    mode_register_check_declared(TransferNames, Names),
    % Two rules under one mode name are refused: the construct would not know which machine it is.
    mode_register_check_distinct(TransferNames, distinct_transfer_modes),
    % And every declared mode must carry a rule, or it is a mode that cannot run.
    mode_register_check_covered(Names, TransferNames).

% mode_register_transfer_names(+Transfers, -Names): the mode name of every transfer row.
% An exhausted transfer block yields no more names.
mode_register_transfer_names([], []).
% Each row must be a transfer of two fields whose mode name is an atom.
mode_register_transfer_names([Row|Rest], [Name|Names]) :-
    % Refuse anything that is not a transfer row, naming what arrived.
    (   Row = transfer(Name, _Rule)
    ->  true
    ;   domain_error(transfer, Row)
    ),
    % A transfer is keyed by an atom, the same key shape the register uses.
    must_be(atom, Name),
    % Read the names out of the remaining rows.
    mode_register_transfer_names(Rest, Names).

% mode_register_check_declared(+Used, +Names): every name used must be a name the register declares.
% An exhausted list of used names is clean.
mode_register_check_declared([], _Names).
% Each used name must appear in the register.
mode_register_check_declared([Used|Rest], Names) :-
    % A mode name is an atom, and an UNBOUND one would be bound by the check below to the register's
    % first declared name - answering a hole with a mode that belongs to somebody else. Judge the key
    % here, in the ONE place both the transfer block and the transition table come through.
    must_be(atom, Used),
    % Refuse a name the register never declared, so nothing points off the end of the register.
    (   memberchk(Used, Names)
    ->  true
    ;   existence_error(mode_entry, Used)
    ),
    % Judge the remaining used names.
    mode_register_check_declared(Rest, Names).

% mode_register_check_covered(+Names, +TransferNames): every declared mode must carry a rule.
% An exhausted register is fully covered.
mode_register_check_covered([], _TransferNames).
% Each declared mode must find its rule in the transfer block.
mode_register_check_covered([Name|Rest], TransferNames) :-
    % Refuse a mode with no transfer function; a mode that cannot run is not a mode.
    (   memberchk(Name, TransferNames)
    ->  true
    ;   existence_error(transfer_function, Name)
    ),
    % Judge the remaining declared modes.
    mode_register_check_covered(Rest, TransferNames).

% mode_register_check_transitions(+Transitions, +Names): judge the transition table block.
mode_register_check_transitions(Transitions, Names) :-
    % Judge this store exactly as the other stores are judged.
    mode_register_check_store(Transitions),
    % Judge every row's shape and both of its endpoints.
    mode_register_check_rows(Transitions, Names).

% mode_register_check_rows(+Transitions, +Names): judge each transition row in turn.
% An exhausted table is clean.
mode_register_check_rows([], _Names).
% Each row carries a trigger, a direction, a timescale and an agency - four fields, or none.
mode_register_check_rows([Row|Rest], Names) :-
    % Refuse anything that is not the corpus's four-field row, naming what arrived.
    (   Row = transition(_Trigger, From, To, _Timescale, _Agency)
    ->  true
    ;   domain_error(transition, Row)
    ),
    % Both endpoints must be modes the register declares, or the machine leaves its own register.
    mode_register_check_declared([From, To], Names),
    % Judge the remaining rows.
    mode_register_check_rows(Rest, Names).

% mode_register_check_faults(+Faults): judge the fault regimes and watchdogs block.
mode_register_check_faults(Faults) :-
    % Judge this store exactly as the other stores are judged.
    mode_register_check_store(Faults),
    % Judge every fault entry's shape.
    mode_register_check_fault_rows(Faults).

% mode_register_check_fault_rows(+Faults): judge each fault entry in turn.
% An exhausted fault block is clean.
mode_register_check_fault_rows([]).
% Each entry carries a boundary signature, a warning condition and a watchdog - three fields, or none.
mode_register_check_fault_rows([Row|Rest]) :-
    % Refuse anything that is not the corpus's three-field fault entry, naming what arrived.
    (   Row = fault(_Boundary, _Warning, _Watchdog)
    ->  true
    ;   domain_error(fault, Row)
    ),
    % Judge the remaining entries.
    mode_register_check_fault_rows(Rest).

% ---------------------------------------------------------------------------
% READING A REGISTER
% ---------------------------------------------------------------------------

% mode_register_current(+Automaton, -Current): the mode the construct is in right now.
mode_register_current(Automaton, Current) :-
    % Open the automaton, refusing a hole or an impostor term.
    mode_register_shape(Automaton, Current, _Register, _Transfers, _Transitions, _Faults).

% mode_register_entries(+Automaton, -Register): the mode register block itself, entry by entry.
mode_register_entries(Automaton, Register) :-
    % Open the automaton and hand back its register block.
    mode_register_shape(Automaton, _Current, Register, _Transfers, _Transitions, _Faults).

% mode_register_modes(+Automaton, -Names): the formal names of every mode the register holds.
mode_register_modes(Automaton, Names) :-
    % Open the automaton and read its register block.
    mode_register_entries(Automaton, Register),
    % Judge the store's shape before walking it, so a hole is never walked as an empty list.
    mode_register_check_store(Register),
    % Read the formal name out of every entry.
    mode_register_entry_names(Register, Names).

% mode_register_size(+Automaton, -Size): how many modes the register holds - itself a statement.
mode_register_size(Automaton, Size) :-
    % Read the register's names.
    mode_register_modes(Automaton, Names),
    % The size of the register is how many modes it names.
    length(Names, Size).

% mode_register_transfer(+Automaton, +Mode, -Rule): the rule that holds while Mode is current.
mode_register_transfer(Automaton, Mode, Rule) :-
    % Open the automaton and read its transfer block.
    mode_register_shape(Automaton, _Current, _Register, Transfers, _Transitions, _Faults),
    % An unbound key is refused: a membership lookup would bind it and return another mode's rule.
    must_be(atom, Mode),
    % Judge the store's shape before searching it.
    mode_register_check_store(Transfers),
    % Look the mode up by its guarded key, and refuse aloud when the register does not hold it.
    (   memberchk(transfer(Mode, Found), Transfers)
    ->  Rule = Found
    ;   existence_error(mode_entry, Mode)
    ).

% mode_register_current_rule(+Automaton, -Rule): the rule that holds right now.
mode_register_current_rule(Automaton, Rule) :-
    % Read the mode the construct is in.
    mode_register_current(Automaton, Current),
    % Read the rule filed under that mode.
    mode_register_transfer(Automaton, Current, Rule).

% mode_register_transitions(+Automaton, -Transitions): the transition table block.
mode_register_transitions(Automaton, Transitions) :-
    % Open the automaton and hand back its transition table.
    mode_register_shape(Automaton, _Current, _Register, _Transfers, Transitions, _Faults).

% mode_register_faults(+Automaton, -Faults): the fault regimes and watchdogs block.
mode_register_faults(Automaton, Faults) :-
    % Open the automaton and hand back its fault block.
    mode_register_shape(Automaton, _Current, _Register, _Transfers, _Transitions, Faults).

% ---------------------------------------------------------------------------
% KONNECTOME'S OWN CONSTRUCTS, AS REGISTERS OF ONE
% ---------------------------------------------------------------------------
%
% Every construct kind konnectome runs today is a mode-poor component in the corpus's own sense: it
% runs one machine, under one named regime, and never switches. Each therefore earns a register of
% one - stated proudly - and each entry carries the corpus's three fields: the formal name, the
% coined name always prefixed "the", and a one-clause gloss of what the construct does while in it.
% The per-mode transfer function is the construct kind term ITSELF, which is what makes routing every
% construct through its register incapable of changing a single number.
%
% The transition table is empty because a register of one has nowhere to go, and the fault block is
% empty because faults are watched by a supervisor channel konnectome has not built yet.

% mode_register_construct_mode(+Kind, -Formal, -Coined, -Gloss): one construct kind's single mode.
% A CLOCK construct keeps the engine's time and does nothing else.
mode_register_construct_mode(clock, free_running_clock, 'the Metronome',
    'advances its own count by exactly one every tick, so the engine has a time to keep').
% A COPY construct reads another named construct's committed value.
mode_register_construct_mode(copy(_Other), committed_copy, 'the Echo',
    'takes the named other construct''s CURRENT value, never that construct''s future').
% A HOLD construct carries its own value forward untouched.
mode_register_construct_mode(hold, held_value, 'the Kept Reading',
    'keeps its own current value unchanged from one tick to the next').
% A SOURCE construct holds whatever the world has clamped on it.
mode_register_construct_mode(source, clamped_input, 'the Clamped Window',
    'holds the reading the world clamps on it, unchanged, for as long as the clamp lasts').
% A RELAY construct passes its gathered input at a gain fixed in its own wiring.
mode_register_construct_mode(relay(_Gain), tonic_relay, 'the Faithful Relay',
    'passes its total weighted input onward, scaled by its own fixed gain').
% A MODULATED RELAY passes its gathered input at a gain the broadcast sets where it stands.
mode_register_construct_mode(relay_modulated(_Base, _Modulator), modulated_tonic_relay,
    'the Listening Relay',
    'passes its total weighted input onward at a gain the broadcast sets in its own territory').

% mode_register_of_construct_kind(+Kind, -Automaton): the canonical register of one for a kind.
mode_register_of_construct_kind(Kind, Automaton) :-
    % An unbound kind is refused: a dispatch on a hole would bind it to the first clause it met.
    (   var(Kind)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % Look up this kind's single mode; a kind konnectome does not run simply has no register.
    mode_register_construct_mode(Kind, Formal, Coined, Gloss),
    % Build the register of one, filing the construct's own rule as that mode's transfer function.
    mode_register_new(Formal,
                      [mode_entry(Formal, Coined, Gloss)],
                      [transfer(Formal, Kind)],
                      [],
                      [],
                      Automaton).

% mode_register_construct_rule(+Kind, -Rule): the rule an engine should apply for a construct kind.
mode_register_construct_rule(Kind, Rule) :-
    % An unbound kind is refused here too, at the door every engine now comes through.
    (   var(Kind)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % A registered kind's rule is read THROUGH its register, which is what makes the register real.
    (   mode_register_of_construct_kind(Kind, Automaton)
    ->  mode_register_current_rule(Automaton, Rule)
    % An unregistered kind passes through unchanged, so this resolver never becomes a second
    % authority on what an engine accepts: whatever refusal an engine has, it keeps, and it names
    % exactly the kind the caller wrote. Where an engine has NO refusal - the tick engine has none,
    % which is Observation-7 in the ledger - pass-through preserves that silence rather than
    % inventing a policy here, so this slice changes no engine's admission rule.
    ;   Rule = Kind
    ).
