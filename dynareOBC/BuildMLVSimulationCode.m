function BuildMLVSimulationCode( M, dynareOBC )

%% Create configuration object of class 'coder.MexCodeConfig'.

cfg = coder.config('mex');
cfg.EnableMemcpy = false;
cfg.InitFltsAndDblsToZero = false;
cfg.MATLABSourceComments = true;
cfg.ConstantInputs = 'IgnoreValues';
cfg.GenerateReport = true;
cfg.ConstantFoldingTimeout = 2147483647;
if dynareOBC.Estimation
    cfg.EnableVariableSizing = true;
    cfg.DynamicMemoryAllocation = 'AllVariableSizeArrays';
else
    cfg.EnableVariableSizing = false;
    cfg.DynamicMemoryAllocation = 'Off';
end
cfg.SaturateOnIntegerOverflow = false;
cfg.EnableAutoExtrinsicCalls = false;
cfg.InlineThreshold = 2147483647;
cfg.InlineThresholdMax = 2147483647;
cfg.InlineStackLimit = 2147483647;
cfg.StackUsageMax = 2000000;
cfg.IntegrityChecks = false;
cfg.ResponsivenessChecks = false;
cfg.ExtrinsicCalls = false;
cfg.GlobalDataSyncMethod = 'NoSync';

%% Define argument types for entry-point 'dynareOBCTempGetMLVs'.
ARGS = cell(1,1);
ARGS{1} = cell(5,1);
if dynareOBC.Estimation
    ARGS{1}{1} = coder.typeof( 0, [ sum( dynareOBC.OriginalLeadLagIncidence(:) > 0 ), Inf ], [ 0 1 ] );
else
    ARGS{1}{1} = coder.typeof( zeros( sum( dynareOBC.OriginalLeadLagIncidence(:) > 0 ), 1 ) );
end
ARGS{1}{2} = coder.typeof( zeros( 1, M.exo_nbr ) );
if dynareOBC.Estimation
    ARGS{1}{3} = coder.typeof( M.params );
else
    ARGS{1}{3} = coder.Constant( M.params );
end
ARGS{1}{4} = coder.typeof( zeros( M.endo_nbr, 1 ) );
ARGS{1}{5} = coder.Constant( 1 ); %#ok<NASGU>

%% Invoke MATLAB Coder.
codegen -config cfg dynareOBCTempGetMLVs -args ARGS{1} -o dynareOBCTempGetMLVs
