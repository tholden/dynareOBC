function [ x, f ] = FMinBndWrapper( OptiFunction, x, lb, ub, varargin )
    Options = optimset( 'MaxFunEvals', Inf, 'MaxIter', Inf, 'TolX', 1e-10 );
    for i = 1 : 2 : length( varargin )
        Options.( varargin{ i } ) = varargin{ i + 1 };
    end
    n = length( x );
    if n == 1
        Options = optimset( Options, 'display', 'iter' );
        [ x, f ] = FMinBndInternal( OptiFunction, lb, ub, Options );
    else
        Options = optimset( Options, 'display', 'off' );
        Iter = 1;
        fprintf( '\nInitial evaluation.\n' );
        f = OptiFunction( x );
        fprintf( 'Initial f: %.15g\n', f );
        while true
            fprintf( 'Parallel step %d.\n', Iter );
            xPNew = zeros( n, 1 );
            fPNew = zeros( n, 1 );
            uBound = zeros( n, 1 );
            parfor i = 1 : n
                [ xPNew( i ), fPNew( i ) ] = FMinBndInternal( @( xi ) OptiFunction( SetCoefficient( x, i, xi ) ), lb( i ), ub( i ), Options ); %#ok<PFBNS>
                Denom = xPNew( i ) - x( i );
                if Denom >= 0
                    uBound( i ) = ( ub( i ) - x( i ) ) / Denom;
                else
                    uBound( i ) = ( lb( i ) - x( i ) ) / Denom;
                end
            end
            [ fPNewBest, fPNewBestIndex ] = min( fPNew );
            xPNewBest = SetCoefficient( x, fPNewBestIndex, xPNew( fPNewBestIndex ) );
            fprintf( 'Serial step %d.\n', Iter );
            [ xNew, fNew ] = FMinBndInternal( @( u ) OptiFunction( ( 1 - u ) * x + u * xPNew ), 0, min( uBound ), Options );
            if fNew > fPNewBest
                xNew = xPNewBest;
                fNew = fPNewBest;
            end
            BreakCondition = max( abs( x - xNew ) ) < 1e-10 || fNew > f - 1e-8;
            x = xNew;
            f = fNew;
            if BreakCondition
                return
            end
        end
    end
end

function x = SetCoefficient( x, i, xi )
    x( i ) = xi;
end

function [ x, f ] = FMinBndInternal( OptiFunction, lb, ub, Options )
    if isfinite( lb )
        if isfinite( ub )
            [ x, f ] = fminbnd( OptiFunction, lb, ub, Options );
        else
            [ u, f ] = fminbnd( @( u ) OptiFunction( lb - log( 1 - u ) ), 0, 1, Options );
            x = lb - log( 1 - u );
        end
    else
        if isfinite( ub )
            [ u, f ] = fminbnd( @( u ) OptiFunction( ub + log( u ) ), 0, 1, Options );
            x = ub + log( u );
        else
            [ u, f ] = fminbnd( @( u ) OptiFunction( log( u ) - log( 1 - u ) ), 0, 1, Options );
            x = log( u ) - log( 1 - u );
        end
    end
end
