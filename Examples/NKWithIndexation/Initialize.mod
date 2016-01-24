// Define the empty array for convenience.
// Dynare's preprocessor does not support [ ] for an empty array
@#define EmptyArray = [ "" ] - [ "" ]
@#ifndef EndoVariables
	@#define EndoVariables = EmptyArray
@#endif
@#ifndef ExtraModelEquations
	@#define ExtraModelEquations = EmptyArray
@#endif
@#ifndef ExtraSteadyStateEquations
	@#define ExtraSteadyStateEquations = EmptyArray
@#endif
// The code below is for an extension to be introduced shortly.
@#ifndef ShockProcesses
	@#define ShockProcesses = EmptyArray
@#endif
@#ifndef ExtraShockBlockLines
	@#define ExtraShockBlockLines = EmptyArray
@#endif
