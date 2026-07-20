% Declare this file as the 'drive_system' module and list the predicates it exports.
:- module(drive_system, [
    % drive_system_error/3: one drive's current error, the distance from its set-point.
    drive_system_error/3,
    % drive_system_step/6: advance all drives one tick, compute the reward, broadcast it as dopamine.
    drive_system_step/6,
    % drive_system_proposals/3: each drive proposes an action to reduce it, in proportion to its error.
    drive_system_proposals/3,
    % drive_system_apply_action/4: the released action moves the body, so the body responds to what is done.
    drive_system_apply_action/4
]).

% Import membership, summation, and selection for body variables, rewards, and body updates.
:- use_module(library(lists), [memberchk/2, sum_list/2, select/3]).
% Import maplist for updating every drive together.
:- use_module(library(apply), [maplist/4]).
% Reuse the neuromodulatory bus to broadcast the reward as dopamine.
:- use_module(library(neuromodulator_bus), [neuromodulator_bus_broadcast/4]).

% The drive system is Architecture Component 5: the homeostatic drives that make the System want
% things. A drive is drive(Name, Variable, SetPoint, PreviousError). Each tick it reads its monitored
% body variable, measures how far that value sits from its set-point, and the reward for the tick is
% the TOTAL REDUCTION of error across all drives (Section A2.4). That reward is then broadcast as
% phasic dopamine, which later becomes the third factor of learning. On the very first tick a drive's
% PreviousError is the atom 'none', so that first tick yields no spurious reward.

% drive_system_error(+Drive, +BodyState, -NewError): the drive's error, the absolute distance from set-point.
drive_system_error(drive(_Name, Variable, SetPoint, _Previous), BodyState, NewError) :-
    % Read the monitored variable's current value from the body state.
    memberchk(Variable-Value, BodyState),
    % The error is the absolute distance of that value from the set-point.
    NewError is abs(Value - SetPoint).

% drive_system_update_one(+BodyState, +Drive0, -Drive, -ErrorReduction): advance one drive by a tick.
drive_system_update_one(BodyState, drive(Name, Variable, SetPoint, PreviousError0),
                        drive(Name, Variable, SetPoint, NewError), ErrorReduction) :-
    % Read the monitored variable's current value from the body state.
    memberchk(Variable-Value, BodyState),
    % Measure this tick's error as the absolute distance from the set-point.
    NewError is abs(Value - SetPoint),
    % On the first tick the previous error is the new error, so no spurious reward is produced.
    ( PreviousError0 == none -> Previous = NewError ; Previous = PreviousError0 ),
    % The reduction is how much the error fell since last tick; a rise is a negative reduction.
    ErrorReduction is Previous - NewError.

% drive_system_step(+Drives0, +BodyState, +Bus0, -Drives, -Reward, -Bus): one drive-loop tick.
drive_system_step(Drives0, BodyState, Bus0, Drives, Reward, Bus) :-
    % Advance every drive, collecting the updated drives and each one's error reduction.
    maplist(drive_system_update_one(BodyState), Drives0, Drives, Reductions),
    % The reward for the tick is the total error reduction across all drives.
    sum_list(Reductions, Reward),
    % Broadcast that reward as the phasic dopamine level for this tick.
    neuromodulator_bus_broadcast(Bus0, dopamine, Reward, Bus).

% drive_system_proposals(+Drives, +BodyState, -Candidates): each drive proposes an action to reduce it.
drive_system_proposals(Drives, BodyState, Candidates) :-
    % Each drive proposes reducing itself, with a salience equal to its current error (A2.4 biasing).
    findall(action(reduce(Name), Error),
            ( member(drive(Name, Variable, SetPoint, Previous), Drives),
              drive_system_error(drive(Name, Variable, SetPoint, Previous), BodyState, Error) ),
            Candidates).

% drive_system_toward(+Value, +SetPoint, -NewValue): move a value one step toward the set-point.
drive_system_toward(Value, SetPoint, NewValue) :-
    % Step down if above the set-point, up if below, and hold if already there.
    ( Value > SetPoint -> NewValue is Value - 1
    ; Value < SetPoint -> NewValue is Value + 1
    ; NewValue = Value
    ).

% drive_system_move_variable(+Variable, +SetPoint, +BodyState0, -BodyState): step one body variable toward its set-point.
drive_system_move_variable(Variable, SetPoint, BodyState0, BodyState) :-
    % If the body carries the variable, step it toward the set-point; otherwise leave the body unchanged.
    ( select(Variable-Value, BodyState0, Rest)
      -> drive_system_toward(Value, SetPoint, NewValue),
         keysort([Variable-NewValue | Rest], BodyState)
      ;  BodyState = BodyState0
    ).

% drive_system_apply_action(+Outcome, +Drives, +BodyState0, -BodyState): the released action moves the body.
% A reduce action moves that drive's monitored variable one step toward its set-point.
drive_system_apply_action(released(reduce(Name)), Drives, BodyState0, BodyState) :-
    % Find the named drive so its monitored variable and set-point are known.
    memberchk(drive(Name, Variable, SetPoint, _Previous), Drives),
    % Commit to this clause once the reduce action names a real drive.
    !,
    % Move that drive's monitored variable one step toward its set-point.
    drive_system_move_variable(Variable, SetPoint, BodyState0, BodyState).
% Any other outcome (a different action, or none) leaves the body unchanged.
drive_system_apply_action(_Outcome, _Drives, BodyState, BodyState).
