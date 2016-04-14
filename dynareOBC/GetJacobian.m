function Jacobian = GetJacobian( f, x, nf )
    nx = length( x );
    Jacobian = zeros( nf, nx );
    seps = sqrt( eps );
    parfor i = 1 : nx
        xi = x( i );
        h = abs( seps * xi );
        if h < eps
            h = eps;
        end
        Jacobian( :, i ) = ( f( SetElement( x, i, x + h ) ) - f( SetElement( x, i, x - h ) ) ) / ( 2 * h ); %#ok<PFBNS>
    end
end

function x = SetElement( x, i, xi )
    x( i ) = xi;
end
