dynareOBC DynareOBCVersion.mod NoCubature ShockSequenceFile=ExtendedPathResults.mat
DOBCNEndoSequence = oo_.endo_simul;
save DynareOBCResultsNew.mat DOBCNEndoSequence
