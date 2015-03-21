function Combinations = GenerateCombinations( Length, MaximumOrder, LessOrEqual )
    if nargin < 2
        MaximumOrder = Length;
    end
    if nargin < 3
        LessOrEqual = 0;
    end
    Combinations = zeros( 0, Length );
    CurrentCombination = zeros( 1, Length );
    while CurrentCombination( Length ) <= MaximumOrder
        if ( sum( CurrentCombination ) == MaximumOrder ) || ( ( sum( CurrentCombination ) <= MaximumOrder ) && LessOrEqual )
            Combinations = [ Combinations; CurrentCombination ]; %#ok<AGROW>
        end
        CurrentCombination( 1 ) = CurrentCombination( 1 ) + 1;
        for i = 1 : ( Length - 1 )
            if CurrentCombination( i ) > MaximumOrder
                CurrentCombination( i + 1 ) = CurrentCombination( i + 1 ) + 1;
                CurrentCombination( 1 : i ) = 0;
            end
        end
    end
    Combinations = sortrows( Combinations );
    Combinations = Combinations( end:(-1):1, : );
end
