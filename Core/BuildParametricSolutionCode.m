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
cfg.DynamicMemoryAllocation = 'Off';
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

%% Define argument types for entry-point 'CustomLanMeyerGohdePrunedSimulation'.
ARGS = cell(1,1);
ARGS{1} = cell(1,1);
ARGS{1}{1} = coder.typeof( zeros( 1, Tss ) ); %#ok<NASGU>

%% Invoke MATLAB Coder.
strTss = int2str( Tss );
MFileText = fileread( 'dynareOBCTempSolution.m' );
MFileText = regexprep( MFileText, '^\s*for\s+([^=]+)=([^,;]+)(,|;|$)', 'for $1 = coder.unroll\( $2 \);', 'ignorecase', 'lineanchors', 'dotexceptnewline' );
MFile = fopen( 'dynareOBCTempSolution.m', 'w' );
fprintf( MFile, '%s', MFileText );
codegen -config cfg dynareOBCTempSolution -args ARGS{1} -o dynareOBCTempSolution_mex
copyfile( [ 'dynareOBCTempSolution_mex.' mexext ], [ 'dynareOBCTempSolution_mex.' mexext ], 'f' );
