% State the fact: name(cognitive_cycle) — wires all ten components into one running tick, the loop of the mind.
name(cognitive_cycle).
% State the fact: version('0.6.0') — slice 74 wires the working-memory blackboard: the tick maintains
% the board once every hundred ticks under DECISION-23 and erases it outright on every offline tick.
version('0.6.0').
% State the fact: the title names the construct and what it integrates.
title('cognitive_cycle — the integrated one-tick cognitive cycle wiring all ten architecture components in the Section A3.3 order (konnectome build slice 8)').
% State the fact: the author is the parent organization ai-university-aiu.
author('ai-university-aiu', 'ai.university.aiu@gmail.com').
% State the fact: requires the component packs it orchestrates (their dependencies come transitively), the bus it announces on, since slice 37 the two-process governor it seats in the tick, since slice 38 the offline consolidation engine the thrown switch commands, since slice 72 the conflict monitor the arbitration step now runs through, and since slice 74 the working-memory blackboard the tick maintains and erases.
requires([drive_system, connection_graph, action_selector, override_controller, conflict_monitor, plasticity_engine, observer, neuromodulator_bus, two_process_governor, offline_consolidation, working_memory_blackboard]).
% State the fact: layer(0) — base infrastructure; same-layer edges to the components it composes are allowed.
layer(0).
