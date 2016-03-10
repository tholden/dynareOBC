% solve_one_constraint [zdatalinear zdatapiecewise zdatass oo base M base] = solve one constraint(modnam, modnamstar, constraint, constraint relax, shockssequence, irfshock, nperiods, maxiter, init);
% 
% Inputs: 
% modnam: name of .mod file for the reference regime (excludes the .mod extension).
% modnamstar: name of .mod file for the alternative regime (excludes the .mod exten- sion).
% constraint: the constraint (see notes 1 and 2 below). When the condition in constraint evaluates to true, the solution switches from the reference to the alternative regime.
% constraint relax: when the condition in constraint relax evaluates to true, the solution returns to the reference regime.
% shockssequence: a sequence of unforeseen shocks under which one wants to solve the model (size T×nshocks).
% irfshock: label for innovation for IRFs, from Dynare .mod file (one or more of the ?varexo?).
% nperiods: simulation horizon (can be longer than the sequence of shocks defined in shockssequence; must be long enough to ensure convergence back to the reference model at the end of the simulation horizon and may need to be varied depending on the sequence of shocks).
% maxiter: maximum number of iterations allowed for the solution algorithm (20 if not specified).
% init:	the initial position for the vector of state variables, in deviation from steady state (if not specified, the default is steady state). The ordering follows the definition order in the .mod files.
%
% Outputs:
% zdatalinear: an array containing paths for all endogenous variables ignoring the occasionally binding constraint (the linear solution), in deviation from steady state. Each column is a variable, the order is the definition order in the .mod files.
% zdatapiecewise: an array containing paths for all endogenous variables satisfying the occasionally binding constraint (the occbin/piecewise solution), in deviation from steady state. Each column is a variable, the order is the definition order in the .mod files.
% zdatass: theinitialpositionforthevectorofstatevariables,indeviationfromsteady state (if not specified, the default is a vectors of zero implying that the initial conditions coincide with the steady state). The ordering follows the definition order in the .mod files.
% oobase,Mbase: structures produced by Dynare for the reference model ? see Dynare User Guide.

load ExtendedPathResults.mat;
addpath( [ fileparts( which( 'dynare' ) ) '\occbin' ] );
[ ~, OBEndoSequence ] = solve_one_constraint( 'OccBinVersionSteady', 'OccBinVersionBound', 'd<=0', 'd>0', ShockSequence', '', length( ShockSequence + 2000 ), 100 );
OBEndoSequence = OBEndoSequence';
close all force;
delete OccBinVersion*.mat *.log OccBinVersion*.m OccBinVersion*_*.*
rmdir OccBinVersionSteady s
rmdir OccBinVersionBound s
save OccBinResults.mat OBEndoSequence
