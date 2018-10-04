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

parameters u alpha;

alpha = 0.94; // 0.97;
u = 1 - PI_STEADY / beta_STEADY * alpha / 1.0001;
//beta_STEADY = beta_STEADY * alpha / ( 1 - u );
psi = psi * ( 1 - u ) ^ ( 1 + vartheta );

varexo epsilon_m;

var y pi r nu;

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
    #W = psi * L^vartheta * C / ( 1 - u ) ^ ( 1 + vartheta );
    #MC = W/A;
    #M = exp(-sigma_m * epsilon_m);
    #R = exp( max( log( PI_STEADY / beta_STEADY * alpha / ( 1 - u ) ) - log( 1.005 / 0.994 ), log( ( PI_STEADY / beta_STEADY * alpha / ( 1 - u ) ) * ( ((PI/STEADY_STATE(PI))^phi_pi) * ((Y/STEADY_STATE(Y))^phi_y) ) * M ) ) );
    #AUX2 = varepsilon / (varepsilon - 1) * AUX1;
    #AUX2_LEAD = varepsilon / (varepsilon - 1) * AUX1_LEAD;
    #m = alpha  / ( 1 - alpha ) * u / ( 1 - u ) * STEADY_STATE( C ) / ( 1 - u );
    // 1 = R * beta_LEAD * ( C / C_LEAD ) / PI_LEAD;
    ( 1 - u ) / C = R * beta_LEAD / PI_LEAD * ( ( 1 - u )^2 / C_LEAD + u / m );
    AUX1 = MC * (Y/C) + theta * beta_LEAD * PI_LEAD^(varepsilon) * AUX1_LEAD;
    AUX2 = PI_STAR * ((Y/C) + theta * beta_LEAD * ((PI_LEAD^(varepsilon-1))/PI_STAR_LEAD) * AUX2_LEAD);
    log( NU ) = log( theta * (PI^varepsilon) * NU_LAG + (1 - theta) * PI_STAR^(-varepsilon) );
    y = log( Y );
    pi = log( PI );
    r = log( R );
    nu = log( NU );
end;

steady_state_model;
    PI_ = PI_STEADY;
    PI_STAR_ = ( (1 - theta * (1 / PI_)^(1 - varepsilon) ) / (1 - theta) )^(1/(1 - varepsilon));
    NU_ = ( ( 1 - theta) / (1 - theta * PI_ ^varepsilon) ) * PI_STAR_ ^(-varepsilon);
    W_ = A_STEADY * PI_STAR_ * ((varepsilon - 1) / varepsilon) * ( (1 - theta * beta_STEADY * PI_ ^varepsilon)/(1 - theta * beta_STEADY * PI_ ^(varepsilon-1)));
    C_ = (W_ /(psi / ( 1 - u ) ^ ( 1 + vartheta ) * ((1/(1 - Sg_STEADY)) * NU_/ A_STEADY)^vartheta))^(1/(1 + vartheta));
    Y_ = (1 / (1 - Sg_STEADY)) * C_;
    G_ = Sg_STEADY * Y_;
    L_ = Y_ * NU_ / A_STEADY;
    MC_ = W_ / A_STEADY;
    R_ = PI_STEADY / beta_STEADY * alpha / ( 1 - u );
    AUX1_ = W_ / A_STEADY * (Y_ /C_)/(1 - theta * beta_STEADY * PI_ ^varepsilon);
    AUX2_ = PI_STAR_ * (Y_ /C_)/(1 - theta * beta_STEADY * PI_ ^(varepsilon-1));
    // @#include "NKTransSteadyState.mod"
    @#include "InsertNewSteadyStateEquations.mod"
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

stoch_simul( order = 1, irf = 40, periods = 0, irf_shocks = ( epsilon_beta ) ) y pi r nu;
