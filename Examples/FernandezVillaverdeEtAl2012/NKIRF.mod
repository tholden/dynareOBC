@#includepath "DynareTransformationEngine"
@#includepath "NKModIncludes"

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

var log_C log_PI log_R;

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
    #R = exp( max( 0, log( ( PI_STEADY / beta_STEADY ) * ( ((PI/STEADY_STATE(PI))^phi_pi) * ((Y/STEADY_STATE(Y))^phi_y) ) * M ) ) );
    #AUX2 = varepsilon / (varepsilon - 1) * AUX1;
    #AUX2_LEAD = varepsilon / (varepsilon - 1) * AUX1_LEAD;
    1 = R * beta_LEAD * ( C / C_LEAD ) / PI_LEAD;
    AUX1 = MC * (Y/C) + theta * beta_LEAD * PI_LEAD^(varepsilon) * AUX1_LEAD;
    AUX2 = PI_STAR * ((Y/C) + theta * beta_LEAD * ((PI_LEAD^(varepsilon-1))/PI_STAR_LEAD) * AUX2_LEAD);
    log( NU ) = log( theta * (PI^varepsilon) * NU_LAG + (1 - theta) * PI_STAR^(-varepsilon) );
    log_C = log( C );
    log_PI = log( PI );
    log_R = log( R );
end;

steady_state_model;
    @#include "NKTransSteadyState.mod"
    @#include "InsertNewSteadyStateEquations.mod"
    log_C = log( C_ );
    log_PI = log( PI_STEADY );
    log_R = log( R_ );
end;

shocks;
    @#include "InsertNewShockBlockLines.mod"
    var epsilon_m = 1;
end;

steady;
check;

stoch_simul( order = 1, irf = 100, periods = 0, irf_shocks = ( epsilon_beta ) ) log_C log_L log_beta log_NU log_PI log_R;
