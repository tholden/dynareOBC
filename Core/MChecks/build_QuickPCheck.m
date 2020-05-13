% BUILD_QUICKPCHECK   Generate MEX-function QuickPCheck_mex from QuickPCheck.
% 
% Script generated from project 'QuickPCheck.prj' on 16-Jul-2016.
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

%% Define argument types for entry-point 'QuickPCheck'.
ARGS = cell(1,1);
ARGS{1} = cell(1,1);
ARGS{1}{1} = coder.typeof(0,[Inf Inf],[1 1]);

%% Invoke MATLAB Coder.
WarningState = warning( 'off', 'MATLAB:subscripting:noSubscriptsSpecified' );
codegen -config cfg QuickPCheck -args ARGS{1}
warning( WarningState );
