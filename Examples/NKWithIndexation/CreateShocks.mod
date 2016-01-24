@#define NumShockProcesses = length( ShockProcesses ) / 6
@#for ShockIndex in 1 : NumShockProcesses
	@#define IndexIntoShockProcesses = ShockIndex * 6 - 5
	@#define VariableName = ShockProcesses[IndexIntoShockProcesses]
	@#define Minimum = ShockProcesses[IndexIntoShockProcesses+1]
	@#define Maximum = ShockProcesses[IndexIntoShockProcesses+2]
	@#define SteadyState = ShockProcesses[IndexIntoShockProcesses+3]
	@#define Rho = ShockProcesses[IndexIntoShockProcesses+4]
	@#define Sigma = ShockProcesses[IndexIntoShockProcesses+5]
	// Add the shock process as an endogenous, so that everything will be defined for us
	@#define EndoVariables = EndoVariables + [ VariableName, Minimum, Maximum ]
	@#include "InternalClassifyDeclare.mod"
	@#define ShockName = "epsilon_" + VariableName
	@#define TransformedSteadyState = "(" + TransformationPrefix + SteadyState + TrnasformationSuffix + ")"
	// Add an equation for the shock process
	@#define ExtraModelEquations = ExtraModelEquations + [ FullVariableName + " = (1-(" + Rho + ")) * " + TransformedSteadyState + " + (" + Rho + ") * " + FullVariableName + "(-1)" + " + (" + Sigma + ") * " + ShockName + ";" ]
	// And one for its steady-state
	@#define ExtraSteadyStateEquations = ExtraSteadyStateEquations + [ VariableName + "_ = " + SteadyState + ";" ]
	// Declare our new shock
	varexo @{ShockName};
	// And set its variance.
	@#define ExtraShockBlockLines = ExtraShockBlockLines + [ "var " + ShockName + " = 1;" ]
@#endfor
