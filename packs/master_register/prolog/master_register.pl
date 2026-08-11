% Declare this file as the 'master_register' module and list the predicates it exports.
:- module(master_register, [
    % master_register_poles/1: the two positions the sleep-wake flip-flop has, and no third.
    master_register_poles/1,
    % master_register_sub_modes/2: the sub-modes one pole holds, from the corpus, in the corpus's order.
    master_register_sub_modes/2,
    % master_register_default_sub_mode/2: the sub-mode a pole stands in when nobody has said which.
    master_register_default_sub_mode/2,
    % master_register_entries/1: the whole widened register, entry by entry, in the corpus's schema.
    master_register_entries/1,
    % master_register_size/1: how many entries the master register holds - itself a statement.
    master_register_size/1,
    % master_register_check/1: refuse a global state the register does not hold, by name.
    master_register_check/1,
    % master_register_settle/2: read a bare or unstated announcement as a fully named global state.
    master_register_settle/2,
    % master_register_announce/3: announce a global state onto the bus, judged before it travels.
    master_register_announce/3,
    % master_register_current/2: read the global state standing on the bus, fully named.
    master_register_current/2,
    % master_register_downward_assignment/2: what a global state sets at each construct kind below it.
    master_register_downward_assignment/2,
    % master_register_assign_downward/3: apply a state's downward assignment through the throw channel.
    master_register_assign_downward/3,
    % master_register_throw_rows/3: the assignment walk itself, exported so it can be PROVED.
    % The table is empty today, so a test driving master_register_assign_downward/3 alone would pass
    % vacuously and prove only that nothing happens. Exporting the walk lets a test hand it a FIXTURE
    % assignment and check that a real row really does reach the throw channel - the same reason
    % slice 44's test first checks a transition table is non-empty before asserting a name is absent.
    master_register_throw_rows/3
]).

% Import the list utilities used for membership and for reading a roster.
:- use_module(library(lists), [memberchk/2]).
% Import the type checker that judges a pole or a sub-mode and refuses a hole aloud.
:- use_module(library(error), [must_be/2, domain_error/2]).
% Import the neuromodulator bus, because Layer 11's own answer to how a state reaches everything
% below it is ONE BROADCAST, and konnectome has owned that broadcast since slice 4.
:- use_module(library(neuromodulator_bus), [
    % neuromodulator_bus_global_state/2: read the widened state - a pole and a sub-mode - as one term.
    neuromodulator_bus_global_state/2,
    % neuromodulator_bus_broadcast_global_state/3: announce the widened state, pole and sub-mode together.
    neuromodulator_bus_broadcast_global_state/3,
    % neuromodulator_bus_throw_mode/4: the mode-throw channel slice 41 built, which the assignment uses.
    neuromodulator_bus_throw_mode/4
]).

% ---------------------------------------------------------------------------
% WHAT THIS PACK IS (the mode-register design authority, Part Nine slice seven)
% ---------------------------------------------------------------------------
%
% THE LAST NAMED SLICE OF THE MODE-REGISTER FAMILY, AND THE ONE THE OTHER SIX WERE BUILDING TOWARD.
% Layer 11's outline states the whole point in one sentence: at every layer below, the mode
% transitions kept being thrown FROM ABOVE - and Layer 11 is the thrower. In the corpus's own
% vocabulary a GLOBAL STATE IS NOT A FLAG. It is a COORDINATED ASSIGNMENT OF MODES across every cell,
% junction, motif and region below it, and all twenty-six of its chapters carry a section titled THE
% DOWNWARD ASSIGNMENT (WHAT IT SETS AT EACH LAYER) to say so.
%
% KONNECTOME WALKED INTO THIS AT SLICE 35 WITHOUT NAMING IT. The global operating state put on the
% bus then - exactly two values, online and offline, a third refused by name - IS the master mode
% register in its degenerate two-entry form, and it has had nothing beneath it to assign ever since.
% This slice widens it and gives it the mechanism, and is honest about which of those two is finished.

% ---------------------------------------------------------------------------
% DECISION-5, TAKEN HERE: THE POLE IS PRESERVED, THE SUB-MODE IS ADDED BENEATH IT, AND THE SUB-MODE
% IS PART OF THE STATE'S IDENTITY RATHER THAN A DECORATION ON IT
% ---------------------------------------------------------------------------
%
% THE DESIGN AUTHORITY ASKED FOR "A NAMED GLOBAL STATE PLUS A SUB-MODE" AND DID NOT SAY WHETHER THE
% EXISTING BINARY SURVIVES. konnectome decides that it does, and that it becomes the POLE.
%
% THE FIRST REASON IS THE CORPUS'S OWN STRUCTURE AND IT IS THE STRONGEST. The binary was never an
% approximation waiting to be replaced: the corpus catalogues THE SLEEP-WAKE FLIP-FLOP as its own
% entry, a mutual-inhibition switch "engineered for fast, complete, bistable transitions", and it
% catalogues the waking states and the sleep states as two FAMILIES on either side of it. There is
% genuinely a binary at the top and genuinely a family beneath each side. A design that dissolved the
% binary into a flat list of state names would have thrown away a distinction the corpus draws with
% its own dedicated chapter, and would have left konnectome's own flip-flop - the two-process
% governor, built at slice 37 - with nothing to be a flip-flop BETWEEN.
%
% THE SECOND REASON IS THAT IT COSTS NO EXISTING CALLER ANYTHING. Every predicate written since slice
% 35 that asks the bus for the operating state means "am I awake or asleep", and keeps getting
% exactly that answer, because the channel's old reader hands back THE POLE ALONE and always will.
% Behaviour is pinned identical, and the capstone story is byte-identical, because the widening adds
% a field that nothing existing reads.
%
% THE THIRD REASON IS THAT IT IS THE REVERSIBLE HALF OF AN IRREVERSIBLE-LOOKING CHANGE. A sub-mode
% roster can be extended, corrected, or given a fifth entry by a later slice. A pole cannot be added:
% a third pole would break the flip-flop, and every construct that has read this channel since slice
% 35 would have to be revisited. Widening BENEATH the binary is additive; widening THROUGH it is not.
%
% AND THE SECOND HALF OF DECISION-5, WHICH ANSWERS THE DESIGN AUTHORITY'S PART SEVEN ITEM 4 - a
% question the corpus explicitly does not settle: DO SUB-MODES CHANGE THE DOWNWARD ASSIGNMENT, OR
% ONLY SCALE ITS PARAMETERS? KONNECTOME DECIDES THAT THE ASSIGNMENT IS KEYED ON THE WHOLE STATE,
% POLE AND SUB-MODE TOGETHER, SO A SUB-MODE MAY CHANGE IT.
%
% The reason is measured rather than preferred. The corpus's own downward assignments for two
% sub-modes of the same pole are not scalings of one another and cannot be made into one: N2 assigns
% the thalamus to "its rhythmic spindling mode" and opens a plasticity window for spindle-timed
% reactivation, while N3 assigns the up-down slow oscillation, systems consolidation and synaptic
% renormalisation. Those are different mode names at the same grain, not the same assignment at two
% strengths. A design that keyed the assignment on the pole alone would have made every sub-mode
% decorative by construction, and would have foreclosed the exact distinction the corpus spends two
% chapters drawing. The cost is accepted openly: keying on the whole state means the assignment table
% grows with the roster rather than with the poles.
%
% WHAT DECISION-5 DOES NOT DECIDE. It does not decide the OVERLAY question of Part Seven item 3 - how
% two simultaneously active states compose, which the corpus supplies no rule for - because
% konnectome holds ONE standing state and cannot yet reach that case; the arousal, stress and
% sickness states of the corpus's Part Four, which are the ones that plainly overlay a base state,
% are not built and the composition rule is deferred WITH them. It does not decide the conflict rule
% between an assignment and a construct's own transition, because DECISION-1 already did: the throw
% preempts, and this slice inherits that rather than re-opening it. It does not decide that the four
% sub-modes per pole are the right four - see the roster note. And it does not make konnectome
% real-time: a sub-mode is a name, and nothing here has a duration.

% ---------------------------------------------------------------------------
% THE REGISTER
% ---------------------------------------------------------------------------
%
% THE ROSTER IS THE CORPUS'S AND ITS BOUNDARY IS KONNECTOME'S, AND THE TWO ARE SEPARATED HERE SO
% NEITHER IS MISTAKEN FOR THE OTHER. Every sub-mode name below is a Layer 11 outline entry, taken in
% the outline's own order, with the outline's own coined name carried as the formal name. WHAT IS
% KONNECTOME'S IS THE CUT: the corpus catalogues twenty-six entries and this register holds eight,
% because the other eighteen are state MACHINERY (the flip-flops, the two processes, the broadcast
% service), the arousal and stress states that OVERLAY a base state rather than being one, the
% ultradian wheel which the corpus itself says is "a whole-night program, not a state", and the
% engineered and pathological configurations the corpus flags separately. Taking all twenty-six would
% have put a governor and a disease into a register of operating states, which is the fault-is-not-a-
% mode error of slice 42 arriving one grain higher up.

% master_register_poles(-Poles): the two positions the sleep-wake flip-flop has, and no third.
master_register_poles([online, offline]).

% The waking family, Layer 11 outline Part One, entries 1 through 4, in the outline's own order.
% Entry 1, and the corpus calls it the default assumption of nearly every cognitive experiment ever run.
master_register_entry(online, alert_task_engaged, 'Alert Task-Engaged Waking', 'computes on the world').
% Entry 2, and the corpus's own warning about it is that idle is not off.
master_register_entry(online, relaxed_wakefulness, 'The Alpha Idle', 'idles but stays ready').
% Entry 3, admitted by the corpus with a moderate-confidence note about its boundaries.
master_register_entry(online, focused_absorption, 'The Flow Configuration', 'performs without self-monitoring').
% Entry 4, which the corpus insists is a real state and not merely a boundary.
master_register_entry(online, drowsy_waking, 'The Descending Platform', 'fails vigilance on the way down').
% The sleep family, Layer 11 outline Part Two, entries 5 through 8, in the outline's own order.
% Entry 5, the brief vestibule.
master_register_entry(offline, sleep_onset, 'The Hypnagogic Threshold', 'crosses out of waking').
% Entry 6, which the corpus insists is not a mere corridor.
master_register_entry(offline, spindled_light_sleep, 'Spindled Light Sleep', 'packages what was learned').
% Entry 7, the night shift during which the plant is both cleaned and rebuilt.
master_register_entry(offline, slow_wave_sleep, 'The Deep Works', 'consolidates and renormalises').
% Entry 8, cortex awake-like and body paralysed, which the corpus says carries two sub-modes of its own.
master_register_entry(offline, rapid_eye_movement, 'The Paradoxical Theatre', 'recalibrates and integrates').

% THE DEFAULTS ARE NOT KONNECTOME'S EITHER, AND THAT IS WHY THEY ARE SAFE. A bare announcement -
% every announcement made anywhere in this repository before this slice - names a pole and no
% sub-mode, and something must say which sub-mode it means. Inventing one would have made every
% historical announcement mean something konnectome chose in 2026 rather than something the corpus
% supports. Each default below is the corpus's own account of what that pole ORDINARILY IS.

% Waking defaults to Alert Task-Engaged Waking, which the corpus calls the default assumption of
% nearly every cognitive experiment ever run - the plainest statement of a default in the volume.
master_register_default_sub_mode(online, alert_task_engaged).
% Sleep defaults to slow-wave sleep, and this is a MEASURED choice rather than an obvious one: it is
% the state whose downward assignment names systems consolidation and synaptic renormalisation, which
% is precisely and only what konnectome's offline_consolidation pack has done since slice 38. The
% default is what konnectome's offline phase ALREADY IS, read back from the corpus rather than picked.
master_register_default_sub_mode(offline, slow_wave_sleep).

% master_register_sub_modes(+Pole, -SubModes): the sub-modes one pole holds, in the corpus's order.
master_register_sub_modes(Pole, SubModes) :-
    % Refuse an unbound or foreign pole before a roster is read for it.
    master_register_check_pole(Pole),
    % Gather this pole's entries in declaration order, which is the corpus outline's own order.
    findall(SubMode, master_register_entry(Pole, SubMode, _Formal, _Does), SubModes).

% master_register_entries(-Entries): the whole widened register, in the corpus's three-field schema.
master_register_entries(Entries) :-
    % Every entry carries the state it names, its formal name, and what runs while it holds - the
    % same three fields every other register in this repository has carried since slice 39.
    findall(mode_entry(global_state(Pole, SubMode), Formal, Does),
            master_register_entry(Pole, SubMode, Formal, Does),
            Entries).

% master_register_size(-Size): how many entries the master register holds - itself a statement.
master_register_size(Size) :-
    % Read the register and count it, rather than restating a number that could drift from the roster.
    master_register_entries(Entries),
    % The length IS the statement: the corpus holds that a register's length says what the system
    % trusts a component to decide, and konnectome's master register is now eight rather than two.
    length(Entries, Size).

% master_register_check_pole(+Pole): refuse an unbound or foreign pole, by name.
master_register_check_pole(Pole) :-
    % An unbound pole cannot be judged, and a roster read would bind it to whichever is listed first.
    (   var(Pole)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % Read the two poles from the one place they are written.
    master_register_poles(Poles),
    % A third pole is refused aloud, exactly as the bus has refused one since slice 35.
    (   memberchk(Pole, Poles)
    ->  true
    ;   domain_error(master_register_pole, Pole)
    ).

% master_register_check(+GlobalState): refuse a global state the register does not hold, by name.
master_register_check(GlobalState) :-
    % An unbound state is a hole and is refused before anything is read out of it.
    (   var(GlobalState)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % Refuse anything that is not the widened two-field term, naming what arrived.
    (   GlobalState = global_state(Pole, SubMode)
    ->  true
    ;   domain_error(master_register_global_state, GlobalState)
    ),
    % Refuse an unbound or foreign pole first, so the roster read below cannot be for nothing.
    master_register_check_pole(Pole),
    % A sub-mode is named by a plain atom, the same key shape every mode name in this build uses.
    must_be(atom, SubMode),
    % THE REFUSAL THAT MAKES THE ROSTER A ROSTER: a sub-mode belonging to the OTHER pole is refused
    % just as firmly as one belonging to neither, because a register that accepted slow-wave sleep as
    % a kind of waking would be a list of names rather than a statement about what the system does.
    (   master_register_entry(Pole, SubMode, _Formal, _Does)
    ->  true
    ;   domain_error(master_register_sub_mode_of_pole(Pole), SubMode)
    ).

% master_register_settle(+Announced, -GlobalState): read a bare or unstated announcement as named.
master_register_settle(Announced, GlobalState) :-
    % An unbound announcement is refused rather than settled into whichever state is listed first.
    (   var(Announced)
    ->  throw(error(instantiation_error, _))
    ;   true
    ),
    % A bare pole, and a widened term whose sub-mode was never stated, both mean the same thing: this
    % pole, at whatever the corpus says this pole ordinarily is. Both are settled in one place.
    (   Announced = global_state(Pole, unstated)
    ->  master_register_settle_default(Pole, GlobalState)
    ;   Announced = global_state(_Pole, _SubMode)
    ->  % A fully stated announcement is judged and handed back unchanged.
        master_register_check(Announced),
        GlobalState = Announced
    ;   atom(Announced)
    ->  % A bare atom is a pole and nothing else, which is every announcement made before slice 46.
        master_register_settle_default(Announced, GlobalState)
    ;   % Anything else is refused aloud rather than settled into a state nobody announced.
        domain_error(master_register_global_state, Announced)
    ).

% master_register_settle_default(+Pole, -GlobalState): the pole at the sub-mode the corpus calls ordinary.
master_register_settle_default(Pole, GlobalState) :-
    % Refuse an unbound or foreign pole before a default is read for it.
    master_register_check_pole(Pole),
    % Read this pole's default from the one place it is written.
    master_register_default_sub_mode(Pole, SubMode),
    % Hand back the fully named state, which now says which of the pole's sub-modes is meant.
    GlobalState = global_state(Pole, SubMode).

% master_register_announce(+Bus0, +GlobalState, -Bus): announce a global state onto the bus.
master_register_announce(Bus0, GlobalState, Bus) :-
    % JUDGE AGAINST THE ROSTER BEFORE THE STATE TRAVELS, because the channel judges shape only. The
    % division is slice 42's: shape is structural and belongs to the channel, a roster is policy and
    % belongs to the construct that owns it. Announcing through this predicate is what buys the
    % roster's refusal; the raw channel remains open and remains merely well formed.
    master_register_check(GlobalState),
    % Write it on the one broadcast the architecture permits, which is Layer 11's own answer to how a
    % state reaches everything below it: written once, read many times, by nobody's instruction.
    neuromodulator_bus_broadcast_global_state(Bus0, GlobalState, Bus).

% master_register_current(+Bus, -GlobalState): read the global state standing on the bus, fully named.
master_register_current(Bus, GlobalState) :-
    % Read whatever the channel is carrying, which may be widened, bare, or silent.
    neuromodulator_bus_global_state(Bus, Announced),
    % Settle it into a fully named state, so a reader never has to know which of the three it got.
    master_register_settle(Announced, GlobalState).

% ---------------------------------------------------------------------------
% THE DOWNWARD ASSIGNMENT
% ---------------------------------------------------------------------------
%
% THE MECHANISM IS BUILT AND THE TABLE IS EMPTY, AND THE EMPTINESS IS THE FINDING RATHER THAN THE
% SHORTFALL. This is the same shape slice 39 used when it gave every construct a fault block that was
% present and empty: the block was honest because nothing existed to do the watching, and it was
% filled three slices later when the watcher arrived. This table is honest for a reason that is
% sharper and worth stating precisely, because it is the most useful thing this slice found.
%
% THE CORPUS ASSIGNS TO NAMED INDIVIDUALS AND KONNECTOME HAS ONLY KINDS. Read any of the twenty-six
% downward assignments and every row addresses a NAMED CONSTRUCT: the thalamus to faithful relay, the
% hippocampus to theta-coded encoding with ripple replay suppressed, the thalamic reticular cells to
% rhythmic burst firing, the flip-flop motifs OF THE STATE MACHINERY latched to wake. konnectome has
% no named individuals at any of those grains. It has ARCHETYPES - relay, integrator, oscillator,
% attractor, gate, comparator - which are KINDS, instantiated wherever a world happens to want one.
%
% SO THE ONE ROW THAT LOOKS AVAILABLE IS THE ONE THAT MUST BE REFUSED. The corpus says the state
% machinery's flip-flops latch to wake, and konnectome's gate archetype was validated block by block
% at slice 40 against the corpus's own flip-flop entry - so it is tempting to write that waking
% assigns every gate the open mode. IT WOULD BE WRONG, and wrong in a way that would be very hard to
% find later: it would assign EVERY GATE IN THE REPOSITORY the mode of ONE NAMED FLIP-FLOP, including
% gates installed in roles that have nothing to do with the state machinery. That is the armchair
% guessing the Fourth Commandment forbids, wearing a corpus citation - the same shape slice 45 named
% when it refused a window length: A DEFAULT WITH A BORROWED WARRANT IS AN INVENTED NUMBER THAT HAS
% LEARNED TO CITE, arriving here as a MODE rather than as a number.
%
% THE CLOSER IS NAMED AND IT IS ALREADY ON THE QUEUE: the region-grain construct, which the design
% authority deferred by name and which requires promoting a territory from a level to a first-class
% NAMED construct. When konnectome has named individuals, this table has rows. Until then it has a
% mechanism, proved end to end against a fixture so that it cannot pass vacuously, and no rows.
%
% AND THE MECHANISM ITSELF INVENTS NOTHING AND OPENS NO DOOR. An assignment is applied through the
% MODE THROW channel slice 41 built, which is the corpus's own coordination mechanism and which
% slice 41 characterised in the sentence this slice leans on entirely: THE THROW IS A ROW, NOT A
% DOOR. A construct that declares no thrown row for its kind simply cannot be commanded, and says so
% through its own register rather than through a list kept elsewhere of who may command whom. That is
% what makes a downward assignment safe to aim at a kind at all: the assignment publishes, and each
% construct's own transition table decides whether it has anywhere to go.

% master_register_downward_assignment(+GlobalState, -Assignments): what a state sets at each kind below.
master_register_downward_assignment(GlobalState, Assignments) :-
    % Judge the state against the roster before an assignment is read for it, so a state nobody holds
    % can never be reported as one that assigns nothing.
    master_register_check(GlobalState),
    % Gather this state's declared rows. There are none today, for the reason written above, and the
    % table is read through findall rather than stated as [] so that adding one row is adding one
    % clause rather than editing this predicate.
    findall(assign(ConstructKind, Mode),
            master_register_assignment_row(GlobalState, ConstructKind, Mode),
            Assignments).

% THE TABLE HAS ROWS FROM SLICE 50, AND WHAT CHANGED WAS NOT THE MECHANISM BUT WHAT KONNECTOME HAS
% TO POINT AT (DECISION-9). The objection written above is about MULTIPLICITY, not about naming: a row
% aimed at "gate" is wrong because there are many gates and the corpus meant one of them. IT DOES NOT
% REACH A CONSTRUCT OF WHICH THERE IS EXACTLY ONE. The working memory blackboard is such a construct -
% the corpus's own gloss is "a small erasable surface ... read by everything", singular, definite and
% shared - so a row addressing it by name reaches exactly what the chapter was talking about and
% nothing else. The objection does not apply here rather than being overridden, and that distinction
% is the whole of DECISION-9. The ledger carries its argument and, as importantly, its list of what it
% does NOT decide - beginning with the fact that konnectome has no registry of instances, so the
% singleton claim is a claim made in prose by the pack that makes it, and not a proof.
%
% AND EVERY ROW STILL PUBLISHES RATHER THAN COMMANDS. Naming a construct here buys no authority over
% it: the row travels the mode-throw channel, the throw is a row and not a door, and a construct that
% declares no matching transition simply cannot be moved. That is why a table naming the blackboard
% does not make this file a controller, and it is the reason the rows are written here, in one
% readable table, rather than scattered into the packs they address.

% master_register_assignment_row(+GlobalState, -ConstructKind, -Mode): one row of one state's assignment.
%
% SLOW-WAVE SLEEP WIPES THE BOARD. Layer 10's Entry 16 gives its third mode as "slow-wave-sleep
% erasure, delay activity being incompatible with the slow oscillation's silent states", and this
% register's own gloss for the state is "consolidates and renormalises". Two volumes, one state, no
% conflict - and konnectome invents nothing in between them.
master_register_assignment_row(global_state(offline, slow_wave_sleep),
                               working_memory_blackboard,
                               erased_idle).
% REM LEAVES THE BOARD UNGOVERNED, WHICH IS NOT THE SAME AS LEAVING IT EMPTY. Entry 16's fourth mode
% is "rapid-eye-movement (REM) fragments igniting without gate control". The row says the GATE is
% gone; the surface still carries whatever ignites on it. Assigning erasure to both sleep states
% would have been the tidy reading and the corpus does not support it.
master_register_assignment_row(global_state(offline, rapid_eye_movement),
                               working_memory_blackboard,
                               ungoverned_flicker).
% NO OTHER STATE HAS A ROW, AND THE TWO KINDS OF ABSENCE BELOW ARE DIFFERENT AND BOTH DELIBERATE.
% SLEEP ONSET AND SPINDLED LIGHT SLEEP have none because Entry 16 says nothing about them, and a
% guess would be an invented mode that had learned to cite. THE FOUR WAKING STATES have none because
% Entry 16 says something that forbids one: it gives the waking transition the agency SELF_SELECTED,
% so a downward row for a waking state would overwrite, on every announcement, a choice the corpus
% places with the board. The global state does not get a vote on which waking posture the blackboard
% is in, and the silence of this table for online states is where konnectome says so.

% master_register_assign_downward(+Bus0, +GlobalState, -Bus): apply a state's assignment to the bus.
master_register_assign_downward(Bus0, GlobalState, Bus) :-
    % Read the state's rows, which judges the state on the way in.
    master_register_downward_assignment(GlobalState, Assignments),
    % Throw each row onto the mode-throw channel, in the table's own order.
    master_register_throw_rows(Assignments, Bus0, Bus).

% master_register_throw_rows(+Assignments, +Bus0, -Bus): throw each row in turn onto the bus.
% An exhausted assignment leaves the bus exactly as it found it, which is what an empty table means.
master_register_throw_rows([], Bus, Bus).
% Each row is one throw at one construct kind, through the channel slice 41 built.
master_register_throw_rows([assign(ConstructKind, Mode)|Rest], Bus0, Bus) :-
    % Throw this row. The channel judges the kind and the mode, and refuses the reserved silence name.
    neuromodulator_bus_throw_mode(Bus0, ConstructKind, Mode, Bus1),
    % Throw the remaining rows.
    master_register_throw_rows(Rest, Bus1, Bus).
