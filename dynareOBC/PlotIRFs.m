function PlotIRFs( M, options, oo, dynareOBC )

    % code derived from stoch_simul.m
    
    T = dynareOBC.IRFPeriods;
    
    options.nodisplay = dynareOBC.NoDisplay;
    
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
            hh = dyn_figure(options,'Name',['Orthogonalized shock to ' CurrentShock]);
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
            dyn_saveas(hh,[dynareOBC.BaseFileName '_IRF_' CurrentShock],options);
        else
            for fig = 1:nbplt-1
                hh = dyn_figure(options,'Name',['Orthogonalized shock to ' CurrentShock ' figure ' int2str(fig)]);
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
                dyn_saveas(hh,[ dynareOBC.BaseFileName '_IRF_' CurrentShock int2str(fig)],options);
            end
            hh = dyn_figure(options,'Name',['Orthogonalized shock to ' CurrentShock ' figure ' int2str(nbplt)]);
            m = 0;
            for plt = 1:number_of_plots_to_draw-(nbplt-1)*nstar;
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
            dyn_saveas(hh,[ dynareOBC.BaseFileName '_IRF_' CurrentShock int2str(nbplt) ],options);
        end        
    end

end

