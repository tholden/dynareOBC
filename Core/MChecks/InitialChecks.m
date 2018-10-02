function dynareOBC = InitialChecks( dynareOBC )
    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;
    
    UseVPA = dynareOBC.UseVPA && ( isoctave || ( license( 'checkout', 'Symbolic_Toolbox' ) && ~isempty( which( 'vpa' ) ) ) );
    
    M = dynareOBC.MMatrix;
    Ms = dynareOBC.MsMatrix;
    
    sIndices = dynareOBC.sIndices;
    
    NormalizeTolerance = sqrt( eps );
    [ ~, ~, d2 ] = NormalizeMatrix( Ms, NormalizeTolerance, NormalizeTolerance );
    M = bsxfun( @times, M, d2 );
    d1 = 1 ./ CleanSmallVector( max( abs( M ), [], 2 ), NormalizeTolerance );
    M = bsxfun( @times, d1, M );
    Ms = M( sIndices, : );
    
    dynareOBC.NormalizedMMatrix = M;
    dynareOBC.NormalizedMsMatrix = Ms;
    dynareOBC.d1MMatrix = d1;
    dynareOBC.d1sMMatrix = d1( sIndices );
    dynareOBC.d2MMatrix = d2;

    varsigma = sdpvar( 1, 1 );
    y = sdpvar( Ts * ns, 1 );
    
    MsScale = 1e3;
    scaledMs = MsScale * Ms;
    
    Constraints = [ 0 <= y, y <= 1, varsigma <= scaledMs * y ];
    Objective = -varsigma;
    Diagnostics = optimize( Constraints, Objective, dynareOBC.LPOptions );
    
    if Diagnostics.problem ~= 0
        warning( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your DynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
        vy = NaN( Ts * ns, 1 );
    else
        vy = value( y );
    end
    
    vy = max( 0, vy ./ max( 1, max( vy ) ) );
    new_varsigma = min( scaledMs * vy );

    AltConstraints = [ 0 <= y, y <= 1, y' * scaledMs <= 0 ];
    AltObjective = -ones( 1, Ts * ns ) * y;
    AltDiagnostics = optimize( AltConstraints, AltObjective, dynareOBC.LPOptions );

    if AltDiagnostics.problem ~= 0
        warning( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your DynareOBC install, or try a different solver. Internal error message: ' AltDiagnostics.info ] );
        new_sum_y = NaN;
    else
        vy = value( y );
        vy = max( 0, vy ./ max( 1, max( vy ) ) );
        new_sum_y = sum( vy );
    end
    
    ptestVal = 0;

    vvarsigma = value( varsigma );
    if new_varsigma > 0 || ( isnan( new_varsigma ) && new_sum_y <= 1e-6 )
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
        disp( 'Skipping tests of feasibility with infinite T (TimeToEscapeBounds).' );
        disp( 'To run them, set FeasibilityTestGridSize=INTEGER where INTEGER>0.' );
        fprintf( '\n' );
    else
        disp( 'Performing tests of feasibility with infinite T (TimeToEscapeBounds).' );
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
        
        LoopMessage = sprintf( 'M did not pass either the sufficient condition to be an S matrix for infinite T, or the sufficient condition to not be an S matrix for infinite T.\nTo discover the properties of M, try reruning with higher TimeToEscapeBounds.\n' );
        
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
                    error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your DynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
                end

                vvarsigma = value( varsigma );
                vy = value( y );
                vy = max( 0, vy ./ max( 1, max( vy ) ) );
                assign( y, vy );
                new_varsigma = min( value( LBConstraints ) );

                if new_varsigma > 0
                    error( 'dynareOBC:EarlyExitParFor', ...
                        'M is an S matrix for infinite T, so the LCP should be feasible for sufficiently large T.\nThis is a necessary condition for there to always be a solution.\nphiF:\n%.15g\nphiG:\n%.15g\nvarsigma lower bound, bounds:\n%.15g %.15g\n', ...
                        rhoFC, rhoGC, new_varsigma, vvarsigma ...
                    );
                elseif ~SkipUpperBound
                    Diagnostics = optimize( [ UBConstraints0, varsigma <= UBConstraints ], Objective, dynareOBC.LPOptions );

                    if Diagnostics.problem ~= 0
                        error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your DynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
                    end

                    if value( varsigma ) <= 0
                        error( 'dynareOBC:EarlyExitParFor', ...
                            'M is neither an S matrix nor a P matrix for infinite T, so the LCP is likely to be non-feasible in some situations, even for arbitrarily large T.\nphiF:\n%.15g\nphiG:\n%.15g\nvarsigma upper bound:\n%.15g\n', ...
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
    
    global QuickPCheckUseMex ptestUseMex AltPTestUseMex
    
    LargestPMatrix = dynareOBC.LargestPMatrix;
    T = 0;
    
    if LargestPMatrix < Ts           
        if QuickPCheckUseMex
            disp( 'Checking whether the contiguous principal sub-matrices of M have positive determinants, using the MEX version of QuickPCheck.' );
            [ ~, StartEndDet, IndicesToCheck ] = QuickPCheck_mex( Ms );
        else
            disp( 'Checking whether the contiguous principal sub-matrices of M have positive determinants, using the non-MEX version of QuickPCheck.' );
            [ ~, StartEndDet, IndicesToCheck ] = QuickPCheck( Ms );
        end
        
        QuickPCheckResult = true;
        for i = 1 : 3
            if any( IndicesToCheck(i,:) <= 0 )
                continue
            end
            TmpSet = IndicesToCheck(i,1):IndicesToCheck(i,2);
            if UseVPA
                TmpDet = double( det( vpa( Ms( TmpSet, TmpSet ) ) ) );
            else
                TmpDet = RobustDeterminantDD( Ms( TmpSet, TmpSet ) );
            end
            if TmpDet <= 0
                QuickPCheckResult = false;
                StartEndDet = [ IndicesToCheck(i,:), TmpDet ];
                break
            end
        end

        if QuickPCheckResult
            fprintf( 'No contiguous principal sub-matrices with negative determinants found. This is a necessary condition for M to be a P-matrix.\n\n' );
        else
            ptestVal = -1;
            fprintf( 'The sub-matrix with indices %d:%d has determinant %.15g.\n\n', StartEndDet( 1 ), StartEndDet( 2 ), StartEndDet( 3 ) );
        end
        
        if ptestVal >= 0
            AbsArguments = abs( angle( eig( Ms ) ) );

            if all( AbsArguments < pi - pi / size( Ms, 1 ) ) || ( ( size( Ms, 1 ) == 1 ) && ( Ms( 1, 1 ) > 0 ) )
                disp( 'Additional necessary condition for M to be a P-matrix is satisfied.' );
                disp( 'pi - pi / T - max( abs( angle( eig( M ) ) ) ):' );
                disp( pi - pi / size( Ms, 1 ) - max( AbsArguments ) );
                if  dynareOBC.AltPTest == 0
                    if dynareOBC.PTest == 0
                        disp( 'Skipping the full P test, thus we cannot know whether there may be multiple solutions.' );
                        disp( 'To run the full P test, run dynareOBC again with PTest=INTEGER where INTEGER>0.' );
                    else
                        TM = dynareOBC.PTest;

                        T = min( TM, Ts );
                        if LargestPMatrix < T
                            Indices = bsxfun( @plus, (1:T)', ( 0 ):Ts:((ns-1)*Ts ) );
                            Indices = Indices(:);
                            Mc = Ms( Indices, Indices );                
                            if ptestUseMex
                                disp( 'Testing whether the requested sub-matrix of M is a P-matrix using the MEX version of ptest.' );
                                if ptest_mex( Mc )
                                    ptestVal = 1;
                                else
                                    ptestVal = -1;
                                end
                            else
                                disp( 'Testing whether the requested sub-matrix of M is a P-matrix using the non-MEX version of ptest.' );
                                OpenPool;
                                if ptest( Mc )
                                    ptestVal = 1;
                                else
                                    ptestVal = -1;
                                end
                            end
                        end
                    end
                end
            else
                disp( 'Additional necessary condition for M to be a P-matrix is not satisfied.' );
                disp( 'pi - pi / T - max( abs( angle( eig( M ) ) ) ):' );
                disp( pi - pi / size( Ms, 1 ) - max( AbsArguments ) );
                ptestVal = -1;
            end
        end

        if dynareOBC.AltPTest ~= 0
            TM = dynareOBC.AltPTest;

            T = min( TM, Ts );
            if LargestPMatrix < T
                Indices = bsxfun( @plus, (1:T)', ( 0 ):Ts:((ns-1)*Ts ) );
                Indices = Indices(:);
                Mc = Ms( Indices, Indices );                
                if AltPTestUseMex
                    disp( 'Testing whether the requested sub-matrix of M is a P-matrix using the MEX version of AltPTest.' );
                    [ ~, IndicesToCheck ] = AltPTest_mex( Mc, true );
                else
                    disp( 'Testing whether the requested sub-matrix of M is a P-matrix using the non-MEX version of AltPTest.' );
                    [ ~, IndicesToCheck ] = AltPTest( Mc, true );
                end
                if UseVPA
                    AltPTestResult = true;
                    for i = 1 : 3
                        TmpSet = IndicesToCheck{i};
                        if ~isempty( TmpSet ) && double( det( vpa( Mc( IndicesToCheck{i}, IndicesToCheck{i} ) ) ) ) <= 0
                            AltPTestResult = false;
                            break
                        end
                    end
                else
                    AltPTestResult = true;
                    for i = 1 : 3
                        TmpSet = IndicesToCheck{i};
                        if ~isempty( TmpSet ) && RobustDeterminantDD( Mc( IndicesToCheck{i}, IndicesToCheck{i} ) ) <= 0
                            AltPTestResult = false;
                            break
                        end
                    end
                end
                if AltPTestResult
                    if ptestVal < 0
                        warning( 'dynareOBC:InconsistentAltPTest', 'AltPTest apparently disagrees with results based on necessary conditions, perhaps due to numerical problems. Try using PTest instead.' );
                    end
                    ptestVal = 1;
                else
                    ptestVal = -1;
                end
                fprintf( '\n' );
            end
        end

    else
    	disp( 'Skipping further P tests, since we have already established that M is a P-matrix.' );
    end
    
    if LargestPMatrix > 0
        if ptestVal > 0
            T = max( T, LargestPMatrix );
        else
            T = LargestPMatrix;
        end
        ptestVal = 1;
    end
    
    if ptestVal > 0
        MPTS = [ 'The M matrix with T (TimeToEscapeBounds) equal to ' int2str( T ) ];
        fprintf( '\n' );
        disp( [ MPTS ' is a P-matrix. There is a unique solution to the model, conditional on the bound binding for at most ' int2str( T ) ' periods.' ] );
        disp( 'This is a necessary condition for M to be a P-matrix with arbitrarily large T (TimeToEscapeBounds).' );
        if ptestUseMex
            DiagIsP = ptest_mex( dynareOBC.d0s + diag( eps( max( 1, abs( diag( dynareOBC.d0s ) ) ) ) ) );
        else
            DiagIsP = ptest( dynareOBC.d0s + diag( eps( max( 1, abs( diag( dynareOBC.d0s ) ) ) ) ) );
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
        TmpMStrings = { 'M', '0.5 * ( M + M'' )' };
        for MakeSymmetric = 0:1
            TmpMString = TmpMStrings{ MakeSymmetric + 1 };
            fprintf( '\n' );
            disp( [ 'Running full test to see if the requested sub-matrix of ' TmpMString ' is a P and/or (strictly) semi-monotone matrix.' ] );
            fprintf( '\n' );
            [ MinimumDeterminant, MinimumS, MinimumS0 ] = FullTest( dynareOBC.FullTest, dynareOBC, MakeSymmetric, UseVPA );
            MFTS = [ 'The ' TmpMString ' matrix with T (TimeToEscapeBounds) equal to ' int2str( dynareOBC.FullTest ) ];
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
    end
    
    dynareOBC.ParametricSolutionHorizon = 0;
    dynareOBC.ParametricSolutionMode = 0;
    
    if dynareOBC.Estimation || dynareOBC.FullHorizon || dynareOBC.ReverseSearch || ( ~dynareOBC.Smoothing && dynareOBC.SimulationPeriods == 0 && ( dynareOBC.IRFPeriods == 0 || ( ~dynareOBC.SlowIRFs && dynareOBC.NoCubature ) ) )
        dynareOBC.MaxParametricSolutionDimension = 0;
    end

    if isfield( dynareOBC, 'A2PowersTrans' )
        LengthZ2 = size( dynareOBC.A2PowersTrans{1}, 1 );
        Order2ConditionalCovariance = ( ~dynareOBC.NoCubature ) && dynareOBC.SecondOrderConditionalCovariance;
        ParallelRetrieveConditionalCovariances = ( LengthZ2 >= dynareOBC.RetrieveConditionalCovariancesParallelizationCutOff ) && Order2ConditionalCovariance;
    else
        ParallelRetrieveConditionalCovariances = false;
    end
    
    PoolNotNeeded = ~dynareOBC.Estimation && ~dynareOBC.Smoothing && ( ( dynareOBC.SimulationPeriods == 0 && dynareOBC.IRFPeriods == 0 ) || ( ~ParallelRetrieveConditionalCovariances && ~dynareOBC.SlowIRFs && dynareOBC.NoCubature && dynareOBC.MLVSimulationMode <= 1 ) );
    
    PoolOpened = false;
    d1sSubMMatrices = dynareOBC.d1sSubMMatrices;
    for Tss = min( ceil( dynareOBC.MaxParametricSolutionDimension / ns ), dynareOBC.LargestPMatrix ) : -1 : 1
        
        if ~PoolOpened && ( ~PoolNotNeeded || ( Tss >= dynareOBC.MinParametricSolutionParallelisationDimension ) )
            OpenPool;
            PoolOpened = true;
        end

        PLCP = struct;
        PLCP.M = dynareOBC.NormalizedSubMsMatrices{ Tss };
        PLCP.q = zeros( Tss * ns, 1 );
        PLCP.Q = eye( Tss * ns );
        
        d1s = d1sSubMMatrices{ Tss };
        
        PLCP.Ath = [ eye( Tss * ns ); -eye( Tss * ns ) ];
        PLCP.bth = [ d1s; d1s ];

        fprintf( '\n' );
        disp( 'Solving for a parametric solution over the requested domain.' );
        fprintf( '\n' );

        try
            warning( 'off', 'MATLAB:lang:badlyScopedReturnValue' );
            warning( 'off', 'MATLAB:nargchk:deprecated' );
            ParametricSolution = mpt_plcp( Opt( PLCP ) );
            if ParametricSolution.exitflag == 1
                try
                    ParametricSolution.xopt.toC( 'z', 'dynareOBCTempSolution' );
                    mex( 'dynareOBCTempSolution_mex.c' );
                    dynareOBC.ParametricSolutionHorizon = Tss;
                    dynareOBC.ParametricSolutionMode = 2;
                    break;
                catch MPTError
                    disp( [ 'Error ' MPTError.identifier ' in compiling the parametric solution to C: ' MPTError.message ] );
                    disp( 'Attempting to compile via a MATLAB intermediary with MATLAB Coder.' );
                    try
                        ParametricSolution.xopt.toMatlab( 'dynareOBCTempSolution', 'z', 'first-region' );
                        dynareOBC.ParametricSolutionHorizon = Tss;
                        dynareOBC.ParametricSolutionMode = 1;
                    catch MPTTMError
                        disp( [ 'Error ' MPTTMError.identifier ' writing the MATLAB file for the parameteric solution: ' MPTTMError.message ] );
                        continue;
                    end
                    try
                        BuildParametricSolutionCode( Tss );
                        dynareOBC.ParametricSolutionMode = 2;
                        break;
                    catch CoderError
                        disp( [ 'Error ' CoderError.identifier ' compiling the MATLAB file with MATLAB Coder: ' CoderError.message ] );
                    end
                end
            end
        catch Error
            disp( [ 'Failed to solve for a parametric solution. Internal error: ' Error.message ] );
        end
    end
    
    if dynareOBC.ParametricSolutionHorizon > 0
        rehash;
    end
    
    if PoolNotNeeded
        ClosePool;
    end

    yalmip( 'clear' );
    warning( 'off', 'MATLAB:lang:badlyScopedReturnValue' );
    
    fprintf( '\n' );
    disp( 'Discovering and testing the installed MILP solver.' );
        
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
    
    if ~ismember( lSolverString, { 'gurobi', 'cplex', 'xpress', 'mosek', 'scip' } )
        warning( 'dynareOBC:PoorQualitySolver', 'You are using a low quality MILP solver. This may result in incorrect results, solution failures and slow performance.\nIt is strongly recommended that you install one of the commercial solvers listed in the read-me document (all of which are free to academia).' );
    end
        
end
