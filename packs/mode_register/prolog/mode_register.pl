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
    % mode_register_departure/3: where the table sends this construct, under a NAMED AGENCY.
    mode_register_departure/3,
    % mode_register_faults/2: the fault regimes and watchdogs block.
    mode_register_faults/2,
    % mode_register_of_construct_kind/2: the canonical register for a konnectome construct kind.
    mode_register_of_construct_kind/2,
    % mode_register_construct_rule/2: the rule an engine should apply, read through the register.
    mode_register_construct_rule/2,
    % mode_register_confidence_grades/1: the confidence grades the corpus was observed to use.
    mode_register_confidence_grades/1,
    % mode_register_tags/3: the tags one mode entry carries, which for most entries is none.
    mode_register_tags/3,
    % mode_register_confidence/3: the confidence grade a mode carries, or the refusal to invent one.
    mode_register_confidence/3,
    % mode_register_admissions/2: every mode admitted as a fault, with the rationale that admitted it.
    mode_register_admissions/2
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
%                WATCHED, and are admitted as modes only where the entry says so and says why - which
%                is slice 66's repair and is set out below.
%
% A REGISTER OF ONE IS FIRST-CLASS, NOT DEGENERATE. The corpus says so in as many words, three
% separate times, and states the interpretation directly: the length of a register is a statement of
% what the system trusts the component to decide. konnectome's existing single-rule constructs are
% therefore not a debt to be repaid but faithful models of mode-poor components, and this slice
% re-expresses them as registers of one WITHOUT CHANGING A SINGLE NUMBER.
%
% Two fields the corpus carries and slice 39 did NOT build, declared there so the gap would be a
% decision and not an oversight: the per-mode CONFIDENCE tag, which the design authority's Part Nine
% defers by name, and the per-mode ADMITTED-AS-FAULT flag, which "belongs with the supervisor channel
% that does not exist yet". BOTH ENTER HERE, AT SLICE 66, AND THE LATENESS IS THE POINT - see the
% next section.

% ---------------------------------------------------------------------------
% THE TWO DEFERRED FIELDS, AND WHY THEY ARRIVE TWENTY-SEVEN SLICES LATE (slice 66, OBSERVATION-19)
% ---------------------------------------------------------------------------
%
% THE SUPERVISOR CHANNEL WAS BUILT AT SLICE 42. The deferral written four lines above named its own
% unblocking condition - "the supervisor channel that does not exist yet" - and that condition was
% met three slices later, twenty-two slices before anybody noticed. NOBODY MISREAD ANYTHING: slice 39
% read the design authority correctly, recorded the omission correctly, and stated exactly what would
% release it. WHAT FAILED IS THAT NOTHING WATCHES A DEFERRAL'S CONDITION - a note saying "when X
% exists, revisit this" is invisible on the day X arrives, because the session that builds X is
% looking at X and not at the list of things that were waiting for it. That is OBSERVATION-19 and it
% is worth more than the fields it unblocked.
%
% AND IN THOSE TWENTY-TWO SLICES THE OMISSION HARDENED INTO A RULE THE SOURCE NEVER STATED. The
% supervisor's blanket ban - a declared fault signature may never be a declared mode - was written
% into the README, the tutorial and the vision-set analysis as though it were the design authority's
% own position. IT IS NOT. docs/design/05 Part Four, under a heading reading "TWO QUALIFICATIONS THAT
% A STRICT VALIDATOR WOULD GET WRONG", says the opposite in as many words: "A TAGGED MINORITY OF
% FAULTS ARE ADMITTED INTO THE REGISTER ON A USAGE ARGUMENT, always with the reasoning written inline
% ... The schema therefore needs a per-mode admitted-as-fault flag and a rationale slot, NOT A BLANKET
% EXCLUSION."
%
% WHAT IS BEING REPAIRED IS THE UNRECORDED DEPARTURE, NOT THE STRICTNESS. The argument for the ban -
% that a machine with an official way to be broken will run it silently and forever - is a good
% argument and is not withdrawn; it survives below as the requirement that an admission must SAY WHY.
% What was wrong is that konnectome enforced a stricter rule than its source states with nothing
% anywhere recording the departure, which is the one thing that must not happen.
%
% THE SCHEMA, AND WHY IT ADMITS TWO SHAPES RATHER THAN ONE.
%
%     mode_entry(FormalName, CoinedName, Gloss)          - an untagged entry, and most entries are.
%     mode_entry(FormalName, CoinedName, Gloss, Tags)    - a tagged entry, and the corpus's tagged
%                                                          entries are A MINORITY, in its own words.
%
% THE AUTHORITY'S OWN PHRASE IS "A TAGGED MINORITY", so a schema in which every entry must carry a
% tag block would misdescribe the corpus it is transcribing, and rewriting fifty-odd existing entries
% to carry an empty list would have been a large change that said nothing. The three-field entry is
% not a legacy form to be migrated: it is the untagged majority, and it means what it has always
% meant.
%
% Tags is a list, each element one of:
%
%     admitted_as_fault(Rationale) - this mode names a way the construct BREAKS and is in the register
%                                    anyway, on a usage argument. THE RATIONALE IS REQUIRED AND IS THE
%                                    LOAD-BEARING HALF: without it the softened rule is just a hole.
%                                    An admitted fault must say why it is admitted, in the corpus's own
%                                    manner, and cannot be admitted silently. The corpus's four
%                                    rationales, quoted by the authority, are the model: "admitted only
%                                    as fault"; "a fault regime, admitted only because it names the
%                                    failure"; "a used but pathological standing state, admitted here
%                                    because it is reached routinely in disease and is largely
%                                    reversible"; "admitted because rods progressively escape it to
%                                    contribute in daylight, so it is a normal boundary of operation".
%     confidence(Grade)            - how well established this mode is. The authority: "Confidence is
%                                    operational, not decorative: at least one junction entry REFUSES
%                                    to admit a mode on evidential grounds". The Layer 6 volume carries
%                                    about 340 such tags.
%
% AND AN ENTRY WITHOUT A CONFIDENCE TAG IS NOT A CONFIDENT ENTRY. mode_register_confidence/3 answers
% confidence_not_stated, by name, and never a grade konnectome chose. A silent default here would be
% this build's own recurring failure - a zero that reads as calm - in a field whose whole purpose is
% to record how much the source is prepared to claim.

% ---------------------------------------------------------------------------
% THE CONFIDENCE GRADES
% ---------------------------------------------------------------------------
%
% THE LIST IS A TRANSCRIPTION OF WHAT THE AUTHORITY OBSERVED IN THE CORPUS, NORMALISED INTO THIS
% BUILD'S SNAKE_CASE, AND THAT NORMALISATION IS KONNECTOME'S OWN AND IS SIGNED HERE. The authority
% records the observed values as "high, moderate, moderate on exact rate bands, low, well established,
% and confidence deliberately low". konnectome takes the five distinct GRADES and drops the qualifying
% clause of the second, because "moderate on exact rate bands" is a moderate with a scope note and the
% scope belongs to the mode rather than to the grade.
%
% ANYTHING OUTSIDE THE LIST IS REFUSED ALOUD rather than accepted as a sixth grade, so a new grade has
% to be added here deliberately, by somebody who has read the corpus and can say where it came from.

% mode_register_confidence_grades(-Grades): the confidence grades a mode entry may declare.
mode_register_confidence_grades([high, moderate, low, well_established, deliberately_low]).

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
% Each entry must be a mode entry - untagged or tagged - whose formal name is an atom.
mode_register_entry_names([Entry|Rest], [Name|Names]) :-
    % Open the entry, refusing anything that is neither shape and judging any tags it carries.
    mode_register_open_entry(Entry, Name, _Coined, _Gloss, _Tags),
    % Read the names out of the remaining entries.
    mode_register_entry_names(Rest, Names).

% mode_register_open_entry(+Entry, -Name, -Coined, -Gloss, -Tags): open either shape of mode entry.
% THE UNTAGGED ENTRY IS THE MAJORITY FORM AND ITS TAG BLOCK IS EMPTY, which is a statement that it
% carries no tags and NOT a statement that it was checked and found ordinary.
mode_register_open_entry(Entry, Name, Coined, Gloss, Tags) :-
    % Refuse anything that is neither the three-field nor the four-field entry, naming what arrived.
    (   Entry = mode_entry(Name, Coined, Gloss)
    ->  Tags = []
    ;   Entry = mode_entry(Name, Coined, Gloss, Tags)
    ->  true
    ;   domain_error(mode_entry, Entry)
    ),
    % A mode is named by an atom, so a register can never be keyed on a number or a compound.
    must_be(atom, Name),
    % Judge whatever tags the entry declares, here, in the one place every entry is opened.
    mode_register_check_tags(Tags).

% mode_register_check_tags(+Tags): judge a mode entry's tag block.
mode_register_check_tags(Tags) :-
    % Judge the store's shape first, so a hole can never be read as an untagged entry.
    mode_register_check_store(Tags),
    % Read the name of every tag, refusing any tag this schema does not carry.
    mode_register_tag_names(Tags, Names),
    % ONE TAG OF EACH KIND. Two confidence grades on one mode is a mode with two claims about how well
    % established it is, and two admissions is two rationales where the reader needs one.
    mode_register_check_distinct(Names, distinct_mode_tags).

% mode_register_tag_names(+Tags, -Names): the name of every tag, judged as it is read.
% An exhausted tag block yields no more names.
mode_register_tag_names([], []).
% An ADMITTED-AS-FAULT tag carries the rationale that admitted it, and the rationale is required.
mode_register_tag_names([Tag|Rest], [admitted_as_fault|Names]) :-
    % Commit once the tag's name matches, before the rationale is judged, so the complaint names the tag.
    Tag = admitted_as_fault(Rationale),
    % Commit to this reading of the tag.
    !,
    % THE RATIONALE IS THE LOAD-BEARING HALF and a hole in it would admit a fault silently.
    must_be(atom, Rationale),
    % AND AN EMPTY RATIONALE IS NOT A RATIONALE. A blank slot passes a shape check and says nothing,
    % which is exactly the admission this rule exists to prevent.
    (   Rationale == ''
    ->  domain_error(mode_register_admission_rationale, Rationale)
    ;   true
    ),
    % Read the names out of the remaining tags.
    mode_register_tag_names(Rest, Names).
% A CONFIDENCE tag carries one of the grades the corpus was observed to use, and no other.
mode_register_tag_names([Tag|Rest], [confidence|Names]) :-
    % Commit once the tag's name matches.
    Tag = confidence(Grade),
    % Commit to this reading of the tag.
    !,
    % A grade is named by an atom, the same key shape a mode name uses.
    must_be(atom, Grade),
    % A grade outside the transcribed list is refused, so a sixth grade must be added deliberately.
    mode_register_confidence_grades(Grades),
    % Refuse an unknown grade aloud, naming the grade that arrived.
    (   memberchk(Grade, Grades)
    ->  true
    ;   domain_error(mode_register_confidence_grade, Grade)
    ),
    % Read the names out of the remaining tags.
    mode_register_tag_names(Rest, Names).
% Anything else is refused rather than carried along as a tag nobody can read back.
mode_register_tag_names([Tag|_Rest], _Names) :-
    % An unrecognised tag silently ignored would let a misspelt admission read as an ordinary mode.
    domain_error(mode_entry_tag, Tag).

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

% ---------------------------------------------------------------------------
% READING A DEPARTURE OUT OF THE TABLE, UNDER A NAMED AGENCY (slice 41)
% ---------------------------------------------------------------------------
%
% AGENCY WAS ALWAYS A COLUMN; UNTIL THIS SLICE NOTHING READ IT. Slice 40 made the transition table
% the sole authority on direction, and every row it wrote was self_selected, so a lookup that simply
% took the first row leaving a mode could not be wrong. The moment a SECOND agency writes rows into
% the same table - which is exactly what slice 41 does - "the first row leaving this mode" stops
% being a question with one answer, and a lookup that does not name the agency it wants would return
% whichever row happened to be declared first. That is the default-drift lens, caught before it paid
% out: the departure lookup is keyed on the agency HERE, in the one place both routes come through,
% rather than in each caller.
%
% AMBIGUITY IS REFUSED RATHER THAN RESOLVED. Two rows leaving one mode under one agency describe a
% construct that does not know which machine it becomes, and the corpus never writes such a table.
% konnectome refuses it aloud instead of quietly preferring the earlier row.

% mode_register_departure(+Automaton, +Agency, -ToMode): where the table sends this construct when it
% leaves the mode it is standing in, under the named agency.
mode_register_departure(Automaton, Agency, ToMode) :-
    % An unbound agency is refused: it would match the first row of ANY agency and answer confidently.
    must_be(atom, Agency),
    % Read the judged mode the construct is departing from; the constructor judged this slot already.
    mode_register_current(Automaton, FromMode),
    % Read the transition table out of the register, so the table is the one authority on direction.
    mode_register_transitions(Automaton, Transitions),
    % Judge the store's shape before walking it, so a hole is never walked as an empty table.
    mode_register_check_store(Transitions),
    % Gather every destination this agency declares from this mode; the trigger is deliberately not
    % re-named here, so the table cannot drift out from under a lookup that spells its trigger twice.
    findall(To, member(transition(_Trigger, FromMode, To, _Timescale, Agency), Transitions), Destinations),
    % One destination is the answer; none and many are both refused aloud, by different names.
    (   Destinations = [Only]
    ->  ToMode = Only
    ;   Destinations == []
    ->  existence_error(mode_transition, FromMode)
    ;   domain_error(single_mode_departure, Destinations)
    ).

% ---------------------------------------------------------------------------
% READING THE TWO TAGGED FIELDS (slice 66)
% ---------------------------------------------------------------------------

% mode_register_tags(+Automaton, +Mode, -Tags): the tags one mode entry carries.
mode_register_tags(Automaton, Mode, Tags) :-
    % An unbound key is refused: a lookup would bind it and hand back another mode's tags.
    must_be(atom, Mode),
    % Read the register block through the automaton's own accessor.
    mode_register_entries(Automaton, Register),
    % Judge the store's shape before searching it, so a hole is never searched as an empty register.
    mode_register_check_store(Register),
    % Find the named entry, judging it as it is opened, and refuse a mode the register does not hold.
    (   mode_register_find_entry(Register, Mode, Found)
    ->  Tags = Found
    ;   existence_error(mode_entry, Mode)
    ).

% mode_register_find_entry(+Register, +Mode, -Tags): the named entry's tags, judged as they are read.
% The entry at the front of what remains is either the one wanted or one to step past.
mode_register_find_entry([Entry|Rest], Mode, Tags) :-
    % Open this entry, which judges its shape and its tag block whether or not it is the one wanted.
    mode_register_open_entry(Entry, Name, _Coined, _Gloss, Found),
    % Take this entry's tags when its name matches, and otherwise search the remaining entries.
    (   Name == Mode
    ->  Tags = Found
    ;   mode_register_find_entry(Rest, Mode, Tags)
    ).

% mode_register_confidence(+Automaton, +Mode, -Confidence): the confidence a mode declares.
% AN ENTRY WITHOUT A CONFIDENCE TAG ANSWERS confidence_not_stated, BY NAME, AND NEVER A GRADE. The
% corpus's own confidence field is operational rather than decorative, so a silent default here would
% put a claim in konnectome's mouth that no source made.
mode_register_confidence(Automaton, Mode, Confidence) :-
    % Read the mode's tags, which refuses a hole, an impostor entry and a mode the register lacks.
    mode_register_tags(Automaton, Mode, Tags),
    % Take the declared grade where there is one, and say so plainly where there is not.
    (   memberchk(confidence(Grade), Tags)
    ->  Confidence = confidence(Grade)
    ;   Confidence = confidence_not_stated
    ).

% mode_register_admissions(+Automaton, -Admissions): every mode admitted as a fault, with its reason.
% THIS IS WHAT MAKES THE DEPARTURE FROM THE BLANKET RULE READABLE. A softened rule whose exceptions
% cannot be listed is a hole; a softened rule whose exceptions each carry their argument is a design.
mode_register_admissions(Automaton, Admissions) :-
    % Read the register block through the automaton's own accessor.
    mode_register_entries(Automaton, Register),
    % Judge the store's shape before walking it.
    mode_register_check_store(Register),
    % Gather the admitted modes, judging every entry on the way past.
    mode_register_gather_admissions(Register, Admissions).

% mode_register_gather_admissions(+Register, -Admissions): the admitted entries, entry by entry.
% An exhausted register admits nothing.
mode_register_gather_admissions([], []).
% Each entry is admitted or is not, and either way it is judged as it is opened.
mode_register_gather_admissions([Entry|Rest], Admissions) :-
    % Open the entry, which judges its shape and its tag block.
    mode_register_open_entry(Entry, Name, _Coined, _Gloss, Tags),
    % An admitted entry joins the list carrying the rationale that admitted it; anything else passes.
    (   memberchk(admitted_as_fault(Rationale), Tags)
    ->  Admissions = [mode_register_admission(Name, Rationale)|MoreAdmissions]
    ;   Admissions = MoreAdmissions
    ),
    % Gather the remaining entries.
    mode_register_gather_admissions(Rest, MoreAdmissions).

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
