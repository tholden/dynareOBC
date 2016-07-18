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

@#include "NKParameters.mod"

varexo epsilon_m;

var y pi r nu;

@#define MaxLag = 29
@#for lag in 0:MaxLag
    var L@{lag}_epsilon_m;
@#endfor

model;
	@#include "InsertNewModelEquations.mod"
    L0_epsilon_m = epsilon_m;
    @#for lag in 1:MaxLag
        L@{lag}_epsilon_m = L@{lag-1}_epsilon_m(-1);
    @#endfor
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
	#M = exp(sigma_m * L29_epsilon_m);
	#R = exp( ( log( ( PI_STEADY / beta_STEADY ) * ( ((PI/STEADY_STATE(PI))^phi_pi) * ((Y/STEADY_STATE(Y))^phi_y) ) * M ) ) );
	#AUX2 = varepsilon / (varepsilon - 1) * AUX1;
	#AUX2_LEAD = varepsilon / (varepsilon - 1) * AUX1_LEAD;
	1 = R * beta_LEAD * ( C / C_LEAD ) / PI_LEAD;
	AUX1 = MC * (Y/C) + theta * beta_LEAD * PI_LEAD^(varepsilon) * AUX1_LEAD;
	AUX2 = PI_STAR * ((Y/C) + theta * beta_LEAD * ((PI_LEAD^(varepsilon-1))/PI_STAR_LEAD) * AUX2_LEAD);
	log( NU ) = log( theta * (PI^varepsilon) * NU_LAG + (1 - theta) * PI_STAR^(-varepsilon) );
    y = log( Y );
    pi = log( PI );
    r = log( R );
    nu = log( NU );
end;

steady_state_model;
	@#include "NKTransSteadyState.mod"
	@#include "InsertNewSteadyStateEquations.mod"
    @#for lag in 0:MaxLag
        L@{lag}_epsilon_m = 0;
    @#endfor
    y = log( Y_ );
    pi = log( PI_STEADY );
    r = log( R_ );
    nu = log( NU_ );
end;

shocks;
	@#include "InsertNewShockBlockLines.mod"
	var epsilon_m = 1;
end;

steady;
check;

options_.impulse_responses.plot_threshold = -1;

stoch_simul( order = 1, irf = 60, periods = 0, irf_shocks = ( epsilon_m ) ) y pi r nu;
