% Load the stabiliser module under test from the library path.
:- use_module(library(stabiliser)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Load the bus, because the stability bias travels as a LEVEL on the channel konnectome already has.
:- use_module(library(neuromodulator_bus)).
% Load the two-process governor, whose two constants this slice turns from declared into derived.
:- use_module(library(two_process_governor)).
% Load the archetype library, to pin that the stabiliser's agency is in no transition table.
:- use_module(library(archetype)).
% Load the list utilities used by the tests.
:- use_module(library(lists)).

% Open the test block for the stabiliser pack.
:- begin_tests(stabiliser).

% ---------------------------------------------------------------------------
% WHAT THE STABILISER IS
% ---------------------------------------------------------------------------

% The key the bias travels under is named once, and it is a PLAIN ATOM - the bus's oldest key shape.
test(the_bias_travels_under_one_named_plain_atom_key) :-
    % Read the key from its single home.
    stabiliser_bias_key(Key),
    % It is the stability bias, and it is an atom rather than a compound.
    assertion(Key == stability_bias),
    % A plain atom is the level key shape, which is what DECISION-1 says a bias must use.
    assertion(atom(Key)).

% DECISION-1 APPLIED, NOT RE-OPENED: the bias is published as a LEVEL and read back as a level.
test(the_bias_is_published_as_a_level_on_the_existing_channel) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % The stabiliser publishes a band half-width of three.
    stabiliser_publish(Bus0, 3, Bus),
    % It reads back through the stabiliser's own accessor.
    stabiliser_bias(Bus, Bias),
    % The value is the one published.
    assertion(Bias == 3),
    % AND it reads back through the bus's ORDINARY LEVEL READ, which is the proof it is a level:
    % nothing about this value needs the stabiliser to interpret it.
    stabiliser_bias_key(Key),
    neuromodulator_bus_level(Bus, Key, SameBias),
    % The two reads agree, because there is only one value and one key shape.
    assertion(SameBias == 3).

% THE READ-WITH-A-NAMED-DEFAULT IDIOM, now established a fifth time: silence reads as ZERO.
test(a_bus_nobody_published_to_reads_a_bias_of_zero) :-
    % An empty bus, on which no stabiliser has ever spoken.
    neuromodulator_bus_new(Bus),
    % The standing bias reads back as zero rather than failing or binding a hole.
    stabiliser_bias(Bus, Bias),
    % Zero is a band of no width: one boundary, which is the symmetric toggle konnectome already had.
    assertion(Bias == 0).

% A NEGATIVE BIAS INVERTS THE BAND and is refused aloud, never published where a switch could read it.
test(a_negative_bias_is_refused_at_publication) :-
    % An empty bus to publish onto.
    neuromodulator_bus_new(Bus0),
    % Try to publish a band of negative width.
    catch(stabiliser_publish(Bus0, -1, _Bus), Error, true),
    % The refusal names the stabiliser's own domain, so the offending value cannot hide.
    assertion(Error = error(domain_error(stabiliser_bias, -1), _)).

% THE UNBOUND-WRONG-JUDGEMENT LENS: a hole would be bound by the arithmetic and would invent a band.
test(an_unbound_bias_is_refused_before_any_band_is_computed) :-
    % Ask for a band whose width nobody supplied.
    catch(stabiliser_band(9, _Unbound, _Upper, _Lower), Error, true),
    % It is refused as an instantiation fault rather than answered.
    assertion(Error = error(instantiation_error, _)).

% An unbound MIDPOINT would invent where the band sits, and is refused for the same reason.
test(an_unbound_midpoint_is_refused_before_any_band_is_computed) :-
    % Ask for a band whose position nobody supplied.
    catch(stabiliser_band(_Unbound, 7, _Upper, _Lower), Error, true),
    % It is refused as an instantiation fault rather than answered.
    assertion(Error = error(instantiation_error, _)).

% ---------------------------------------------------------------------------
% THE AGENCY: A BIAS MOVES NOTHING
% ---------------------------------------------------------------------------

% The stabiliser states its agency rather than leaving it to be inferred from what it happens to do.
test(the_stabiliser_states_its_agency) :-
    % Read the agency from its single home.
    stabiliser_agency(Agency),
    % It publishes a bias; it does not throw a mode. The two shapes are not the same thing.
    assertion(Agency == broadcast_bias).

% AND THE AGENCY IS IN NO TRANSITION TABLE, which is the sharpest available statement of what a bias
% is: since slice 40 a construct is moved ONLY by a row of its own table, and the stabiliser has none.
test(the_stabilisers_agency_appears_in_no_transition_table) :-
    % Read the stabiliser's agency.
    stabiliser_agency(Agency),
    % Read the gate's transition table, which is the only populated table in the repository.
    archetype_gate_transitions(Transitions),
    % Gather every agency the table names.
    findall(RowAgency, member(transition(_Trigger, _From, _To, _Timescale, RowAgency), Transitions), Agencies),
    % The table has agencies - this test would pass vacuously against an empty table, so check first.
    assertion(Agencies \== []),
    % And the stabiliser's is not among them: it changes where a boundary sits, and moves nothing.
    assertion(\+ memberchk(Agency, Agencies)).

% ---------------------------------------------------------------------------
% DECISION-3: WHICH GRAINS THE SCALAR GOVERNS
% ---------------------------------------------------------------------------

% The grain question the corpus answers two ways is DECIDED, and the decision is readable.
test(the_governed_grains_are_stated_and_are_the_construct_grain_alone) :-
    % Read the roster from its single home.
    stabiliser_governed_grains(Grains),
    % The construct grain, and nothing else.
    assertion(Grains == [construct_grain]).

% THE DECISION IS A REFUSAL AND NOT A COMMENT: the motif grain is turned away by name.
test(the_motif_grain_is_refused_aloud_rather_than_quietly_steadied) :-
    % Ask the stabiliser to govern the grain the corpus answers differently.
    catch(stabiliser_check_grain(motif_grain), Error, true),
    % It is refused, naming the grain, so the two-grain ambiguity cannot be crossed by accident.
    assertion(Error = error(domain_error(stabiliser_governed_grain, motif_grain), _)).

% The governed grain passes the same check, so the refusal is a gate and not a wall.
test(the_construct_grain_passes_the_same_check) :-
    % The one governed grain is admitted.
    stabiliser_check_grain(construct_grain).

% An unbound grain would be bound to the one governed grain by a careless check; it is refused.
test(an_unbound_grain_is_refused) :-
    % Ask about a grain nobody named.
    catch(stabiliser_check_grain(_Unbound), Error, true),
    % It is refused as an instantiation fault rather than admitted.
    assertion(Error = error(instantiation_error, _)).

% ---------------------------------------------------------------------------
% THE BAND ITSELF
% ---------------------------------------------------------------------------

% A band is a midpoint and a half-width, and the two boundaries follow.
test(a_band_is_a_midpoint_and_a_half_width) :-
    % A midpoint of nine and a half-width of seven.
    stabiliser_band(9, 7, Upper, Lower),
    % The upper boundary is the one a rising quantity must reach.
    assertion(Upper == 16),
    % The lower boundary is the one a falling quantity must reach.
    assertion(Lower == 2).

% AT A BIAS OF ZERO THE TWO BOUNDARIES COINCIDE, which is the symmetric toggle konnectome already had.
test(a_bias_of_zero_collapses_the_band_to_a_single_boundary) :-
    % A midpoint of nine and no width at all.
    stabiliser_band(9, 0, Upper, Lower),
    % Both boundaries are the midpoint: one boundary, no hysteresis, today's behaviour.
    assertion(Upper == 9),
    assertion(Lower == 9).

% ---------------------------------------------------------------------------
% THE GOVERNOR'S TWO CONSTANTS, NOW DERIVED RATHER THAN DECLARED
% ---------------------------------------------------------------------------

% THE PROOF THAT NOTHING WAS INVENTED: the derived band reproduces the governor's own long-standing
% pair EXACTLY. Sixteen and two were never replaced by different numbers; they were restated as what
% they always were, a band about a midpoint, and the restatement is checked rather than asserted.
test(the_derived_band_reproduces_the_governors_own_two_constants_exactly) :-
    % The governor's own default block, built the way it has been built since it shipped.
    two_process_governor_new(Governor),
    % Unpack the block the governor is actually running on.
    Governor = two_process_governor(_Pressure, _Phase, Base),
    % Read the midpoint and half-width the stabiliser publishes as its defaults.
    stabiliser_default_midpoint(Midpoint),
    stabiliser_default_bias(Bias),
    % Derive a parameter block whose band comes from the stabiliser rather than from two constants.
    stabiliser_governor_parameters(Base, Midpoint, Bias, Derived),
    % The derived block is the original block, field for field. Nothing in the machine moved.
    assertion(Derived == Base).

% A GOVERNOR BUILT ON THE DERIVED BLOCK RUNS THE SAME DAY, which is the claim that actually matters:
% identical parameters are only evidence, and identical behaviour is the proof.
test(a_governor_on_the_derived_band_runs_an_identical_day) :-
    % The governor as it has always been built.
    two_process_governor_new(Original),
    % Unpack its block and re-derive that block through the stabiliser.
    Original = two_process_governor(Pressure, Phase, Base),
    stabiliser_default_midpoint(Midpoint),
    stabiliser_default_bias(Bias),
    stabiliser_governor_parameters(Base, Midpoint, Bias, Derived),
    % Build a second governor standing in exactly the same place, on the derived band.
    Rebuilt = two_process_governor(Pressure, Phase, Derived),
    % Run both for a full corpus day of twenty-four ticks and gather the states each selects.
    test_stabiliser_run_day(Original, online, 24, OriginalStates),
    test_stabiliser_run_day(Rebuilt, online, 24, RebuiltStates),
    % The two days are identical, tick for tick.
    assertion(OriginalStates == RebuiltStates).

% THE HONEST INTERACTION, PINNED RATHER THAN DISCOVERED LATER: the governor refuses a band of zero
% width. A gate reads a zero bias as "no hysteresis" and behaves as before; the governor cannot,
% because its own guard has forbidden a flat or inverted band since it was built, and a flat band
% would chatter. The two consumers therefore read the SAME scalar and have DIFFERENT floors, and that
% is stated here so nobody meets it as a surprise.
test(the_governor_refuses_a_band_of_zero_width_where_a_gate_accepts_one) :-
    % The governor's own default block.
    two_process_governor_new(two_process_governor(_P, _Ph, Base)),
    % Derive a block whose band has no width at all.
    stabiliser_governor_parameters(Base, 9, 0, Flat),
    % Standing a governor on it and stepping is refused by the governor's own hysteresis guard.
    catch(two_process_governor_step(two_process_governor(0, 0, Flat), online, _G, _S), Error, true),
    % The refusal is the governor's, by its own name, and it names the flat band it was handed.
    assertion(Error = error(domain_error(two_process_governor_hysteresis, 9-9), _)).

% A parameter block of the wrong shape is refused by the governor's own name, not quietly reshaped.
test(a_misshapen_parameter_block_is_refused_by_the_governors_own_name) :-
    % Hand the derivation something that is not a governor parameter block.
    catch(stabiliser_governor_parameters(not_a_block(1), 9, 7, _Parameters), Error, true),
    % The refusal borrows the governor's domain name, because it is the governor's shape being judged.
    assertion(Error = error(domain_error(two_process_governor_parameters, not_a_block(1)), _)).

% test_stabiliser_run_day(+Governor, +State, +Ticks, -States): run the governor and gather its selections.
test_stabiliser_run_day(_Governor, _State, 0, []) :- !.
test_stabiliser_run_day(Governor0, State0, Ticks, [State|Rest]) :-
    % Advance both processes one tick and take the state the flip-flop selects.
    two_process_governor_step(Governor0, State0, Governor, State),
    % Count the tick down.
    Remaining is Ticks - 1,
    % Continue from the advanced governor in the newly selected state.
    test_stabiliser_run_day(Governor, State, Remaining, Rest).

% Close the test block for the stabiliser pack.
:- end_tests(stabiliser).
