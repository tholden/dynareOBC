%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The 'estimated_params' block lists all parameters to be estimated and 
% specifies bounds and priors as necessary.
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

estimated_params;
xiw_p,               BETA_PDF,       0.75,              0.1;
b_p,                 BETA_PDF,       0.5,               0.1;
@# if cee == 0
Fomegabar_p,         BETA_PDF,       0.0075,            0.00375;
mu_p,                BETA_PDF,       0.275,             0.15;
@# endif
sigmaa_p,            NORMAL_PDF,     1,                 1;
Sdoupr_p,            NORMAL_PDF,     5,                 3;
xip_p,               BETA_PDF  ,     0.5,               0.1;
aptil_p,             NORMAL_PDF,     1.5,               0.25;
rhotil_p,            BETA_PDF,       0.75,              0.1;
iota_p,              BETA_PDF,       0.5,               0.15;
iotaw_p,             BETA_PDF,       0.5,               0.15;
iotamu_p,            BETA_PDF,       0.5,               0.15;
adytil_p,            NORMAL_PDF,     0.25,              0.1;
@# if cee == 0
@# if some_financial_data
@# if signal_corr_nonzero
signal_corr_p,       NORMAL_PDF,     0,                 0.5;
@# endif
@# endif
@# endif
rholambdaf_p,        BETA_PDF,       0.5,               0.2;
rhomuup_p,           BETA_PDF,       0.5,               0.2;
rhog_p,              BETA_PDF,       0.5,               0.2;
rhomuzstar_p,        BETA_PDF,       0.5,               0.2;
rhoepsil_p,          BETA_PDF,       0.5,               0.2;
@# if cee == 0
rhosigma_p,          BETA_PDF,       0.5,               0.2;
@# endif
rhozetac_p,          BETA_PDF,       0.5,               0.2;
rhozetai_p,          BETA_PDF,       0.5,               0.2;
@# if cee == 0
@# if Spread1_in_financial_data
rhoterm_p,           BETA_PDF,       0.5,               0.2;
@# endif
@# if stopsignal == 0
stdsigma2_p,         INV_GAMMA2_PDF, 0.000824957911384, 0.00116666666667;
@# endif
stdsigma1_p,         INV_GAMMA2_PDF, 0.00233333333333,  0.00329983164554;  
@# endif
stderr e_lambdaf,    INV_GAMMA2_PDF, 0.00233333333333,  0.00329983164554;
stderr e_muup,       INV_GAMMA2_PDF, 0.00233333333333,  0.00329983164554;
stderr e_g,          INV_GAMMA2_PDF, 0.00233333333333,  0.00329983164554;
stderr e_muzstar,    INV_GAMMA2_PDF, 0.00233333333333,  0.00329983164554;
@# if cee == 0
stderr e_gamma,      INV_GAMMA2_PDF, 0.00233333333333,  0.00329983164554;
@# endif
stderr e_epsil,      INV_GAMMA2_PDF, 0.00233333333333,  0.00329983164554;
stderr e_xp,         INV_GAMMA2_PDF, 0.583333333333,    0.824957911384;
stderr e_zetac,      INV_GAMMA2_PDF, 0.00233333333333,  0.00329983164554;
stderr e_zetai,      INV_GAMMA2_PDF, 0.00233333333333,  0.00329983164554;
@# if cee == 0
@# if Spread1_in_financial_data
stderr e_term,       INV_GAMMA2_PDF, 0.00233333333333,  0.00329983164554;
@# endif
@# if net_worth_in_financial_data
stderr networth_obs, INV_GAMMA_PDF,  0.01,              5;
@# endif
@# endif
end;