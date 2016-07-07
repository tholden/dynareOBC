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

    for SetSize = O:nsT
        
        disp( [ 'Starting set size ' int2str( SetSize ) '.' ] );
        
        Set = O:SetSize;
        EndSet = Set + nsT - SetSize;
        
        y = sdpvar( double( SetSize ), 1 );
                
        while true
        
            % Test Set
            
            MSub = M( Indices( Set ), Indices( Set ) );
            
            MDet = det( MSub );
            MinimumDeterminant = min( MinimumDeterminant, MDet );
            
            Constraints = [ 0 <= y, y <= 1, varsigma <= MSub * y ];
            Objective = -varsigma;
            Diagnostics = optimize( Constraints, Objective, dynareOBC.LPOptions );

            if Diagnostics.problem ~= 0
                error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
            end

            MinimumS = min( MinimumS, value( varsigma ) );
            
            Constraints = [ 0 <= y, y <= 1, 0 <= MSub * y ];
            Objective = -sum( y );
            Diagnostics = optimize( Constraints, Objective, dynareOBC.LPOptions );

            if Diagnostics.problem ~= 0
                error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
            end

            MinimumS0 = min( MinimumS0, -value( Objective ) );

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

        disp( [ 'Completed set size ' int2str( SetSize ) '. Current values:' ] );
        disp( [ MinimumDeterminant, MinimumS, MinimumS0 ] );
        
        if BreakFlag
            break;
        end
        
    end 
        
end

