% BUILD_SPKRON   Generate MEX-function spkron_internal_mex_mex from
%  spkron_internal_mex.
% 
% Script generated from project 'spkron.prj' on 18-Apr-2015.
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
cfg.EnableDynamicMemoryAllocation = true;
cfg.SaturateOnIntegerOverflow = false;
cfg.EnableAutoExtrinsicCalls = false;
cfg.InlineBetweenUserFunctions = 'Always';
cfg.InlineBetweenMathWorksFunctions = 'Always';
cfg.InlineBetweenUserAndMathWorksFunctions = 'Always';
cfg.StackUsageMax = 16777216;
cfg.IntegrityChecks = false;
cfg.ResponsivenessChecks = false;
cfg.ExtrinsicCalls = false;
cfg.EchoExpressions = false;
cfg.GlobalDataSyncMethod = 'NoSync';
cfg.SIMDAcceleration = 'Full';

%% Define argument types for entry-point 'spkron_internal_mex'.
ARGS = cell(1,1);
ARGS{1} = cell(4,1);
ARGS{1}{1} = coder.typeof(int32(0));
ARGS{1}{2} = coder.typeof(0,[Inf  3],[1 0]);
ARGS{1}{3} = coder.typeof(int32(0));
ARGS{1}{4} = coder.typeof(0,[Inf  3],[1 0]);

%% Invoke MATLAB Coder.
WarningState = warning( 'off', 'MATLAB:subscripting:noSubscriptsSpecified' );
codegen -config cfg spkron_internal_mex -args ARGS{1}
warning( WarningState );
