function [ IsPMatrix, IndicesToCheck ] = AltPTest( Input, Verbose )
   
    O = int64( 1 );
    Length = int64( min( size( Input, 1 ), size( Input, 2 ) ) );
    
    MinimumDeterminant = Inf;
    MinimumDeterminantLB = Inf;
    MinimumDeterminantUB = Inf;

    BreakFlag = false;

    if Verbose
        fprintf( '\n' );
    end
    
    IndicesToCheck = cell( 3, 1 );
    IndicesToCheck{1} = zeros( 1, 0, 'int64' );
    IndicesToCheck{2} = zeros( 1, 0, 'int64' );
    IndicesToCheck{3} = zeros( 1, 0, 'int64' );
    
    for SetSize = O:Length
        
        if Verbose
            fprintf( '\nStarting set size %d.\n', SetSize );
        end
        
        Set = O:SetSize;
        EndSet = Set + Length - SetSize;
        
        while true
        
            % Test Set
            
            MSub = Input( Set, Set );
            
            [ MDet, MDetLB, MDetUB ] = RobustDeterminant( MSub );
            MoreFlag = false;
            if MDet < MinimumDeterminant
                MinimumDeterminant = MDet;
                MoreFlag = true;
                IndicesToCheck{1} = Set;
            end
            if MDetLB < MinimumDeterminantLB
                MinimumDeterminantLB = MDetLB;
                if ~MoreFlag
                    IndicesToCheck{2} = Set;
                    MoreFlag = true;
                end
            end
            if MDetUB < MinimumDeterminantUB
                MinimumDeterminantUB = MDetUB;
                if ~MoreFlag
                    IndicesToCheck{3} = Set;
                    MoreFlag = true;
                end
            end
            if MoreFlag
                if MDet < 1e-6
                    if Verbose
                        fprintf( '\nSet found with determinant range: %.15g %.15g %.15g\nSet indices follow:\n', MDetLB, MDet, MDetUB );
                        for idx = O : int64( numel( Set ) )
                            fprintf( '%d\n', Set( idx ) );
                        end
                        fprintf( '\n' );
                    end
                    if MDetUB <= 0
                        BreakFlag = true;
                        break
                    end
                end
            end
                   
            % Increment Set
            
            K = int64( find( Set == EndSet, O ) );
            
            if isempty( K )
                Set( end ) = Set( end ) + O;
            elseif K( 1 ) == O
                break
            else
                Set( ( K( 1 ) - O ):SetSize ) = ( Set( K( 1 ) - O ) + O ):( Set( K( 1 ) - O ) + O + SetSize - ( K( 1 ) - O ) );
            end
        
        end

        if Verbose
            fprintf( '\nCompleted set size %d.\nCurrent minimum determinant range: %.15g  %.15g %.15g\n', SetSize, MinimumDeterminantLB, MinimumDeterminant, MinimumDeterminantUB );
        end
        
        if BreakFlag
            break
        end
        
    end 
    
    IsPMatrix = MinimumDeterminant > 0;
        
end
