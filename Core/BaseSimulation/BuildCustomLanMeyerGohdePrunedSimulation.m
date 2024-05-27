function BuildCustomLanMeyerGohdePrunedSimulation( M, oo, dynareOBC, VaryingDR )
% BUILD_CustomLanMeyerGohdePrunedSimulation   Generate MEX-function
%  CustomLanMeyerGohdePrunedSimulation_mex from CustomLanMeyerGohdePrunedSimulation.
% 
% Script generated from project 'CustomLanMeyerGohdePrunedSimulation.prj' on 27-Aug-2015.
% 
% See also CODER, CODER.CONFIG, CODER.TYPEOF, CODEGEN.

%% Create configuration object of class 'coder.MexCodeConfig'.

cfg = coder.config('mex');
cfg.EnableMemcpy = false;
cfg.InitFltsAndDblsToZero = false;
cfg.MATLABSourceComments = true;
cfg.ConstantInputs = 'Remove';
cfg.GenerateReport = true;
cfg.ConstantFoldingTimeout = 2147483647;
cfg.EnableVariableSizing = true;
cfg.EnableDynamicMemoryAllocation = true;
cfg.SaturateOnIntegerOverflow = false;
cfg.EnableAutoExtrinsicCalls = false;
cfg.InlineBetweenUserFunctions = 'Always';
cfg.InlineBetweenMathWorksFunctions = 'Always';
cfg.InlineBetweenUserAndMathWorksFunctions = 'Always';
cfg.StackUsageMax = 2000000;
cfg.IntegrityChecks = false;
cfg.ResponsivenessChecks = false;
cfg.ExtrinsicCalls = false;
cfg.GlobalDataSyncMethod = 'NoSync';
cfg.SIMDAcceleration = 'Full';

%% Define argument types for entry-point 'CustomLanMeyerGohdePrunedSimulation'.
ARGS = cell(1,1);
ARGS{1} = cell(8,1);
ARGS{1}{1} = coder.Constant(int32(M.nstatic));
ARGS{1}{2} = coder.Constant(int32(M.nspred));
ARGS{1}{3} = coder.Constant(int32(M.endo_nbr));
if VaryingDR
    ARGS{1}{4} = coder.typeof(MakeFull(oo.dr));
else
    ARGS{1}{4} = coder.Constant(MakeFull(oo.dr));
end
ARGS{1}{5} = coder.typeof(0,[M.exo_nbr Inf],[0 1]);
ARGS{1}{6} = coder.typeof(int32(0));
ARGS{1}{7} = coder.Constant(int32(dynareOBC.Order));
ARGS{1}{8} = struct;
ARGS{1}{8}.bound_offset = coder.typeof(dynareOBC.Constant);
ARGS{1}{8}.first = coder.typeof(dynareOBC.Constant);
if dynareOBC.Order >= 3
     ARGS{1}{8}.first_sigma_2 = coder.typeof(dynareOBC.Constant);
end
if dynareOBC.Order >= 2
    ARGS{1}{8}.second = coder.typeof(dynareOBC.Constant);
    if dynareOBC.Order >= 3
         ARGS{1}{8}.third = coder.typeof(dynareOBC.Constant);
    end
end
ARGS{1}{8}.total = coder.typeof(dynareOBC.Constant);
ARGS{1}{8}.total_with_bounds = coder.typeof(dynareOBC.Constant); %#ok<NASGU>

%% Invoke MATLAB Coder.
WarningState = warning( 'off', 'MATLAB:subscripting:noSubscriptsSpecified' );
codegen -config cfg CustomLanMeyerGohdePrunedSimulation -args ARGS{1} -o dynareOBCTempCustomLanMeyerGohdePrunedSimulation
warning( WarningState );
