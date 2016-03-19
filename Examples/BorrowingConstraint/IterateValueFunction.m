function [ Vnew, Xnew, Verr ] = IterateValueFunction( V, X, XB, W, Bv, Av, beta, Ybar, R, UseTightBounds )
    nB = length( Bv );
    nA = length( Av );
    Vtmp = coder.nullcopy( V );
    Xnew = coder.nullcopy( X );
    parfor iA = 1 : nA
        A = Av( iA );
        Wv = W( :, iA );
        Xmax = 0;
        for iB = 1 : nB
            B = Bv( iB ); %#ok<PFBNS>
            XL = Xmax;
            XU = XB( iA, iB );
            if UseTightBounds
                if iA > 1
                    XL = max( XL, X( iA - 1, iB ) );
                end
                if iB > 1
                    XL = max( XL, X( iA, iB - 1 ) );
                end
                if iA < nA
                    XU = min( XU, X( iA + 1, iB ) );
                end
                if iB < nB
                    XU = min( XU, X( iA, iB + 1 ) );
                end
            end
            XU = max( XL, XU );
            [ Vtmp( iA, iB ), Xmax ] = EvaluateValueFunctionAtPoint( B, A, Wv, Bv, V, XL, X( iA, iB ), XU, beta, Ybar, R ); %#ok<PFBNS>
            Xnew( iA, iB ) = Xmax;
        end
    end
    Vnew = coder.nullcopy( Vtmp );
    parfor iA = 1 : nA
        V0min = 0;
        V1min = 0;
        V2min = 0;
        for iB = nB : -1 : 1
            if iB < nB - 1
                V2min = min( V2min, Vtmp( iA, iB ) - V0min - V1min );
                V1min = V1min + V2min; % = min( V1min + V2min, Vtmp( iA, iB ) - V0min) );
                V0min = V0min + V1min; % = min( V0min + V1min + V2min, Vtmp( iA, iB ) );
            elseif iB == nB - 1
                V1min = min( 0, Vtmp( iA, iB ) - V0min );
                V0min = V0min + V1min; % = min( V0min, Vtmp( iA, iB ) );
            else % iB == nB
                V0min = Vtmp( iA, iB );
            end
            Vnew( iA, iB ) = V0min;
        end
    end
    Vnew = cummax( Vnew );
    Xnew = cummax( Xnew );
    Vtmp = abs( Vtmp - Vnew );
    Vtmp = Vtmp(:);
    Verr = max( Vtmp );
end
