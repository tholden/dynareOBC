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

model;
    @#include "InsertNewModelEquations.mod"
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
    #M = exp(-sigma_m * epsilon_m);
    #R = exp( max( 0, log( ( PI_STEADY / beta_STEADY ) * ( ((PIRel/STEADY_STATE(PIRel))^phi_pi) * ((Y/STEADY_STATE(Y))^phi_y) ) * M ) ) );
    #AUX2 = varepsilon / (varepsilon - 1) * AUX1;
    #AUX2_LEAD = varepsilon / (varepsilon - 1) * AUX1_LEAD;
    #PI_LEAD = PIRel_LEAD * PI_STEADY;
    1 = R * beta_LEAD * ( C / C_LEAD ) / PI_LEAD;
    AUX1 = MC * (Y/C) + theta * beta_LEAD * PIRel_LEAD^(varepsilon) * AUX1_LEAD;
    AUX2 = PIRel_STAR * ((Y/C) + theta * beta_LEAD * ((PIRel_LEAD^(varepsilon-1))/PIRel_STAR_LEAD) * AUX2_LEAD);
    log( NU ) = log( theta * (PIRel^varepsilon) * NU_LAG + (1 - theta) * PIRel_STAR^(-varepsilon) );
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
end;

shocks;
    @#include "InsertNewShockBlockLines.mod"
    var epsilon_m = 1;
end;

steady;
check;

stoch_simul( order = 1, irf = 0, periods = 0 );
