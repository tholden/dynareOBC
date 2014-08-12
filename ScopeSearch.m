function [ index, comma ] = ScopeSearch( string, index, step )
    brackets = 0;
    comma = 0;
    while index >= 1 && index <= length( string )
        switch string( index ) 
            case '('
                brackets = brackets + step;
            case ')'
                brackets = brackets - step;
            case ','
                if brackets == 0
                    comma = index;
                end
            otherwise
        end
        if brackets == -1
            index = index - step;
            return
        end
        index = index + step;
    end
    index = index - step;
end
