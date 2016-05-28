RunExtendedPathVersion;
RunOccBinVersion;
RunDynareOBCVersion;
clear all; %#ok<CLALL>
load ExtendedPathResults.mat
load DynareOBCResults.mat DOBCEndoSequence
figure(1); plot(EPEndoSequence'-DOBCEndoSequence');
load OccBinResults.mat OBEndoSequence
if ~isempty( OBEndoSequence )
    figure(2); plot(OBEndoSequence'-DOBCEndoSequence');
end
