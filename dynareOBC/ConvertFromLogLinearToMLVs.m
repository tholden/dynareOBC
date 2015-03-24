function [ ToInsertInModelAtStart, FileLines ] = ConvertFromLogLinearToMLVs( FileLines, EndoVariables, M )
    ToInsertInModelAtStart = { };
    for j = 1 : length( EndoVariables )
        for k = 1 : M.maximum_endo_lead
            string_k = int2str( k );
            ToInsertInModelAtStart{ end + 1 } = [ '#LEAD' string_k '_' EndoVariables{ j } '=exp(log_' EndoVariables{ j } '(' string_k '));' ]; %#ok<*AGROW>
        end
        for k = 1 : M.maximum_endo_lag
            string_k = int2str( k );
            ToInsertInModelAtStart{ end + 1 } = [ '#LAG' string_k '_' EndoVariables{ j } '=exp(log_' EndoVariables{ j } '(-' string_k '));' ];
        end
        ToInsertInModelAtStart{ end + 1 } = [ '#' EndoVariables{ j } '=exp(log_' EndoVariables{ j } ');' ];
    end
    for i = 1 : ( Indices.ModelStart - 1 )
        CurrentLine = FileLines{ i };
        if length( CurrentLine ) > 4 && strcmp( CurrentLine( 1:4 ), 'var ' )
            CurrentLineParts = StringSplit( CurrentLine( 5:end ), { ',', ' ' } );
            CurrentLine = [ 'var log_' strjoin( CurrentLineParts, ' log_' ) ];
        end
        FileLines{ i } = CurrentLine;
    end
    for i = ( Indices.ModelStart + 1 ) : ( Indices.ModelEnd - 1 )
        CurrentLine = FileLines{ i };
        for j = 1 : length( EndoVariables )
            for k = 1 : M.maximum_endo_lead
                string_k = int2str( k );
                CurrentLine = regexprep( CurrentLine, [ '(?<=(^|\W))' EndoVariables{ j } '\(' string_k '\)(?=\W)' ], [ 'LEAD' string_k '_' EndoVariables{ j } ] );
            end
            for k = 1 : M.maximum_endo_lag
                string_k = int2str( k );
                CurrentLine = regexprep( CurrentLine, [ '(?<=(^|\W))' EndoVariables{ j } '\(\-' string_k '\)(?=\W)' ], [ 'LAG' string_k '_' EndoVariables{ j } ] );
            end
            CurrentLine = regexprep( CurrentLine, [ '(?<=(^|\W))' EndoVariables{ j } '\(0\)(?=\W)' ], EndoVariables{ j } );
            CurrentLine = regexprep( CurrentLine, [ '(?<=(^|\W))' EndoVariables{ j } '\(\-0\)(?=\W)' ], EndoVariables{ j } );
        end
        FileLines{ i } = CurrentLine;
    end
end

