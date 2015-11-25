function dynareOBC = InitialChecks( dynareOBC )
    T = dynareOBC.InternalIRFPeriods;
    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;
    
    if ns == 0
        return
    end

    Ms = dynareOBC.MsMatrix;
    
    varsigma = sdpvar( 1, 1 );
    y = sdpvar( Ts * ns, 1 );
    
    Constraints = [ 0 <= y, y <= 1, varsigma <= Ms * y ];
    Objective = -varsigma;
    Diagnostics = optimize( Constraints, Objective, dynareOBC.LPOptions );

    ptestVal = 0;
    if Diagnostics.problem ~= 0
        error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
    end
    
    seps = sqrt( eps );
    if value( varsigma ) >= seps
        fprintf( 1, '\n' );
        disp( 'M is an S matrix, so the LCP is always feasible. This is a necessary condition for there to always be a solution.' );
        fprintf( 1, '\n' );
    else
        fprintf( 1, '\n' );
        disp( 'M is not an S matrix, so there are some q for which the LCP (q,M) has no solution.' );
        fprintf( 1, '\n' );
        ptestVal = -1;
    end

    if isempty( dynareOBC.d0s )
        disp( 'Skipping tests of the sufficient condition for feasibility with arbitrarily large T (TimeToEscapeBounds).' );
    else
        disp( 'Performing tests of the sufficient condition for feasibility with arbitrarily large T (TimeToEscapeBounds).' );
        disp( 'To skip this run dynareOBC with the FeasibilityTestGridSize=0 option.' );

        FTGC = dynareOBC.FeasibilityTestGridSize;
        
        NormInvIMinusF = dynareOBC.NormInvIMinusF;
        Norm_d0 = dynareOBC.Norm_d0;
        InvIMinusHd0s = dynareOBC.InvIMinusHd0s;
        InvIMinusHdPs = dynareOBC.InvIMinusHdPs;
        InvIMinusFdNs = dynareOBC.InvIMinusFdNs;
        dNs = dynareOBC.dNs;

        rhoF = dynareOBC.rhoF;
        rhoG = dynareOBC.rhoG;
        CF = dynareOBC.CF;
        K = dynareOBC.K;

        yInf = sdpvar( ns, 1 );

        Constraints0 = [ 0 <= y, y <= 1, 0 <= yInf, yInf <= 1 ];

        tmp = ones( 1, ns ) * Ts;
        CellMs = mat2cell( Ms, tmp, tmp );
        
        InfiniteSCondition = false;

        for i = 1 : FTGC
            for j = 1 : FTGC
                rhoFC = rhoF( i );
                rhoGC = rhoG( j );
                CFC = CF( i );
                KC = K( i, j );

                rhoFCv = rhoFC .^ ( ( 1:Ts )' );
                rhoGCv = rhoGC .^ ( ( 1:Ts )' );

                dSumIndices = bsxfun( @plus, ( 1:Ts )', (Ts-1):-1:0 );

                DenomFG_G = 1 ./ ( ( 1 - rhoFC * rhoGC ) .* ( 1 - rhoGC ) );
                DenomFG = 1 ./ ( 1 - rhoFC * rhoGC );
                DenomF = 1 ./ ( 1 - rhoFC );

                Constraints = Constraints0;
                for ConVar = 1 : ns % row index
                    Minimand1 = zeros( Ts, 1 );
                    Minimand2 = zeros( Ts, 1 );
                    Minimand3 = 0;
                    for ConShock = 1 : ns % column index
                        yC = y( ( 1:Ts ) + ( ConShock - 1 ) * Ts );
                        yInfC = yInf( ConShock );
                        Norm_d0C = Norm_d0( ConShock );
                        InvIMinusHd0sC = InvIMinusHd0s( ConVar, ConShock );
                        InvIMinusHdPsC = squeeze( InvIMinusHdPs( ConVar, ConShock, : ) );
                        InvIMinusFdNsC = squeeze( InvIMinusFdNs( ConVar, ConShock, : ) );
                        dNsC = squeeze( dNs( ConVar, ConShock, : ) );

                        Minimand1 = Minimand1 + CellMs{ ConVar, ConShock } * yC + InvIMinusHdPsC( Ts:-1:1 ) * yInfC - KC * rhoFCv * rhoGC * rhoGCv( end ) * DenomFG_G * yInfC;
                        Minimand2 = Minimand2 + ( dNsC( dSumIndices ) - KC / DenomFG * rhoFCv( end ) * rhoFCv * rhoGCv' ) * yC + ( InvIMinusFdNsC( 1 ) - InvIMinusFdNsC( 1:Ts ) ) * yInfC + InvIMinusHd0sC * yInfC - KC * rhoFCv * rhoFCv( end ) * rhoGC * rhoGCv( end ) * DenomFG_G * yInfC;
                        Minimand3 = Minimand3 - CFC * DenomF * rhoFC * rhoFCv( end ) * ( 1 - rhoFCv( end ) ) * Norm_d0C - CFC * rhoFC * rhoFCv( end ) * NormInvIMinusF * Norm_d0C * yInfC + InvIMinusFdNsC( 1 ) * yInfC + InvIMinusHd0sC * yInfC - KC * rhoFC * rhoFCv( end ) * rhoFCv( end ) * rhoGC * DenomFG_G;
                    end
                    Constraints = [ Constraints, varsigma <= Minimand1, varsigma <= Minimand2, varsigma <= Minimand3 ]; %#ok<AGROW>
                end
                Diagnostics = optimize( Constraints, Objective, dynareOBC.LPOptions );

                if Diagnostics.problem ~= 0
                    error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
                end

                if value( varsigma ) >= seps
                    fprintf( 1, '\n' );
                    disp( 'M is an S matrix for all sufficiently large T, so the LCP is always feasible for sufficiently large T. This is a necessary condition for there to always be a solution.' );
                    fprintf( 1, '\n' );
                    InfiniteSCondition = true;
                    break;
                end
            end
            if InfiniteSCondition
                break;
            end
        end

        if ~InfiniteSCondition
            fprintf( 1, '\n' );
            disp( 'M did not pass the sufficient condition to be an S matrix for all sufficiently large T, so even for large T, the LCP may not be feasible, so there may not be a solution.' );
            fprintf( 1, '\n' );
        end
    end
    fprintf( 1, '\n' );
    
    
    global ptest_use_mex

    if ptestVal >= 0
        AbsArguments = abs( angle( eig( Ms ) ) );

        if all( AbsArguments < pi - pi / size( Ms, 1 ) )
            disp( 'Necessary condition for M to be a P-matrix is satisfied.' );
            if dynareOBC.NoPTest
                disp( 'Skipping the full ptest, thus we cannot know whether there may be multiple solutions.' );
            else
                if ptest_use_mex
                    disp( 'Testing whether M is a P-matrix using the MEX version of ptest. To skip this run dynareOBC with the noptest option.' );
                    if ptest_mex( Ms )
                        ptestVal = 1;
                    else
                        ptestVal = -1;
                    end
                else
                    disp( 'Testing whether M is a P-matrix using the non-MEX version of ptest.' );
                    disp( 'To skip this run dynareOBC with the noptest option.' );
                    if ptest( Ms )
                        ptestVal = 1;
                    else
                        ptestVal = -1;
                    end
                end
            end
        else
            ptestVal = -1;
        end
    end
    if ptestVal > 0
        disp( [ 'M is a P-matrix. There is a unique solution to the model, conditional on the bound binding for less than ' int2str( dynareOBC.TimeToEscapeBounds ) ' periods.' ] );
        if ptest_use_mex
            DiagIsP = ptest_mex( dynareOBC.d0s );
        else
            DiagIsP = ptest( dynareOBC.d0s );
        end
        if DiagIsP
            disp( 'A weak necessary condition for M to be a P-matrix with arbitrarily large T (TimeToEscapeBounds) is satisfied.' );
        else
            disp( 'A weak necessary condition for M to be a P-matrix with arbitrarily large T (TimeToEscapeBounds) is not satisfied.' );
            disp( 'Thus, for sufficiently large T, M is not a P matrix. There are multiple solutions to the model in at least some states of the world.' );
            disp( 'However, due to your low choice of TimeToEscapeBounds, DynareOBC will only ever find one of these multiple solutions.' );
        end
    elseif ptestVal < 0
        disp( 'M is not a P-matrix. There are multiple solutions to the model in at least some states of the world.' );
        disp( 'The one returned will depend on the chosen value of omega.' );
    end
    fprintf( 1, '\n' );
    
    if dynareOBC.FullTest > 0
        FTS = int2str( dynareOBC.FullTest );
        MFTS = [ 'M( 1:' FTS ', 1:' FTS ' )' ];
        fprintf( 1, '\n' );
        disp( [ 'Running full test to see if ' MFTS ' is a P and/or (strictly) semi-monotone matrix.' ] );
        fprintf( 1, '\n' );
        [ MinimumDeterminant, MinimumS, MinimumS0 ] = FullTest( dynareOBC.FullTest, dynareOBC );
        if MinimumDeterminant >= 1e-8
            disp( [ MFTS ' is a P-matrix.' ] );
        else
            disp( [ MFTS ' is not a P-matrix.' ] );
        end
        if MinimumS >= 1e-8
            disp( [ MFTS ' is a strictly semi-monotone matrix.' ] );
        else
            disp( [ MFTS ' is not a strictly semi-monotone matrix.' ] );
        end
        if MinimumS0 >= 1e-8
            disp( [ MFTS ' is a semi-monotone matrix.' ] );
        else
            disp( [ MFTS ' is not a semi-monotone matrix.' ] );
        end        
    end
    
    for Tss = dynareOBC.TimeToSolveParametrically : -1 : 0
        ssIndices = vec( bsxfun( @plus, (1:Tss)', 0:Ts:((ns-1)*Ts) ) )';
        Mss = Ms( ssIndices, ssIndices );
        if min( eig( Mss + Mss' ) ) > sqrt( eps )
            break;
        end
    end

    if Tss > 0
        dynareOBC.ssIndices = ssIndices;

        PLCP = struct;
        PLCP.M = Mss;
        PLCP.q = zeros( Tss, 1 );
        PLCP.Q = eye( Tss );
        PLCP.Ath = [ eye( Tss ); -eye( Tss ) ];
        PLCP.bth = ones( 2 * Tss, 1 );

        fprintf( 1, '\n' );
        disp( 'Solving for a parametric solution over the requested domain.' );
        fprintf( 1, '\n' );
        OpenPool;
        try
            ParametricSolution = mpt_plcp( Opt( PLCP ) );
            if ParametricSolution.exitflag == 1
                try
                    ParametricSolution.xopt.toC( 'z', 'dynareOBCTempSolution' );
                    mex dynareOBCTempSolution_mex.c;
                    dynareOBC.ParametricSolutionFound = 2;
                catch
                    try
                        ParametricSolution.xopt.toMatlab( 'dynareOBCTempSolution', 'z', 'first-region' );
                        dynareOBC.ParametricSolutionFound = 1;
                    catch 
                    end
                end
            end
            rehash;
        catch
        end
    end
end
