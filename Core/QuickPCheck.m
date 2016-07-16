function [ CouldBePMatrix, StartEndDet ] = QuickPCheck( Input )
   
    O = int64( 1 );
    Length = int64( min( size( Input, 1 ), size( Input, 2 ) ) );
    
    StartEndDet = zeros( 1, 3 );
    
    CouldBePMatrix = true;
    
    for SetStart = O:Length
        
        for SetEnd = SetStart:Length
        
            Set = SetStart:SetEnd;
            
            MSub = Input( Set, Set );
            
            MDet = RobustDeterminant( MSub );
            
            if MDet <= 0
                CouldBePMatrix = false;
                StartEndDet( 1 ) = SetStart;
                StartEndDet( 2 ) = SetEnd;
                StartEndDet( 3 ) = MDet;
                break;
            end
        
        end
        
        if ~CouldBePMatrix
            break;
        end

    end 
    
end
