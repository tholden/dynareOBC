dynareOBC DynareOBCVersion.mod NoCubature ShockSequenceFile=ExtendedPathResults.mat
DOBCEndoSequence = oo_.endo_simul;
save DynareOBCResults.mat DOBCEndoSequence
