function ReturnStruct = ExpectedReturn( InitialStateOrShock, M, dr, dynareOBC )

    SelectState = dynareOBC.SelectState;
    T = dynareOBC.InternalIRFPeriods;
    
    if isstruct( InitialStateOrShock )
        % then we are being called from SimulateModel and InitialStateOrModel is the InitialState
        InitialState = InitialStateOrShock;
        y1 = InitialState.first( dr.order_var );   
        if dynareOBC.Order > 1
            y1s = y1( SelectState );
            y2 = InitialState.second( dr.order_var );
            y1s2 = spkron( y1s, y1s );
            z2 = [ y1; y2; y1s2 ];
            if dynareOBC.Order > 2
                z = [ z2; InitialState.first_sigma_2( dr.order_var ); InitialState.third( dr.order_var ); spkron( y2( SelectState ), y1s ); spkron( y1s2, y1s ) ];
            else
                z = z2;
            end
        else
            z = y1;
        end
    else
        % then we are being called from FastIRFs and InitialStateOrShock is the Shock
        Shock = InitialStateOrShock;
        z = dynareOBC.Mean_z;
        
        nEndo = M.endo_nbr;
        nState = length( SelectState );
        
        % derived from pruning_abounds.m
        
        i1 = nEndo;
        % y1o = z( 1:i1 );
        % y1os = y1o( SelectState );
        
        ghuTShock = dr.ghu * Shock;
        y1 = ghuTShock;
        
        if dynareOBC.Order > 1
            
            i2 = i1 + nEndo;
            y2o = z( (i1+1):i2 );
            y2os = y2o( SelectState );
            
            ShockKShock = spkron( Shock, Shock );
            y2 = y2o + 0.5 * ( dr.ghuu * ShockKShock );
            
            nState2 = nState * nState;
            i3 = i2 + nState2;
            y1sKy1so = z( (i2+1):i3 );
            
            ghusTShock = ghuTShock( SelectState );
            y1sKy1s = y1sKy1so + spkron( ghusTShock, ghusTShock );
            
            z2 = [ y1; y2; y1sKy1s ];
            
            if dynareOBC.Order > 2

                ghuss_nlma = dr.ghuss_nlma;
                
                i4 = i3 + nEndo;
                y1sigma2o = z( (i3+1):i4 );
                
                y1sigma2 = y1sigma2o + 0.5 * ( ghuss_nlma * Shock );
                
                i5 = i4 + nEndo;
                y3o = z( (i4+1):i5 );
                
                nExo = M.exo_nbr;
                nExo2 = nExo * nExo;
                nExo3 = nExo2 * nExo;
                ShockKShockKShock = ( speye( nExo3 ) + spkron( speye( nExo ), commutation_sparse( nExo, nExo ) ) + commutation_sparse( nExo, nExo2 ) ) * spkron( vec( M.Sigma_e ), Shock ) + spkron( ShockKShock, Shock );
                y3 = y3o + (1/6) * ( dr.ghuuu * ShockKShockKShock ) + 0.5 * ( dr.ghxxu * spkron( y1sKy1so, Shock ) ) + dr.ghxu * spkron( y2os, Shock );
                                    
                i6 = i5 + nState2;
                y2sKy1so = z( (i5+1):i6 );
                
                % simulation_first(:,t) = dr.ghx*simulation_first(select_state,t-1)+dr.ghu*E(:,t-1);
                % simulation_second(:,t) = dr.ghx*simulation_second(select_state,t-1) +(1/2)*( dr.ghxx*sxs+2*dr.ghxu*sxe+dr.ghuu*exe );
                
                % TODO: Replace by kron class.
                
                ghxs = dr.ghx( SelectState, : );
                ghus = dr.ghu( SelectState, : );
                y2sKy1s = y2sKy1so + spkron( ghxs * y2os, ghusTShock ) + 0.5 * spkron( dr.ghxx( SelectState, : ) * y1sKy1so, ghusTShock ) ...
                                   + spkron( dr.ghxu( SelectState, : ), ghxs ) * spkron( speye( nState ), commutation_sparse( nExo, nState ) ) * spkron( y1sKy1so, Shock ) ...
                                   + 0.5 * spkron( dr.ghuu( SelectState, : ), ghus ) * ShockKShockKShock;
                
                % nState3 = nState2 * nState;
                % i7 = i6 + nState3;
                % y1sKy1sKy1so = z( (i6+1):i7 );
                
                y1sKy1sKy1s = ( spkron( speye( nState ), speye( nState2 ) + commutation_sparse( nState, nState ) ) + commutation_sparse( nState, nState2 ) ) * spkron( spkron( ghxs, ghxs ), ghus ) * spkron( y1sKy1so, Shock ) ...
                            + spkron( spkron( ghus, ghus ), ghus ) * ShockKShockKShock;
                        
                z = [ z2; y1sigma2; y3; y2sKy1s; y1sKy1sKy1s ];
            else
                z = z2;
            end
            
        else
            z = y1;
        end
    end
    
    Length_z = size( z, 1 );
    
    zPath = zeros( Length_z, T );
    zPath( :, 1 ) = z;
    
    c = dynareOBC.c;
    A = dynareOBC.A;
    
    for i = 2 : T
        % z( (i6+1):end ) = 0;
        z = c + A * z;
        zPath( :, i ) = z;
    end
    
    ReturnStruct = struct;
    ReturnStruct.first = zPath( dr.inv_order_var, : );
    ReturnStruct.total = bsxfun( @plus, ReturnStruct.first, dynareOBC.Constant );
    
    if dynareOBC.Order > 1
        ReturnStruct.second = zPath( length( y1 ) + dr.inv_order_var, : );
        ReturnStruct.total = ReturnStruct.total + ReturnStruct.second;
        if dynareOBC.Order > 2
            ReturnStruct.first_sigma_2 = zPath( length( z2 ) + dr.inv_order_var, : );
            ReturnStruct.third = zPath( length( y1 ) + length( z2 ) + dr.inv_order_var, : );
            ReturnStruct.total = ReturnStruct.total + ReturnStruct.first_sigma_2 + ReturnStruct.third;
        end
    end

end

