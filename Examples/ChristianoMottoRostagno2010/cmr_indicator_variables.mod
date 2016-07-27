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

% The model sets some measurement error on net worth.  If net worth is not
% included in the financial variables, it should not have measurement error,
% and that measurement error should not be estimated.
 
@#define net_worth_in_financial_data = ("networth_obs" in financial_data)

% The model estimates an autocorrelation and standard deviation term for
% the term structure.  If the spread is not included in the data, then
% the autocorrelation and standard deviation should not be estimated.

@#define Spread1_in_financial_data = ("Spread1_obs" in financial_data)

% When no financial data were included in the model, sig_corr_p is also not
% estimated. So, we need an indicator to see if no financial data are
% in the observable variables.

@#define credit_in_financial_data = ("credit_obs" in financial_data)
@#define premium_in_financial_data = ("premium_obs" in financial_data)

@#define cee = 0

@#if cee == 0

    @#define some_financial_data = (Spread1_in_financial_data || credit_in_financial_data || premium_in_financial_data || net_worth_in_financial_data)

@#else
    
    @#define some_financial_data = 0

@#endif

@#define possible_signals = ["0", "1", "2", "3", "4", "5", "6", "7", "8"]

@#define taylor1p5 = 0

@#define sticky_prices = 1
@#define sticky_wages = 1
@#define sigma_in_taylor_rule = 0
