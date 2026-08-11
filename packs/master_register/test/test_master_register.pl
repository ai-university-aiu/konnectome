% Load the master register module under test from the library path.
:- use_module(library(master_register)).
% Load the neuromodulator bus, because the whole point of a global state is that it is ANNOUNCED, and
% a register that could not be read back off the real bus would not be a master register.
:- use_module(library(neuromodulator_bus)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Open the test block for the master register pack.
:- begin_tests(master_register).

% ---------------------------------------------------------------------------
% THE REGISTER ITSELF
% ---------------------------------------------------------------------------

% The flip-flop has exactly two poles, and the register does not quietly grow a third.
test(the_flip_flop_has_exactly_two_poles) :-
    % Read the poles from the one place they are written.
    master_register_poles(Poles),
    % Which are the two konnectome has broadcast since slice 35, unchanged.
    Poles == [online, offline].

% THE WIDENING, MEASURED. The master register held two entries and now holds eight.
test(the_master_register_now_holds_eight_entries) :-
    % The size is read from the roster rather than restated, so it cannot drift from it.
    master_register_size(Size),
    % Four waking sub-modes and four sleep sub-modes, from the Layer 11 outline's Parts One and Two.
    Size == 8.

% Each pole holds four sub-modes, in the corpus outline's own order.
test(each_pole_holds_four_sub_modes_in_the_corpus_order) :-
    % The waking family, Layer 11 outline entries 1 through 4.
    master_register_sub_modes(online, Waking),
    % In the outline's order, which is the order they are declared in.
    Waking == [alert_task_engaged, relaxed_wakefulness, focused_absorption, drowsy_waking],
    % The sleep family, Layer 11 outline entries 5 through 8.
    master_register_sub_modes(offline, Sleeping),
    % In the outline's order likewise.
    Sleeping == [sleep_onset, spindled_light_sleep, slow_wave_sleep, rapid_eye_movement].

% Every entry carries the corpus's own three fields, the same schema every register has held since
% slice 39 - so a watcher holding nothing but a state name can read what runs while it holds.
test(every_entry_carries_the_registers_three_fields) :-
    % Read the whole register.
    master_register_entries(Entries),
    % The first entry is waking's default, carrying its formal name and what runs while it holds.
    Entries = [mode_entry(global_state(online, alert_task_engaged),
                          'Alert Task-Engaged Waking',
                          'computes on the world')|_Rest].

% A third pole is refused aloud, exactly as the bus has refused one since slice 35.
test(a_third_pole_is_refused, throws(error(domain_error(master_register_pole, drowsing), _))) :-
    % A pole the flip-flop does not have cannot have a roster read for it.
    master_register_sub_modes(drowsing, _SubModes).

% An unbound pole is refused rather than bound to whichever pole is listed first.
test(an_unbound_pole_is_refused, throws(error(instantiation_error, _))) :-
    % A hole where a pole belongs would invent a pole and a roster for it.
    master_register_sub_modes(_Hole, _SubModes).

% ---------------------------------------------------------------------------
% THE ROSTER IS A ROSTER: A SUB-MODE BELONGS TO ITS OWN POLE AND TO NO OTHER
% ---------------------------------------------------------------------------

% A fully named state the register holds passes.
test(a_state_the_register_holds_passes) :-
    % Waking, alert and task-engaged.
    master_register_check(global_state(online, alert_task_engaged)),
    % And sleep, in the deep works.
    master_register_check(global_state(offline, slow_wave_sleep)).

% THE CENTRAL REFUSAL OF THE ROSTER: a sub-mode belonging to the OTHER pole is refused just as firmly
% as one belonging to neither, because a register that accepted slow-wave sleep as a kind of waking
% would be a list of names rather than a statement about what the system does.
test(a_sub_mode_of_the_other_pole_is_refused,
     throws(error(domain_error(master_register_sub_mode_of_pole(online), slow_wave_sleep), _))) :-
    % Slow-wave sleep is a real sub-mode, and it is not a way of being awake.
    master_register_check(global_state(online, slow_wave_sleep)).

% A sub-mode belonging to neither pole is refused by the same rule and the same error.
test(a_sub_mode_of_no_pole_is_refused,
     throws(error(domain_error(master_register_sub_mode_of_pole(offline), daydreaming), _))) :-
    % A plausible name the corpus does not catalogue is still not in the register.
    master_register_check(global_state(offline, daydreaming)).

% A term that is not a widened state is refused aloud, naming what arrived.
test(a_term_that_is_not_a_global_state_is_refused,
     throws(error(domain_error(master_register_global_state, online), _))) :-
    % A bare pole is a legal ANNOUNCEMENT and is not a fully named STATE, and check judges states.
    master_register_check(online).

% An unbound state is refused before anything is read out of it.
test(an_unbound_state_is_refused, throws(error(instantiation_error, _))) :-
    % A hole cannot be judged against a roster.
    master_register_check(_Hole).

% ---------------------------------------------------------------------------
% THE DEFAULTS, WHICH ARE THE CORPUS'S AND NOT KONNECTOME'S
% ---------------------------------------------------------------------------

% A bare pole - which is every announcement made anywhere in this repository before slice 46 - settles
% to that pole at the sub-mode the corpus calls ordinary for it.
test(a_bare_pole_settles_to_the_corpus_default) :-
    % Waking settles to the state the corpus calls the default assumption of nearly every experiment.
    master_register_settle(online, Waking),
    % Which is alert, task-engaged waking.
    Waking == global_state(online, alert_task_engaged),
    % Sleep settles to the state whose downward assignment names consolidation and renormalisation -
    % which is precisely and only what konnectome's offline phase has done since slice 38.
    master_register_settle(offline, Sleeping),
    % Which is slow-wave sleep, read back from the corpus rather than picked.
    Sleeping == global_state(offline, slow_wave_sleep).

% A widened term whose sub-mode was never stated settles the same way, in the same one place.
test(an_unstated_sub_mode_settles_to_the_same_default) :-
    % The channel reports an un-stated sub-mode with this reserved name rather than inventing one.
    master_register_settle(global_state(online, unstated), Settled),
    % And the register is what supplies the name, because a roster is the register's job.
    Settled == global_state(online, alert_task_engaged).

% A fully stated announcement is handed back unchanged, and is judged on the way through.
test(a_fully_stated_announcement_settles_to_itself) :-
    % A state the register holds.
    master_register_settle(global_state(offline, rapid_eye_movement), Settled),
    % Comes back exactly as it went in.
    Settled == global_state(offline, rapid_eye_movement).

% And a fully stated announcement the register does NOT hold is refused while settling, so a bad
% state cannot enter through the settling door having been refused at the announcing one.
test(settling_refuses_a_state_the_register_does_not_hold,
     throws(error(domain_error(master_register_sub_mode_of_pole(online), sleep_onset), _))) :-
    % Sleep onset is not a way of being awake, wherever it is presented.
    master_register_settle(global_state(online, sleep_onset), _Settled).

% ---------------------------------------------------------------------------
% BEHAVIOUR PINNED IDENTICAL: EVERY READER WRITTEN BEFORE THE WIDENING STILL GETS ITS ANSWER
% ---------------------------------------------------------------------------

% THE SLICE'S CENTRAL PROMISE. A widened announcement still reads back through the OLD reader as the
% pole alone, so every predicate written since slice 35 that asks "am I awake or asleep" is correct
% rather than merely compatible.
test(a_widened_state_still_reads_back_as_the_pole_alone) :-
    % An empty bus.
    neuromodulator_bus_new(Bus0),
    % Announce a fully named sleep state through the register, which judges it against the roster.
    master_register_announce(Bus0, global_state(offline, rapid_eye_movement), Bus),
    % The reader every caller since slice 35 uses hands back the POLE, not the compound.
    neuromodulator_bus_operating_state(Bus, Pole),
    % Which is offline, exactly as it would have been before the widening existed.
    Pole == offline.

% A bare announcement, in the shape every existing caller makes, is unchanged in both directions.
test(a_bare_announcement_is_unchanged_in_both_directions) :-
    % An empty bus.
    neuromodulator_bus_new(Bus0),
    % Announce the way every caller has since slice 35, through the channel's original predicate.
    neuromodulator_bus_broadcast_operating_state(Bus0, offline, Bus),
    % The original reader answers exactly as it always did.
    neuromodulator_bus_operating_state(Bus, Pole),
    % Which is offline.
    Pole == offline,
    % And the register reads the same bus as a fully named state, supplying the sub-mode itself.
    master_register_current(Bus, GlobalState),
    % Which is sleep in the deep works, the pole's corpus default.
    GlobalState == global_state(offline, slow_wave_sleep).

% A silent bus - one that never heard a state at all - reads as waking, as it has since slice 35.
test(a_silent_bus_reads_as_the_waking_default) :-
    % An empty bus that has heard nothing.
    neuromodulator_bus_new(Bus),
    % The original reader answers online, the waking default, unchanged.
    neuromodulator_bus_operating_state(Bus, Pole),
    % Which is online.
    Pole == online,
    % And the register names the sub-mode a silent bus means.
    master_register_current(Bus, GlobalState),
    % Which is alert, task-engaged waking.
    GlobalState == global_state(online, alert_task_engaged).

% The newest announcement wins, exactly as it does for every level on this bus.
test(the_newest_announcement_wins) :-
    % An empty bus.
    neuromodulator_bus_new(Bus0),
    % Announce waking.
    master_register_announce(Bus0, global_state(online, focused_absorption), Bus1),
    % Then announce sleep.
    master_register_announce(Bus1, global_state(offline, spindled_light_sleep), Bus2),
    % The newest announcement is what stands.
    master_register_current(Bus2, GlobalState),
    % Which is the spindled light sleep just announced.
    GlobalState == global_state(offline, spindled_light_sleep).

% ANNOUNCING THROUGH THE REGISTER BUYS THE ROSTER'S REFUSAL, which is the point of announcing through
% it rather than writing on the raw channel.
test(announcing_a_state_the_register_does_not_hold_is_refused,
     throws(error(domain_error(master_register_sub_mode_of_pole(online), slow_wave_sleep), _))) :-
    % An empty bus.
    neuromodulator_bus_new(Bus0),
    % A well formed term that names a sub-mode of the wrong pole never reaches the bus.
    master_register_announce(Bus0, global_state(online, slow_wave_sleep), _Bus).

% THE DIVISION OF LABOUR IS PINNED, because it is a design decision and not an accident: the CHANNEL
% judges shape, and lets a roster violation through, because a roster is policy and belongs to the
% construct that owns it. This is the same division slice 42 drew for mode_register and faults.
test(the_channel_judges_shape_and_not_the_roster) :-
    % An empty bus.
    neuromodulator_bus_new(Bus0),
    % The raw channel accepts a well formed term whose sub-mode belongs to the other pole.
    neuromodulator_bus_broadcast_global_state(Bus0, global_state(online, slow_wave_sleep), Bus),
    % And it reads back, because the channel was never asked to hold an opinion about rosters.
    neuromodulator_bus_global_state(Bus, Announced),
    % Exactly as it was written.
    Announced == global_state(online, slow_wave_sleep).

% But the channel DOES refuse a pole the flip-flop does not have, because that is structural.
test(the_channel_refuses_a_third_pole,
     throws(error(domain_error(neuromodulator_bus_operating_state, drowsing), _))) :-
    % An empty bus.
    neuromodulator_bus_new(Bus0),
    % A third pole is refused by the channel's own long-standing domain.
    neuromodulator_bus_broadcast_global_state(Bus0, global_state(drowsing, alert_task_engaged), _Bus).

% And it refuses a term that is not a widened state at all.
test(the_channel_refuses_a_term_that_is_not_a_widened_state,
     throws(error(domain_error(neuromodulator_bus_global_state, awake), _))) :-
    % An empty bus.
    neuromodulator_bus_new(Bus0),
    % A bare atom is not a widened state and is refused by the widened writer, naming what arrived.
    neuromodulator_bus_broadcast_global_state(Bus0, awake, _Bus).

% ---------------------------------------------------------------------------
% THE DOWNWARD ASSIGNMENT
% ---------------------------------------------------------------------------

% THE TABLE IS NO LONGER EMPTY, AND THE TEST THAT SAID IT WAS HAS BEEN REPLACED RATHER THAN DELETED.
% Until slice 50 this suite pinned the emptiness of every state's assignment, and the pin was correct:
% konnectome had construct KINDS where the corpus has NAMED INDIVIDUALS. DECISION-9 did not overturn
% that reasoning; it found the case the reasoning does not reach - a construct of which there is
% exactly one - and the working memory blackboard is the first of them. So the two rows below are the
% pinned fact now, and the emptiness that remains is pinned separately and for its own stated reason.
test(the_two_sleep_states_the_corpus_speaks_about_carry_their_rows) :-
    % Slow-wave sleep wipes the board.
    master_register_downward_assignment(global_state(offline, slow_wave_sleep), Deep),
    assertion(Deep == [assign(working_memory_blackboard, erased_idle)]),
    % REM removes the gate rather than the surface - a different mode, not a stronger one.
    master_register_downward_assignment(global_state(offline, rapid_eye_movement), Rem),
    assertion(Rem == [assign(working_memory_blackboard, ungoverned_flicker)]).

% NO WAKING STATE ASSIGNS ANYTHING, AND THIS EMPTINESS IS A REFUSAL RATHER THAN A GAP WAITING TO BE
% FILLED. Entry 16 gives the waking transition the agency SELF_SELECTED, so a row here would overwrite
% a choice the corpus places with the board itself, on every single announcement.
test(no_waking_state_assigns_anything_and_that_is_the_refusal) :-
    % Every waking sub-mode the register holds.
    master_register_sub_modes(online, WakingSubModes),
    % Assigns nothing, and the check runs over all four rather than over a chosen one.
    forall(member(SubMode, WakingSubModes),
           (   master_register_downward_assignment(global_state(online, SubMode), Assignments),
               Assignments == []
           )).

% THE TWO SLEEP STATES THE CORPUS IS SILENT ABOUT ALSO ASSIGN NOTHING, and this is a THIRD kind of
% emptiness, kept apart from the other two on purpose: not "no individual to address" and not "the
% construct's own choice", but simply a state no chapter has spoken about yet.
test(the_unspoken_sleep_states_assign_nothing) :-
    % Sleep onset is in the register and in no chapter's mode table.
    master_register_downward_assignment(global_state(offline, sleep_onset), Onset),
    assertion(Onset == []),
    % So is spindled light sleep.
    master_register_downward_assignment(global_state(offline, spindled_light_sleep), Spindled),
    assertion(Spindled == []).

% WHATEVER ROWS EXIST ARE WELL FORMED, and this check runs over all eight states rather than a chosen
% one.
test(every_row_of_every_state_is_well_formed) :-
    % Every entry the register holds.
    master_register_entries(Entries),
    % Every row it assigns names an atom construct and an atom mode, and nothing else.
    forall(member(mode_entry(GlobalState, _Formal, _Does), Entries),
           (   master_register_downward_assignment(GlobalState, Assignments),
               forall(member(Row, Assignments),
                      (   Row = assign(Kind, Mode),
                          atom(Kind),
                          atom(Mode)
                      ))
           )).

% An assignment cannot be read for a state the register does not hold, so a state nobody holds can
% never be reported as one that assigns nothing.
test(an_assignment_cannot_be_read_for_a_state_the_register_does_not_hold,
     throws(error(domain_error(master_register_sub_mode_of_pole(online), sleep_onset), _))) :-
    % A state that is not in the register has no assignment, and saying so is not the same as
    % handing back an empty one.
    master_register_downward_assignment(global_state(online, sleep_onset), _Assignments).

% Applying an assignment with no rows leaves the bus exactly as it found it, which is what having no
% rows MEANS. THE STATE CHOSEN HERE IS A WAKING ONE ON PURPOSE, and the reason is DECISION-9's own
% refusal rather than today's load list: the chapter gives the waking transition to the construct's
% OWN agency, so a waking state is the one kind of state this register has argued must never carry a
% downward row. A test written against a sleep state would have been correct until slice 50 and
% quietly wrong afterwards.
test(applying_an_assignment_with_no_rows_changes_nothing) :-
    % A bus carrying a level, so that "unchanged" is a real claim and not a claim about nothing.
    neuromodulator_bus_new(Empty),
    % Put something on it.
    neuromodulator_bus_broadcast(Empty, dopamine, 3, Bus0),
    % Apply a waking state's downward assignment, which carries no rows and is argued never to.
    master_register_assign_downward(Bus0, global_state(online, alert_task_engaged), Bus),
    % The bus is unchanged, term for term.
    Bus == Bus0.

% THE MECHANISM IS PROVED AGAINST A FIXTURE, so the empty table cannot hide a broken walk. A test
% that drove only the empty table would pass vacuously and would prove that nothing happens.
test(the_assignment_walk_really_does_reach_the_throw_channel) :-
    % An empty bus.
    neuromodulator_bus_new(Bus0),
    % A FIXTURE assignment - not the register's, which is empty - carrying two rows.
    master_register_throw_rows([assign(gate, closed), assign(relay, quiet)], Bus0, Bus),
    % The first row stands as a thrown mode on the channel slice 41 built.
    neuromodulator_bus_thrown_mode(Bus, gate, GateMode),
    % Which is the mode the row named.
    GateMode == closed,
    % And so does the second, so the walk does not stop after one.
    neuromodulator_bus_thrown_mode(Bus, relay, RelayMode),
    % Which is the mode its row named.
    RelayMode == quiet.

% AND THE ASSIGNMENT OPENS NO DOOR, WHICH IS THE PROPERTY THAT MAKES IT SAFE TO AIM AT A KIND AT ALL.
% Slice 41's throw is A ROW, NOT A DOOR: a kind nobody has thrown at reads back as silence, so a
% construct that declares no thrown row simply cannot be commanded.
test(a_kind_the_assignment_did_not_name_is_untouched) :-
    % An empty bus.
    neuromodulator_bus_new(Bus0),
    % A fixture assignment naming one kind only.
    master_register_throw_rows([assign(gate, closed)], Bus0, Bus),
    % A kind the assignment never named reads back as the reserved silence, not as an instruction.
    neuromodulator_bus_thrown_mode(Bus, oscillator, Mode),
    % Which is the channel's own reserved name for having been told nothing.
    Mode == no_mode_thrown.

% Close the test block for the master register pack.
:- end_tests(master_register).
