function PlotIRFs( M, options, oo, dynareOBC )

    % code derived from stoch_simul.m
    
    T = dynareOBC.IRFPeriods;
    
    NoDisplay = dynareOBC.NoDisplay;
    GraphFormat = options.graph_format;
    
    for i = dynareOBC.ShockSelect
        CurrentShock = deblank( M.exo_names( i, : ) );
        IRFs = zeros( 0, T );
        IRFsWithoutBounds = zeros( 0, T );
        IRFOffsets = zeros( 0, T );
        VariableNames = { };
        for j = dynareOBC.VariableSelect
            CurrentVariable = deblank( M.endo_names( j, : ) );
            IRFName = [ CurrentVariable '_' CurrentShock ];
            if isfield( oo.irfs, IRFName )
                CurrentIRF = oo.irfs.( IRFName );
                if max( abs( CurrentIRF ) ) > options.impulse_responses.plot_threshold
                    VariableNames{ end + 1 } = CurrentVariable; %#ok<AGROW>
                    CurrentIRFOffset = dynareOBC.IRFOffsets.( IRFName )( 1:T );
                    IRFOffsets( end + 1, : ) = CurrentIRFOffset; %#ok<AGROW>
                    IRFs( end + 1, : ) = CurrentIRFOffset + CurrentIRF; %#ok<AGROW>
                    IRFsWithoutBounds( end + 1, : ) = CurrentIRFOffset + dynareOBC.IRFsWithoutBounds.( IRFName ); %#ok<AGROW>
                end
            end
        end
        for j = dynareOBC.MLVSelect
            CurrentVariable = dynareOBC.MLVNames{j};
            IRFName = [ CurrentVariable '_' CurrentShock ];
            if isfield( oo.irfs, IRFName )
                CurrentIRF = oo.irfs.( IRFName );
                if max( abs( CurrentIRF ) ) > options.impulse_responses.plot_threshold
                    VariableNames{ end + 1 } = CurrentVariable; %#ok<AGROW>
                    CurrentIRFOffset = dynareOBC.IRFOffsets.( IRFName )( 1:T );
                    IRFOffsets( end + 1, : ) = CurrentIRFOffset; %#ok<AGROW>
                    IRFs( end + 1, : ) = CurrentIRFOffset + CurrentIRF; %#ok<AGROW>
                    IRFsWithoutBounds( end + 1, : ) = CurrentIRFOffset + dynareOBC.IRFsWithoutBounds.( IRFName ); %#ok<AGROW>
                end
            end
        end
                
        number_of_plots_to_draw = size(IRFs,1);
        [nbplt,nr,nc,lr,lc,nstar] = pltorg(number_of_plots_to_draw);
        if nbplt == 0
        elseif nbplt == 1
            hh = OpenFigure(NoDisplay,'Name',['Orthogonalized shock to ' CurrentShock]);
            for j = 1:number_of_plots_to_draw
                subplot(nr,nc,j);
                plot(1:T,transpose(IRFs(j,:)),'-k','linewidth',1);
                hold on
                plot(1:T,transpose(IRFsWithoutBounds(j,:)),':k','linewidth',1);
                plot(1:T,transpose(IRFOffsets(j,:)),'-r','linewidth',0.5);
                hold off
                xlim([1 T]);
                title(VariableNames{j},'Interpreter','none');
            end
            SaveFigure(hh,[dynareOBC.BaseFileName '_IRF_' CurrentShock],NoDisplay,GraphFormat);
        else
            for fig = 1:nbplt-1
                hh = OpenFigure(NoDisplay,'Name',['Orthogonalized shock to ' CurrentShock ' figure ' int2str(fig)]);
                for plt = 1:nstar
                    subplot(nr,nc,plt);
                    j = (fig-1)*nstar+plt;
                    plot(1:T,transpose(IRFs(j,:)),'-k','linewidth',1);
                    hold on
                    plot(1:T,transpose(IRFsWithoutBounds(j,:)),':k','linewidth',1);
                    plot(1:T,transpose(IRFOffsets(j,:)),'-r','linewidth',0.5);
                    hold off
                    xlim([1 T]);
                    title(VariableNames{j},'Interpreter','none');
                end
                SaveFigure(hh,[ dynareOBC.BaseFileName '_IRF_' CurrentShock int2str(fig)],NoDisplay,GraphFormat);
            end
            hh = OpenFigure(NoDisplay,'Name',['Orthogonalized shock to ' CurrentShock ' figure ' int2str(nbplt)]);
            m = 0;
            for plt = 1:number_of_plots_to_draw-(nbplt-1)*nstar
                m = m+1;
                subplot(lr,lc,m);
                j = (nbplt-1)*nstar+plt;
                plot(1:T,transpose(IRFs(j,:)),'-k','linewidth',1);
                hold on
                plot(1:T,transpose(IRFsWithoutBounds(j,:)),':k','linewidth',1);
                plot(1:T,transpose(IRFOffsets(j,:)),'-r','linewidth',0.5);
                hold off
                xlim([1 T]);
                title(VariableNames{j},'Interpreter','none');
            end
            SaveFigure(hh,[ dynareOBC.BaseFileName '_IRF_' CurrentShock int2str(nbplt) ],NoDisplay,GraphFormat);
        end        
    end

end

function h = OpenFigure( NoDisplay, varargin )

% Copyright (C) 2012-2017 Dynare Team
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

    if NoDisplay
        h = figure( varargin{:}, 'visible', 'off' );
    else
        h = figure( varargin{:} );
    end

end

function SaveFigure( h, FileName, NoDisplay, GraphFormat )

% Copyright (C) 2012-2017 Dynare Team
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

    if any(strcmp('eps',cellstr(GraphFormat)))
        if isoctave
            FileName = strrep(FileName,'/',filesep);
            FileName = strrep(FileName,'\',filesep);
            if NoDisplay && ispc
                set(h, 'Visible','on');
            end
        end
        print(h,'-depsc2',[FileName,'.eps'])
    end
    if any(strcmp('pdf',cellstr(GraphFormat)))
        if isoctave
            error('Octave cannot create pdf files!')
        else
            print(h,'-dpdf',[FileName,'.pdf'])
        end
    end
    if any(strcmp('fig',cellstr(GraphFormat)))
        if isoctave
            error('Octave cannot create fig files!')
        else
            if NoDisplay
                %  THE FOLLOWING LINES COULD BE USED IF BUGS/PROBLEMS ARE REPORTED USING LINE 60
                %             set(h,'Units','Normalized')
                %             mypos=get(h,'Position');
                %             set(h,'Position',[-1 -1 mypos(3:4)])
                %             set(h, 'Visible','on');
                set(h,'CreateFcn','set(gcf, ''Visible'',''on'')') ;
            end
            saveas(h,[FileName '.fig']);
        end
    end
    if any(strcmp('none',cellstr(GraphFormat)))
        % don't save
        % check here as a reminder that none is an option to graph_format
    end
    if NoDisplay
        close(h);
    end

end

