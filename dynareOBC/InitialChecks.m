function dynareOBC = InitialChecks( dynareOBC )
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
    
    if value( varsigma ) >= 1e-8
        skipline( );
        disp( 'M is an S matrix, so the LCP is always feasible. This is a necessary condition for there to always be a solution.' );
        skipline( );
    else
        skipline( );
        disp( 'M is not an S matrix, so there are some q for which the LCP (q,M) has no solution.' );
        skipline( );
        ptestVal = -1;
    end
    
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
                    disp( 'Testing whether M is a P-matrix using the non-MEX version of ptest. To skip this run dynareOBC with the noptest option.' );
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
        disp( 'M is a P-matrix. There is at most one solution to the model.' );
    elseif ptestVal < 0
        disp( 'M is not a P-matrix. There are multiple solutions to the model in at least some states of the world.' );
        disp( 'The one returned will depend on the chosen value of omega.' );
    end
    skipline();
    
    if dynareOBC.FullTest > 0
        FTS = int2str( dynareOBC.FullTest );
        MFTS = [ 'M( 1:' FTS ', 1:' FTS ' )' ];
        skipline();
        disp( [ 'Running full test to see if ' MFTS ' is a P and/or (strictly) semi-monotone matrix.' ] );
        skipline();
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

        skipline( );
        disp( 'Solving for a parametric solution over the requested domain.' );
        skipline( );
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
