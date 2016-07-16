%
% Status : main Dynare file
%
% Warning : this file is generated automatically by Dynare
%           from model file (.mod)

if isoctave || matlab_ver_less_than('8.6')
    clear all
else
    clearvars -global
    clear_persistent_variables(fileparts(which('dynare')), false)
end
tic0 = tic;
% Save empty dates and dseries objects in memory.
dates('initialize');
dseries('initialize');
% Define global variables.
global M_ options_ oo_ estim_params_ bayestopt_ dataset_ dataset_info estimation_info ys0_ ex0_
options_ = [];
M_.fname = 'news_bkw2012';
M_.dynare_version = '4.5-unstable';
oo_.dynare_version = '4.5-unstable';
options_.dynare_version = '4.5-unstable';
%
% Some global variables initialization
%
global_initialization;
diary off;
diary('news_bkw2012.log');
M_.exo_names = 'epsilon';
M_.exo_names_tex = 'epsilon';
M_.exo_names_long = 'epsilon';
M_.endo_names = 'y';
M_.endo_names_tex = 'y';
M_.endo_names_long = 'y';
M_.endo_names = char(M_.endo_names, 'pi');
M_.endo_names_tex = char(M_.endo_names_tex, 'pi');
M_.endo_names_long = char(M_.endo_names_long, 'pi');
M_.endo_names = char(M_.endo_names, 'z');
M_.endo_names_tex = char(M_.endo_names_tex, 'z');
M_.endo_names_long = char(M_.endo_names_long, 'z');
M_.endo_names = char(M_.endo_names, 'd');
M_.endo_names_tex = char(M_.endo_names_tex, 'd');
M_.endo_names_long = char(M_.endo_names_long, 'd');
M_.endo_names = char(M_.endo_names, 'r');
M_.endo_names_tex = char(M_.endo_names_tex, 'r');
M_.endo_names_long = char(M_.endo_names_long, 'r');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_0');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_0');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_0');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_1');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_1');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_1');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_2');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_2');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_2');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_3');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_3');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_3');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_4');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_4');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_4');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_5');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_5');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_5');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_6');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_6');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_6');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_7');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_7');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_7');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_8');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_8');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_8');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_9');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_9');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_9');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_10');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_10');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_10');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_11');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_11');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_11');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_12');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_12');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_12');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_13');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_13');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_13');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_14');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_14');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_14');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_15');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_15');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_15');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_16');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_16');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_16');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_17');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_17');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_17');
M_.endo_names = char(M_.endo_names, 'AUX_EXO_LAG_19_18');
M_.endo_names_tex = char(M_.endo_names_tex, 'AUX\_EXO\_LAG\_19\_18');
M_.endo_names_long = char(M_.endo_names_long, 'AUX_EXO_LAG_19_18');
M_.param_names = 'sigma';
M_.param_names_tex = 'sigma';
M_.param_names_long = 'sigma';
M_.param_names = char(M_.param_names, 'nu');
M_.param_names_tex = char(M_.param_names_tex, 'nu');
M_.param_names_long = char(M_.param_names_long, 'nu');
M_.param_names = char(M_.param_names, 'beta');
M_.param_names_tex = char(M_.param_names_tex, 'beta');
M_.param_names_long = char(M_.param_names_long, 'beta');
M_.param_names = char(M_.param_names, 'theta');
M_.param_names_tex = char(M_.param_names_tex, 'theta');
M_.param_names_long = char(M_.param_names_long, 'theta');
M_.param_names = char(M_.param_names, 'gamma');
M_.param_names_tex = char(M_.param_names_tex, 'gamma');
M_.param_names_long = char(M_.param_names_long, 'gamma');
M_.param_names = char(M_.param_names, 'pi_STEADY');
M_.param_names_tex = char(M_.param_names_tex, 'pi\_STEADY');
M_.param_names_long = char(M_.param_names_long, 'pi_STEADY');
M_.param_names = char(M_.param_names, 'phi_pi');
M_.param_names_tex = char(M_.param_names_tex, 'phi\_pi');
M_.param_names_long = char(M_.param_names_long, 'phi_pi');
M_.param_names = char(M_.param_names, 'phi_y');
M_.param_names_tex = char(M_.param_names_tex, 'phi\_y');
M_.param_names_long = char(M_.param_names_long, 'phi_y');
M_.param_names = char(M_.param_names, 'eta');
M_.param_names_tex = char(M_.param_names_tex, 'eta');
M_.param_names_long = char(M_.param_names_long, 'eta');
M_.param_names = char(M_.param_names, 'tauw');
M_.param_names_tex = char(M_.param_names_tex, 'tauw');
M_.param_names_long = char(M_.param_names_long, 'tauw');
M_.param_names = char(M_.param_names, 'rhod');
M_.param_names_tex = char(M_.param_names_tex, 'rhod');
M_.param_names_long = char(M_.param_names_long, 'rhod');
M_.param_names = char(M_.param_names, 'sigmad');
M_.param_names_tex = char(M_.param_names_tex, 'sigmad');
M_.param_names_long = char(M_.param_names_long, 'sigmad');
M_.param_names = char(M_.param_names, 'rhoz');
M_.param_names_tex = char(M_.param_names_tex, 'rhoz');
M_.param_names_long = char(M_.param_names_long, 'rhoz');
M_.param_names = char(M_.param_names, 'sigmaz');
M_.param_names_tex = char(M_.param_names_tex, 'sigmaz');
M_.param_names_long = char(M_.param_names_long, 'sigmaz');
M_.exo_det_nbr = 0;
M_.exo_nbr = 1;
M_.endo_nbr = 24;
M_.param_nbr = 14;
M_.orig_endo_nbr = 5;
M_.aux_vars(1).endo_index = 6;
M_.aux_vars(1).type = 3;
M_.aux_vars(1).orig_index = 1;
M_.aux_vars(1).orig_lead_lag = 0;
M_.aux_vars(2).endo_index = 7;
M_.aux_vars(2).type = 3;
M_.aux_vars(2).orig_index = 1;
M_.aux_vars(2).orig_lead_lag = -1;
M_.aux_vars(3).endo_index = 8;
M_.aux_vars(3).type = 3;
M_.aux_vars(3).orig_index = 1;
M_.aux_vars(3).orig_lead_lag = -2;
M_.aux_vars(4).endo_index = 9;
M_.aux_vars(4).type = 3;
M_.aux_vars(4).orig_index = 1;
M_.aux_vars(4).orig_lead_lag = -3;
M_.aux_vars(5).endo_index = 10;
M_.aux_vars(5).type = 3;
M_.aux_vars(5).orig_index = 1;
M_.aux_vars(5).orig_lead_lag = -4;
M_.aux_vars(6).endo_index = 11;
M_.aux_vars(6).type = 3;
M_.aux_vars(6).orig_index = 1;
M_.aux_vars(6).orig_lead_lag = -5;
M_.aux_vars(7).endo_index = 12;
M_.aux_vars(7).type = 3;
M_.aux_vars(7).orig_index = 1;
M_.aux_vars(7).orig_lead_lag = -6;
M_.aux_vars(8).endo_index = 13;
M_.aux_vars(8).type = 3;
M_.aux_vars(8).orig_index = 1;
M_.aux_vars(8).orig_lead_lag = -7;
M_.aux_vars(9).endo_index = 14;
M_.aux_vars(9).type = 3;
M_.aux_vars(9).orig_index = 1;
M_.aux_vars(9).orig_lead_lag = -8;
M_.aux_vars(10).endo_index = 15;
M_.aux_vars(10).type = 3;
M_.aux_vars(10).orig_index = 1;
M_.aux_vars(10).orig_lead_lag = -9;
M_.aux_vars(11).endo_index = 16;
M_.aux_vars(11).type = 3;
M_.aux_vars(11).orig_index = 1;
M_.aux_vars(11).orig_lead_lag = -10;
M_.aux_vars(12).endo_index = 17;
M_.aux_vars(12).type = 3;
M_.aux_vars(12).orig_index = 1;
M_.aux_vars(12).orig_lead_lag = -11;
M_.aux_vars(13).endo_index = 18;
M_.aux_vars(13).type = 3;
M_.aux_vars(13).orig_index = 1;
M_.aux_vars(13).orig_lead_lag = -12;
M_.aux_vars(14).endo_index = 19;
M_.aux_vars(14).type = 3;
M_.aux_vars(14).orig_index = 1;
M_.aux_vars(14).orig_lead_lag = -13;
M_.aux_vars(15).endo_index = 20;
M_.aux_vars(15).type = 3;
M_.aux_vars(15).orig_index = 1;
M_.aux_vars(15).orig_lead_lag = -14;
M_.aux_vars(16).endo_index = 21;
M_.aux_vars(16).type = 3;
M_.aux_vars(16).orig_index = 1;
M_.aux_vars(16).orig_lead_lag = -15;
M_.aux_vars(17).endo_index = 22;
M_.aux_vars(17).type = 3;
M_.aux_vars(17).orig_index = 1;
M_.aux_vars(17).orig_lead_lag = -16;
M_.aux_vars(18).endo_index = 23;
M_.aux_vars(18).type = 3;
M_.aux_vars(18).orig_index = 1;
M_.aux_vars(18).orig_lead_lag = -17;
M_.aux_vars(19).endo_index = 24;
M_.aux_vars(19).type = 3;
M_.aux_vars(19).orig_index = 1;
M_.aux_vars(19).orig_lead_lag = -18;
M_.Sigma_e = zeros(1, 1);
M_.Correlation_matrix = eye(1, 1);
M_.H = 0;
M_.Correlation_matrix_ME = 1;
M_.sigma_e_is_diagonal = 1;
M_.det_shocks = [];
options_.block=0;
options_.bytecode=0;
options_.use_dll=0;
erase_compiled_function('news_bkw2012_static');
erase_compiled_function('news_bkw2012_dynamic');
M_.orig_eq_nbr = 5;
M_.eq_nbr = 24;
M_.ramsey_eq_nbr = 0;
M_.lead_lag_incidence = [
 0 21 45;
 0 22 46;
 0 23 0;
 0 24 0;
 1 25 0;
 2 26 0;
 3 27 0;
 4 28 0;
 5 29 0;
 6 30 0;
 7 31 0;
 8 32 0;
 9 33 0;
 10 34 0;
 11 35 0;
 12 36 0;
 13 37 0;
 14 38 0;
 15 39 0;
 16 40 0;
 17 41 0;
 18 42 0;
 19 43 0;
 20 44 0;]';
M_.nstatic = 2;
M_.nfwrd   = 2;
M_.npred   = 20;
M_.nboth   = 0;
M_.nsfwrd   = 2;
M_.nspred   = 20;
M_.ndynamic   = 22;
M_.equations_tags = {
};
M_.static_and_dynamic_models_differ = 0;
M_.exo_names_orig_ord = [1:1];
M_.maximum_lag = 1;
M_.maximum_lead = 1;
M_.maximum_endo_lag = 1;
M_.maximum_endo_lead = 1;
oo_.steady_state = zeros(24, 1);
M_.maximum_exo_lag = 0;
M_.maximum_exo_lead = 0;
oo_.exo_steady_state = zeros(1, 1);
M_.params = NaN(14, 1);
M_.NNZDerivatives = [58; -1; -1];
M_.params( 3 ) = 0.997;
beta = M_.params( 3 );
M_.params( 4 ) = 7.67;
theta = M_.params( 4 );
M_.params( 9 ) = 0.2;
eta = M_.params( 9 );
M_.params( 10 ) = 0.2;
tauw = M_.params( 10 );
M_.params( 5 ) = 458.4;
gamma = M_.params( 5 );
M_.params( 2 ) = 0.28;
nu = M_.params( 2 );
M_.params( 7 ) = 3.46;
phi_pi = M_.params( 7 );
M_.params( 8 ) = 1.63;
phi_y = M_.params( 8 );
M_.params( 1 ) = 1;
sigma = M_.params( 1 );
M_.params( 11 ) = 0.88;
rhod = M_.params( 11 );
M_.params( 13 ) = 0.96;
rhoz = M_.params( 13 );
M_.params( 12 ) = 0.0027;
sigmad = M_.params( 12 );
M_.params( 14 ) = 0.0052;
sigmaz = M_.params( 14 );
M_.params( 6 ) = 0;
pi_STEADY = M_.params( 6 );
%
% SHOCKS instructions
%
M_.exo_det_length = 0;
M_.Sigma_e(1, 1) = 1;
steady;
oo_.dr.eigval = check(M_,options_,oo_);
options_.irf = 40;
options_.order = 1;
options_.periods = 0;
var_list_ = char();
info = stoch_simul(var_list_);
save('news_bkw2012_results.mat', 'oo_', 'M_', 'options_');
if exist('estim_params_', 'var') == 1
  save('news_bkw2012_results.mat', 'estim_params_', '-append');
end
if exist('bayestopt_', 'var') == 1
  save('news_bkw2012_results.mat', 'bayestopt_', '-append');
end
if exist('dataset_', 'var') == 1
  save('news_bkw2012_results.mat', 'dataset_', '-append');
end
if exist('estimation_info', 'var') == 1
  save('news_bkw2012_results.mat', 'estimation_info', '-append');
end
if exist('dataset_info', 'var') == 1
  save('news_bkw2012_results.mat', 'dataset_info', '-append');
end
if exist('oo_recursive_', 'var') == 1
  save('news_bkw2012_results.mat', 'oo_recursive_', '-append');
end


disp(['Total computing time : ' dynsec2hms(toc(tic0)) ]);
if ~isempty(lastwarn)
  disp('Note: warning(s) encountered in MATLAB/Octave code')
end
diary off
