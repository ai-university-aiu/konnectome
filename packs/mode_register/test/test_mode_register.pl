% Load the mode_register module under test from the library path.
:- use_module(library(mode_register)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% A ready-made one-mode automaton used by the reading tests below.
% one_mode_automaton(-Automaton): the smallest register the corpus admits, stated proudly.
one_mode_automaton(Automaton) :-
    % Build a register of exactly one mode, its transfer, an empty table, and no faults.
    mode_register_new(tonic_relay,
                      [mode_entry(tonic_relay, 'the Faithful Relay', 'passes what it is given')],
                      [transfer(tonic_relay, relay(1))],
                      [],
                      [],
                      Automaton).

% Open the test block for the mode_register pack.
:- begin_tests(mode_register).

% ---------------------------------------------------------------------------
% THE SHAPE OF A HYBRID AUTOMATON
% ---------------------------------------------------------------------------

% A REGISTER OF ONE IS FIRST-CLASS: the corpus states it proudly three times, so it must build.
test(a_register_of_one_is_first_class) :-
    % Build the smallest admissible register.
    one_mode_automaton(Automaton),
    % Its size is one, which is a statement about the construct and not a gap.
    mode_register_size(Automaton, Size),
    % The register holds exactly one mode.
    assertion(Size == 1).

% The current mode is the slot the register indexes with, and it reads back as it was set.
test(the_current_mode_reads_back) :-
    % Build the smallest admissible register.
    one_mode_automaton(Automaton),
    % Read the mode the construct is currently in.
    mode_register_current(Automaton, Current),
    % It is the mode the automaton was built in.
    assertion(Current == tonic_relay).

% The register block lists what the construct can BE, and nothing about how it does it.
test(the_register_lists_its_mode_names) :-
    % Build the smallest admissible register.
    one_mode_automaton(Automaton),
    % Read the names of every mode in the register.
    mode_register_modes(Automaton, Modes),
    % The one-mode register names exactly its one mode.
    assertion(Modes == [tonic_relay]).

% THE PER-MODE TRANSFER FUNCTION is the separate block that says how the construct behaves.
test(the_current_mode_names_the_rule) :-
    % Build the smallest admissible register.
    one_mode_automaton(Automaton),
    % Read the rule that holds while the current mode holds.
    mode_register_current_rule(Automaton, Rule),
    % It is the construct's own update rule, unchanged.
    assertion(Rule == relay(1)).

% THE TRANSITION TABLE is present and empty: a one-mode register has nowhere to go.
test(a_one_mode_transition_table_is_empty) :-
    % Build the smallest admissible register.
    one_mode_automaton(Automaton),
    % Read the transition table.
    mode_register_transitions(Automaton, Transitions),
    % A register of one admits no transition rows at all.
    assertion(Transitions == []).

% THE FAULT BLOCK is present and empty: faults are watched, never admitted as modes.
test(the_fault_block_is_present_and_empty) :-
    % Build the smallest admissible register.
    one_mode_automaton(Automaton),
    % Read the fault regimes.
    mode_register_faults(Automaton, Faults),
    % No fault regime is recorded until the supervisor channel exists.
    assertion(Faults == []).

% ---------------------------------------------------------------------------
% REFUSALS: EVERY STORE JUDGED THE SAME WAY (the unbound-wrong-judgement lens)
% ---------------------------------------------------------------------------

% An unbound automaton is refused, never read as though it were a term.
test(refuses_an_unbound_automaton, throws(error(instantiation_error, _))) :-
    % Read the current mode of nothing at all.
    mode_register_current(_Unbound, _Current).

% A term that is not a hybrid automaton is refused aloud by name.
test(refuses_a_term_that_is_not_an_automaton,
     throws(error(domain_error(hybrid_automaton, mystery), _))) :-
    % Read the current mode of an impostor term.
    mode_register_current(mystery, _Current).

% A REGISTER OF ZERO IS NOT A REGISTER: the corpus records none of zero at any grain.
test(refuses_an_empty_register,
     throws(error(domain_error(non_empty_mode_register, []), _))) :-
    % Try to build an automaton with no modes at all.
    mode_register_new(tonic_relay, [], [], [], [], _Automaton).

% An unbound register store is refused: an unbound list argument to maplist binds silently to [].
test(refuses_an_unbound_register,
     throws(error(instantiation_error, _))) :-
    % Try to build an automaton whose register is a hole.
    mode_register_new(tonic_relay, _Hole, [], [], [], _Automaton).

% A partial register list is refused: a partial list is silently truncated and the caller's tail mutated.
test(refuses_a_partial_register,
     throws(error(instantiation_error, _))) :-
    % Try to build an automaton whose register runs off into an unbound tail.
    mode_register_new(tonic_relay,
                      [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')|_Tail],
                      [transfer(tonic_relay, relay(1))], [], [], _Automaton).

% A register holding something that is not a mode entry is refused by name.
test(refuses_a_malformed_register_entry,
     throws(error(domain_error(mode_entry, mystery), _))) :-
    % Try to build an automaton whose register holds a bare atom.
    mode_register_new(tonic_relay, [mystery], [transfer(tonic_relay, relay(1))],
                      [], [], _Automaton).

% Two entries may not share a name, or the transfer lookup would be ambiguous.
test(refuses_a_duplicate_mode_name,
     throws(error(domain_error(distinct_mode_names, [tonic_relay, tonic_relay]), _))) :-
    % Try to build a register naming the same mode twice.
    mode_register_new(tonic_relay,
                      [mode_entry(tonic_relay, 'the First', 'one'),
                       mode_entry(tonic_relay, 'the Second', 'two')],
                      [transfer(tonic_relay, relay(1))], [], [], _Automaton).

% A mode name must be an atom, so a register can never be keyed on a compound or a number.
test(refuses_a_mode_name_that_is_not_an_atom,
     throws(error(type_error(atom, 7), _))) :-
    % Try to build a register whose mode is named by a number.
    mode_register_new(7, [mode_entry(7, 'the Numbered', 'one')],
                      [transfer(7, relay(1))], [], [], _Automaton).

% An unbound current mode is refused: a membership check would bind it to the first entry.
test(refuses_an_unbound_current_mode,
     throws(error(instantiation_error, _))) :-
    % Try to build an automaton whose current mode is a hole.
    mode_register_new(_Hole, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [transfer(tonic_relay, relay(1))], [], [], _Automaton).

% A current mode absent from the register is refused: a construct cannot be in a mode it does not have.
test(refuses_a_current_mode_absent_from_the_register,
     throws(error(existence_error(mode_entry, burst), _))) :-
    % Try to build an automaton standing in a mode its register never declared.
    mode_register_new(burst, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [transfer(tonic_relay, relay(1))], [], [], _Automaton).

% ---------------------------------------------------------------------------
% REFUSALS: THE TWO BLOCKS JUDGED IN ONE PLACE (the default-drift lens)
% ---------------------------------------------------------------------------

% An unbound transfer store is refused exactly as the register store is: judge every store the same way.
test(refuses_an_unbound_transfer_block,
     throws(error(instantiation_error, _))) :-
    % Try to build an automaton whose transfer block is a hole.
    mode_register_new(tonic_relay, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      _Hole, [], [], _Automaton).

% Every declared mode must carry a transfer function: a mode with no rule is a mode that cannot run.
test(refuses_a_mode_with_no_transfer_function,
     throws(error(existence_error(transfer_function, tonic_relay), _))) :-
    % Try to build a register whose one mode has no rule beneath it.
    mode_register_new(tonic_relay, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [], [], [], _Automaton).

% A transfer function for a mode the register never declared is refused by name.
test(refuses_a_transfer_for_an_undeclared_mode,
     throws(error(existence_error(mode_entry, burst), _))) :-
    % Try to build a register carrying a rule for a mode it does not hold.
    mode_register_new(tonic_relay, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [transfer(tonic_relay, relay(1)), transfer(burst, relay(9))],
                      [], [], _Automaton).

% Two rules for one mode are refused: the construct would not know which machine it is.
test(refuses_two_transfers_for_one_mode,
     throws(error(domain_error(distinct_transfer_modes, [tonic_relay, tonic_relay]), _))) :-
    % Try to build a register carrying two rules under one mode name.
    mode_register_new(tonic_relay, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [transfer(tonic_relay, relay(1)), transfer(tonic_relay, relay(2))],
                      [], [], _Automaton).

% A malformed transfer row is refused by name, never accepted as an opaque term.
test(refuses_a_malformed_transfer_row,
     throws(error(domain_error(transfer, mystery), _))) :-
    % Try to build a register whose transfer block holds a bare atom.
    mode_register_new(tonic_relay, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [mystery], [], [], _Automaton).

% ---------------------------------------------------------------------------
% REFUSALS: THE TRANSITION TABLE AND THE FAULT BLOCK
% ---------------------------------------------------------------------------

% A transition row carries trigger, direction, timescale and agency - four fields, or none.
test(refuses_a_malformed_transition_row,
     throws(error(domain_error(transition, mystery), _))) :-
    % Try to build a register whose transition table holds a bare atom.
    mode_register_new(tonic_relay, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [transfer(tonic_relay, relay(1))], [mystery], [], _Automaton).

% A transition may not run to a mode the register does not hold, or the machine would leave its own register.
test(refuses_a_transition_to_an_undeclared_mode,
     throws(error(existence_error(mode_entry, burst), _))) :-
    % Try to build a table whose row points off the end of the register.
    mode_register_new(tonic_relay, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [transfer(tonic_relay, relay(1))],
                      [transition(drive_above_threshold, tonic_relay, burst, milliseconds, self_selected)],
                      [], _Automaton).

% REVIEW PIN: an unbound transition ENDPOINT is refused, never bound. The review found that the
% endpoint check reached memberchk with an unguarded key, so a caller writing two holes got back a
% transition it never wrote - pointing at the register's FIRST mode, which belongs to another entry.
test(refuses_an_unbound_transition_endpoint,
     throws(error(instantiation_error, _))) :-
    % Try to build a table whose row leaves both of its endpoints as holes.
    mode_register_new(tonic_relay, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [transfer(tonic_relay, relay(1))],
                      [transition(drive_above_threshold, _From, _To, milliseconds, self_selected)],
                      [], _Automaton).

% REVIEW PIN: the destination is judged as strictly as the origin, so neither end can be a hole.
test(refuses_an_unbound_transition_destination,
     throws(error(instantiation_error, _))) :-
    % Try to build a table whose row names its origin and leaves its destination a hole.
    mode_register_new(tonic_relay, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [transfer(tonic_relay, relay(1))],
                      [transition(drive_above_threshold, tonic_relay, _To, milliseconds, self_selected)],
                      [], _Automaton).

% REVIEW PIN: an unbound TRANSFER key is refused at the same guard, because both blocks' names are
% judged in one place and a law judged in two places drifts.
test(refuses_an_unbound_transfer_mode_name,
     throws(error(instantiation_error, _))) :-
    % Try to build a transfer block whose row is keyed by a hole.
    mode_register_new(tonic_relay, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [transfer(_Hole, relay(1))], [], [], _Automaton).

% An unbound transition table is refused exactly as the other two stores are.
test(refuses_an_unbound_transition_table,
     throws(error(instantiation_error, _))) :-
    % Try to build an automaton whose transition table is a hole.
    mode_register_new(tonic_relay, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [transfer(tonic_relay, relay(1))], _Hole, [], _Automaton).

% A fault entry carries a boundary signature, a warning condition and a watchdog - three fields, or none.
test(refuses_a_malformed_fault_entry,
     throws(error(domain_error(fault, mystery), _))) :-
    % Try to build a register whose fault block holds a bare atom.
    mode_register_new(tonic_relay, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [transfer(tonic_relay, relay(1))], [], [mystery], _Automaton).

% An unbound fault block is refused exactly as the other three stores are.
test(refuses_an_unbound_fault_block,
     throws(error(instantiation_error, _))) :-
    % Try to build an automaton whose fault block is a hole.
    mode_register_new(tonic_relay, [mode_entry(tonic_relay, 'the Faithful Relay', 'passes')],
                      [transfer(tonic_relay, relay(1))], [], _Hole, _Automaton).

% ---------------------------------------------------------------------------
% THE LOOKUP ITSELF (the key-shape aliasing lens)
% ---------------------------------------------------------------------------

% An unbound mode key is refused: a membership lookup would bind it and return another mode's rule.
test(the_transfer_lookup_refuses_an_unbound_mode,
     throws(error(instantiation_error, _))) :-
    % Build the smallest admissible register.
    one_mode_automaton(Automaton),
    % Ask for the rule of no mode in particular.
    mode_register_transfer(Automaton, _Hole, _Rule).

% A mode the register does not hold is refused, never answered with somebody else's rule.
test(the_transfer_lookup_refuses_an_undeclared_mode,
     throws(error(existence_error(mode_entry, burst), _))) :-
    % Build the smallest admissible register.
    one_mode_automaton(Automaton),
    % Ask for the rule of a mode the register never declared.
    mode_register_transfer(Automaton, burst, _Rule).

% ---------------------------------------------------------------------------
% KONNECTOME'S OWN CONSTRUCTS, RE-EXPRESSED AS REGISTERS OF ONE
% ---------------------------------------------------------------------------

% EVERY construct kind konnectome runs today has a register: the repository becomes a valid
% mode-register system without a single number changing.
test(every_construct_kind_has_a_register) :-
    % The three tick-engine kinds and the three connection-graph kinds are the whole set.
    Kinds = [clock, copy(other), hold, source, relay(1), relay_modulated(1, dopamine)],
    % Each one resolves to its own hybrid automaton.
    forall(member(Kind, Kinds),
           % A register exists for this kind and passes its own validation.
           ( mode_register_of_construct_kind(Kind, Automaton),
             mode_register_check(Automaton) )).

% Each of those registers holds exactly one mode, which is the whole claim of this slice.
test(every_construct_register_holds_exactly_one_mode) :-
    % The whole set of construct kinds konnectome runs today.
    Kinds = [clock, copy(other), hold, source, relay(1), relay_modulated(1, dopamine)],
    % Every one of them is a mode-poor construct, and says so.
    forall(member(Kind, Kinds),
           % The register's size is one.
           ( mode_register_of_construct_kind(Kind, Automaton),
             mode_register_size(Automaton, 1) )).

% THE BIT-IDENTICAL LAW: the rule under a construct's current mode IS the construct's kind term,
% so routing every construct through its register cannot change a single number.
test(the_transfer_of_the_current_mode_is_the_construct_kind_itself) :-
    % The whole set of construct kinds konnectome runs today.
    Kinds = [clock, copy(other), hold, source, relay(1), relay_modulated(1, dopamine)],
    % For each, the rule read out of the register is the kind that went in.
    forall(member(Kind, Kinds),
           % The register's current rule is the kind term, unchanged.
           ( mode_register_of_construct_kind(Kind, Automaton),
             mode_register_current_rule(Automaton, Kind) )).

% Every mode entry carries the corpus's three fields: a formal name, a coined name, and a gloss.
test(every_construct_mode_carries_a_coined_name_and_a_gloss) :-
    % The whole set of construct kinds konnectome runs today.
    Kinds = [clock, copy(other), hold, source, relay(1), relay_modulated(1, dopamine)],
    % Each register's one entry is fully filled in.
    forall(member(Kind, Kinds),
           % The entry names the mode formally, coins it vividly, and glosses what it does.
           ( mode_register_of_construct_kind(Kind, Automaton),
             mode_register_entries(Automaton, [mode_entry(Formal, Coined, Gloss)]),
             atom(Formal),
             atom(Coined),
             sub_atom(Coined, 0, 4, _, 'the '),
             atom(Gloss),
             Gloss \== '' )).

% No two construct kinds share a formal mode name, so a register's mode always says which machine it is.
test(the_construct_mode_names_are_all_distinct) :-
    % The whole set of construct kinds konnectome runs today.
    Kinds = [clock, copy(other), hold, source, relay(1), relay_modulated(1, dopamine)],
    % Collect the formal name of each kind's one mode.
    findall(Formal,
            % For each kind, read its register's current mode name.
            ( member(Kind, Kinds),
              mode_register_of_construct_kind(Kind, Automaton),
              mode_register_current(Automaton, Formal) ),
            Formals),
    % Sorting away duplicates leaves the list the same length: every name is its own.
    sort(Formals, Sorted),
    % Six kinds, six distinct mode names.
    assertion(length(Formals, 6)),
    % And no name was lost to a collision.
    assertion(length(Sorted, 6)).

% A kind konnectome does not run has NO register, and the lookup fails quietly rather than
% inventing one - because the authority on what a step accepts stays with that step.
test(an_unregistered_kind_has_no_register) :-
    % Ask for the register of a kind that does not exist.
    assertion(\+ mode_register_of_construct_kind(mystery, _Automaton)).

% AND THE RULE RESOLVER PASSES IT THROUGH UNCHANGED, so every engine's own refusal fires exactly
% as it did before, naming the kind the caller wrote.
test(the_rule_resolver_passes_an_unregistered_kind_through) :-
    % Resolve the rule of a kind that has no register.
    mode_register_construct_rule(mystery, Rule),
    % The rule is the kind itself, so the engine refuses it by that name.
    assertion(Rule == mystery).

% For a registered kind the rule comes THROUGH the register, which is what makes the register real.
test(the_rule_resolver_reads_a_registered_kind_from_its_register) :-
    % Resolve the rule of a construct kind konnectome runs.
    mode_register_construct_rule(relay(0.5), Rule),
    % The rule is the one its register's current mode names.
    assertion(Rule == relay(0.5)).

% An unbound kind is refused: a resolver that dispatched on a hole would bind it to the first clause.
test(the_rule_resolver_refuses_an_unbound_kind,
     throws(error(instantiation_error, _))) :-
    % Ask for the rule of no kind at all.
    mode_register_construct_rule(_Hole, _Rule).

% ---------------------------------------------------------------------------
% THE DEPARTURE LOOKUP, KEYED ON AGENCY (konnectome build slice 41)
% ---------------------------------------------------------------------------

% A two-mode register whose table carries BOTH agencies leaving the same mode - the arrangement
% slice 41 creates, and the one an unkeyed lookup would get wrong.
% two_agency_automaton(+Current, -Automaton): a machine two different agencies can move.
two_agency_automaton(Current, Automaton) :-
    % Build a register of two, with a self-selected departure and a thrown one leaving each mode.
    mode_register_new(Current,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds'),
                       mode_entry(loud, 'the Raised Voice', 'does its work while it holds')],
                      [transfer(quiet, hold), transfer(loud, relay(1))],
                      [transition(own_drive, quiet, loud, one_tick, self_selected),
                       transition(own_drive, loud, quiet, one_tick, self_selected),
                       transition(broadcast_mode_throw, quiet, loud, one_tick, broadcast_thrown),
                       transition(broadcast_mode_throw, loud, quiet, one_tick, broadcast_thrown)],
                      [],
                      Automaton).

% The lookup returns the departure belonging to the agency it was asked for, and only that one.
test(departure_is_read_under_the_agency_asked_for) :-
    % A machine standing in its quiet mode.
    two_agency_automaton(quiet, Automaton),
    % Its own departure.
    mode_register_departure(Automaton, self_selected, Own),
    % Leads to loud.
    assertion(Own == loud),
    % And the departure a broadcast would give it.
    mode_register_departure(Automaton, broadcast_thrown, Thrown),
    % Leads to loud as well, by a different row that must be read separately to be trusted.
    assertion(Thrown == loud).

% An agency the table names nowhere is refused aloud rather than failing in silence.
test(an_agency_with_no_row_is_refused,
     throws(error(existence_error(mode_transition, quiet), _))) :-
    % A machine standing in its quiet mode.
    two_agency_automaton(quiet, Automaton),
    % Ask for a departure under an agency that governs nothing here.
    mode_register_departure(Automaton, supervisor_forced, _ToMode).

% REVIEW PIN, the unbound-wrong-judgement lens: an unbound AGENCY is refused. It is the whole point
% of this lookup that the agency is named, and a hole would match the first row of any agency and
% answer confidently with a departure nobody asked for.
test(an_unbound_agency_is_refused,
     throws(error(instantiation_error, _))) :-
    % A machine standing in its quiet mode.
    two_agency_automaton(quiet, Automaton),
    % Ask for a departure under no agency at all.
    mode_register_departure(Automaton, _Hole, _ToMode).

% TWO ROWS UNDER ONE AGENCY LEAVING ONE MODE ARE REFUSED, not silently resolved in favour of the
% earlier row: a construct that does not know which machine it becomes is a table fault, and the
% corpus writes no such table.
test(an_ambiguous_departure_is_refused,
     throws(error(domain_error(single_mode_departure, [loud, quiet]), _))) :-
    % Build a machine whose table sends it two ways at once under the same agency.
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds'),
                       mode_entry(loud, 'the Raised Voice', 'does its work while it holds')],
                      [transfer(quiet, hold), transfer(loud, relay(1))],
                      [transition(own_drive, quiet, loud, one_tick, self_selected),
                       transition(other_drive, quiet, quiet, one_tick, self_selected)],
                      [],
                      Automaton),
    % Ask where it goes, and be refused rather than answered.
    mode_register_departure(Automaton, self_selected, _ToMode).

% A register of one has nowhere to go under any agency, and says so aloud.
test(a_register_of_one_refuses_every_departure,
     throws(error(existence_error(mode_transition, tonic_relay), _))) :-
    % The smallest register the corpus admits, whose transition table is empty.
    one_mode_automaton(Automaton),
    % Ask where it goes.
    mode_register_departure(Automaton, self_selected, _ToMode).

% ---------------------------------------------------------------------------
% THE TWO DEFERRED FIELDS (slice 66, OBSERVATION-19's closer)
% ---------------------------------------------------------------------------

% A helper: a two-mode machine one of whose modes is admitted as a fault, with its reason.
% admitting_automaton(-Automaton): a construct that says which of its modes is a way of being broken.
admitting_automaton(Automaton) :-
    % The admitted mode carries the corpus's own manner of rationale, written inline on the entry.
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds'),
                       mode_entry(runaway, 'the Runaway', 'flips as fast as its input changes',
                                  [admitted_as_fault('admitted only because it names the failure'),
                                   confidence(moderate)])],
                      [transfer(quiet, hold), transfer(runaway, relay(1))],
                      [transition(own_drive, quiet, runaway, one_tick, self_selected)],
                      [fault(runaway, flips_too_fast, oscillation_watchdog)],
                      Automaton).

% THE UNTAGGED ENTRY IS UNCHANGED AND MEANS WHAT IT ALWAYS MEANT. The corpus's tagged entries are a
% minority, so the three-field entry is the majority form and not a legacy shape awaiting migration.
test(an_untagged_entry_carries_no_tags) :-
    one_mode_automaton(Automaton),
    mode_register_modes(Automaton, [Mode]),
    mode_register_tags(Automaton, Mode, Tags),
    assertion(Tags == []).

% AN ENTRY WITHOUT A CONFIDENCE TAG IS NOT A CONFIDENT ENTRY. It answers by name rather than with a
% grade konnectome chose, which is this build's own recurring failure - a zero that reads as calm -
% in the one field whose purpose is to record how much the source is prepared to claim.
test(an_entry_without_a_confidence_tag_states_that_rather_than_a_grade) :-
    one_mode_automaton(Automaton),
    mode_register_modes(Automaton, [Mode]),
    mode_register_confidence(Automaton, Mode, Confidence),
    assertion(Confidence == confidence_not_stated).

% A tagged entry hands back the grade it declares.
test(a_tagged_entry_hands_back_the_grade_it_declares) :-
    admitting_automaton(Automaton),
    mode_register_confidence(Automaton, runaway, Confidence),
    assertion(Confidence == confidence(moderate)).

% And the admissions are readable, each carrying the reasoning that admitted it.
test(an_admitted_mode_is_listed_with_the_reason_that_admitted_it) :-
    admitting_automaton(Automaton),
    mode_register_admissions(Automaton, Admissions),
    assertion(Admissions == [mode_register_admission(runaway,
                                'admitted only because it names the failure')]).

% A register with nothing admitted admits nothing, and says so as an empty list rather than by failing.
test(a_register_with_nothing_admitted_lists_no_admissions) :-
    one_mode_automaton(Automaton),
    mode_register_admissions(Automaton, Admissions),
    assertion(Admissions == []).

% THE RATIONALE IS THE LOAD-BEARING HALF, so an admission without one is not a mode entry at all.
test(an_admission_without_a_rationale_is_refused,
     throws(error(domain_error(mode_entry_tag, admitted_as_fault), _))) :-
    mode_register_new(broken,
                      [mode_entry(broken, 'the Broken One', 'is broken while it holds',
                                  [admitted_as_fault])],
                      [transfer(broken, hold)],
                      [],
                      [],
                      _Automaton).

% AND AN EMPTY RATIONALE IS NOT A RATIONALE. A blank slot passes a shape check and says nothing, which
% is precisely the silent admission this rule exists to prevent.
test(an_empty_rationale_is_refused,
     throws(error(domain_error(mode_register_admission_rationale, ''), _))) :-
    mode_register_new(broken,
                      [mode_entry(broken, 'the Broken One', 'is broken while it holds',
                                  [admitted_as_fault('')])],
                      [transfer(broken, hold)],
                      [],
                      [],
                      _Automaton).

% A rationale that is a hole is refused before it can be admitted silently.
test(a_rationale_that_is_a_hole_is_refused,
     throws(error(instantiation_error, _))) :-
    mode_register_new(broken,
                      [mode_entry(broken, 'the Broken One', 'is broken while it holds',
                                  [admitted_as_fault(_Reason)])],
                      [transfer(broken, hold)],
                      [],
                      [],
                      _Automaton).

% A confidence grade outside the transcribed list is refused, so a sixth grade must be added
% deliberately by somebody who can say which corpus entry it came from.
test(a_confidence_grade_outside_the_transcribed_list_is_refused,
     throws(error(domain_error(mode_register_confidence_grade, extremely_high), _))) :-
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds',
                                  [confidence(extremely_high)])],
                      [transfer(quiet, hold)],
                      [],
                      [],
                      _Automaton).

% The transcribed grades are the five the design authority recorded, normalised into snake_case.
test(the_confidence_grades_are_the_five_the_authority_recorded) :-
    mode_register_confidence_grades(Grades),
    assertion(Grades == [high, moderate, low, well_established, deliberately_low]).

% TWO CONFIDENCE GRADES ON ONE MODE IS TWO CLAIMS ABOUT HOW WELL ESTABLISHED IT IS, and the register
% refuses rather than preferring whichever was written first.
test(two_tags_of_one_kind_on_one_mode_are_refused,
     throws(error(domain_error(distinct_mode_tags, _Tags), _))) :-
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds',
                                  [confidence(high), confidence(low)])],
                      [transfer(quiet, hold)],
                      [],
                      [],
                      _Automaton).

% AN UNRECOGNISED TAG IS REFUSED RATHER THAN IGNORED. A misspelt admission silently dropped would read
% as an ordinary mode, which is the whole failure the flag exists to make visible.
test(an_unrecognised_tag_is_refused,
     throws(error(domain_error(mode_entry_tag, admited_as_fault(oops)), _))) :-
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds',
                                  [admited_as_fault(oops)])],
                      [transfer(quiet, hold)],
                      [],
                      [],
                      _Automaton).

% A tag block that is a hole is refused rather than read as an untagged entry.
test(a_tag_block_that_is_a_hole_is_refused,
     throws(error(instantiation_error, _))) :-
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds', _Tags)],
                      [transfer(quiet, hold)],
                      [],
                      [],
                      _Automaton).

% A tag block that is not a list is refused rather than walked.
test(a_tag_block_that_is_not_a_list_is_refused,
     throws(error(type_error(list, admitted_as_fault(because)), _))) :-
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds',
                                  admitted_as_fault(because))],
                      [transfer(quiet, hold)],
                      [],
                      [],
                      _Automaton).

% A tagged mode is a mode like any other: it needs a transfer function, and it is refused without one.
test(a_tagged_mode_still_needs_a_transfer_function,
     throws(error(existence_error(transfer_function, runaway), _))) :-
    mode_register_new(quiet,
                      [mode_entry(quiet, 'the Held Breath', 'does nothing while it holds'),
                       mode_entry(runaway, 'the Runaway', 'flips as fast as its input changes',
                                  [admitted_as_fault('admitted only because it names the failure')])],
                      [transfer(quiet, hold)],
                      [],
                      [],
                      _Automaton).

% Asking a register for the tags of a mode it does not hold is refused aloud by name.
test(the_tags_of_a_mode_the_register_does_not_hold_are_refused,
     throws(error(existence_error(mode_entry, absent), _))) :-
    one_mode_automaton(Automaton),
    mode_register_tags(Automaton, absent, _Tags).

% An unbound mode key is refused, because the lookup would bind it and hand back another mode's tags.
test(an_unbound_mode_key_is_refused_by_the_tag_lookup,
     throws(error(instantiation_error, _))) :-
    admitting_automaton(Automaton),
    mode_register_tags(Automaton, _Mode, _Tags).

% Close the test block for the mode_register pack.
:- end_tests(mode_register).
