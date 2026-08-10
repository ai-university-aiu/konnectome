% Declare this file as the 'supervisor' module and list the predicates it exports.
:- module(supervisor, [
    % supervisor_channel_new/1: an empty channel, on which every construct kind reads as unwatched.
    supervisor_channel_new/1,
    % supervisor_faults_are_not_modes/1: the template's directive, made a refusal rather than a habit.
    supervisor_faults_are_not_modes/1,
    % supervisor_watch/3: judge one construct's fault block against the watchdogs' readings.
    supervisor_watch/3,
    % supervisor_report_warnings/2: the warnings a report carries.
    supervisor_report_warnings/2,
    % supervisor_report_unwatched/2: the fault regimes no watchdog reported on.
    supervisor_report_unwatched/2,
    % supervisor_publish/4: a supervisor writes one construct kind's report onto the channel.
    supervisor_publish/4,
    % supervisor_report/3: read the report standing for one construct kind, unwatched by default.
    supervisor_report/3
]).

% Import the list utilities used for membership and gathering.
:- use_module(library(lists), [memberchk/2, member/2]).
% Import the type checker that judges a store or a key and refuses a hole aloud.
:- use_module(library(error), [must_be/2, domain_error/2, existence_error/2]).
% Import exclude for replacing a construct kind's older report when a newer one is published.
:- use_module(library(apply), [exclude/3]).
% Import the mode register, because a fault block is one of the hybrid automaton's four blocks and
% the supervisor reads it through the register's own accessors rather than beside them.
:- use_module(library(mode_register), [
    % mode_register_faults/2: read an automaton's fault regimes and watchdogs block.
    mode_register_faults/2,
    % mode_register_modes/2: read the formal names of every mode the register declares.
    mode_register_modes/2
]).

% ---------------------------------------------------------------------------
% THE DIRECTIVE THIS PACK EXISTS TO ENFORCE (the design authority, Part Nine slice five)
% ---------------------------------------------------------------------------
%
% A FAULT IS NOT A MODE, AND THE CORPUS FORBIDS THE CONFUSION BY NAME. The Layer 6 chapter template
% states the admission rule for a mode register directly: a regime enters the register only if the
% HEALTHY system uses it, and the ways a component BREAKS are watched by supervisor processes that
% publish warnings - never listed as regimes the component operates in. konnectome has honoured that
% rule since slice 39 by leaving every fault block present and EMPTY, which was correct and was also
% an IOU: the block could not be filled until there was something to do the watching.
%
% This pack is the watcher. With it, the fault blocks stop being empty.
%
% WHY THE DISTINCTION IS WORTH A PACK RATHER THAN A CONVENTION. A mode and a fault look alike from a
% distance - both are named conditions a construct can be in - and the difference is entirely in what
% the system is entitled to DO about them. A mode has a transfer function: while it holds, the
% construct runs a different machine, on purpose, and the system's behaviour in that mode is part of
% the design. A fault has no transfer function and never will: it is a boundary the construct was not
% designed to cross, and the only correct response is to say so out loud to somebody who can act. If
% a fault were admitted as a mode, the system would acquire a DESIGNED behaviour for being broken,
% and would then run it silently and indefinitely, which is the exact failure the corpus's directive
% exists to prevent. Written as a convention this is a sentence people forget. Written here it is a
% refusal that fires.
%
% THE THREE THINGS A FAULT ENTRY CARRIES, which are the corpus's own three fields:
%   fault(BoundarySignature, WarningCondition, Watchdog)
% BoundarySignature - the named boundary the construct is not designed to cross. It is NOT a mode
%                     name, and supervisor_faults_are_not_modes/1 refuses a register in which it is.
% WarningCondition  - what the supervisor says when the boundary is crossed.
% Watchdog          - who is watching. Naming the watcher is what makes an unwatched fault visible as
%                     an unwatched fault rather than as a clean one.
%
% KONNECTOME INVENTS NO THRESHOLD HERE, AND THAT IS A DELIBERATE SHAPE RATHER THAN AN OMISSION. Each
% reading arrives carrying its own ALLOWANCE, supplied by the caller that owns the watchdog. The
% supervisor compares and reports; it does not decide how much oscillation is too much, because the
% corpus supplies no such number at this grain and this family's standing rule is that no number in
% the pack is konnectome's invention.
%
% AND THREE OUTCOMES, NOT TWO. A fault regime is WARNED (a reading crossed its allowance), CLEAN (a
% reading did not), or UNWATCHED (no watchdog reported at all). The third is the one a two-outcome
% design would lose, and losing it is how a system comes to believe that silence means health. An
% unwatched fault is reported as unwatched, by name, beside the warnings.

% ---------------------------------------------------------------------------
% THE CHANNEL
% ---------------------------------------------------------------------------
%
% THE SUPERVISOR CHANNEL IS ITS OWN CHANNEL AND NOT A KEY ON THE NEUROMODULATOR BUS, and the reason
% is worth recording so a later slice does not merge them by tidiness. The neuromodulator bus is
% Architecture Component 4: the broadcast field of global brain-chemical levels, the one place the
% architecture permits a global value, read by every construct's update and learning rule. A
% supervisor warning is not a chemical and is not addressed to the constructs at all - it is
% addressed OUTWARD, to whoever can act on a component that has left its design envelope. Putting it
% on the chemical bus would have made every construct's update rule a potential reader of its own
% failure report, which is a coupling nothing has asked for.

% supervisor_channel_new(-Channel): an empty channel, on which every construct kind reads as unwatched.
supervisor_channel_new([]).

% supervisor_check_kind(+ConstructKind): refuse an unbound or compound construct kind, by name.
supervisor_check_kind(ConstructKind) :-
    % An unbound kind cannot be judged, and a lookup would bind it to whichever kind is listed first.
    (   var(ConstructKind)
    ->  throw(error(instantiation_error, _))
    % A construct kind is addressed by a plain atom, the same key shape the bus uses for its channels.
    ;   atom(ConstructKind)
    ->  true
    % Anything else is refused aloud rather than becoming a key nobody can read back.
    ;   domain_error(supervisor_construct_kind, ConstructKind)
    ).

% supervisor_matches(+ConstructKind, +Pair): the pair carries this construct kind's report.
supervisor_matches(ConstructKind, ConstructKind-_Report).

% supervisor_publish(+Channel0, +ConstructKind, +Report, -Channel): publish one kind's report.
supervisor_publish(Channel0, ConstructKind, Report, Channel) :-
    % Refuse an unbound or compound construct kind before touching the channel.
    supervisor_check_kind(ConstructKind),
    % Refuse anything that is not a report, so the channel cannot carry a term nobody can read back.
    supervisor_check_report(Report),
    % Drop any older report for this kind, so the newest watch wins, as the newest broadcast does.
    exclude(supervisor_matches(ConstructKind), Channel0, Without),
    % Add the new report and keep the channel in a canonical sorted order.
    keysort([ConstructKind-Report|Without], Channel).

% supervisor_report(+Channel, +ConstructKind, -Report): the report standing for one construct kind.
supervisor_report(Channel, ConstructKind, Report) :-
    % An unbound channel is refused, never silently bound by the lookup into a partial list.
    (   var(Channel)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % Refuse an unbound or compound construct kind before reading.
    supervisor_check_kind(ConstructKind),
    % A published report reads back; a kind nobody has watched is NOT reported clean - it is reported
    % as having nothing watched, which is a different statement and the one that is true.
    (   memberchk(ConstructKind-Found, Channel)
    ->  Report = Found
    ;   Report = supervisor_report([], [])
    ).

% supervisor_check_report(+Report): refuse anything that is not the two-block report term.
supervisor_check_report(Report) :-
    % An unbound report is a hole and is refused before it can be published as a clean bill of health.
    (   var(Report)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % A report carries exactly two blocks: what was warned, and what nobody watched.
    (   Report = supervisor_report(Warnings, Unwatched)
    ->  true
    ;   domain_error(supervisor_report, Report)
    ),
    % Both blocks are judged as stores, so a hole can never be published as an empty block.
    must_be(list, Warnings),
    % The same judgement for the second block, in the same place.
    must_be(list, Unwatched).

% supervisor_report_warnings(+Report, -Warnings): the warnings a report carries.
supervisor_report_warnings(Report, Warnings) :-
    % Judge the report's shape before reading a block out of it.
    supervisor_check_report(Report),
    % Hand back the warning block.
    Report = supervisor_report(Warnings, _Unwatched).

% supervisor_report_unwatched(+Report, -Unwatched): the fault regimes no watchdog reported on.
supervisor_report_unwatched(Report, Unwatched) :-
    % Judge the report's shape before reading a block out of it.
    supervisor_check_report(Report),
    % Hand back the unwatched block.
    Report = supervisor_report(_Warnings, Unwatched).

% ---------------------------------------------------------------------------
% THE DIRECTIVE, AS A REFUSAL
% ---------------------------------------------------------------------------

% supervisor_faults_are_not_modes(+Automaton): refuse a register that admits a fault as a mode.
supervisor_faults_are_not_modes(Automaton) :-
    % Read the register's declared mode names through the register's own accessor.
    mode_register_modes(Automaton, Names),
    % Read the fault block through the register's own accessor, so there is one authority on both.
    mode_register_faults(Automaton, Faults),
    % Judge every fault entry's boundary signature against the modes the register declares.
    supervisor_check_signatures(Faults, Names).

% supervisor_check_signatures(+Faults, +Names): judge each fault entry's signature in turn.
% An exhausted fault block admits nothing and is clean.
supervisor_check_signatures([], _Names).
% Each entry's boundary signature must be a name the register does NOT declare as a mode.
supervisor_check_signatures([Entry|Rest], Names) :-
    % Refuse anything that is not the corpus's three-field fault entry, naming what arrived.
    (   Entry = fault(Signature, _Condition, _Watchdog)
    ->  true
    ;   domain_error(fault, Entry)
    ),
    % A boundary signature is named by an atom, the same key shape a mode name uses.
    must_be(atom, Signature),
    % THE DIRECTIVE ITSELF: a signature that is also a declared mode is refused aloud, because a
    % construct with a designed behaviour for being broken will run it silently and forever.
    (   memberchk(Signature, Names)
    ->  domain_error(supervisor_fault_is_not_a_mode, Signature)
    ;   true
    ),
    % Judge the remaining entries.
    supervisor_check_signatures(Rest, Names).

% ---------------------------------------------------------------------------
% THE WATCH
% ---------------------------------------------------------------------------

% supervisor_watch(+Automaton, +Readings, -Report): judge a fault block against the watchdogs' readings.
supervisor_watch(Automaton, Readings, Report) :-
    % Refuse a register that admits a fault as a mode BEFORE watching it, so a malformed register can
    % never be reported on as though it were well formed.
    supervisor_faults_are_not_modes(Automaton),
    % Judge the readings store's shape, so a hole is never walked as an empty set of readings.
    must_be(list, Readings),
    % Judge every reading's shape and its two numbers, once, before any of them is compared.
    supervisor_check_readings(Readings),
    % Read the fault block through the register's own accessor.
    mode_register_faults(Automaton, Faults),
    % Judge every fault regime against the readings, gathering warnings and unwatched regimes apart.
    supervisor_judge(Faults, Readings, Warnings, Unwatched),
    % Assemble the two blocks into the report term.
    Report = supervisor_report(Warnings, Unwatched).

% supervisor_check_readings(+Readings): judge every reading's shape and both of its numbers.
% An exhausted readings store is clean.
supervisor_check_readings([]).
% Each reading names a boundary signature, a measured value, and the allowance the CALLER supplies.
supervisor_check_readings([Reading|Rest]) :-
    % Refuse anything that is not a three-field reading, naming what arrived.
    (   Reading = supervisor_reading(Signature, Value, Allowance)
    ->  true
    ;   domain_error(supervisor_reading, Reading)
    ),
    % A reading is keyed by an atom, the same key shape a fault's signature uses.
    must_be(atom, Signature),
    % Judge both numbers HERE, in the one place every reading comes through, rather than at the
    % comparison - where a hole would be answered by an arithmetic error naming nothing useful.
    must_be(number, Value),
    % The allowance is judged as strictly as the value, because a hole in either makes the verdict a
    % guess, and a supervisor that guesses is worse than no supervisor at all.
    must_be(number, Allowance),
    % Judge the remaining readings.
    supervisor_check_readings(Rest).

% supervisor_judge(+Faults, +Readings, -Warnings, -Unwatched): the verdict, regime by regime.
% An exhausted fault block warns about nothing and leaves nothing unwatched.
supervisor_judge([], _Readings, [], []).
% Each fault regime is warned about, found clean, or found unwatched.
supervisor_judge([fault(Signature, Condition, Watchdog)|Rest], Readings, Warnings, Unwatched) :-
    % Gather every reading filed under this signature, so an ambiguous watch is visible rather than
    % silently resolved in favour of whichever reading the caller happened to list first. This is
    % slice 41's declaration-order lens applied to new code the slice after it was earned.
    findall(Value-Allowance,
            member(supervisor_reading(Signature, Value, Allowance), Readings),
            Found),
    % Judge this regime, then judge the rest.
    (   Found = [OneValue-OneAllowance]
    ->  % A single reading is a real watch: compare it against the allowance the caller supplied.
        (   OneValue > OneAllowance
        ->  % The boundary was crossed, so the supervisor says so, carrying the numbers it judged on.
            Warnings = [supervisor_warning(Signature, Condition, Watchdog, OneValue, OneAllowance)|MoreWarnings],
            % A warned regime is watched, so it does not also appear as unwatched.
            Unwatched = MoreUnwatched
        ;   % The boundary held, so this regime is clean and appears in neither block.
            Warnings = MoreWarnings,
            % And it is watched, so it is not unwatched either.
            Unwatched = MoreUnwatched
        )
    ;   Found == []
    ->  % No watchdog reported, which is NOT the same as reporting health, and is named as such.
        Warnings = MoreWarnings,
        % The regime is listed as unwatched, carrying the name of the watchdog that did not report.
        Unwatched = [supervisor_unwatched(Signature, Watchdog)|MoreUnwatched]
    ;   % Two readings for one boundary is a caller fault: the supervisor refuses rather than pick.
        domain_error(supervisor_single_reading_per_signature, Signature)
    ),
    % Judge the remaining fault regimes.
    supervisor_judge(Rest, Readings, MoreWarnings, MoreUnwatched).
