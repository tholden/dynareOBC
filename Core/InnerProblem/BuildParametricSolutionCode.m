function BuildParametricSolutionCode( Tss )

%% Create configuration object of class 'coder.MexCodeConfig'.

cfg = coder.config('mex');
cfg.EnableMemcpy = false;
cfg.InitFltsAndDblsToZero = false;
cfg.MATLABSourceComments = true;
cfg.ConstantInputs = 'IgnoreValues';
cfg.GenerateReport = true;
cfg.ConstantFoldingTimeout = 2147483647;
cfg.EnableVariableSizing = false;
cfg.EnableDynamicMemoryAllocation = false;
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
ARGS{1} = cell(1,1);
ARGS{1}{1} = coder.typeof( zeros( 1, Tss ) ); %#ok<NASGU>

%% Invoke MATLAB Coder.
MFileText = fileread( 'dynareOBCTempSolution.m' );
MFileText = regexprep( MFileText, '^\s*for\s+([^=]+)=([^,;]+)(,|;|$)', 'for $1 = coder.unroll\( $2 \);', 'ignorecase', 'lineanchors', 'dotexceptnewline' );
MFile = fopen( 'dynareOBCTempSolution.m', 'w' );
fprintf( MFile, '%s', MFileText );

WarningState = warning( 'off', 'MATLAB:subscripting:noSubscriptsSpecified' );
codegen -config cfg dynareOBCTempSolution -args ARGS{1} -o dynareOBCTempSolution_mex
warning( WarningState );
