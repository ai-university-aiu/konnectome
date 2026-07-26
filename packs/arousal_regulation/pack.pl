% State the fact: name(arousal_regulation) — an aroused state brought back toward baseline over time.
name(arousal_regulation).
% State the fact: version('0.1.0') — the regulation pilot, the second of Rung Four's two remaining trials (konnectome build slice 19).
version('0.1.0').
% State the fact: the title names the construct, its ladder rung, and its konnectome build slice.
title('arousal_regulation — the Rung Four regulation pilot: an aroused state, carried as norepinephrine on the neuromodulatory bus, brought back toward its tonic baseline over time and settling exactly there, never past (konnectome build slice 19)').
% State the fact: the author is the parent organization ai-university-aiu.
author('ai-university-aiu', 'ai.university.aiu@gmail.com').
% State the fact: regulation reuses the neuromodulatory bus - it reads and rewrites one modulator's level.
requires([neuromodulator_bus]).
% State the fact: layer(0) — regulation reads and writes the bus through the library path and adds no update rule.
layer(0).
