disp( 'This script checks that DynareOBC''s solution agrees with Dynare''s for the Brendon Paustian and Yates (2012) model.' );

disp( 'The Dynare solution first:' );

dynare BPYModelCheck

drawnow;

delete BPYModelCheck*.m
delete BPYModelCheck*.log
delete BPYModelCheck*.mat
rmdir BPYModelCheck s

disp( 'Now the DynareOBC solution:' );

ShockSequence = [ 0 1 zeros( 1, 38 ) ];
save ShockSequence ShockSequence;

dynareOBC BPYModelCheck MLVSimulationMode=1 ShockSequenceFile=ShockSequence.mat
