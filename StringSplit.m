function OutputCellArray = StringSplit( String, CellArrayOfDelimiters, varargin )
% A version of strsplit which removes empty strings from the result
    OutputCellArray = strsplit( String, CellArrayOfDelimiters, varargin{:} );
    OutputCellArray( strcmp('',OutputCellArray) ) = [];
end

