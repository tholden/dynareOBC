%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The Model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) 2013 Benjamin K. Johannsen, Lawrence J. Christiano
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or (at
% your option) any later version.
% 
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see http://www.gnu.org/licenses/.

model;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Auxiliary expressions.  These simplify the equations without adding
% additional variables.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#Re = RRe - 1;
#LAG_Re = RRe(-1) - 1;

#Rk = RRk - 1;
#LEAD_Rk = RRk(+1) - 1;
#LAG_Rk = RRk(-1) - 1;

  # pitilde    = (pitarget^iota_p * pi(-1)^(1-iota_p) * pibar_p^(1-iota_p-(1-iota_p)));
  # Kp         = (Fp * ((1 - xip_p * (pitilde / pi)^(1/(1-lambdaf))) / (1 - xip_p))^(1-lambdaf));
  # rk_ss      = (steady_state(rk));
  # a          = (rk_ss * (exp(sigmaa_p * (u - 1)) - 1) / sigmaa_p);
  @# if cee == 0  
  # F          = (normcdf(((log(omegabar) + sigma(-1)^2 / 2) / sigma(-1))));
  # G          = (normcdf((log(omegabar) + sigma(-1)^2 / 2) / sigma(-1) - sigma(-1)));
  # H          = (normcdf((log(omegabar) + sigma(-1)^2 / 2) / sigma(-1) - 2 * sigma(-1)));              
  # d          = (((G + omegabar * (1 - F)) - ((1 - mu_p) * G + omegabar * (1 - F))) * (1 + Rk) * q(-1) * kbar(-1) / (muzstar * pi));
  @# endif
  # pitildep1  = (pitarget(+1)^iota_p * pi^(1-iota_p) * pibar_p^(1-iota_p-(1-iota_p)));
  # yz         = (pstar^(lambdaf/(lambdaf-1)) * (epsil * (u * kbar(-1) / (muzstar * upsil_p))^alpha_p 
                 * (h * wstar^(lambdaw_p/(lambdaw_p-1)))^(1-alpha_p) - phi));
  # Kpp1       = (Fp(+1) * ((1 - xip_p * (pitildep1 / pi(+1))^(1/(1-lambdaf(+1)))) / (1 - xip_p))^(1-lambdaf(+1)));
  # pitildewp1 = (pitarget(+1)^iotaw_p * pi^(1-iotaw_p) * pibar_p^(1-iotaw_p-(1-iotaw_p)));
  # piwp1      = (pi(+1) * muzstar(+1) * wtilde(+1) / wtilde);
  # piw        = (pi * muzstar * wtilde / wtilde(-1));
  # pitildew   = (pitarget^iotaw_p * pi(-1)^(1-iotaw_p) * pibar_p^(1-iotaw_p-(1-iotaw_p)));
  # Kwp1       = (((1 - xiw_p * (pitildewp1 / piwp1 * muzstar_p^(1-iotamu_p) * muzstar(+1)^iotamu_p)^(1/(1-lambdaw_p))) 
                 / (1-xiw_p))^(1-lambdaw_p*(1+sigmaL_p)) * wtilde(+1) * Fw(+1) / psiL_p);
  # Kw         = (((1 - xiw_p * (pitildew / piw * muzstar_p^(1-iotamu_p) * muzstar^iotamu_p)^(1/(1-lambdaw_p))) 
                 / (1 - xiw_p))^(1-lambdaw_p*(1+sigmaL_p)) * wtilde * Fw / psiL_p);
  # S          = (exp(sqrt(Sdoupr_p / 2)*(zetai * muzstar * upsil_p * i / i(-1) - muzstar_p * upsil_p))
                 + exp(-sqrt(Sdoupr_p / 2) * (zetai * muzstar * upsil_p * i/i(-1) - muzstar_p * upsil_p)) - 2);
  # Spr        = (sqrt(Sdoupr_p / 2) * (exp(sqrt(Sdoupr_p / 2) * (zetai * muzstar * upsil_p * i / i(-1) - muzstar_p * upsil_p)) 
                 - exp(-sqrt(Sdoupr_p / 2) * (zetai * muzstar * upsil_p * i / i(-1) - muzstar_p * upsil_p))));
  # Sprp1      = (sqrt(Sdoupr_p / 2) * (exp(sqrt(Sdoupr_p / 2) * (zetai(+1) * muzstar(+1) * upsil_p * i(+1) / i - muzstar_p * upsil_p)) 
                 - exp(-sqrt(Sdoupr_p / 2) * (zetai(+1) * muzstar(+1) * upsil_p * i(+1) / i - muzstar_p * upsil_p))));
  @# if cee == 0
  # Fp1        = (normcdf((log(omegabar(+1)) + sigma^2 / 2) / sigma));
  # Gp1        = (normcdf((log(omegabar(+1)) + sigma^2 / 2) / sigma - sigma));
  # G_ss       = (normcdf((log(steady_state(omegabar)) + steady_state(sigma)^2 / 2) / steady_state(sigma) - steady_state(sigma), 0, 1));
  @# endif

  # Rk_ss      = (steady_state(Rk));
  # kbar_ss    = (steady_state(kbar));
  @# if cee == 0
  # n_ss       = (steady_state(n));
  # sigma_ss   = (steady_state(sigma));
  @# endif 
  # h_ss       = (steady_state(h));
  # g_ss       = (etag_p * (steady_state(c) + steady_state(i)) / (1 - etag_p));
  @# if cee == 0
  # Gammap1    = (omegabar(+1) * (1 - Fp1) + Gp1);
  # Gammaprp1  = (1 - Fp1);
  # Gprp1      = (omegabar(+1) * normpdf((log(omegabar(+1)) + sigma^2 / 2) / sigma) / omegabar(+1) / sigma);
  @# endif


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Equations characterizing equilibrium.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Eqn 1: Law of motion for \latex{p^*}
    pstar = ((1 - xip_p) * (Kp / Fp)^(lambdaf/(1-lambdaf)) 
            + xip_p * ((pitilde / pi) * pstar(-1))^(lambdaf/(1-lambdaf)))^((1-lambdaf)/lambdaf);
  
  % Eqn 2: Law of motion for \latex{F_p}.
    Fp = zetac * lambdaz * yz + (pitildep1 / pi(+1))^(1/(1-lambdaf(+1))) * beta_p * xip_p * Fp(+1);
  
  % Eqn 3: Law of motion for \latex{K_p}
  % This error is ignored.
  %  Kp = zetac * lambdaf * lambdaz * pstar^(lambdaf/(lambdaf-1)) * yz * s 
  %       + beta_p * xip_p * (pitildep1 / pi(+1))^(lambdaf(+1)/(1-lambdaf(+1))) * Kpp1;
    Kp = zetac * lambdaf * lambdaz * yz * s 
         + beta_p * xip_p * (pitildep1 / pi(+1))^(lambdaf(+1)/(1-lambdaf(+1))) * Kpp1;
  
  % Eqn 4: Relationship between \latex{K_p} and \latex{F_p}.
  % This equation is contained in the definitions of Kp and Kpp1 in the
  % auxiliary equations.
  
  % Eqn 5: Law of motion for \latex{F_w}.
    Fw = zetac * lambdaz * wstar^(lambdaw_p/(lambdaw_p-1)) * h * (1 - taul_p) / lambdaw_p 
         + beta_p * xiw_p * muzstar_p^((1-iotamu_p)/(1-lambdaw_p)) * (muzstar(+1)^(iotamu_p/(1-lambdaw_p)-1))
         * pitildewp1^(1/(1-lambdaw_p)) / pi(+1) * (1 / piwp1)^(lambdaw_p/(1-lambdaw_p))  *  Fw(+1);
  
  % Eqn 6: Law of motion for \latex{K_w}.
    Kw = zetac * (wstar^(lambdaw_p/(lambdaw_p-1)) * h)^(1+sigmaL_p) * zeta_p + beta_p * xiw_p
         * (pitildewp1 / piwp1 * muzstar_p^(1-iotamu_p) * muzstar(+1)^iotamu_p)^(lambdaw_p*(1+sigmaL_p)/(1-lambdaw_p)) * Kwp1;
  
  % Eqn 7: Relationship between \latex{F_w} and \latex{K_w}.
  % This equation is contained in the definitions of Kw and Kwp1 in the
  % auxiliary equations.
  
  % Eqn 8: Law of motion of \latex{w^*}
    wstar = ((1 - xiw_p) * ( ((1 - xiw_p * (pitildew / piw * muzstar_p^(1-iotamu_p) * muzstar^iotamu_p)^(1/(1-lambdaw_p))) 
            / (1 - xiw_p))^lambdaw_p ) + xiw_p * (pitildew / piw * muzstar_p^(1-iotamu_p) * muzstar^iotamu_p 
            * wstar(-1))^(lambdaw_p/(1-lambdaw_p)))^(1/(lambdaw_p/(1-lambdaw_p)));
  
  % Eqn 9: Efficiency condition for setting captial utilization
    rk = tauo_p * rk_ss * exp(sigmaa_p * (u - 1));
  
  % Eqn 10: Rental rate on capital 
    rk = alpha_p * epsil * ((upsil_p * muzstar * h * wstar^(lambdaw_p/(lambdaw_p-1)) /(u * kbar(-1)))^(1 - alpha_p)) * s;
  
  % Eqn 11: Marginal Cost 
    s = (rk / alpha_p)^alpha_p * (wtilde / (1 - alpha_p))^(1-alpha_p) / epsil;
  

  % Eqn 12: Resource constraint
    @# if cee == 0
    yz = g + c + i / muup + tauo_p * a * kbar(-1) / (muzstar * upsil_p) + d + bigtheta_p * (1 - gamma) * (n - we_p) / gamma;
    @# else
    yz = g + c + i / muup + tauo_p * a * kbar(-1) / (muzstar * upsil_p) ;
    @# endif  

  % Eqn 13: Law of motion for capital
    kbar = (1 - delta_p) * kbar(-1) / (muzstar * upsil_p) + (1 - S) * i;
  
  % Eqn 14: Household FOC w.r.t. risk-free bonds
    0 = beta_p * zetac(+1) * lambdaz(+1) / (muzstar(+1) * pi(+1)) * (1 + (1 - taud_p) * Re) - zetac * lambdaz;
  
  % Eqn 15: Household FOC w.r.t. consumption
    (1 + tauc_p) * zetac * lambdaz = muzstar * zetac / (c * muzstar - b_p * c(-1)) 
                                     - b_p * beta_p * zetac(+1) / (c(+1) * muzstar(+1) - b_p * c);
  
  % Eqn 16: FOC for capital
    @# if cee == 0
    %0 = (1 - Gp1 - omegabar(+1) * (1 - Fp1)) * (1 + LEAD_Rk) / (1 + Re) + (1 - Fp1) / (1 - Fp1 - mu_p * omegabar(+1) 
    %    * normpdf((log(omegabar(+1)) + sigma^2 / 2) / sigma) / omegabar(+1) / sigma) * ((1 + LEAD_Rk) / (1 + Re) * ((1 - mu_p) * Gp1 
    %    + omegabar(+1) * (1 - Fp1)) - 1);

    0 = (1 - Gammap1) * (1 + LEAD_Rk) / (1 + Re) + Gammaprp1 / (Gammaprp1 - mu_p * Gprp1) * ((1 + LEAD_Rk) / (1 + Re) * (Gammap1 - mu_p * Gp1) - 1);

    @# else
    0 = beta_p * zetac(+1) * lambdaz(+1) / (muzstar(+1) * pi(+1)) * (1 + LEAD_Rk) - zetac * lambdaz;
    @# endif
  
  % Eqn 17: Definition of return of entrepreneurs, Rk
    1 + Rk = ((1 - tauk_p) * (u * rk - tauo_p * a) + (1 - delta_p) * q) * pi / (upsil_p * q(-1)) + tauk_p * delta_p;
  
  % Eqn 18: Household FOC w.r.t. investment
    0 = - zetac * lambdaz / muup + lambdaz * zetac * q * (-Spr * zetai * i * muzstar * upsil_p / i(-1) + 1 - S)
        + beta_p * zetac(+1) * lambdaz(+1) * q(+1) * Sprp1 * (zetai(+1) * i(+1) * muzstar(+1) * upsil_p / i)^2 / (muzstar(+1) * upsil_p);
  
  % Eqn 19: Definition of yz.  
  % This equation is represented in the definition of yz in the definition
  % of the auxiliary equations.
  
  @# if cee == 1
  % Eqn 20: Monetary Policy Rule

        % log( 1 + Re ) = ( 1 - rhotil_p ) * log( 1 + Re_p ) + rhotil_p * log( 1 + LAG_Re ) + ( 1 - rhotil_p ) / ( 1 + Re_p ) * (aptil_p * pi_p * log(pi(+1) / pitarget) + (1 / 4) * adytil_p * muzstar_p * log(gdp_obs));

  % monetary policy rule with short term interest rate:

        log( 1 + Re ) = max( 0, ( 1 - rhotil_p ) * log( 1 + Re_p ) + rhotil_p * log( 1 + LAG_Re ) +
        ( 1 / ( 1 + Re_p ) ) * ( (1 - rhotil_p) * ( pi_p * log(pitarget / pi_p) 
        + aptil_p * pi_p * (log(pi(+1)) - log(pitarget)) 
        + (1 / 4) * adytil_p * muzstar_p * ((c_p * log(c / c(-1)) 
                             + i_p * log(i / i(-1)) - i_p * log(muup / muup(-1)) + g_p * log(g / g(-1)) ) / ( (c_p+i_p)/(1-etag_p) ) 
                             + log(muzstar / muzstar_p))
        + adptil_p * log(pi / pi(-1)) 
        - (1 / 4) * aytil_p * (c_p * log(c / c_p) + i_p * log(i / i_p) 
                             - i_p * log(muup) + g_p * log(g / g_p)) / ((c_p+i_p)/(1-etag_p)) )
        - (1 - @{stopshock}) * (1 / 400) * e_xp ) );

  @#else
    % monetary policy rule with short term interest rate:

        log( 1 + Re ) = max( 0, ( 1 - rhotil_p ) * log( 1 + Re_p ) + rhotil_p * log( 1 + LAG_Re ) +
        ( 1 / ( 1 + Re_p ) ) * ( (1 - rhotil_p) * ( pi_p * log(pitarget / pi_p) 
        + aptil_p * pi_p * (log(pi(+1)) - log(pitarget)) 
        + (1 / 4) * adytil_p * muzstar_p * ((c_p * log(c / c(-1)) 
                             + i_p * log(i / i(-1)) - i_p * log(muup / muup(-1)) + g_p * log(g / g(-1)) ) / ( (c_p+i_p)/(1-etag_p) ) 
                             + log(muzstar / muzstar_p))
        + actil_p * muzstar_p * (log(q * kbar - n) 
                             - log(q(-1)*kbar(-1)-n(-1)) + log(muzstar / muzstar_p))
        + adptil_p * log(pi / pi(-1)) 
        - (1 / 4) * aytil_p * (c_p * log(c / c_p) + i_p * log(i / i_p) 
                             - i_p * log(muup) + g_p * log(g / g_p)) / ((c_p+i_p)/(1-etag_p)) )
        - (1 - @{stopshock}) * (1 / 400) * e_xp
    @# if sigma_in_taylor_rule
        - Re_p * 1 * (sigma - steady_state(sigma)) ) );
    @# else
        ) );
    @# endif
  @#endif
  % Eqn 21: GDP
  % This is not used.  It is only used in the manuscript in the monetary
  % policy rule.
  %  # y = g + c + i / muup;
  
    @# if cee == 0
  % Eqn 22: Zero profit condition
    q(-1) * kbar(-1) * (1 + Rk) * ((1 - mu_p) * G + omegabar * (1 - F)) / (n(-1) * (1 + LAG_Re)) - q(-1) * kbar(-1) / n(-1) + 1;
  
  % Eqn 23: Law of motion of net worth
    n = gamma / (pi * muzstar) * (Rk - LAG_Re-((G + omegabar * (1 - F)) - ((1 - mu_p) * G + omegabar * (1 - F))) * (1 + Rk)) 
        * kbar(-1) * q(-1) + we_p + gamma * (1 + LAG_Re) * n(-1) / (pi * muzstar);
   
    volEquity = (1 + Rk) * q(-1) * kbar(-1) / n(-1) * sqrt( (exp(sigma(-1)^2)/(1-F)*(1-H) - ((1-G)/(1-F))^2) );

    @#for varname in [ "term", "pi", "muzstar", "zetac", "lambdaz" ]
        LEAD_1_@{varname} = @{varname}(+1);
        @#for index in 2 : 40
            LEAD_@{index}_@{varname} = LEAD_@{index-1}_@{varname}(+1);
        @#endfor
    @#endfor

  % Long rate
    zetac * lambdaz = ((1 + RL) * beta_p)^40 * LEAD_40_zetac * LEAD_40_lambdaz
    @#for index in 1 : 40
      * (LEAD_@{index}_term / (LEAD_@{index}_pi * LEAD_@{index}_muzstar))
    @#endfor
    ;
    
  % Real risk free 10 year rate
    zetac * lambdaz  = (rL * beta_p)^40 * LEAD_40_zetac * LEAD_40_lambdaz 
    @#for index in 1 : 40
      /  LEAD_@{index}_muzstar
    @#endfor
    ;
   @# endif


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Observation equations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

@#ifdef dynareOBC
    networth_obs    = 1;
    inflation_obs   = 1;
    hours_obs       = 1;
    credit_obs      = 1;
    gdp_obs         = 1;
    wage_obs        = 1;
    investment_obs  = 1;
    consumption_obs = 1;
    premium_obs     = 1;
    Spread1_obs     = 1;
    Re_obs          = 1;
    pinvest_obs     = 1;
    RealRe_obs      = 1;
@#else
  consumption_obs = c / c(-1) * muzstar / muzstar_p;
  @#if cee == 0
  credit_obs      = (q * kbar - n) / (q(-1) * kbar(-1) - n(-1)) * muzstar / muzstar_p;
  @#endif
  gdp_obs         = (c + i / muup + g) / (c(-1) + i(-1) / muup(-1) + g(-1)) * muzstar / muzstar_p;
  hours_obs       = h / h_ss;
  inflation_obs   =  pi / pi_p;
  investment_obs  = i / i(-1) * muzstar / muzstar_p;
  @# if cee == 0
  networth_obs    = n / n(-1) * muzstar / muzstar_p;
  premium_obs     = exp((((G + omegabar * (1 - F)) - ((1 - mu_p) * G + omegabar * (1 - F))) * (1 + Rk) * q(-1) * kbar(-1) 
                    / (q(-1) * kbar(-1) - n(-1))) - mu_p * G_ss * (1 + Rk_ss) * kbar_ss / (kbar_ss - n_ss));
  @# endif
  pinvest_obs     = muup(-1) / muup;
  Re_obs          = exp(Re - Re_p);
  RealRe_obs      = ((1 + Re) / pi(+1))/((1 + Re_p) / pi_p);
  @# if cee == 0
  Spread1_obs     = 1 + RL - Re;  
  @# endif
  wage_obs        = wtilde / wtilde(-1) * muzstar / muzstar_p;
@#endif


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Shock equations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  log(epsil / epsil_p)       = rhoepsil_p    * log(epsil(-1) / epsil_p)       + (1 - @{stopshock}) * e_epsil;
  log(g / g_ss)              = rhog_p        * log(g(-1) / g_ss)              - (1 - @{stopshock}) * e_g;
  @# if cee == 0
  log(gamma / gamma_p)       = rhogamma_p    * log(gamma(-1) / gamma_p)       - (1 - @{stopshock}) * e_gamma;
  @# endif
  log(lambdaf / lambdaf_p)   = rholambdaf_p  * log(lambdaf(-1) / lambdaf_p)   - (1 - @{stopshock}) * e_lambdaf;
  log(muup / muup_p)         = rhomuup_p     * log(muup(-1) / muup_p)         - (1 - @{stopshock}) * e_muup;
  log(muzstar / muzstar_p)   = rhomuzstar_p  * log(muzstar(-1) / muzstar_p)   - (1 - @{stopshock}) * e_muzstar;
  log(pitarget / pitarget_p) = rhopitarget_p * log(pitarget(-1) / pitarget_p) - (1 - @{stopshock}) * e_pitarget;
  @# if cee == 0
  log(term / term_p)         = rhoterm_p     * log(term(-1) / term_p)         + (1 - @{stopshock}) * e_term;
  @# endif
  log(zetac / zetac_p)       = rhozetac_p    * log(zetac(-1) / zetac_p)       - (1 - @{stopshock}) * e_zetac;
  log(zetai / zetai_p)       = rhozetai_p    * log(zetai(-1) / zetai_p)       + (1 - @{stopshock}) * e_zetai;
  
  @# if cee == 0
    @#for index1 in 1 : 8
        LAG_1_xi@{index1} = xi@{index1}(-1);
        @#for index2 in 2 : index1
            LAG_@{index2}_xi@{index1} = LAG_@{index2-1}_xi@{index1}(-1);
        @#endfor
    @#endfor

  log(sigma / sigma_ss) = rhosigma_p * log(sigma(-1) / sigma_ss)  + log(xi0) 
  @#for index in 1 : 8
    + log(LAG_@{index}_xi@{index})
  @#endfor 
  ;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Signal equations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  @#if ("8" in possible_signals)
  log(xi8) = stdsigma2_p * e_xi8;
  @#else
  log(xi8) = 0;
  @#endif
  
  @#if ("7" in possible_signals)
  log(xi7) = signal_corr_p * stdsigma2_p * e_xi8 
  @#for index in ["7"]
    + sqrt(1 - signal_corr_p^2) * stdsigma2_p * e_xi@{index}
  @#endfor
  ;
  @#else
  log(xi7) = 0;
  @#endif
  
  @#if ("6" in possible_signals)
  log(xi6) = signal_corr_p^2 * stdsigma2_p * e_xi8
  @#for index in ["7", "6"]
    + sqrt(1 - signal_corr_p^2) * signal_corr_p^(@{index} - 6) * stdsigma2_p * e_xi@{index}
  @#endfor
  ;
  @#else
  log(xi6) = 0;
  @#endif

  @#if ("5" in possible_signals)
  log(xi5) = signal_corr_p^3 * stdsigma2_p * e_xi8
  @#for index in ["7", "6", "5"]
    + sqrt(1 - signal_corr_p^2) * signal_corr_p^(@{index} - 5) * stdsigma2_p * e_xi@{index}
  @#endfor
  ;
  @#else
  log(xi5) = 0;
  @#endif

  @#if ("4" in possible_signals)
  log(xi4) = signal_corr_p^4 * stdsigma2_p * e_xi8
  @#for index in ["7", "6", "5", "4"]
    + sqrt(1 - signal_corr_p^2) * signal_corr_p^(@{index} - 4) * stdsigma2_p * e_xi@{index}
  @#endfor
  ;
  @#else
  log(xi4) = 0;
  @#endif

  @#if ("3" in possible_signals)  
  log(xi3) = signal_corr_p^5 * stdsigma2_p * e_xi8
  @#for index in ["7", "6", "5", "4", "3"]
    + sqrt(1 - signal_corr_p^2) * signal_corr_p^(@{index} - 3) * stdsigma2_p * e_xi@{index}
  @#endfor
  ;
  @#else
  log(xi3) = 0;
  @#endif

  @#if ("2" in possible_signals)  
  log(xi2) = signal_corr_p^6 * stdsigma2_p * e_xi8
  @#for index in ["7", "6", "5", "4", "3", "2"]
    + sqrt(1 - signal_corr_p^2) * signal_corr_p^(@{index} - 2) * stdsigma2_p * e_xi@{index}
  @#endfor
  ;
  @#else
  log(xi2) = 0;
  @#endif
  
  @#if ("1" in possible_signals)
  log(xi1) = signal_corr_p^7 * stdsigma2_p * e_xi8
  @#for index in ["7", "6", "5", "4", "3", "2", "1"]
    + sqrt(1 - signal_corr_p^2) * signal_corr_p^(@{index} - 1) * stdsigma2_p * e_xi@{index}
  @#endfor
  ;
  @#else
  log(xi1) = 0;
  @#endif
  
  @# if ("0" in possible_signals)
  log(xi0) = signal_corr_p^8 * stdsigma1_p * e_xi8
  @#for index in ["7", "6", "5", "4", "3", "2", "1"]
    + sqrt(1 - signal_corr_p^2) * signal_corr_p^(@{index} - 0) * stdsigma1_p * e_xi@{index}
  @#endfor
  + sqrt(1-signal_corr_p^2) * stdsigma1_p * e_sigma;
  @#else
  log(xi0)=0;
  @#endif  
  @#endif
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This ensures zero profits.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  phi = steady_state(phi);

end;
