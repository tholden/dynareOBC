function DispMoments(M, options, oo, dynareOBC)
% Derived from disp_moments.m in Dynare. Original file follows.

% Displays moments of simulated variables

% Copyright (C) 2001-2012 Dynare Team
%
% This file is part of Dynare.
%
% Dynare is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Dynare is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

WarningState = warning( 'off', 'all' );

try
    Drop = dynareOBC.SimulationDrop;
    y = oo.endo_simul;
    VariableSelect = dynareOBC.VariableSelect;
    y = y(VariableSelect,Drop+1:end)';
    MLVNames = dynareOBC.MLVNames;
    MLVSelect = dynareOBC.MLVSelect;
    for i = MLVSelect
        MLVName = MLVNames{i};
        y = [ y, dynareOBC.MLVSimulationWithBounds.( MLVName )( Drop+1:end )' ]; %#ok<AGROW>
    end
    m = nanmean(y);

    if options.hp_filter
        [~,y] = sample_hp_filter(y,options.hp_filter);
    else
        y = bsxfun(@minus, y, m);
    end

    s2 = nanmean(y.*y);
    s = sqrt(s2);
    oo.mean = transpose(m);
    oo.var = y'*y/size(y,1);

    labels = deblank( char( [ dynareOBC.EndoVariables( VariableSelect ) dynareOBC.MLVNames( MLVSelect ) ] ) );

    if options.nomoments == 0
        z = [ m' s' s2' (nanmean(y.^3)./s2.^1.5)' (nanmean(y.^4)./(s2.*s2)-3)' ];    
        title='MOMENTS OF SIMULATED VARIABLES';
        if options.hp_filter
            title = [title ' (HP filter, lambda = ' ...
                     num2str(options.hp_filter) ')'];
        end
        headers=char('VARIABLE','MEAN','STD. DEV.','VARIANCE','SKEWNESS', ...
                     'KURTOSIS');
        dyntable(title,headers,labels,z,size(labels,2)+2,16,6);
    end

    if options.nocorr == 0
        corr = (y'*y/size(y,1))./(s'*s);
        if options.noprint == 0
            title = 'CORRELATION OF SIMULATED VARIABLES';
            if options.hp_filter
                title = [title ' (HP filter, lambda = ' ...
                         num2str(options.hp_filter) ')'];
            end
            headers = char('VARIABLE',M.endo_names(VariableSelect,:));
            dyntable(title,headers,labels,corr,size(labels,2)+2,8,4);
        end
    end

%     if options_.noprint == 0 && length(options_.conditional_variance_decomposition)
%        fprintf('\nSTOCH_SIMUL: conditional_variance_decomposition requires theoretical moments, i.e. periods=0.\n') 
%     end

    ar = options.ar;
    if ar > 0
        autocorr = [];
        for i=1:ar
            oo.autocorr{i} = y(ar+1:end,:)'*y(ar+1-i:end-i,:)./((size(y,1)-ar)*std(y(ar+1:end,:))'*std(y(ar+1-i:end-i,:)));
            autocorr = [ autocorr diag(oo.autocorr{i}) ];
        end
        if options.noprint == 0
            title = 'AUTOCORRELATION OF SIMULATED VARIABLES';
            if options.hp_filter
                title = [title ' (HP filter, lambda = ' ...
                         num2str(options.hp_filter) ')'];
            end
            headers = char('VARIABLE',int2str([1:ar]'));
            dyntable(title,headers,labels,autocorr,size(labels,2)+2,8,4);
        end
    end
catch Error
    warning(WarningState);
    rethrow(Error);
end
warning(WarningState);
