%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The 'estimated_params_init' block declares numerical initial values for 
% the optimizer when these are different from the prior mean.
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

estimated_params_init;	 	 
stderr e_lambdaf,        0.0109559606811660;  
stderr e_muup,           0.0039857917638490;
stderr e_g,              0.0228127233194570;
stderr e_muzstar,        0.0071487847687080;
@# if cee == 0
stderr e_gamma,          0.0081035403472920;
@# endif
stderr e_epsil,          0.0046338119312200;
stderr e_xp,             0.4893446208831330;
stderr e_zetac,          0.0233253551183060;
stderr e_zetai,          0.0549648244379450;
@# if cee == 0
@# if Spread1_in_financial_data
stderr e_term,           0.0016037530257270;
@# endif
@# if net_worth_in_financial_data
stderr networth_obs,     0.0174589738467390;
@# endif
@# endif
xiw_p,                   0.8127963113950160;
b_p,                     0.7358438226929010;
@# if cee == 0
Fomegabar_p,             0.0055885692972290;
mu_p,                    0.2148945111281970;
@# endif
sigmaa_p,                2.5355534195260200;
Sdoupr_p,               10.7800000034422000;
xip_p,                   0.7412186033856290;
@# if taylor1p5 == 1
aptil_p,                 1.5;
@# else
aptil_p,                 2.3964959426752000;
@# endif
rhotil_p,                0.8502964502607260;
iota_p,                  0.8973670521349900;
iotaw_p,                 0.4890735358842230;
iotamu_p,                0.9365652807278990;
adytil_p,                0.3649436543356210; 

@# if cee == 0
@# if (some_financial_data && signal_corr_nonzero)
signal_corr_p,           0.3861343781103740;
@# endif
@# endif

rholambdaf_p,            0.9108528528580380;
rhomuup_p,               0.9870257396836700;
rhog_p,                  0.9427215849959780;
rhomuzstar_p,            0.1459051086113400;
rhoepsil_p,              0.8089285617540170;
@# if cee == 0
rhosigma_p,              0.9706370265612010;
@# endif 
rhozetac_p,              0.8968400853887450;
rhozetai_p,              0.9086616567125290;
@# if cee == 0
@# if Spread1_in_financial_data
rhoterm_p,               0.9743991813961140;
@# endif
@# if stopsignal == 0
stdsigma2_p,             0.0282985295279650;
@# endif
stdsigma1_p,		 0.0700061676650730;
@# endif
end;