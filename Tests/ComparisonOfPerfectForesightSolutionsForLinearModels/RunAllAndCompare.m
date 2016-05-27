RunExtendedPathVersion;
RunOccBinVersion;
RunDynareOBCVersion;
clear all; %#ok<CLALL>
load ExtendedPathResults.mat
load OccBinResults.mat
load DynareOBCResults.mat DOBCEndoSequence
figure(1); plot(EPEndoSequence'-DOBCEndoSequence');
figure(2); plot(OBEndoSequence'-DOBCEndoSequence');
