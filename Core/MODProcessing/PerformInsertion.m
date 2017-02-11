function [ FileLines, Indices ] = PerformInsertion( ToInsert, InsertLocation, FileLines, Indices )
    FileLines = [ FileLines( 1:(InsertLocation-1) ) ToInsert FileLines( InsertLocation:end ) ];
    IndicesFields = fieldnames( Indices );
    InsertLength = length( ToInsert );
    for i = 1 : length( IndicesFields )
        if Indices.( IndicesFields{ i } ) >= InsertLocation
            Indices.( IndicesFields{ i } ) = Indices.( IndicesFields{ i } ) + InsertLength;
        end
    end
end
