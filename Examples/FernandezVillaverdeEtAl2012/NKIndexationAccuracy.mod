@#include "Initialize.mod"
@#define EndoVariables = EndoVariables + [ "PI", "0", "theta^(1/(1-varepsilon))" ]
@#define EndoVariables = EndoVariables + [ "L", "0", "Inf" ]
@#define EndoVariables = EndoVariables + [ "NU", "0", "Inf" ]
@#define EndoVariables = EndoVariables + [ "AUX1", "0", "Inf" ]
@#define ShockProcesses = ShockProcesses + [ "A", "0", "Inf", "A_STEADY", "rho_a", "sigma_a" ]
@#define ShockProcesses = ShockProcesses + [ "beta", "0", "Inf", "beta_STEADY", "rho_b", "sigma_b" ]
@#define ShockProcesses = ShockProcesses + [ "Sg", "0", "Inf", "Sg_STEADY", "rho_g", "sigma_g" ]
@#include "CreateShocks.mod"
@#include "ClassifyDeclare.mod"

@#include "NKIndexationParameters.mod"

varexo epsilon_m;

// Note that complete indexation is "hacked in" to the model without indexation by setting PI_STEADY=1 and then defining TRUE_PI = TRUE_PI_STEADY * PI.

model;
	@#include "InsertNewModelEquations.mod"
	#Y = (A/NU) * L;
	#Y_LEAD = (A_LEAD/NU_LEAD) * L_LEAD;
	#G = Sg*Y;
	#G_LEAD = Sg_LEAD*Y_LEAD;
	#PI_STAR = (( 1 - theta * (PI^(varepsilon-1)) ) / (1 - theta))^(1/(1-varepsilon));
	#PI_STAR_LEAD = (( 1 - theta * (PI_LEAD^(varepsilon-1)) ) / (1 - theta))^(1/(1-varepsilon));
	#C = Y - G;
	#C_LEAD = Y_LEAD - G_LEAD;
	#W = psi * L^vartheta*C;
	#MC = W/A;
	#M = exp(-sigma_m * epsilon_m);
	#R = exp( max( 0, log( TRUE_PI_STEADY * ( PI_STEADY / beta_STEADY ) * ( ((PI/STEADY_STATE(PI))^phi_pi) * ((Y/STEADY_STATE(Y))^phi_y) ) * M ) ) );
	#AUX2 = varepsilon / (varepsilon - 1) * AUX1;
	#AUX2_LEAD = varepsilon / (varepsilon - 1) * AUX1_LEAD;
	#lhs01 = 1;
	#rhs01 = R * beta_LEAD * ( C / C_LEAD ) / PI_LEAD / TRUE_PI_STEADY;
	#error01 = ( lhs01 - rhs01 ) / lhs01;
	#lhs02 = AUX1;
	#rhs02 = MC * (Y/C) + theta * beta_LEAD * PI_LEAD^(varepsilon) * AUX1_LEAD;
	#error02 = ( lhs02 - rhs02 ) / lhs02;
	#lhs03 = AUX2;
	#rhs03 = PI_STAR * ((Y/C) + theta * beta_LEAD * ((PI_LEAD^(varepsilon-1))/PI_STAR_LEAD) * AUX2_LEAD);;
	#error03 = ( lhs03 - rhs03 ) / lhs03;
	#lhs04 = ( NU );
	#rhs04 = ( theta * (PI^varepsilon) * NU_LAG + (1 - theta) * PI_STAR^(-varepsilon) );
	#error04 = ( lhs04 - rhs04 ) / lhs04;
	1 = R * beta_LEAD * ( C / C_LEAD ) / PI_LEAD / TRUE_PI_STEADY;
	AUX1 = MC * (Y/C) + theta * beta_LEAD * PI_LEAD^(varepsilon) * AUX1_LEAD;
	AUX2 = PI_STAR * ((Y/C) + theta * beta_LEAD * ((PI_LEAD^(varepsilon-1))/PI_STAR_LEAD) * AUX2_LEAD);
	log( NU ) = log( theta * (PI^varepsilon) * NU_LAG + (1 - theta) * PI_STAR^(-varepsilon) );
end;

steady_state_model;
	@#include "NKTransSteadyState.mod"
	@#include "InsertNewSteadyStateEquations.mod"
end;

shocks;
	@#include "InsertNewShockBlockLines.mod"
	var epsilon_m = 1;
end;

steady;
check;

stoch_simul( order = 3, irf = 0, periods = 1100 ) error01, error02, error03, error04;