function Build_pruning_abounds_stripped( M, oo, dynareOBC, VaryingDR )
% BUILD_PRUNING_ABOUNDS_STRIPPED   Generate MEX-function
%  pruning_abounds_stripped_mex from pruning_abounds_stripped.
% 
% Script generated from project 'pruning_abounds_stripped.prj' on 27-Aug-2015.
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
cfg.DynamicMemoryAllocation = 'AllVariableSizeArrays';
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

%% Define argument types for entry-point 'pruning_abounds_stripped'.
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
ARGS{1}{8}.bound = coder.typeof(dynareOBC.Constant);
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
codegen -config cfg pruning_abounds_stripped -args ARGS{1} -o dynareOBCTempPruningAbounds
