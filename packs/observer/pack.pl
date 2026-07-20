% State the fact: name(observer) — the passive observer that records each tick as a Causalontology record.
name(observer).
% State the fact: version('0.1.0') — the first delivery, konnectome build slice 2.
version('0.1.0').
% State the fact: the title names the construct, its architecture component, and what it records.
title('observer — the passive observer (Architecture Component 9); records each tick as a Causalontology token_occurrence (konnectome build slice 2)').
% State the fact: the author is the parent organization ai-university-aiu.
author('ai-university-aiu', 'ai.university.aiu@gmail.com').
% State the fact: requires([causal_core]) — reuses PrologAI's Causalontology core to content-address records.
requires([causal_core]).
% State the fact: layer(0) — base infrastructure; the observer only reads and records, changing nothing.
layer(0).
