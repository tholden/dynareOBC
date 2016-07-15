% BUILD_ALTPTEST   Generate MEX-function AltPTest_mex from AltPTest.
% 
% Script generated from project 'AltPTest.prj' on 15-Jul-2016.
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
cfg.EnableAutoExtrinsicCalls = false;
cfg.InlineThreshold = 2147483647;
cfg.InlineThresholdMax = 2147483647;
cfg.InlineStackLimit = 2147483647;
cfg.StackUsageMax = 16777216;
cfg.IntegrityChecks = false;
cfg.ResponsivenessChecks = false;
cfg.ExtrinsicCalls = false;
cfg.EchoExpressions = false;
cfg.GlobalDataSyncMethod = 'NoSync';

%% Define argument types for entry-point 'AltPTest'.
ARGS = cell(1,1);
ARGS{1} = cell(2,1);
ARGS{1}{1} = coder.typeof(0,[Inf Inf],[1 1]);
ARGS{1}{2} = coder.typeof(false);

%% Invoke MATLAB Coder.
codegen -config cfg AltPTest -args ARGS{1}
