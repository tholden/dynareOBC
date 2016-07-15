function [ MinimumDeterminant, MinimumS, MinimumS0 ] = FullTest( TM, dynareOBC )

    Ts = int64( dynareOBC.TimeToEscapeBounds );
    ns = int64( dynareOBC.NumberOfMax );
    TM = int64( TM );
    
    T = min( TM, Ts );
    O = int64( 1 );
    Indices = bsxfun( @plus, (O:T)', int64( 0 ):Ts:((ns-O)*Ts ) );
    Indices = Indices(:);
    M = dynareOBC.MsMatrix( Indices, Indices );
    
    nsT = ns * T;
    
    MinimumDeterminant = Inf;
    MinimumS = Inf;
    MinimumS0 = Inf;
    
    BreakFlag = false;

    varsigma = sdpvar( 1, 1 );
    
    fprintf( '\n' );

    for SetSize = O:nsT
        
        disp( [ 'Starting set size ' int2str( SetSize ) '.' ] );
        
        Set = O:SetSize;
        EndSet = Set + nsT - SetSize;
        
        y = sdpvar( double( SetSize ), 1 );
                
        while true
        
            % Test Set
            
            MSub = M( Indices( Set ), Indices( Set ) );
            
            MDet = det( MSub );
            if MDet < 1e-8
                fprintf( '\nSet found with determinant: %.15g\nSet indices follow:\n', MDet );
                disp( Indices( Set ) );
                fprintf( '\n' );
            end
            MinimumDeterminant = min( MinimumDeterminant, MDet );
            
            Constraints = [ 0 <= y, y <= 1, varsigma <= MSub * y ];
            Objective = -varsigma;
            Diagnostics = optimize( Constraints, Objective, dynareOBC.LPOptions );

            if Diagnostics.problem ~= 0
                error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
            end

            STestVal = value( varsigma );
            if STestVal < 1e-8
                fprintf( '\nSet found with S test value: %.15g\nSet indices follow:\n', STestVal );
                disp( Indices( Set ) );
                fprintf( '\n' );
            end
            MinimumS = min( MinimumS, STestVal );
            
            Constraints = [ 0 <= y, y <= 1, 0 <= MSub * y ];
            Objective = -sum( y );
            Diagnostics = optimize( Constraints, Objective, dynareOBC.LPOptions );

            if Diagnostics.problem ~= 0
                error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
            end

            S0TestVal = -value( Objective );
            if S0TestVal < 1e-8
                fprintf( '\nSet found with S0 test value: %.15g\nSet indices follow:\n', S0TestVal );
                disp( Indices( Set ) );
                fprintf( '\n' );
            end
            MinimumS0 = min( MinimumS0, S0TestVal );

            % Early Exit
            
            if MinimumDeterminant < 1e-8 && MinimumS < 1e-8 && MinimumS0 < 1e-8
                BreakFlag = true;
                break;
            end
        
            % Increment Set
            
            K = find( Set == EndSet, O );
            
            if isempty( K )
                Set( end ) = Set( end ) + O;
            elseif K == 1
                break;
            else
                Set( ( K - O ):SetSize ) = ( Set( K - O ) + O ):( Set( K - O ) + O + SetSize - ( K - O ) );
            end
        
        end

        fprintf( 'Completed set size %d.\nCurrent minimum determinant, S test val and S0 test val, respectively:', int2str( SetSize ) );
        disp( [ MinimumDeterminant, MinimumS, MinimumS0 ] );
        
        if BreakFlag
            break;
        end
        
    end 
        
end

