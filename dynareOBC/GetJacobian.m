function Jacobian = GetJacobian( f, x, nf )
    nx = length( x );
    seps = sqrt( eps );
    parfor i = 1 : nx
        xi = x( i );
        h = abs( seps * xi );
        while true
            if h < eps
                h = eps;
            end
            try
                Jacobian( :, i ) = ( f( SetElement( x, i, xi + h ) ) - f( SetElement( x, i, xi - h ) ) ) / ( 2 * h ); %#ok<PFBNS>
            catch
            end
            if all( isfinite( Jacobian( :, i ) ) ) || h == eps
                break;
            else
                h = 0.5 * h;
            end
        end
    end
end

function x = SetElement( x, i, xi )
    x( i ) = xi;
end
