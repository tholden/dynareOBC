function [ y, GlobalVarianceShare ] = PerformCubature( UnconstrainedReturnPath, oo, dynareOBC, FirstOrderSimulation, DisableParFor, varargin )
   
    [ RootConditionalCovariance, GlobalVarianceShare ] = RetrieveConditionalCovariances( oo, dynareOBC, FirstOrderSimulation );
    
    BaseDimension = size( RootConditionalCovariance, 2 );
    if BaseDimension == 0
        y = SolveBoundsProblem( UnconstrainedReturnPath );
        return
    end
    
    QuasiMonteCarloLevelP1 = dynareOBC.QuasiMonteCarloLevel + 1;
    
    if dynareOBC.HigherOrderSobolDegree > 0
        CubaturePoints = HigherOrderSobol( BaseDimension, QuasiMonteCarloLevelP1, dynareOBC.HigherOrderSobolDegree, false );
        NumPoints = size( CubaturePoints, 2 );
    else
        NumPoints = 2 .^ QuasiMonteCarloLevelP1 - 1;
        CubaturePoints = SobolSequence( BaseDimension, NumPoints );
    end
    CubatureWeight = 1 / NumPoints;
    
    Points = bsxfun( @plus, UnconstrainedReturnPath, RootConditionalCovariance * CubaturePoints );
    
    Tolerance = dynareOBC.Tolerance;
    
    SupNormPoints = max( abs( Points ) );
    SupNormPoints( SupNormPoints < Tolerance ) = 1;
    
    PointsScaled = Points ./ SupNormPoints;
    
    IrrelevantPoints = all( PointsScaled >= -Tolerance );

    Points( :, IrrelevantPoints ) = [];
    NumPoints = size( Points, 2 );
    
    MaxCubatureSerialLoop = dynareOBC.MaxCubatureSerialLoop;
    
    CubatureRegions = dynareOBC.CubatureRegions;
    
    if NumPoints > CubatureRegions
        
        CubaturePruningCutOff = dynareOBC.CubaturePruningCutOff;
        MaxCubatureDimension  = dynareOBC.MaxCubatureDimension;
        
        IDs = ones( NumPoints, 1 );
        
        if CubatureRegions > 1
        
            % Get initial centroid locations
            NormalizedPoints = Points ./ sqrt( sum( Points .* Points ) );
            NormalizedPoints = [ NormalizedPoints.', min( 0, NormalizedPoints.' ) ];
            NormalizedPoints = TrimmedPCA( NormalizedPoints, CubaturePruningCutOff, MaxCubatureDimension );
            
            NumRegions = 1;
            
            while NumRegions < CubatureRegions

                if NumRegions > 1
                    RegionSSEs = zeros( NumRegions, 1 );
                    for i = 1 : NumRegions
                        PointSelect = IDs == i;
                        Mean = mean( NormalizedPoints( PointSelect, : ) );
                        RegionSSEs( i ) = sum( sum( bsxfun( @minus, NormalizedPoints( PointSelect, : ), Mean ) .^ 2 ) );
                    end
                    [ ~, ToSplit ] = max( RegionSSEs );
                else
                    ToSplit = 1;
                end
                
                PointIndices = find( IDs == ToSplit );
                
                if NumRegions == 1
                    Projection = NormalizedPoints( PointIndices, 1 );
                else
                    C = cov( NormalizedPoints( PointIndices, : ) );
                    [ w, ~ ] = eigs( C, 1 );
                    w = w ./ sqrt( sum( w .* w ) );
                    Projection = NormalizedPoints( PointIndices, : ) * w;
                end
                
                Projection = Projection - mean( Projection );
                
                NRegion = numel( Projection );
                
                SortedProjection = sort( Projection );
                
                CumSumSortedProjection = cumsum( SortedProjection( 1 : ( end - 1 ) ) );
                
                jRegion = ( 1 : ( NRegion - 1 ) ).';
                
                Maximand = ( CumSumSortedProjection .* CumSumSortedProjection ) ./ ( jRegion .* ( NRegion - jRegion ) ); % Continuous Otsu's method
                
                [ ~, CutOffIndex ] = max( Maximand );
                
                CutOff = SortedProjection( CutOffIndex );
                
                % SelectClusterL = Projection <= CutOff;
                SelectClusterR = Projection > CutOff;
                
                NumRegions = NumRegions + 1;
                
                IDs( PointIndices( SelectClusterR ) ) = NumRegions;
                
            end
            
            assert( numel( unique( IDs ) ) == CubatureRegions );
            
            if dynareOBC.CubatureClusteringEffort > 0
                StartCentroids = zeros( CubatureRegions, size( NormalizedPoints, 2 ) );

                for i = 1 : CubatureRegions
                    StartCentroids( i, : ) = mean( NormalizedPoints( IDs == i, : ) );
                end
            
                if dynareOBC.Debug
                    kmeansDisplay = 'iter';
                else
                    kmeansDisplay = 'off';
                end

                if dynareOBC.CubatureClusteringEffort > 1
                    kmeansOnlinePhase = 'on';
                else
                    kmeansOnlinePhase = 'off';
                end
                
                % Refine with the kmeans algorithm
                IDs = kmeans( NormalizedPoints, CubatureRegions, 'Start', StartCentroids, 'Display', kmeansDisplay, 'OnlinePhase', kmeansOnlinePhase, 'MaxIter', 100 * CubatureRegions );
            end

            UniqueIDs = unique( IDs );
            
            assert( numel( UniqueIDs ) == CubatureRegions );
            assert( all( UniqueIDs(:).' == 1 : CubatureRegions ) );

        end
        
        CubatureCATCHDegree = dynareOBC.CubatureCATCHDegree;
        
        if CubatureCATCHDegree <= 0
        
            NewPoints = zeros( size( Points, 1 ), CubatureRegions );
            CubatureWeights = zeros( 1, CubatureRegions );

            for i = 1 : CubatureRegions
                PointSelect = IDs == i;
                NewPoints( :, i ) = mean( Points( :, PointSelect ), 2 );
                CubatureWeights( i ) = CubatureWeight * sum( PointSelect );
            end

        else
            
            CubatureLPOptions = dynareOBC.CubatureLPOptions;
            CubatureRelWeightCutOff = dynareOBC.CubatureRelWeightCutOff;
            
            NewPoints = cell( 1, CubatureRegions );
            CubatureWeights = cell( 1, CubatureRegions );
            
            if ( nargin > 6 ) && ( CubatureRegions > 1 )
                vararginAlt = strrep( varargin, 'integral', 'cubature rules' );
                p = TimedProgressBar( CubatureRegions, 20, vararginAlt{:} );
            else
                p = [];
            end

            if DisableParFor || CubatureRegions <= MaxCubatureSerialLoop
                for i = 1 : CubatureRegions
                    [ NewPoints{ i }, CubatureWeights{ i } ] = GetCubatureRule( Points( :, IDs == i ), CubatureWeight, CubatureCATCHDegree, CubaturePruningCutOff, MaxCubatureDimension, CubatureLPOptions, CubatureRelWeightCutOff );
                    if ~isempty( p )
                        p.progress;
                    end
                end
            else
                for i = 1 : CubatureRegions
                    NewPoints{ i } = Points( :, IDs == i );
                end
                parfor i = 1 : CubatureRegions
                    [ NewPoints{ i }, CubatureWeights{ i } ] = GetCubatureRule( NewPoints{ i }, CubatureWeight, CubatureCATCHDegree, CubaturePruningCutOff, MaxCubatureDimension, CubatureLPOptions, CubatureRelWeightCutOff );
                    if ~isempty( p )
                        p.progress;
                    end
                end
            end
            
            if ~isempty( p )
                p.stop;
            end

            NewPoints       = cell2mat( NewPoints );
            CubatureWeights = cell2mat( CubatureWeights );
            
        end
        
        Points = NewPoints;
        NumPoints = size( Points, 2 );

    else
        CubatureWeights = repmat( CubatureWeight, 1, NumPoints );
    end
    
    y = zeros( dynareOBC.TimeToEscapeBounds * dynareOBC.NumberOfMax, 1 );

    WarningGenerated = false;

    if nargin > 6
        p = TimedProgressBar( NumPoints, 20, varargin{:} );
    else
        p = [];
    end
    
    if DisableParFor || NumPoints <= MaxCubatureSerialLoop
        for j = 1 : NumPoints
            lastwarn( '' );
            WarningState = warning( 'off', 'all' );
            try
                yNew = SolveBoundsProblem( Points( :, j ) );
                y = y + yNew * CubatureWeights( j );
            catch Error
                warning( WarningState );
                rethrow( Error );
            end
            warning( WarningState );
            WarningGenerated = WarningGenerated | ~isempty( lastwarn );
            if ~isempty( p )
                p.progress;
            end
        end
    else
        parfor j = 1 : NumPoints
            lastwarn( '' );
            WarningState = warning( 'off', 'all' );
            try
                yNew = SolveBoundsProblem( Points( :, j ) );
                y = y + yNew * CubatureWeights( j );
            catch Error
                warning( WarningState );
                rethrow( Error );
            end
            warning( WarningState );
            WarningGenerated = WarningGenerated | ~isempty( lastwarn );
            if ~isempty( p )
                p.progress;
            end
        end
    end

	if ~isempty( p )
        p.stop;
	end
    
    if WarningGenerated
        warning( 'dynareOBC:CubatureWarnings', 'Warnings were generated in the inner cubature loop; try increasing TimeToEscapeBounds.' );
    end

end

function X = TrimmedPCA( X, CubaturePruningCutOff, MaxCubatureDimension )
    [ ~, X, D ] = pca( X );
    assert( issorted( D, 'descend' ) );
    D( D < CubaturePruningCutOff * D( 1 ) ) = 0;
    D( ( MaxCubatureDimension + 1 ) : end ) = 0;
    X = X( :, D > eps );
end

function [ CurrentPoints, CurrentWeights ] = GetCubatureRule( CurrentPoints, CubatureWeight, CubatureCATCHDegree, CubaturePruningCutOff, MaxCubatureDimension, CubatureLPOptions, CubatureRelWeightCutOff )

    CurrentNumPoints = size( CurrentPoints, 2 );

    Basis = [ CurrentPoints.', min( 0, CurrentPoints.' ) ];
    Basis = TrimmedPCA( Basis, CubaturePruningCutOff, min( CurrentNumPoints, 2 * MaxCubatureDimension ) );
    Basis = Basis ./ std( Basis );
    Basis = [ ones( CurrentNumPoints, 1 ), Basis ];

    Degree1Basis = Basis;

    NBasis = size( Basis, 2 );
    NDegree1Basis = NBasis;

    Degree1Basis = reshape( Degree1Basis, CurrentNumPoints, 1, NDegree1Basis );

    for Degree = 2 : CubatureCATCHDegree

        Basis = reshape( bsxfun( @times, Basis, Degree1Basis ), CurrentNumPoints, NBasis * NDegree1Basis );
        Basis = TrimmedPCA( Basis, CubaturePruningCutOff, CurrentNumPoints );
        Basis = Basis ./ std( Basis );
        Basis = [ ones( CurrentNumPoints, 1 ), Basis ]; %#ok<AGROW>

        NewNBasis = size( Basis, 2 );
        assert( NewNBasis >= NBasis );

        if NewNBasis == NBasis
            CubatureCATCHDegree = Degree;
            break
        else
            NBasis = NewNBasis;
        end

    end

    Basis = bsxfun( @times, Basis, 1 ./ max( abs( Basis ) ) );

    ObjectiveVector = sum( max( 0, -CurrentPoints ) .^ ( CubatureCATCHDegree + 1 ) ).';
    ObjectiveVector = ObjectiveVector .* ( 1 ./ max( abs( ObjectiveVector ) ) );

    WeightsVector = sdpvar( CurrentNumPoints, 1 );
    Diagnostics = optimize( [ WeightsVector >= 0, Basis.' * WeightsVector == sum( Basis ).' * CubatureWeight ], ObjectiveVector.' * WeightsVector, CubatureLPOptions );

    if Diagnostics.problem ~= 0
        error( 'dynareOBC:FailedToSolveLPProblem', [ 'This should never happen. Double-check your DynareOBC install, or try a different solver. Internal error message: ' Diagnostics.info ] );
    end

    WeightsVector = value( WeightsVector );

    MaxWeightsVector = max( WeightsVector );

    PointSelect = WeightsVector > CubatureRelWeightCutOff * MaxWeightsVector;

    CurrentPoints = CurrentPoints( :, PointSelect );
    CurrentWeights = WeightsVector( PointSelect ).';

    CurrentWeights = CurrentWeights .* ( ( CubatureWeight * CurrentNumPoints ) ./ sum( CurrentWeights ) );
    
end
