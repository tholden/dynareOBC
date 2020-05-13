function DispMoments(~, options, oo, dynareOBC)
% Derived from disp_moments.m in Dynare. Original file comment follows.

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
    nVars = length( VariableSelect );
    y = y(VariableSelect,Drop+1:end)';
    MLVNames = dynareOBC.MLVNames;
    MLVSelect = dynareOBC.MLVSelect;
    nVars = nVars + length( MLVSelect );
    for i = MLVSelect
        MLVName = MLVNames{i};
        y = [ y, dynareOBC.MLVSimulationWithBounds.( MLVName )( Drop+1:end )' ]; %#ok<AGROW>
    end
    
    if isempty( y )
        return
    end
    
    m = nanmean2(y);

    if options.hp_filter
        [~,y] = sample_hp_filter(y,options.hp_filter);
    else
        y = bsxfun(@minus, y, m);
    end

    s2 = nanmean2(y.*y);

    s = sqrt(s2);
    oo.mean = transpose(m);
    
    reshapetmp = nanmean2( cell2mat( cellfun( @( yv ) vec( yv' * yv )', mat2cell( y, ones( size( y, 1 ), 1 ) ), 'UniformOutput', false ) ) );
    if numel( reshapetmp ) == nVars * nVars
        oo.var = reshape( reshapetmp, [ nVars, nVars ] );
    else
        oo.var = NaN( nVars, nVars );
    end

    labels = deblank( char( [ dynareOBC.EndoVariables( VariableSelect ) dynareOBC.MLVNames( MLVSelect ) ] ) );

    DynareVersion = dynareOBC.DynareVersion;

    if options.nomoments == 0
        z = [ m' s' s2' (nanmean2(y.^3)./s2.^1.5)' (nanmean2(y.^4)./(s2.*s2)-3)' ];    
        title='MOMENTS OF SIMULATED VARIABLES';
        if options.hp_filter
            title = [title ' (HP filter, lambda = ' ...
                     num2str(options.hp_filter) ')'];
        end
        headers=char('VARIABLE','MEAN','STD. DEV.','VARIANCE','SKEWNESS', ...
                     'KURTOSIS');
        if DynareVersion >= 4.6
            dyntable(options,title,cellstr(headers),cellstr(labels),z,size(labels,2)+2,16,6);
        elseif DynareVersion >= 4.5
            dyntable(options,title,headers,labels,z,size(labels,2)+2,16,6);
        else
            dyntable(title,headers,labels,z,size(labels,2)+2,16,6);
        end
    end

    if options.nocorr == 0
        corr = oo.var ./( s' * s );
        if options.noprint == 0
            title = 'CORRELATION OF SIMULATED VARIABLES';
            if options.hp_filter
                title = [title ' (HP filter, lambda = ' ...
                         num2str(options.hp_filter) ')'];
            end
            headers = char( 'VARIABLE', labels );
            if DynareVersion >= 4.6
                dyntable(options,title,cellstr(headers),cellstr(labels),corr,size(labels,2)+2,8,4);
            elseif DynareVersion >= 4.5
                dyntable(options,title,headers,labels,corr,size(labels,2)+2,8,4);
            else
                dyntable(title,headers,labels,corr,size(labels,2)+2,8,4);
            end
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
            autocorr = [ autocorr diag(oo.autocorr{i}) ]; %#ok<AGROW>
        end
        if options.noprint == 0
            title = 'AUTOCORRELATION OF SIMULATED VARIABLES';
            if options.hp_filter
                title = [title ' (HP filter, lambda = ' ...
                         num2str(options.hp_filter) ')'];
            end
            headers = char('VARIABLE',int2str((1:ar)'));
            if DynareVersion >= 4.6
                dyntable(options,title,cellstr(headers),cellstr(labels),autocorr,size(labels,2)+2,8,4);
            elseif DynareVersion >= 4.5
                dyntable(options,title,headers,labels,autocorr,size(labels,2)+2,8,4);
            else
                dyntable(title,headers,labels,autocorr,size(labels,2)+2,8,4);
            end
        end
    end
catch Error
    warning(WarningState);
    rethrow(Error);
end
warning(WarningState);
