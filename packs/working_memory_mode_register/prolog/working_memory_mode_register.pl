% Declare this file as the 'working_memory_mode_register' module and list the predicates it exports.
:- module(working_memory_mode_register, [
    % working_memory_mode_register_construct/1: the name of the singleton this register is a register OF.
    working_memory_mode_register_construct/1,
    % working_memory_mode_register_entries/1: the four-mode register block, in the corpus's order.
    working_memory_mode_register_entries/1,
    % working_memory_mode_register_modes/1: the formal names of the four modes.
    working_memory_mode_register_modes/1,
    % working_memory_mode_register_size/1: how many modes the register holds - itself a statement.
    working_memory_mode_register_size/1,
    % working_memory_mode_register_automaton/1: the whole hybrid automaton, built through the mode_register pack.
    working_memory_mode_register_automaton/1,
    % working_memory_mode_register_transfer/2: the rule that holds while a named mode is current.
    working_memory_mode_register_transfer/2,
    % working_memory_mode_register_transitions/1: the transition table block.
    working_memory_mode_register_transitions/1,
    % working_memory_mode_register_faults/1: the fault regimes and watchdogs block.
    working_memory_mode_register_faults/1,
    % working_memory_mode_register_assigned_mode/2: the mode a global state throws at the board, or none.
    working_memory_mode_register_assigned_mode/2,
    % working_memory_mode_register_mode_on_bus/2: the mode standing thrown at the board on a given bus.
    working_memory_mode_register_mode_on_bus/2,
    % working_memory_mode_register_self_governed/1: the reserved answer meaning nothing is throwing at the board.
    working_memory_mode_register_self_governed/1
]).

% Import the list utilities used for membership and gathering.
:- use_module(library(lists), [memberchk/2]).
% Import the refusal used when a throw names a mode this register does not hold.
:- use_module(library(error), [existence_error/2]).
% Reuse slice 39's formalism rather than restating it; this register is judged by the same checker
% every other register in this repository is judged by.
:- use_module(library(mode_register), [mode_register_new/6, mode_register_transfer/3]).
% Reuse slice 46's master register for the roster of global states and for its own state checker.
:- use_module(library(master_register), [master_register_downward_assignment/2]).
% Reuse slice 41's mode-throw channel, which is the one route a downward assignment travels.
:- use_module(library(neuromodulator_bus), [neuromodulator_bus_thrown_mode/3,
                                            neuromodulator_bus_no_mode_thrown/1]).

% ---------------------------------------------------------------------------
% WHAT THIS PACK IS
% ---------------------------------------------------------------------------
%
% This is LAYER_10_MODES_MANUSCRIPT.txt ENTRY 16, THE WORKING MEMORY SYSTEM, written into the mode
% register formalism slice 39 built. The chapter hands over a four-mode register, a per-mode transfer
% function for each, a transition table and a fault block, in the same five-part shape every entry in
% that volume uses, and konnectome's job here is transcription plus the judgment about what will not
% transcribe.
%
% THIS REGISTER IS A REGISTER OF AN INDIVIDUAL, AND THAT IS THE WHOLE REASON IT COULD BE BUILT. Every
% register in this repository before this one is a register of a KIND - of clock, of hold, of relay -
% and a kind has many instances. THE BLACKBOARD IS A SINGLETON. The corpus says so in its own gloss:
% "a small erasable surface, written by attention, read by everything, wiped by the next task". One
% surface, definite article, shared. That single fact is what turns slice 46's empty downward
% assignment table from a gap into a table with rows, and DECISION-9 below is where that is argued.
%
% WHAT THIS PACK DOES NOT DO, STATED HERE SO THE GAPS ARE DECISIONS AND NOT OVERSIGHTS.
%
% IT RESTATES NO CONSTANT. Capacity, decay, collapse and the admission window all live one pack down
% in working_memory_blackboard, where slice 49 put them, and a register that repeated any of them
% would be a second place for a number to drift. The transfer functions below are POSTURES, not
% parameters: what the surface is doing and what the gate is doing, in two words, from the chapter's
% own per-mode prose.
%
% IT WIRES NOTHING INTO THE TICK. OBSERVATION-13 stands untouched: the board's step rate is still not
% konnectome's to declare, and this slice does not declare it. A register says what a construct CAN
% BE. It does not run it.
%
% IT DOES NOT DECIDE WHAT THE BOARD DOES IN THE TWO SLEEP SUB-MODES THE CORPUS IS SILENT ABOUT. The
% master register holds four offline sub-modes and this chapter speaks about two of them. The other
% two get no row, and the absence is read back as an explicit answer rather than as a mode.

% ---------------------------------------------------------------------------
% THE CONSTRUCT THIS REGISTER IS OF
% ---------------------------------------------------------------------------

% working_memory_mode_register_construct(-Name): the singleton this register is a register of.
% The name is the blackboard pack's own name, which is what makes the address checkable by a reader:
% there is one pack, it builds one surface, and the corpus's gloss says there is one of it.
working_memory_mode_register_construct(working_memory_blackboard).

% ---------------------------------------------------------------------------
% THE MODE REGISTER - THE CHAPTER'S FOUR ENTRIES, IN THE CHAPTER'S OWN ORDER
% ---------------------------------------------------------------------------
%
% Three fields and no more, as every register in this build has carried since slice 39: the formal
% name, the coined name always prefixed "the", and a one-clause gloss of what the construct does
% while it is in that mode. The rule is not here, the parameters are not here, and the entry and exit
% conditions are not here.

% Entry one. The chapter's own words are "attractors locked against distraction while contents are used".
working_memory_mode_register_entry(robust_maintenance, 'The Held Chalk',
    'holds what is written against distraction while everything above reads it').
% Entry two. The chapter's own words are "basal-ganglia-gated admission of new content, old content released".
working_memory_mode_register_entry(gated_updating, 'The Fresh Slate',
    'opens the admission gate, takes new content on, and lets old content go').
% Entry three. The chapter's own words are "slow-wave-sleep erasure, delay activity being incompatible
% with the slow oscillation's silent states".
working_memory_mode_register_entry(erased_idle, 'The Wiped Board',
    'carries nothing, because delay activity cannot survive the slow oscillation''s silent states').
% Entry four. The chapter's own words are "rapid-eye-movement (REM) fragments igniting without gate
% control, one account of dream incoherence".
working_memory_mode_register_entry(ungoverned_flicker, 'The Doodling Board',
    'takes whatever ignites, because nothing is holding the admission gate').

% working_memory_mode_register_entries(-Entries): the register block, in the corpus's own order.
working_memory_mode_register_entries(Entries) :-
    % Gather the entries in declaration order, which is the chapter's order, into the three-field term
    % the mode_register pack judges.
    findall(mode_entry(Formal, Coined, Gloss),
            working_memory_mode_register_entry(Formal, Coined, Gloss),
            Entries).

% working_memory_mode_register_modes(-Names): the formal names of the four modes.
working_memory_mode_register_modes(Names) :-
    % Read the names out of the one place the roster is written.
    findall(Formal, working_memory_mode_register_entry(Formal, _Coined, _Gloss), Names).

% working_memory_mode_register_size(-Size) : how many modes the register holds.
working_memory_mode_register_size(Size) :-
    % Count the roster rather than restating a number that could drift away from it.
    working_memory_mode_register_modes(Names),
    % THE LENGTH IS THE STATEMENT. The corpus holds that a register's length says what the system
    % trusts a component to decide, and four is what this chapter trusts the blackboard with.
    length(Names, Size).

% ---------------------------------------------------------------------------
% THE PER-MODE TRANSFER FUNCTIONS
% ---------------------------------------------------------------------------
%
% THE RULE TERM HOLDS TWO FIELDS AND NOT ONE NUMBER: wm_posture(Surface, Admission).
%
% Surface is what the written contents are doing - held or wiped. Admission is what the gate is
% doing - refused, gated, or ungoverned. Both fields are read straight off the chapter's per-mode
% transfer prose, and between them they say everything this chapter says about a mode that is not
% already a constant living in the blackboard pack.
%
% THE THREE ADMISSION WORDS ARE NOT A SCALE AND MUST NOT BE READ AS ONE. "Refused" and "ungoverned"
% are not the two ends of a dial with "gated" in the middle: refused is a gate that is working and
% held shut, ungoverned is NO GATE AT ALL. The chapter is explicit that the dream case is fragments
% "igniting WITHOUT GATE CONTROL", not fragments getting past a loose gate, and the two produce
% different behaviour on the same surface. Slice 49 met the identical shape one grain down when it
% refused to let an absent slot and a collapsed slot share one answer.

% Robust Maintenance. "Persistent prefrontal-parietal activity holds roughly 3 to 4 items across
% delays of seconds ... acetylcholine and noradrenaline set robustness to distraction." Held, and
% locked: this is the mode whose whole job is not admitting anything.
working_memory_mode_register_rule(robust_maintenance, wm_posture(held, refused)).
% Gated Updating. "The basal ganglia gate admits task-relevant items ... the explicit admission
% control." Held, and open: the gate is working and it is letting things through.
working_memory_mode_register_rule(gated_updating, wm_posture(held, gated)).
% Erased Idle. "Contents do not survive sleep onset." Wiped, and shut: there is nothing on the
% surface and nothing is being put there.
working_memory_mode_register_rule(erased_idle, wm_posture(wiped, refused)).
% Ungoverned Flicker. "Fragments ignite without admission control." Held, and ungoverned: things are
% arriving on the surface and no gate decided that they should.
working_memory_mode_register_rule(ungoverned_flicker, wm_posture(held, ungoverned)).

% working_memory_mode_register_transfers(-Transfers): the transfer block, parallel to the register.
working_memory_mode_register_transfers(Transfers) :-
    % Gather one row per mode, in the register's own order, so the two blocks cannot drift apart.
    findall(transfer(Formal, Rule),
            working_memory_mode_register_rule(Formal, Rule),
            Transfers).

% working_memory_mode_register_transfer(+Mode, -Rule): the rule that holds while Mode is current.
working_memory_mode_register_transfer(Mode, Rule) :-
    % Read the rule THROUGH the built automaton rather than off the clause above, so that this
    % lookup inherits the mode_register pack's refusals - an unbound key and a mode the register
    % does not declare are both refused there, in the one place every register in this build shares.
    working_memory_mode_register_automaton(Automaton),
    % Look the mode up under the shared checker.
    mode_register_transfer(Automaton, Mode, Rule).

% ---------------------------------------------------------------------------
% THE TRANSITION TABLE - AND THE ROW THAT IS NOT A TRANSITION
% ---------------------------------------------------------------------------
%
% OBSERVATION-14, AND IT IS THIS SLICE'S FINDING. THE CHAPTER'S TRANSITION TABLE CONTAINS A ROW THAT
% DOES NOT DESCRIBE A TRANSITION. Three of its four rows name a departure and an arrival. The fourth
% reads, in full: "Any mode under acute stress: excess catecholamines push D1 tone off the inverted-U,
% the gate loosens, and capacity effectively drops, within minutes; the same curve explains why
% Parkinson medication can impair this system."
%
% THAT ROW NAMES NO DESTINATION MODE, AND IT IS NOT AN OMISSION. It is a different kind of claim
% wearing the same table's heading: the first three rows are DISCRETE mode changes and this one is a
% CONTINUOUS shift of the parameters the current mode runs on. The board does not become a different
% machine under stress. It stays the machine it was and that machine gets worse.
%
% KONNECTOME'S FOUR-FIELD ROW CANNOT HOLD IT, AND THE NATURAL WRONG MOVE IS EXACTLY THE ONE TO NAME.
% A builder who wants the corpus's table to arrive complete writes a self-loop - transition(acute_stress,
% Mode, Mode, minutes, thrown_from_above) for each of the four - and it would be accepted by the
% checker, and it would look like fidelity. It is the opposite. mode_register_departure/3 would then
% answer a caller asking where acute stress sends the board with "to the mode you are already in",
% which is a confident answer to a question whose true answer is "stress does not send it anywhere".
% A self-loop says A TRANSITION HAPPENED AND LANDED HOME. The corpus says NO TRANSITION HAPPENS.
%
% SO THE ROW IS REFUSED ALOUD RATHER THAN TRANSCRIBED. It is not written, it is named here, and it is
% logged as OBSERVATION-14 in the ledger. This is slice 42's "a fault is not a mode" arriving from a
% new direction - A MODULATION IS NOT A TRANSITION - and it is the third time in four slices that the
% dangerous claim has been one the corpus really does make, on the right page, about a different kind
% of thing. Its closer is named and not done: konnectome has no D1 tone, no inverted-U and no
% catecholamine curve, so there is nothing here for the row to modulate. When the arousal and stress
% states of the Layer 11 volume's Part Four are built - the ones the master register left out because
% they OVERLAY a base state rather than being one - this row is theirs, and it should arrive as an
% overlay on the transfer function rather than as an edge in this table.
%
% AGENCY IS A COLUMN AND EVERY ROW BELOW FILLS IT, because slice 41 made the departure lookup keyed on
% agency and this is the first register in the build where two agencies really do write rows into one
% table: the waking cycle is the board's own and the sleep chain is thrown at it from above.

% Row one, and the chapter's own words: "task context or reward prediction signals open the gate,
% sub-second, cycling many times per minute during fluent thought".
working_memory_mode_register_transition(
    task_context_or_reward_prediction, robust_maintenance, gated_updating, sub_second, self_selected).
% Row two, and it is the RETURN half of row one's cycle rather than a row the chapter writes on its
% own line. The chapter states the CYCLE - "cycling many times per minute during fluent thought" - and
% a cycle between two modes has two edges. What the chapter does NOT give is a separate trigger for
% the way back, so the trigger written here is the chapter's own word for the cycle rather than a
% condition konnectome guessed at. Omitting this row was the alternative and it was rejected: a table
% with only the outward edge would say the board can be updated once and can never go back to holding,
% which contradicts the sentence the row is taken from.
working_memory_mode_register_transition(
    cycling_during_fluent_thought, gated_updating, robust_maintenance, sub_second, self_selected).
% Row three, and the chapter's own words: "Waking modes to Erased Idle to Ungoverned Flicker: thrown
% from above by the sleep-stage broadcast, the dominant slow transitions." The chapter writes this as
% a CHAIN, so it becomes one edge out of each waking mode into Erased Idle, and one edge from there
% onward - never a direct waking-to-flicker edge, which the chain does not license.
working_memory_mode_register_transition(
    sleep_stage_broadcast, robust_maintenance, erased_idle, slow, thrown_from_above).
% Row four, the same chain out of the other waking mode.
working_memory_mode_register_transition(
    sleep_stage_broadcast, gated_updating, erased_idle, slow, thrown_from_above).
% Row five, the chain's second link, and the corpus's own ordering: erasure comes first and the
% ungoverned theatre comes after it.
working_memory_mode_register_transition(
    sleep_stage_broadcast, erased_idle, ungoverned_flicker, slow, thrown_from_above).

% working_memory_mode_register_transitions(-Transitions): the transition table block.
working_memory_mode_register_transitions(Transitions) :-
    % Gather the rows in declaration order, which is the chapter's order.
    findall(transition(Trigger, From, To, Timescale, Agency),
            working_memory_mode_register_transition(Trigger, From, To, Timescale, Agency),
            Transitions).

% ---------------------------------------------------------------------------
% THE FAULT BLOCK
% ---------------------------------------------------------------------------
%
% FAULTS ARE WATCHED AND NEVER ADMITTED AS MODES, which is slice 42's rule and this chapter obeys it
% without being asked: perseveration and distractibility appear under FAULT REGIMES and not in the
% mode register, even though a careless reading would make each of them a fifth and a sixth posture.
%
% THE CHAPTER GIVES TWO BOUNDARY SIGNATURES AND THREE WATCHDOGS, AND IT DOES NOT PAIR THEM. Its
% sentence is "a gate stuck shut is perseveration, a gate stuck open is distractibility, and both live
% on the same dopamine curve; watchdogs are the inverted-U itself as a self-limiting envelope,
% noradrenaline-mediated network resets, and parietal normalisation limiting attractor runaway."
% The watchdog list is offered to BOTH signatures together - "both live on the same curve" is the
% chapter saying so directly - so both rows carry the same list rather than having one invented
% apiece. Splitting them would have been konnectome deciding which watchdog catches which fault, and
% the chapter does not decide that.

% working_memory_mode_register_watchdogs(-Watchdogs): the three the chapter names, in its own order.
working_memory_mode_register_watchdogs([inverted_u_self_limiting_envelope,
                                        noradrenergic_network_reset,
                                        parietal_normalisation]).

% The first boundary signature: the gate that will not open.
working_memory_mode_register_fault_row(gate_stuck_shut, perseveration).
% The second boundary signature: the gate that will not shut.
working_memory_mode_register_fault_row(gate_stuck_open, distractibility).

% working_memory_mode_register_faults(-Faults): the fault regimes and watchdogs block.
working_memory_mode_register_faults(Faults) :-
    % Read the watchdog list once, from the one place it is written.
    working_memory_mode_register_watchdogs(Watchdogs),
    % Build one three-field fault entry per boundary signature, both carrying the shared list.
    findall(fault(Boundary, Warning, Watchdogs),
            working_memory_mode_register_fault_row(Boundary, Warning),
            Faults).

% ---------------------------------------------------------------------------
% THE AUTOMATON
% ---------------------------------------------------------------------------
%
% THE CURRENT MODE IS ROBUST MAINTENANCE, AND THIS IS THE ONE PLACE A READER SHOULD LOOK HARDEST,
% BECAUSE IT IS THE SHAPE OF EVERY DEFAULT THIS BUILD HAS LEARNED TO DISTRUST. The chapter states no
% resting mode for the blackboard. So why is one written here?
%
% BECAUSE THE CURRENT-MODE SLOT IS NOT A DEFAULT AND CANNOT BE OMITTED. mode_register_check/1 refuses
% an automaton whose current mode is not in its register, which means the term cannot be built at all
% without one, and the corpus's own formalism is the same: a hybrid automaton is always standing
% somewhere. What is written here is a STARTING POSITION for a term nothing yet steps, not a claim
% about what the blackboard ordinarily is - and the difference is checkable rather than asserted,
% because NOTHING IN THIS PACK READS IT. The mode a caller actually gets is read off the bus by
% working_memory_mode_register_mode_on_bus/2 below, and a silent bus answers "self-governed" rather
% than answering with this slot.
%
% AND THE CHOICE AMONG THE FOUR IS THE CORPUS'S ORDER RATHER THAN KONNECTOME'S PREFERENCE: Robust
% Maintenance is the chapter's first entry, and the first entry is where the chapter starts reading.
% That is a weaker warrant than a stated default and it is written down as a weaker one.

% working_memory_mode_register_automaton(-Automaton): the whole hybrid automaton, judged as it is built.
working_memory_mode_register_automaton(Automaton) :-
    % Read the four blocks from the four places they are written.
    working_memory_mode_register_entries(Entries),
    working_memory_mode_register_transfers(Transfers),
    working_memory_mode_register_transitions(Transitions),
    working_memory_mode_register_faults(Faults),
    % Build it through slice 39's constructor, which judges every block before handing the term back,
    % so a register that had drifted out of step with its own transfer block could never be read.
    mode_register_new(robust_maintenance, Entries, Transfers, Transitions, Faults, Automaton).

% ---------------------------------------------------------------------------
% DECISION-9 - THE FIRST DOWNWARD ASSIGNMENT THAT ADDRESSES AN INDIVIDUAL
% ---------------------------------------------------------------------------
%
% Slice 46 built the downward assignment mechanism and left its table empty, and wrote down exactly
% why: THE CORPUS ASSIGNS TO NAMED INDIVIDUALS AND KONNECTOME HAS ONLY KINDS. A row aimed at a kind
% would hand one named construct's mode to every instance of that archetype anywhere in the
% repository. Slice 46 named the temptation it refused - waking assigns every gate the open mode -
% and called the closer the region-grain construct.
%
% DECISION-9 TAKES THE SMALLER HALF OF THAT CLOSER, WHICH TURNS OUT TO BE AVAILABLE NOW: A DOWNWARD
% ASSIGNMENT MAY ADDRESS A CONSTRUCT OF WHICH THE REPOSITORY HOLDS EXACTLY ONE, BY ITS NAME.
%
% WHY A SINGLETON IS ADDRESSABLE WHERE A KIND IS NOT. Slice 46's objection was never about names; it
% was about MULTIPLICITY. "Assign every gate the open mode" is wrong because there are many gates and
% the corpus was talking about one of them. There is one blackboard. The corpus's own gloss is "a
% small erasable surface", singular and definite, "read by everything" - a shared surface is shared
% precisely because there is not one per reader. So the row "slow-wave sleep wipes the blackboard"
% reaches exactly what the chapter is talking about and nothing else. THE OBJECTION DOES NOT APPLY,
% RATHER THAN BEING OVERRIDDEN, and that is the whole difference between this row and the gate row
% slice 46 refused.
%
% AND THE ROWS THEMSELVES LIVE IN master_register.pl, BESIDE THE MECHANISM, WHICH IS WHERE SLICE 46
% SAID THEY WOULD GO. A first draft of this slice put them here instead, behind a multifile
% declaration, on the argument that a state register holding a list of the constructs below it is a
% homunculus arriving as a data structure. THAT ARGUMENT WAS WRONG AND IS RECORDED RATHER THAN
% DELETED, because the reasoning that killed it is slice 46's own and is worth not re-deriving: AN
% ASSIGNMENT PUBLISHES, IT DOES NOT COMMAND. The throw is a row and not a door; a construct that
% declares no matching transition simply cannot be moved and says so through its own register. A
% table that names a construct therefore acquires no authority over it, and inventing an indirection
% to avoid a naming that carries no power would have bought nothing and cost a reader the ability to
% read the whole table in one file. The build's rule against armchair architecture applies to
% konnectome's own doctrines too.
%
% WHAT DECISION-9 DOES NOT DECIDE, STATED SO A LATER SLICE DOES NOT INHERIT MORE THAN WAS ARGUED.
%
% IT DOES NOT DECIDE HOW KONNECTOME KNOWS A CONSTRUCT IS A SINGLETON. There is no registry of
% instances and this slice does not build one. The singleton claim is made by the pack that makes it,
% in prose, from the corpus's own definite article - it is a CLAIM AND NOT A PROOF, and a second pack
% that started building blackboards would falsify it silently. The honest closer is the naming and
% addressing facility already on the queue, which is where instance identity actually belongs.
%
% IT DOES NOT DECIDE THE OVERLAY QUESTION. Two simultaneously active states still have no composition
% rule, exactly as slice 46 left it.
%
% IT DOES NOT WIDEN WHAT A ROW MAY SAY. A row still travels the mode-throw channel, still publishes
% rather than commands, and a construct with no matching transition still simply cannot be moved.
%
% AND IT DOES NOT DECIDE WHAT THE BOARD DOES IN SLEEP ONSET OR SPINDLED LIGHT SLEEP. Two of the master
% register's four offline sub-modes get no row below, because this chapter says nothing about them.
% A reader asking gets the reserved "nothing thrown" answer, which is the absence, not a mode.

% THE TWO ROWS THIS SLICE ADDS ARE IN master_register.pl and are read back through the mechanism
% below rather than restated here, so there is one table and not two. What this pack owns is the
% JUDGMENT about them: which modes are the board's, and which states may not have a row at all.
%
% NO WAKING STATE GETS A ROW, AND THAT IS A REFUSAL RATHER THAN A GAP. The master register holds four
% online sub-modes and it would be easy to give each of them robust_maintenance or gated_updating.
% THE CHAPTER FORBIDS IT IN THE COLUMN IT FILLED IN: the waking transition's agency is SELF_SELECTED -
% "task context or reward prediction signals open the gate" - while the sleep transition's agency is
% thrown from above. A downward assignment for a waking state would overwrite, every announcement, a
% choice the corpus says belongs to the board. THE GLOBAL STATE DOES NOT GET A VOTE ON WHICH OF ITS
% TWO WAKING POSTURES THE BLACKBOARD IS IN, and the empty half of that table is where that is said.

% working_memory_mode_register_assigned_mode(+GlobalState, -Mode): the mode a state throws at the
% board, or the reserved "nothing thrown" answer when the corpus gives that state no row.
working_memory_mode_register_assigned_mode(GlobalState, Mode) :-
    % Read the state's whole downward assignment through the master register, which judges the state
    % against its roster on the way in - so a state nobody holds is refused aloud rather than reported
    % as a state that assigns nothing. The two are different facts and slice 49 paid to learn that
    % they must never share an answer.
    master_register_downward_assignment(GlobalState, Assignments),
    % Read the singleton's name from the one place it is written.
    working_memory_mode_register_construct(Construct),
    % Take this board's row out of the state's assignment, if the state has one for it.
    (   memberchk(assign(Construct, Found), Assignments)
    ->  Mode = Found
    % A state with no row for the board is answered with the bus's own reserved silence name rather
    % than with a mode, so "the corpus says nothing about the board here" is never an instruction.
    ;   working_memory_mode_register_self_governed(Mode)
    ).

% ---------------------------------------------------------------------------
% READING THE BOARD'S MODE OFF A BUS
% ---------------------------------------------------------------------------

% working_memory_mode_register_self_governed(-Answer): the reserved answer meaning nothing is throwing
% at the board. It is the mode-throw channel's own silence name, read from the one place it is
% written, rather than a second word for the same fact.
working_memory_mode_register_self_governed(Answer) :-
    % Read the channel's reserved name; slice 41 refuses anybody to THROW it, which is what makes it
    % safe to hand back as an answer.
    neuromodulator_bus_no_mode_thrown(Answer).

% working_memory_mode_register_mode_on_bus(+Bus, -Mode): the mode standing thrown at the board.
%
% A SILENT CHANNEL MEANS SELF-GOVERNED AND IS NEVER READ AS A DEFAULT MODE. This is the pack's whole
% answer to the default-drift lens. The established idiom in this repository is a read WITH A NAMED
% DEFAULT, seven times over, and it is not used here, deliberately: every one of those seven defaults
% is a value the CORPUS states as ordinary, and this chapter states no ordinary mode for the
% blackboard. A default invented here would be an invented value that had learned to cite. So the
% silence reads back as silence, and a caller that needs a mode has to notice that it did not get one.
working_memory_mode_register_mode_on_bus(Bus, Mode) :-
    % Read whatever is standing thrown at the singleton's name on the mode-throw channel. The channel
    % answers an unwritten key with its own reserved silence name, which is exactly the answer wanted.
    neuromodulator_bus_thrown_mode(Bus, working_memory_blackboard, Thrown),
    % Read the reserved name once so the comparison below is against the one place it is written.
    working_memory_mode_register_self_governed(Silence),
    % A standing throw is judged against this register before it is handed back, so a throw naming a
    % mode this board does not have is refused aloud instead of being passed on as though it were one.
    % The channel guarantees a well-formed atom; only this register knows which atoms are its modes.
    (   Thrown == Silence
    ->  Mode = Silence
    ;   working_memory_mode_register_modes(Names),
        (   memberchk(Thrown, Names)
        ->  Mode = Thrown
        ;   existence_error(working_memory_mode_register_mode, Thrown)
        )
    ).
