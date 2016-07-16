function IsPMatrix = AltPTest( Input, Verbose )
   
    O = int64( 1 );
    Length = int64( min( size( Input, 1 ), size( Input, 2 ) ) );
    
    MinimumDeterminant = realmax;

    BreakFlag = false;

    if Verbose
        fprintf( '\n' );
    end
    
    for SetSize = O:Length
        
        if Verbose
            fprintf( '\nStarting set size %d.\n', SetSize );
        end
        
        Set = O:SetSize;
        EndSet = Set + Length - SetSize;
        
        while true
        
            % Test Set
            
            MSub = Input( Set, Set );
            
            MDet = det( MSub );
            if MDet < MinimumDeterminant
                MinimumDeterminant = MDet;
                if MDet < 1e-6
                    if Verbose
                        fprintf( '\nSet found with determinant: %.15g\nSet indices follow:\n', MDet );
                        for idx = O : int64( numel( Set ) )
                            fprintf( '%d\n', Set( idx ) );
                        end
                        fprintf( '\n' );
                    end
                    if MDet < 0
                        BreakFlag = true;
                        break;
                    end
                end
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

        if Verbose
            fprintf( 'Completed set size %d.\nCurrent minimum determinant: %.15g\n', SetSize, MinimumDeterminant );
        end
        
        if BreakFlag
            break;
        end
        
    end 
    
    IsPMatrix =  MinimumDeterminant < 1e-6;
        
end
