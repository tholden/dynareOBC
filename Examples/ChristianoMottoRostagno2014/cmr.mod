%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CMR version, baseline, with credit and term spread
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

% One can estimate the baseline version of the model, 
% and versions of the model obtained by dropping none, one or several of the 
% four 'financial variables'. By dropping none of the variables, the user
% simply estimates the baseline model. The financial variables you want
% included in the estimation are in the following list:

@# define financial_data = ["networth_obs", "credit_obs", "premium_obs", "Spread1_obs"]

% Depending on the variables included in the financial data, we need some
% indicator variables.

@# include "cmr_indicator_variables.mod"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 0. Housekeeping, paths, and estimation decisions.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Declaration of variables and parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@# include "cmr_declarations.mod"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Set parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% when stopshock = 1, then non-risk shocks are all turned off
@# define stopshock = 0

% when stopsignal = 1, then signals on risk are turned off
@# define stopsignal = 0

% when stopunant = 1, then unanticipated risk shock turned off
@# define stopunant = 0

% when signal_corr_nonzero = 1, sig_corr_p can be non zero.
@# define signal_corr_nonzero = 1

@# include "cmr_parameters.mod"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@# include "cmr_model.mod"

@#ifndef dynareOBC
    load cmr_mode.mat;
    ModelParamNames = cellstr( M_.param_names );
    for ii = 1 : length( parameter_names )
        ParamName = parameter_names{ii};
        if length( ParamName ) >= 4 && strcmp( ParamName( end-3 : end ), '_obs' )
            continue;
        end
        if strcmp( ParamName( 1:2 ), 'e_' )
            ParamName = [ 'std' ParamName( 3:end ) '_p' ];
        else
            ParamName = strrep( ParamName, '1', '' );
            if strcmp( ParamName, 'par8_p' )
                ParamName = 'signal_corr_p';
            elseif strcmp( ParamName, 'stdsigmax_p' )
                ParamName = 'stdsigma2_p';
            elseif strcmp( ParamName, 'stdsigma_p' )
                ParamName = 'stdsigma1_p';
            end
        end
        Idx = find( strcmp( ParamName, ModelParamNames ) );
        if isempty( Idx ) || Idx <= 0
            keyboard;
        end
        assert( abs( M_.params( Idx ) - xparam1( ii ) ) < 1e-8 );
        M_.params( Idx ) = xparam1( ii );
        eval( [ ParamName ' = M_.params( ' int2str( Idx ) ' );' ] );
    end
@#endif

% Compute the steady state of the model.
steady;

% Compute the eigenvalues of the model linearized around the steady state.
check;

% Specifiy the shocks.
@# include "cmr_shocks.mod"

@#ifndef dynareOBC
    save_params_and_steady_state( 'steady.txt' );
@#endif

@#ifdef dynareOBC
    stoch_simul( order = 1, loglinear, periods = 0, irf = 40 ) log_c log_i log_pi log_RRe;
@#else
    stoch_simul( order = 1, loglinear, periods = 0, irf = 40 ) c i pi RRe;
@#endif


