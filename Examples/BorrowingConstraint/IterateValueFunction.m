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
        V0max = -Inf;
        V1min = Inf;
        V2max = -Inf;
        for iB = 1 : nB
            % V1minNew = V1min + V2maxNew >= V1min + V2max
            % V1minNew <= V1min
            % V0maxNew = V0max + V1minNew
            % V0max + V1min + V2max <= V0maxNew <= V0max + V1min
            % V0maxNew = max( V0max + V1min + V2max, min( V0max + V1min, Vtmp( iA, iB ) ) );
            % V1minNew = V0maxNew - V0max; % V1minNew = max( V1min + V2max, min( V1min, Vtmp( iA, iB ) - V0max ) );
            % V2maxNew = V1minNew - V1min; % V2maxNew = max( V2max, min( 0, Vtmp( iA, iB ) - V0max - V1min ) );
            % V0max = V0maxNew;
            % V1min = V1minNew;
            % V2max = V2maxNew;
            V2max = max( V2max, min( 0, Vtmp( iA, iB ) - V0max - V1min ) );
            V1min = V1min + V2max;
            V0max = V0max + V1min;
            Vnew( iA, iB ) = V0max;
        end
    end
    Vnew = cummax( Vnew );
    Xnew = cummax( Xnew );
    Vtmp = abs( Vtmp - Vnew );
    Vtmp = Vtmp(:);
    Verr = max( Vtmp );
end
