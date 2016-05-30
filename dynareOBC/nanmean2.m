function out = nanmean2( in )
    out = nanmean( in );
    if isempty( out )
        out = NaN( 1, size( in, 2 ) );
    end
end
