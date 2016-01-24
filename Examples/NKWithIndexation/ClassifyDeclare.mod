@#ifndef MaximumLead
	@#define MaximumLead = 1
@#endif
@#ifndef MaximumLag
	@#define MaximumLag = 1
@#endif
@#if MaximumLead > 99
	@#error "At most 99 leads are supported."
@#endif
@#if MaximumLag > 99
	@#error "At most 99 lags are supported."
@#endif
@#define NumEndoVariables = length( EndoVariables ) / 3
// Define an array of numbers
// Useful as Dynare's preprocessor does not support converting integers to strings
@#define Numbers = [ "1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96","97","98","99" ]
@#for VariableIndex in 1 : NumEndoVariables
	@#define IndexIntoEndoVariables = VariableIndex * 3 - 2
	@#define VariableName = EndoVariables[IndexIntoEndoVariables]
	@#define Minimum = EndoVariables[IndexIntoEndoVariables+1]
	@#define Maximum = EndoVariables[IndexIntoEndoVariables+2]
	
	@#include "InternalClassifyDeclare.mod"
	
	// Declare our new variable
	var @{FullVariableName};
	// Now create new equations
	// First create an equation defining the original variable
	@#define ExtraModelEquations = ExtraModelEquations + [ "#" + VariableName + " = " + InverseTransformationPrefix + FullVariableName + InverseTransformationSuffix + ";" ]
	@#define ExtraSteadyStateEquations = ExtraSteadyStateEquations + [ FullVariableName + " = " + TransformationPrefix + VariableName + "_" + TrnasformationSuffix + ";" ]
	// Then equations to define its lags
	@#define LagString = ""
	@#for Lag in 1 : MaximumLag
		@#define LagString = LagString + "_LAG"
		@#define CurrentLag = Numbers[ Lag ]
		@#define ExtraModelEquations = ExtraModelEquations + [ "#" + VariableName + LagString + " = "  + InverseTransformationPrefix + FullVariableName + "(-" + CurrentLag + ")" + InverseTransformationSuffix + ";" ]
		@#define ExtraModelEquations = ExtraModelEquations + [ "#" + VariableName + "_LAG" + CurrentLag + " = " + VariableName + LagString + ";" ]
	@#endfor
	// Then equations to define its leads
	@#define LeadString = ""
	@#for Lead in 1 : MaximumLag
		@#define LeadString = LeadString + "_LEAD"
		@#define CurrentLead = Numbers[ Lead ]
		@#define ExtraModelEquations = ExtraModelEquations + [ "#" + VariableName + LeadString + " = " + InverseTransformationPrefix + FullVariableName + "(" + CurrentLead + ")" + InverseTransformationSuffix + ";" ]
		@#define ExtraModelEquations = ExtraModelEquations + [ "#" + VariableName + "_LEAD" + CurrentLead + " = " + VariableName + LeadString + ";" ]
	@#endfor
@#endfor
