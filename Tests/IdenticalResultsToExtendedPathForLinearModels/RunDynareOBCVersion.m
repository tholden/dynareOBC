dynareOBC DynareOBCVersion.mod NoCubature ShockSequenceFile=ExtendedPathResults.mat
DOBCEndoSequence = oo_.endo_simul(1:end-1,:);
save DynareOBCResults.mat DOBCEndoSequence
