dynareOBC GI2017NoZLB.mod ShockSequenceFile=ShockSequenceP.mat MLVSimulationMode=1

irf1P = irf1;
irf2P = irf2;
irf3P = irf3;
irf4P = irf4;

save irfP irf1P irf2P irf3P irf4P;

dynareOBC GI2017NoZLB.mod ShockSequenceFile=ShockSequenceN.mat MLVSimulationMode=1

irf1N = irf1;
irf2N = irf2;
irf3N = irf3;
irf4N = irf4;

save irfN irf1N irf2N irf3N irf4N;

GeneratePlots;
