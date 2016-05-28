RunExtendedPathVersion;
OccBinOK = true;
try
    RunOccBinVersion;
catch
    OccBinOK = false;
end
RunDynareOBCVersion;
clear all; %#ok<CLALL>
load ExtendedPathResults.mat
load DynareOBCResults.mat DOBCEndoSequence
figure(1); plot(EPEndoSequence'-DOBCEndoSequence');
if OccBinOK
    load OccBinResults.mat OBEndoSequence
    figure(2); plot(OBEndoSequence'-DOBCEndoSequence');
end
