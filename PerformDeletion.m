function [ FileLines, Indices ] = PerformDeletion( DeleteStart, DeleteEnd, FileLines, Indices )
    if DeleteStart <= 0 || DeleteEnd <= 0
        return
    end
    FileLines = [ FileLines( 1:(DeleteStart-1) ) FileLines( (DeleteEnd+1):end ) ];
    IndicesFields = fieldnames( Indices );
    DeletionLength = DeleteEnd - DeleteStart + 1;
    for i = 1 : length( IndicesFields )
        if Indices.( IndicesFields{ i } ) >= DeleteStart
            if Indices.( IndicesFields{ i } ) > DeleteEnd
                Indices.( IndicesFields{ i } ) = Indices.( IndicesFields{ i } ) - DeletionLength;
            else
                Indices.( IndicesFields{ i } ) = 0;
            end
        end
    end
end