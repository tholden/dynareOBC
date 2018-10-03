%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Declare the endogenous variables in the model. 
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


var 
c
consumption_obs, 
@#if cee == 0
credit_obs,
@# endif
epsil, 
Fp,
Fw, 
g,
@# if cee == 0
gamma,
@# endif
gdp_obs,
h,
hours_obs, 
i,
inflation_obs, 
investment_obs,
kbar,
lambdaf, 
lambdaz,
muup,
muzstar, 
@# if cee == 0
n,
networth_obs,
omegabar,
@# endif
phi,
pi,
pinvest_obs,
pitarget,
@# if cee == 0
premium_obs,
@# endif
pstar,
q,
RRe, 
Re_obs,
RealRe_obs,
@# if cee == 0
rL,
@# endif
rk,
RRk,
@# if cee == 0
RL, 
@# endif
s,
@# if cee == 0
sigma,
xi0, 
xi1, 
xi2, 
xi3, 
xi4, 
xi5, 
xi6, 
xi7, 
xi8, 
Spread1_obs,
term,
volEquity,
@# endif
u,
wage_obs,
wtilde,
wstar, 
zetac,
zetai;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Declare the exogenous variables in the model.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All have been checked.  All are used.
varexo 
e_epsil,
e_g,
@# if cee == 0
e_gamma,
@# endif
e_lambdaf, 
e_muup,
e_muzstar, 
e_pitarget,
@# if cee == 0 
e_sigma,
e_xi1,
e_xi2,
e_xi3, 
e_xi4,
e_xi5,
e_xi6,
e_xi7,
e_xi8,
e_term,
@# endif
e_xp,
e_zetac,
e_zetai;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Declare the parameters in the model.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parameters
actil_p,
adptil_p,
adytil_p,
alpha_p,
aptil_p,
aytil_p,
b_p,
beta_p,
@# if cee == 0
bigtheta_p,
@# endif
c_p,
delta_p,
epsil_p,
etag_p,
@# if cee == 0
Fomegabar_p,
@# endif
g_p,
@# if cee == 0
gamma_p,
@# endif
i_p,
iota_p,
iotamu_p,
iotaw_p,
lambdaf_p,
lambdaw_p,
mu_p,
muup_p,
muzstar_p,
@# if cee == 0
signal_corr_p,
@# endif
pi_p,
pibar_p,
pitarget_p,
psik_p,
psil_p,
psiL_p,
Re_p,
rhoepsil_p,
rhog_p,
@# if cee == 0
rhogamma_p,
@# endif
rholambdaf_p,
rhomuup_p,
rhomuzstar_p,
rhopitarget_p,
@# if cee == 0
rhosigma_p,
@# endif
rhoterm_p,
rhozetac_p,
rhozetai_p,
rhotil_p,
Sdoupr_p,
sigmaL_p,
@# if cee == 0
sigma_p,
@# endif
sigmaa_p,
stdepsil_p,
stdg_p,
@# if cee == 0
stdgamma_p,
@# endif
stdlambdaf_p,
stdmuup_p,
stdmuzstar_p,
stdpitarget_p,
@# if cee == 0
stdsigma1_p,
@# endif
stdterm_p,
stdxp_p,
stdzetac_p,
stdzetai_p,
@# if cee == 0
stdsigma2_p,
@# endif
tauc_p,
taud_p,
tauk_p,
taul_p,
tauo_p,
term_p,
upsil_p,
we_p,
xip_p,
xiw_p,
zeta_p,
zetac_p,
zetai_p;

@# if cee == 0
    @#for index1 in 1 : 8
        @#for index2 in 1 : index1
            var LAG_@{index2}_xi@{index1};
        @#endfor
    @#endfor

    @#for varname in [ "term", "pi", "muzstar", "zetac", "lambdaz" ]
        @#for index in 1 : 40
            var LEAD_@{index}_@{varname};
        @#endfor
    @#endfor
@# endif


