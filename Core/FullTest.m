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
    
    MinimumDeterminant = realmax;
    MinimumS = realmax;
    MinimumS0 = realmax;
    
    BreakFlag = false;

    varsigma = sdpvar( 1, 1 );
    
    fprintf( '\n' );

    for SetSize = O:nsT
        
        fprintf( '\nStarting set size %d.', SetSize );
        
        Set = O:SetSize;
        EndSet = Set + nsT - SetSize;
        
        y = sdpvar( double( SetSize ), 1 );
                
        while true
        
            % Test Set
            
            MSub = M( Set, Set );
            
            MDet = det( MSub );
            if MDet < MinimumDeterminant
                MinimumDeterminant = MDet;
                if MDet < 1e-6
                    fprintf( '\nSet found with determinant: %.15g\nSet indices follow:\n', MDet );
                    fprintf( '%d\n', Indices( Set ) );
                    fprintf( '\n' );
                end
            end
            
            Constraints = [ 0 <= y, y <= 1, varsigma <= MSub * y ];
            Objective = -varsigma;
            Diagnostics = optimize( Constraints, Objective, dynareOBC.LPOptions );

            if Diagnostics.problem ~= 0
                error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
            end

            STestVal = value( varsigma );
            if STestVal < MinimumS
                MinimumS = STestVal;
                if STestVal < 1e-6
                    fprintf( '\nSet found with S test value: %.15g\nSet indices follow:\n', STestVal );
                    fprintf( '%d\n', Indices( Set ) );
                    fprintf( '\n' );
                end
            end
            
            Constraints = [ 0 <= y, y <= 1, 0 <= MSub * y ];
            Objective = -sum( y );
            Diagnostics = optimize( Constraints, Objective, dynareOBC.LPOptions );

            if Diagnostics.problem ~= 0
                error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
            end

            S0TestVal = -value( Objective );
            if S0TestVal < MinimumS0
                MinimumS0 = S0TestVal;
                if S0TestVal < 1e-6
                    fprintf( '\nSet found with S0 test value: %.15g\nSet indices follow:\n', S0TestVal );
                    fprintf( '%d\n', Indices( Set ) );
                    fprintf( '\n' );
                end
            end

            % Early Exit
            
            if MinimumDeterminant < 0 && MinimumS < 1e-6 && MinimumS0 < 1e-6
                BreakFlag = true;
                break;
            end
        
            % Increment Set
            
            K = int64( find( Set == EndSet, O ) );
            
            if isempty( K )
                Set( end ) = Set( end ) + O;
            elseif K( 1 ) == O
                break;
            else
                Set( ( K( 1 ) - O ):SetSize ) = ( Set( K( 1 ) - O ) + O ):( Set( K( 1 ) - O ) + O + SetSize - ( K( 1 ) - O ) );
            end
        
        end

        fprintf( 'Completed set size %d.\nCurrent minimum determinant: %.15g\nCurrent S test val: %.15g\nCurrent S0 test val: %.15g\n', SetSize, MinimumDeterminant, MinimumS, MinimumS0 );
        
        if BreakFlag
            break;
        end
        
    end 
        
end

