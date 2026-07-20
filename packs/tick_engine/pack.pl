% State the fact: name(tick_engine) — the scheduler that keeps time and drives the two-pass synchronous update.
name(tick_engine).
% State the fact: version('0.1.0') — the first konnectome delivery, the heartbeat slice.
version('0.1.0').
% State the fact: the title names the construct, its architecture component, and its konnectome build slice.
title('tick_engine — the scheduler and tick engine, realizing Architecture Component 2 (konnectome build slice 1, the heartbeat)').
% State the fact: the author is the parent organization ai-university-aiu.
author('ai-university-aiu', 'ai.university.aiu@gmail.com').
% State the fact: requires([]) — the heartbeat imports only SWI-Prolog standard libraries.
requires([]).
% State the fact: layer(0) — base infrastructure; the scheduler sits beneath every region, keeping time without preferences.
layer(0).
