function [ CouldBePMatrix, StartEndDet, IndicesToCheck ] = QuickPCheck( Input )
   
    O = int64( 1 );
    Length = int64( min( size( Input, 1 ), size( Input, 2 ) ) );
    
    StartEndDet = zeros( 1, 3 );
    
    IndicesToCheck = zeros( 3, 2, 'int64' );
    
    MinimumDeterminant = Inf;
    MinimumDeterminantLB = Inf;
    MinimumDeterminantUB = Inf;

    CouldBePMatrix = true;
    
    for SetStart = O:Length
        
        for SetEnd = SetStart:Length
        
            Set = SetStart:SetEnd;
            
            MSub = Input( Set, Set );
            
            [ MDet, MDetLB, MDetUB ] = RobustDeterminant( MSub );
            MoreFlag = false;
            if MDet < MinimumDeterminant
                MinimumDeterminant = MDet;
                MoreFlag = true;
                IndicesToCheck( 1, : ) = [ SetStart, SetEnd ];
                if MDet <= 0
                    CouldBePMatrix = false;
                    StartEndDet = [ double( SetStart ), double( SetEnd ), MDet ];
                end
            end
            if MDetLB < MinimumDeterminantLB
                MinimumDeterminantLB = MDetLB;
                if ~MoreFlag
                    IndicesToCheck( 2, : ) = [ SetStart, SetEnd ];
                    MoreFlag = true;
                end
            end
            if MDetUB < MinimumDeterminantUB
                MinimumDeterminantUB = MDetUB;
                if ~MoreFlag
                    IndicesToCheck( 3, : ) = [ SetStart, SetEnd ];
                    MoreFlag = true;
                end
            end
            if MoreFlag && MDetUB <= 0
                CouldBePMatrix = false;
                StartEndDet = [ double( SetStart ), double( SetEnd ), MDet ];
                break;
            end
        
        end
        
        if ~CouldBePMatrix
            break;
        end

    end 
    
end
