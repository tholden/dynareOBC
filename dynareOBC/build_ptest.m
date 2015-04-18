% BUILD_PTEST   Generate MEX-function ptest_mex from ptest.
% 
% Script generated from project 'ptest.prj' on 18-Apr-2015.
% 
% See also CODER, CODER.CONFIG, CODER.TYPEOF, CODEGEN.

%% Create configuration object of class 'coder.MexCodeConfig'.
cfg = coder.config('mex');
cfg.EnableMemcpy = false;
cfg.InitFltsAndDblsToZero = false;
cfg.CustomSourceCode = '#define muDoubleScalarIsNaN( x ) 0';
cfg.MATLABSourceComments = true;
cfg.GenerateReport = true;
cfg.ConstantFoldingTimeout = 2147483647;
cfg.DynamicMemoryAllocation = 'AllVariableSizeArrays';
cfg.SaturateOnIntegerOverflow = false;
cfg.InlineThreshold = 2147483647;
cfg.InlineThresholdMax = 2147483647;
cfg.InlineStackLimit = 2147483647;
cfg.StackUsageMax = 16777216;
cfg.IntegrityChecks = false;
cfg.ResponsivenessChecks = false;
cfg.ExtrinsicCalls = false;
cfg.EchoExpressions = false;
cfg.GlobalDataSyncMethod = 'NoSync';

%% Define argument types for entry-point 'ptest'.
ARGS = cell(1,1);
ARGS{1} = cell(1,1);
ARGS{1}{1} = coder.typeof(0,[Inf Inf],[1 1]);

%% Invoke MATLAB Coder.
codegen -config cfg ptest -args ARGS{1}
