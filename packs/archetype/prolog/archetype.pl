% Declare this file as the 'archetype' module and list the predicates it exports.
:- module(archetype, [
    % archetype_relay/3: the relay rule - pass the weighted input, scaled by gain.
    archetype_relay/3,
    % archetype_integrator/4: the integrator rule - a leaky accumulator.
    archetype_integrator/4,
    % archetype_oscillator/5: the oscillator rule - advance phase and derive receptivity.
    archetype_oscillator/5,
    % archetype_attractor/5: the attractor rule - move toward the nearest stored pattern.
    archetype_attractor/5,
    % archetype_gate/4: the gate rule - flip mode only above threshold.
    archetype_gate/4,
    % archetype_comparator/3: the comparator rule - report the prediction error.
    archetype_comparator/3,
    % archetype_step/3: the dispatch - read the archetype and apply the matching rule.
    archetype_step/3
]).

% Import the list and apply utilities used by the attractor's pattern arithmetic.
:- use_module(library(lists), [sum_list/2]).
% Import maplist for elementwise pattern operations.
:- use_module(library(apply), [maplist/3, maplist/4]).

% ---------------------------------------------------------------------------
% THE SIX ARCHETYPE RULES (Appendix 2, Section A2.3)
% ---------------------------------------------------------------------------

% A RELAY is a pipe that passes what it is given, scaled by its gain.
% archetype_relay(+TotalInput, +Gain, -NextActivation): the scaled input.
archetype_relay(TotalInput, Gain, NextActivation) :-
    % Multiply the total weighted input by the current gain.
    NextActivation is TotalInput * Gain.

% An INTEGRATOR is a bucket that fills with input and leaks a little each tick.
% archetype_integrator(+CurrentActivation, +LeakFactor, +TotalInput, -NextActivation): fill and leak.
archetype_integrator(CurrentActivation, LeakFactor, TotalInput, NextActivation) :-
    % Decay the current activation by the leak factor, then add this tick's input.
    NextActivation is CurrentActivation * LeakFactor + TotalInput.

% An OSCILLATOR is a metronome: its phase advances at its natural frequency and wraps.
% archetype_oscillator(+CurrentPhase, +NaturalFrequency, +CycleLength, -NextPhase, -Gain): keep time.
archetype_oscillator(CurrentPhase, NaturalFrequency, CycleLength, NextPhase, Gain) :-
    % Advance the phase by the natural frequency.
    Sum is CurrentPhase + NaturalFrequency,
    % Wrap the advanced phase back into the range of one full cycle.
    NextPhase is Sum - CycleLength * floor(Sum / CycleLength),
    % Derive the receptivity, which rises and falls once per cycle.
    archetype_receptivity(NextPhase, CycleLength, Gain).

% The receptivity is a raised cosine over the cycle, peaking once and troughing once.
% archetype_receptivity(+Phase, +CycleLength, -Gain): a value in the range zero to one.
archetype_receptivity(Phase, CycleLength, Gain) :-
    % Compute the raised cosine of the phase across one cycle.
    Gain is (1 + cos(2 * pi * Phase / CycleLength)) / 2.

% An ATTRACTOR completes a pattern: it moves a step toward the nearest stored memory.
% archetype_attractor(+CurrentPattern, +InputPattern, +StoredPatterns, +StepFraction, -NextPattern): complete.
archetype_attractor(CurrentPattern, InputPattern, StoredPatterns, StepFraction, NextPattern) :-
    % Blend the current pattern with the arriving input pattern.
    archetype_blend(CurrentPattern, InputPattern, Blended),
    % Find the stored pattern most similar to the blended pattern.
    archetype_nearest(Blended, StoredPatterns, Nearest),
    % Move the current pattern a small step toward that nearest stored pattern.
    archetype_move_toward(CurrentPattern, Nearest, StepFraction, NextPattern).

% A GATE is a stiff switch: it flips its mode only when the drive exceeds its threshold.
% archetype_gate(+CurrentMode, +SwitchDrive, +Threshold, -NextMode): flip or hold.
archetype_gate(CurrentMode, SwitchDrive, Threshold, NextMode) :-
    % Flip the mode when the switching drive is above threshold, otherwise keep it.
    ( SwitchDrive > Threshold
      -> archetype_flip_mode(CurrentMode, NextMode)
      ;  NextMode = CurrentMode
    ).

% A COMPARATOR is a scale: it reports how far the actual input departs from the expected.
% archetype_comparator(+ExpectedInput, +ActualInput, -PredictionError): the signed difference.
archetype_comparator(ExpectedInput, ActualInput, PredictionError) :-
    % Subtract the expected input from the actual input to get the prediction error.
    PredictionError is ActualInput - ExpectedInput.

% ---------------------------------------------------------------------------
% ATTRACTOR HELPERS (composite pattern operations)
% ---------------------------------------------------------------------------

% archetype_flip_mode(?Mode, ?Opposite): the two gate modes are opposites of each other.
% An open gate flips to closed.
archetype_flip_mode(open, closed).
% A closed gate flips to open.
archetype_flip_mode(closed, open).

% archetype_average(+X, +Y, -Mean): the arithmetic mean of two numbers.
archetype_average(X, Y, Mean) :-
    % Average the two values.
    Mean is (X + Y) / 2.

% archetype_blend(+A, +B, -Blended): the elementwise mean of two equal-length patterns.
archetype_blend(A, B, Blended) :-
    % Take the elementwise average across the two patterns.
    maplist(archetype_average, A, B, Blended).

% archetype_squared_difference(+X, +Y, -Square): the squared difference of two numbers.
archetype_squared_difference(X, Y, Square) :-
    % Subtract, then square the difference.
    Difference is X - Y,
    % Square the difference.
    Square is Difference * Difference.

% archetype_distance(+A, +B, -Distance): the squared Euclidean distance between two patterns.
archetype_distance(A, B, Distance) :-
    % Square the elementwise differences.
    maplist(archetype_squared_difference, A, B, Squares),
    % Sum the squared differences.
    sum_list(Squares, Distance).

% archetype_nearest(+Target, +Patterns, -Nearest): the stored pattern closest to the target.
archetype_nearest(Target, [First|Rest], Nearest) :-
    % Measure the distance to the first candidate as the running best.
    archetype_distance(Target, First, FirstDistance),
    % Fold the remaining candidates, keeping the closest.
    archetype_nearest_(Rest, Target, First, FirstDistance, Nearest).

% archetype_nearest_(+Rest, +Target, +BestPattern, +BestDistance, -Nearest): the fold's helper.
% With no candidates left, the running best is the nearest.
archetype_nearest_([], _Target, BestPattern, _BestDistance, BestPattern).
% Otherwise compare the next candidate and keep whichever is closer.
archetype_nearest_([Pattern|More], Target, BestPattern, BestDistance, Nearest) :-
    % Measure the distance to this candidate.
    archetype_distance(Target, Pattern, Distance),
    % Keep the closer of the candidate and the running best.
    ( Distance < BestDistance
      -> archetype_nearest_(More, Target, Pattern, Distance, Nearest)
      ;  archetype_nearest_(More, Target, BestPattern, BestDistance, Nearest)
    ).

% archetype_interpolate(+Step, +Current, +Target, -Next): one number moved toward a target.
archetype_interpolate(Step, Current, Target, Next) :-
    % Move from the current value a fraction Step of the way to the target.
    Next is Current + Step * (Target - Current).

% archetype_move_toward(+Current, +Target, +Step, -Next): move a whole pattern toward a target.
archetype_move_toward(Current, Target, Step, Next) :-
    % Interpolate each element of the pattern toward the target by the step fraction.
    maplist(archetype_interpolate(Step), Current, Target, Next).

% ---------------------------------------------------------------------------
% THE DISPATCH (Appendix 2, Section A2.2): one canonical computation, rewired.
% ---------------------------------------------------------------------------

% archetype_step(+Archetype, +Inputs, -Outputs): read the archetype and apply the matching rule.
% A relay construct: read its total input and gain, produce its next activation.
archetype_step(relay, Inputs, Outputs) :-
    % Read the total weighted input arriving at the construct.
    get_dict(total_input, Inputs, TotalInput),
    % Read the current gain the neuromodulators have set.
    get_dict(gain, Inputs, Gain),
    % Apply the relay rule.
    archetype_relay(TotalInput, Gain, Activation),
    % Return the next activation.
    Outputs = _{activation: Activation}.
% An integrator construct: read its activation, leak, and input, produce its next activation.
archetype_step(integrator, Inputs, Outputs) :-
    % Read the current activation.
    get_dict(activation, Inputs, CurrentActivation),
    % Read the leak factor slightly less than one.
    get_dict(leak_factor, Inputs, LeakFactor),
    % Read the total input for this tick.
    get_dict(total_input, Inputs, TotalInput),
    % Apply the integrator rule.
    archetype_integrator(CurrentActivation, LeakFactor, TotalInput, Activation),
    % Return the next activation.
    Outputs = _{activation: Activation}.
% An oscillator construct: read its phase, frequency, and cycle, produce phase and gain.
archetype_step(oscillator, Inputs, Outputs) :-
    % Read the current phase.
    get_dict(phase, Inputs, Phase),
    % Read the natural frequency.
    get_dict(natural_frequency, Inputs, NaturalFrequency),
    % Read the cycle length.
    get_dict(cycle_length, Inputs, CycleLength),
    % Apply the oscillator rule.
    archetype_oscillator(Phase, NaturalFrequency, CycleLength, NextPhase, Gain),
    % Return the next phase and the derived gain.
    Outputs = _{phase: NextPhase, gain: Gain}.
% An attractor construct: read its pattern, input, memories, and step, produce its next pattern.
archetype_step(attractor, Inputs, Outputs) :-
    % Read the current activation pattern.
    get_dict(pattern, Inputs, Pattern),
    % Read the arriving input pattern.
    get_dict(input_pattern, Inputs, InputPattern),
    % Read the stored patterns.
    get_dict(stored_patterns, Inputs, StoredPatterns),
    % Read the step fraction.
    get_dict(step_fraction, Inputs, StepFraction),
    % Apply the attractor rule.
    archetype_attractor(Pattern, InputPattern, StoredPatterns, StepFraction, NextPattern),
    % Return the next pattern.
    Outputs = _{pattern: NextPattern}.
% A gate construct: read its mode, switch drive, and threshold, produce its next mode.
archetype_step(gate, Inputs, Outputs) :-
    % Read the current mode.
    get_dict(mode, Inputs, Mode),
    % Read the drive to switch the gate.
    get_dict(switch_drive, Inputs, SwitchDrive),
    % Read the switching threshold.
    get_dict(threshold, Inputs, Threshold),
    % Apply the gate rule.
    archetype_gate(Mode, SwitchDrive, Threshold, NextMode),
    % Return the next mode.
    Outputs = _{mode: NextMode}.
% A comparator construct: read its expected and actual inputs, produce the prediction error.
archetype_step(comparator, Inputs, Outputs) :-
    % Read the expected input.
    get_dict(expected_input, Inputs, ExpectedInput),
    % Read the actual input.
    get_dict(actual_input, Inputs, ActualInput),
    % Apply the comparator rule.
    archetype_comparator(ExpectedInput, ActualInput, PredictionError),
    % Return the prediction error as the next activation.
    Outputs = _{activation: PredictionError}.
