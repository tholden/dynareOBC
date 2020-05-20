@#includepath "DynareTransformationEngine"
@#includepath "NKModIncludes"

@#include "Initialize.mod"
@#define EndoVariables = EndoVariables + [ "PI", "0", "theta^(1/(1-varepsilon))" ]
@#define EndoVariables = EndoVariables + [ "EPI", "0", "theta^(1/(1-varepsilon))" ]
@#define EndoVariables = EndoVariables + [ "L", "0", "Inf" ]
@#define EndoVariables = EndoVariables + [ "NU", "0", "Inf" ]
@#define EndoVariables = EndoVariables + [ "AUX1", "0", "Inf" ]
@#define ShockProcesses = ShockProcesses + [ "A", "0", "Inf", "A_STEADY", "rho_a", "sigma_a" ]
@#define ShockProcesses = ShockProcesses + [ "beta", "0", "Inf", "beta_STEADY", "rho_b", "sigma_b" ]
@#define ShockProcesses = ShockProcesses + [ "Sg", "0", "Inf", "Sg_STEADY", "rho_g", "sigma_g" ]
@#include "CreateShocks.mod"
@#include "ClassifyDeclare.mod"

@#include "NKParameters.mod"

varexo epsilon_m, sunspot;

parameters ZeroParam;

ZeroParam = 0;

model;

    @#include "InsertNewModelEquations.mod"

    #PIs = PI_STEADY;
    #PI_STARs = ( (1 - theta * (1 / PIs)^(1 - varepsilon) ) / (1 - theta) )^(1/(1 - varepsilon));
    #NUs = ( ( 1 - theta) / (1 - theta * PIs ^varepsilon) ) * PI_STARs ^(-varepsilon);
    #Ws = A_STEADY * PI_STARs * ((varepsilon - 1) / varepsilon) * ( (1 - theta * beta_STEADY * PIs ^varepsilon)/(1 - theta * beta_STEADY * PIs ^(varepsilon-1)));
    #Cs = (Ws /(psi * ((1/(1 - Sg_STEADY)) * NUs/ A_STEADY)^vartheta))^(1/(1 + vartheta));
    #Ys = (1 / (1 - Sg_STEADY)) * Cs;

    #Y_LAG = (A_LAG/NU_LAG) * L_LAG;
    #Y = (A/NU) * L;
    #Y_LEAD = (A_LEAD/NU_LEAD) * L_LEAD;
    #G = Sg*Y;
    #G_LEAD = Sg_LEAD*Y_LEAD;
    #PI_STAR = (( 1 - theta * (PI^(varepsilon-1)) ) / (1 - theta))^(1/(1-varepsilon));
    #PI_STAR_LEAD = (( 1 - theta * (EPI^(varepsilon-1)) ) / (1 - theta))^(1/(1-varepsilon));
    #C = Y - G;
    #C_LEAD = Y_LEAD - G_LEAD;
    #W = psi * L^vartheta*C;
    #MC = W/A;
    #M = exp(-sigma_m * epsilon_m);
    #R = exp( max( 0, log( ( PI_STEADY / beta_STEADY ) * ( ((PI/PIs)^phi_pi) * ((Y/Y_LAG)^phi_y) ) * M ) ) ); // Make the Taylor rule a function of Y_LAG to make existence more likely about the second steady state.
    #AUX2 = varepsilon / (varepsilon - 1) * AUX1;
    #AUX2_LEAD = varepsilon / (varepsilon - 1) * AUX1_LEAD;
    1 = R * beta_LEAD * ( C / C_LEAD ) / EPI;
    AUX1 = MC * (Y/C) + theta * beta_LEAD * EPI^(varepsilon) * AUX1_LEAD;
    AUX2 = PI_STAR * ((Y/C) + theta * beta_LEAD * ((EPI^(varepsilon-1))/PI_STAR_LEAD) * AUX2_LEAD);
    log( NU ) = log( theta * (PI^varepsilon) * NU_LAG + (1 - theta) * PI_STAR^(-varepsilon) );

    logitT_EPI = logitT_PI(+1) + ZeroParam * sunspot;
    
end;

steady_state_model;
    @#include "NKTransSteadyState.mod"
    EPI_ = PI_;
    @#include "InsertNewSteadyStateEquations.mod"
end;

shocks;
    @#include "InsertNewShockBlockLines.mod"
    var epsilon_m = 1;
    var sunspot = 1;
end;

steady;
check;

stoch_simul( order = 1, irf = 0, periods = 10000 ) Y L PI R;
