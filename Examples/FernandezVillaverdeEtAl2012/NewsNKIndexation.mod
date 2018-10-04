@#includepath "DynareTransformationEngine"
@#includepath "NKModIncludes"

@#include "Initialize.mod"
@#define EndoVariables = EndoVariables + [ "PIRel", "0", "theta^(1/(1-varepsilon))" ]
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
	#PIRel_STAR = (( 1 - theta * (PIRel^(varepsilon-1)) ) / (1 - theta))^(1/(1-varepsilon));
	#PIRel_STAR_LEAD = (( 1 - theta * (PIRel_LEAD^(varepsilon-1)) ) / (1 - theta))^(1/(1-varepsilon));
	#C = Y - G;
	#C_LEAD = Y_LEAD - G_LEAD;
	#W = psi * L^vartheta*C;
	#MC = W/A;
	#M = exp(sigma_m * L29_epsilon_m);
	#R = exp( ( log( ( PI_STEADY / beta_STEADY ) * ( ((PIRel/STEADY_STATE(PIRel))^phi_pi) * ((Y/STEADY_STATE(Y))^phi_y) ) * M ) ) );
	#AUX2 = varepsilon / (varepsilon - 1) * AUX1;
	#AUX2_LEAD = varepsilon / (varepsilon - 1) * AUX1_LEAD;
    #PI = PIRel * PI_STEADY;
    #PI_LEAD = PIRel_LEAD * PI_STEADY;
	1 = R * beta_LEAD * ( C / C_LEAD ) / PI_LEAD;
	AUX1 = MC * (Y/C) + theta * beta_LEAD * PIRel_LEAD^(varepsilon) * AUX1_LEAD;
	AUX2 = PIRel_STAR * ((Y/C) + theta * beta_LEAD * ((PIRel_LEAD^(varepsilon-1))/PIRel_STAR_LEAD) * AUX2_LEAD);
	log( NU ) = log( theta * (PIRel^varepsilon) * NU_LAG + (1 - theta) * PIRel_STAR^(-varepsilon) );
    y = log( Y );
    pi = log( PI );
    r = log( R );
    nu = log( NU );
end;

steady_state_model;
    PIRel_ = 1;
    PI_STAR_ = ( (1 - theta * (1 / PIRel_)^(1 - varepsilon) ) / (1 - theta) )^(1/(1 - varepsilon));
    NU_ = ( ( 1 - theta) / (1 - theta * PIRel_ ^varepsilon) ) * PI_STAR_ ^(-varepsilon);
    W_ = A_STEADY * PI_STAR_ * ((varepsilon - 1) / varepsilon) * ( (1 - theta * beta_STEADY * PIRel_ ^varepsilon)/(1 - theta * beta_STEADY * PIRel_ ^(varepsilon-1)));
    C_ = (W_ /(psi * ((1/(1 - Sg_STEADY)) * NU_/ A_STEADY)^vartheta))^(1/(1 + vartheta));
    Y_ = (1 / (1 - Sg_STEADY)) * C_;
    G_ = Sg_STEADY * Y_;
    L_ = Y_ * NU_ / A_STEADY;
    MC_ = W_ / A_STEADY;
    R_ = PI_STEADY / beta_STEADY;
    AUX1_ = W_ / A_STEADY * (Y_ /C_)/(1 - theta * beta_STEADY * PIRel_ ^varepsilon);
    AUX2_ = PI_STAR_ * (Y_ /C_)/(1 - theta * beta_STEADY * PIRel_ ^(varepsilon-1));
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
