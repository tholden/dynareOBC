function dynareOBC = InitialChecks( dynareOBC )
    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;
    
    if ns == 0
        return
    end

    Ms = dynareOBC.MsMatrix;
    
    varsigma = sdpvar( 1, 1 );
    y = sdpvar( Ts * ns, 1 );
    
    MsScale = 1e4 ./ norm( Ms, Inf );
    scaledMs = MsScale * Ms;
    
    Constraints = [ 0 <= y, y <= 1, varsigma <= scaledMs * y ];
    Objective = -varsigma;
    Diagnostics = optimize( Constraints, Objective, dynareOBC.LPOptions );
    
    if Diagnostics.problem ~= 0
        error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
    end
    
    vy = value( y );
    vy = max( 0, vy ./ max( 1, max( vy ) ) );
    new_varsigma = min( scaledMs * vy );

    AltConstraints = [ 0 <= y, y <= 1, y' * scaledMs <= 0 ];
    AltObjective = -ones( 1, Ts * ns ) * y;
    AltDiagnostics = optimize( AltConstraints, AltObjective, dynareOBC.LPOptions );

    if AltDiagnostics.problem ~= 0
        warning( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' AltDiagnostics.info ] );
        new_sum_y = 0;
    else
        vy = value( y );
        vy = max( 0, vy ./ max( 1, max( vy ) ) );
        new_sum_y = sum( vy );
    end
    
    ptestVal = 0;

    vvarsigma = value( varsigma );
    if new_varsigma > 0 % && new_sum_y <= 1e-6
        fprintf( '\n' );
        disp( 'M is an S matrix, so the LCP is always feasible. This is a necessary condition for there to always be a solution.' );
        disp( 'varsigma bounds (positive means M is an S matrix):' );
        disp( [ new_varsigma vvarsigma ] );
        disp( 'sum of y from the alternative problem (zero means M is an S matrix):' );
        disp( new_sum_y );
        fprintf( '\n' );
        SkipUpperBound = true;
    elseif new_varsigma <= 1e-6 && new_sum_y > 0
        fprintf( '\n' );
        disp( 'M is not an S matrix, so there are some q for which the LCP (q,M) has no solution.' );
        disp( 'varsigma bounds (positive means M is an S matrix):' );
        disp( [ new_varsigma vvarsigma ] );
        disp( 'sum of y from the alternative problem (zero means M is an S matrix):' );
        disp( new_sum_y );
        fprintf( '\n' );
        ptestVal = -1;
        if new_sum_y == 0
            warning( 'dynareOBC:InconsistentSResults', 'The alternative test suggests that M is an S matrix. Results cannot be trusted. This may be caused by numerical inaccuracies.' );
        end
        SkipUpperBound = false;
    else
        fprintf( '\n' );
        disp( 'Due to numerical inaccuracies, we cannot tell if M is an S matrix.' );
        disp( 'varsigma bounds (positive means M is an S matrix):' );
        disp( [ new_varsigma vvarsigma ] );
        disp( 'sum of y from the alternative problem (zero means M is an S matrix):' );
        disp( new_sum_y );
        fprintf( '\n' );
        SkipUpperBound = true;
    end
    
    yalmip( 'clear' );

    if isempty( dynareOBC.d0s )
        disp( 'Skipping tests of feasibility with arbitrarily large T (TimeToEscapeBounds).' );
        disp( 'To run them, set FeasibilityTestGridSize=INTEGER where INTEGER>0.' );
        fprintf( '\n' );
    else
        disp( 'Performing tests of feasibility with arbitrarily large T (TimeToEscapeBounds).' );
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
        CH = dynareOBC.CH;
        D = dynareOBC.D;

        tmp = ones( 1, ns ) * Ts;
        CellMs = mat2cell( Ms, tmp, tmp );
        
        [ iValues, jValues ] = meshgrid( 1:FTGC, 1:FTGC );
        
        LoopMessage = sprintf( 'M did not pass either the sufficient condition to be an S matrix for all sufficiently large T, or the sufficient condition to not be an S matrix for all sufficiently large T.\nTo discover the properties of M, try reruning with higher TimeToEscapeBounds.\n' );
        
        try
            OpenPool;
            parfor GridIndex = 1 : numel( iValues )

                varsigma = sdpvar( 1, 1 );
                y = sdpvar( Ts * ns, 1 );
                yInf = sdpvar( ns, 1 );

                LBConstraints0 = [ 0 <= y, y <= 1, 0 <= yInf, yInf <= 1 ];
                UBConstraints0 = [ 0 <= y, y <= 1 ];

                Objective = -varsigma;

                i = iValues( GridIndex );
                j = jValues( GridIndex );
                rhoFC = rhoF( i ); %#ok<*PFBNS>
                rhoGC = rhoG( j );
                CFC = CF( i );
                CHC = CH( i );
                DC = D( i, j );

                rhoFCv = rhoFC .^ ( ( 1:Ts )' );
                rhoGCv = rhoGC .^ ( ( 1:Ts )' );

                dSumIndices = bsxfun( @plus, ( 1:Ts )', (Ts-1):-1:0 );

                DenomFG = 1 ./ ( 1 - rhoFC * rhoGC );
                DenomF = 1 ./ ( 1 - rhoFC );
                DenomG = 1 ./ ( 1 - rhoGC );
                DenomFG_G = DenomFG * DenomG;

                LBConstraints = [];
                UBConstraints = [];
                for ConVar = 1 : ns % row index
                    LBMinimand1 = zeros( Ts, 1 );
                    LBMinimand2 = zeros( Ts, 1 );
                    LBMinimand3 = 0;
                    UBMinimand = zeros( Ts, 1 );
                    for ConShock = 1 : ns % column index
                        yC = y( ( 1:Ts ) + ( ConShock - 1 ) * Ts );
                        yInfC = yInf( ConShock );
                        Norm_d0C = Norm_d0( ConShock );
                        InvIMinusHd0sC = InvIMinusHd0s( ConVar, ConShock );
                        InvIMinusHdPsC = squeeze( InvIMinusHdPs( ConVar, ConShock, : ) );
                        InvIMinusFdNsC = squeeze( InvIMinusFdNs( ConVar, ConShock, : ) );
                        dNsC = squeeze( dNs( ConVar, ConShock, : ) );

                        LBMinimand1 = LBMinimand1 + CellMs{ ConVar, ConShock } * yC + InvIMinusHdPsC( Ts:-1:1 ) * yInfC - DC * rhoFCv * rhoGC * rhoGCv( end ) * DenomFG_G * yInfC;
                        LBMinimand2 = LBMinimand2 + ( dNsC( dSumIndices ) - DC / DenomFG * rhoFCv( end ) * rhoFCv * rhoGCv' ) * yC + ( InvIMinusFdNsC( 1 ) - InvIMinusFdNsC( 1:Ts ) ) * yInfC + InvIMinusHd0sC * yInfC - DC * rhoFCv * rhoFCv( end ) * rhoGC * rhoGCv( end ) * DenomFG_G * yInfC;
                        LBMinimand3 = LBMinimand3 - CFC * DenomF * rhoFC * rhoFCv( end ) * ( 1 - rhoFCv( end ) ) * Norm_d0C - CFC * rhoFC * rhoFCv( end ) * NormInvIMinusF * Norm_d0C * yInfC + InvIMinusFdNsC( 1 ) * yInfC + InvIMinusHd0sC * yInfC - DC * rhoFC * rhoFCv( end ) * rhoFCv( end ) * rhoGC * DenomFG_G;

                        UBMinimand = UBMinimand + CellMs{ ConVar, ConShock } * yC + CHC * Norm_d0C * DenomG * rhoGCv( Ts:-1:1 ) + DC * rhoFCv * rhoGC * rhoGCv( end ) * DenomFG_G;
                    end
                    LBConstraints = [ LBConstraints; LBMinimand1; LBMinimand2; LBMinimand3 ];
                    UBConstraints = [ UBConstraints; UBMinimand ];
                end
                Diagnostics = optimize( [ LBConstraints0, varsigma <= LBConstraints ], Objective, dynareOBC.LPOptions );

                if Diagnostics.problem ~= 0
                    error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
                end

                vvarsigma = value( varsigma );
                vy = value( y );
                vy = max( 0, vy ./ max( 1, max( vy ) ) );
                assign( y, vy );
                new_varsigma = min( value( LBConstraints ) );

                if new_varsigma > 0
                    error( 'dynareOBC:EarlyExitParFor', ...
                        'M is an S matrix for all sufficiently large T, so the LCP is always feasible for sufficiently large T.\nThis is a necessary condition for there to always be a solution.\nphiF:\n%.15g\nphiG:\n%.15g\nvarsigma lower bound, bounds:\n%.15g %.15g\n', ...
                        rhoFC, rhoGC, new_varsigma, vvarsigma ...
                    );
                elseif ~SkipUpperBound
                    Diagnostics = optimize( [ UBConstraints0, varsigma <= UBConstraints ], Objective, dynareOBC.LPOptions );

                    if Diagnostics.problem ~= 0
                        error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your dynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
                    end

                    if value( varsigma ) <= 0
                        error( 'dynareOBC:EarlyExitParFor', ...
                            'M is neither an S matrix nor a P matrix for all sufficiently large T, so the LCP is sometimes non-feasible for sufficiently large T.\nThe model does not always possess a solution.\nphiF:\n%.15g\nphiG:\n%.15g\nvarsigma upper bound:\n%.15g\n', ...
                            rhoFC, rhoGC, value( varsigma ) ...
                        );
                    end
                end
            end
        catch ErrStruct
            if strcmp( ErrStruct.identifier, 'dynareOBC:EarlyExitParFor' )
                LoopMessage = ErrStruct.message;
            else
                rethrow( ErrStruct );
            end
        end
        
        fprintf( 1, '\n%s\n', LoopMessage );
    end
    
    global ptestUseMex AltPTestUseMex

    if ptestVal >= 0
        AbsArguments = abs( angle( eig( Ms ) ) );

        if all( AbsArguments < pi - pi / size( Ms, 1 ) )
            disp( 'Necessary condition for M to be a P-matrix is satisfied.' );
            disp( 'pi - pi / T - max( abs( angle( eig( M ) ) ) ):' );
            disp( pi - pi / size( Ms, 1 ) - max( AbsArguments ) );
            if  dynareOBC.AltPTest == 0
                if dynareOBC.PTest == 0
                    disp( 'Skipping the full P test, thus we cannot know whether there may be multiple solutions.' );
                    disp( 'To run the full P test, run dynareOBC again with PTest=INTEGER where INTEGER>0.' );
                else
                    TM = dynareOBC.PTest;

                    T = min( TM, Ts );
                    Indices = bsxfun( @plus, (1:T)', ( 0 ):Ts:((ns-1)*Ts ) );
                    Indices = Indices(:);
                    M = dynareOBC.MsMatrix( Indices, Indices );                
                    if ptestUseMex
                        disp( 'Testing whether the requested sub-matrix of M is a P-matrix using the MEX version of ptest.' );
                        if ptest_mex( M )
                            ptestVal = 1;
                        else
                            ptestVal = -1;
                        end
                    else
                        disp( 'Testing whether the requested sub-matrix of M is a P-matrix using the non-MEX version of ptest.' );
                        OpenPool;
                        if ptest( M )
                            ptestVal = 1;
                        else
                            ptestVal = -1;
                        end
                    end
                end
            end
        else
            disp( 'Necessary condition for M to be a P-matrix is not satisfied.' );
            disp( 'pi - pi / T - max( abs( angle( eig( M ) ) ) ):' );
            disp( pi - pi / size( Ms, 1 ) - max( AbsArguments ) );
            ptestVal = -1;
        end
    end
    
    if dynareOBC.AltPTest ~= 0
        TM = dynareOBC.AltPTest;

        T = min( TM, Ts );
        Indices = bsxfun( @plus, (1:T)', ( 0 ):Ts:((ns-1)*Ts ) );
        Indices = Indices(:);
        M = dynareOBC.MsMatrix( Indices, Indices );                
        if AltPTestUseMex
            disp( 'Testing whether the requested sub-matrix of M is a P-matrix using the MEX version of AltPTest.' );
            if AltPTest_mex( M, true )
                if ptestVal < 0
                    warning( 'dynareOBC:InconsistentAltPTest', 'AltPTest apparently disagrees with results based on necessary conditions, perhaps due to numerical problems. Try using PTest instead.' );
                end
                ptestVal = 1;
            else
                ptestVal = -1;
            end
        else
            disp( 'Testing whether the requested sub-matrix of M is a P-matrix using the non-MEX version of AltPTest.' );
            if AltPTest( M, true )
                if ptestVal < 0
                    warning( 'dynareOBC:InconsistentAltPTest', 'AltPTest apparently disagrees with results based on necessary conditions, perhaps due to numerical problems. Try using PTest instead.' );
                end
                ptestVal = 1;
            else
                ptestVal = -1;
            end
        end
    end
    
    if ptestVal > 0
        MPTS = [ 'The M matrix with T (TimeToEscapeBounds) equal to ' int2str( TM ) ];
        fprintf( '\n' );
        disp( [ MPTS ' is a P-matrix. There is a unique solution to the model, conditional on the bound binding for at most ' int2str( TM ) ' periods.' ] );
        disp( 'This is a necessary condition for M to be a P-matrix with arbitrarily large T (TimeToEscapeBounds).' );
        if ptestUseMex
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
    fprintf( '\n' );
    
    if dynareOBC.FullTest > 0
        fprintf( '\n' );
        disp( 'Running full test to see if the requested sub-matrix of M is a P and/or (strictly) semi-monotone matrix.' );
        fprintf( '\n' );
        [ MinimumDeterminant, MinimumS, MinimumS0 ] = FullTest( dynareOBC.FullTest, dynareOBC );
        MFTS = [ 'The M matrix with T (TimeToEscapeBounds) equal to ' int2str( dynareOBC.FullTest ) ];
        if MinimumDeterminant >= 1e-8
            disp( [ MFTS ' is a P-matrix.' ] );
        elseif MinimumDeterminant >= -1e-8
            disp( [ MFTS ' is a P0-matrix.' ] );
        else
            disp( [ MFTS ' is not a P-matrix or a P0-matrix.' ] );
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
    
    dynareOBC.ssIndices = cell( Ts, 1 );
    SkipCalcs = false;

    if ~dynareOBC.Estimation
        PoolOpened = false;
        for Tss = 1 : Ts
            ssIndices = vec( bsxfun( @plus, (1:Tss)', 0:Ts:((ns-1)*Ts) ) )';
            Mss = Ms( ssIndices, ssIndices );

            dynareOBC.ssIndices{ Tss } = ssIndices;

            if SkipCalcs || Tss > dynareOBC.TimeToSolveParametrically || dynareOBC.FullHorizon || min( eig( Mss + Mss' ) ) < sqrt( eps ) || ( dynareOBC.SimulationPeriods == 0 && ( dynareOBC.IRFPeriods == 0 || ( ~dynareOBC.SlowIRFs && dynareOBC.NoCubature ) ) )
                SkipCalcs = true;
                continue;
            end
            
            if ~PoolOpened
                OpenPool;
                PoolOpened = true;
            end

            PLCP = struct;
            PLCP.M = Mss;
            PLCP.q = zeros( Tss, 1 );
            PLCP.Q = eye( Tss );
            PLCP.Ath = [ eye( Tss ); -eye( Tss ) ];
            PLCP.bth = ones( 2 * Tss, 1 );

            fprintf( '\n' );
            disp( 'Solving for a parametric solution over the requested domain.' );
            fprintf( '\n' );

            strTss = int2str( Tss );
            try
                warning( 'off', 'MATLAB:lang:badlyScopedReturnValue' );
                warning( 'off', 'MATLAB:nargchk:deprecated' );
                ParametricSolution = mpt_plcp( Opt( PLCP ) );
                if ParametricSolution.exitflag == 1
                    try
                        ParametricSolution.xopt.toC( 'z', [ 'dynareOBCTempSolution' strTss ] );
                        mex( [ 'dynareOBCTempSolution' strTss '_mex.c' ] );
                        dynareOBC.ParametricSolutionFound( Tss ) = 2;
                    catch MPTError
                        disp( [ 'Error ' MPTError.identifier ' in compiling the parametric solution to C. ' MPTError.message ] );
                        disp( 'Attempting to compile via a MATLAB intermediary with MATLAB Coder.' );
                        try
                            ParametricSolution.xopt.toMatlab( [ 'dynareOBCTempSolution' strTss ], 'z', 'first-region' );
                            dynareOBC.ParametricSolutionFound( Tss ) = 1;
                        catch MPTTMError
                            disp( [ 'Error ' MPTTMError.identifier ' writing the MATLAB file for the parameteric solution. ' MPTTMError.message ] );
                            SkipCalcs = true;
                            continue;
                        end
                        try
                            BuildParametricSolutionCode( Tss );
                            dynareOBC.ParametricSolutionFound( Tss ) = 2;
                        catch CoderError
                            disp( [ 'Error ' CoderError.identifier ' compiling the MATLAB file with MATLAB Coder. ' CoderError.message ] );
                        end
                    end
                end
            catch
                disp( 'Failed to solve for a parametric solution.' );
                SkipCalcs = true;
                continue;
            end
        end
        if sum( dynareOBC.ParametricSolutionFound ) > 0
            rehash;
        end
    end
    
    if ~dynareOBC.Estimation && ( ( dynareOBC.SimulationPeriods == 0 && dynareOBC.IRFPeriods == 0 ) || ( ~dynareOBC.SlowIRFs && dynareOBC.NoCubature && dynareOBC.MLVSimulationMode <= 1 ) )
        ClosePool;
    end

    yalmip( 'clear' );
    warning( 'off', 'MATLAB:lang:badlyScopedReturnValue' );
    
    fprintf( '\n' );
    disp( 'Discovering and testing the installed MILP solver.' );
        
    M = dynareOBC.MMatrix;
    omega = dynareOBC.Omega;
    
    yScaled = sdpvar( Ts * ns, 1 );
    alpha = sdpvar( 1, 1 );
    z = binvar( Ts * ns, 1 );
    
    qScaled = ones( size( M, 1 ), 1 );
    qsScaled = ones( Ts * ns, 1 );

    Constraints = [ 0 <= yScaled, yScaled <= z, 0 <= alpha, 0 <= alpha * qScaled + M * yScaled, alpha * qsScaled + Ms * yScaled <= omega * ( 1 - z ) ];
    Objective = -alpha;
    Diagnostics = optimize( Constraints, Objective, dynareOBC.MILPOptions );
    if Diagnostics.problem ~= 0
        error( 'dynareOBC:FailedToSolveMILPProblem', [ 'This should never happen. Double-check your DynareOBC install, or try a different solver.\nInternal error message: ' Diagnostics.info ] );
    end
    if value( alpha ) <= 1e-5
        warning( 'dynareOBC:IncorrectSolutionToMILPProblem', [ 'It appears your chosen solver is giving the wrong solution to the MILP problem. Double-check your DynareOBC install, or try a different solver.\nInternal message: ' Diagnostics.info ] );
    end
    SolverString = regexp( Diagnostics.info, '(?<=\()\w+(?=(\)|-))', 'match', 'once' );
    lSolverString = lower( SolverString );
    dynareOBC.MILPOptions.solver = [ '+' lSolverString ];
    
    yalmip( 'clear' );
    
    disp( [ 'Found working solver: ' SolverString ] );
    fprintf( '\n' );
    
    if ~ismember( lSolverString, { 'gurobi', 'cplex', 'xpress', 'mosek', 'scip' } );
        warning( 'dynareOBC:PoorQualitySolver', 'You are using a low quality MILP solver. This may result in incorrect results, solution failures and slow performance.\nIt is strongly recommended that you install one of the commercial solvers listed in the read-me document (all of which are free to academia).' );
    end
        
end
