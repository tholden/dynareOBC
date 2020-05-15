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
    
    CubatureRegions = dynareOBC.CubatureRegions;
    
    if NumPoints > CubatureRegions
        
        if CubatureRegions > 1
        
            % Get initial centroid locations
            NormalizedPoints = Points ./ sqrt( sum( Points .* Points ) );
            NormalizedPoints = [ NormalizedPoints.', min( 0, NormalizedPoints.' ) ];
            [ ~, NormalizedPoints, NormalizedPointsVariances ] = pca( NormalizedPoints );
            assert( issorted( NormalizedPointsVariances, 'descend' ) );
            NormalizedPointsVariances( NormalizedPointsVariances < dynareOBC.CubaturePruningCutOff * NormalizedPointsVariances( 1 ) ) = 0;
            NormalizedPointsVariances( ( dynareOBC.MaxCubatureDimension + 1 ) : end ) = 0;
            NormalizedPoints = NormalizedPoints( :, NormalizedPointsVariances > eps );
            
            IDs = ones( NumPoints, 1 );
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
            
            StartCentroids = zeros( CubatureRegions, size( NormalizedPoints, 2 ) );
            
            for i = 1 : CubatureRegions
                StartCentroids( i, : ) = mean( NormalizedPoints( IDs == i, : ) );
            end
            
            assert( numel( unique( IDs ) ) == CubatureRegions );
            
            if dynareOBC.Debug
                kmeansDisplay = 'iter';
            else
                kmeansDisplay = 'off';
            end

            % Refine with the kmeans algorithm
            IDs = kmeans( NormalizedPoints, CubatureRegions, 'Start', StartCentroids, 'Display', kmeansDisplay, 'OnlinePhase', 'on', 'MaxIter', 100 * CubatureRegions );

            UniqueIDs = unique( IDs );
            
            assert( numel( UniqueIDs ) == CubatureRegions );

            NumPoints = numel( UniqueIDs );
            
            NewPoints = zeros( size( Points, 1 ), NumPoints );
            CubatureWeights = zeros( 1, NumPoints );

            for i = 1 : NumPoints
                PointSelect = IDs == UniqueIDs( i );
                NewPoints( :, i ) = mean( Points( :, PointSelect ), 2 );
                CubatureWeights( i ) = CubatureWeight * sum( PointSelect );
            end

            Points = NewPoints;
        
        else
            
            CubatureWeights = CubatureWeight * NumPoints;
            Points = mean( Points, 2 );
            NumPoints = 1;
            
        end
        
    else
        CubatureWeights = repmat( CubatureWeight, 1, NumPoints );
    end
    
    
    if nargin > 6
        p = TimedProgressBar( NumPoints( end ), 20, varargin{:} );
    else
        p = [];
    end
    
    y = zeros( dynareOBC.TimeToEscapeBounds * dynareOBC.NumberOfMax, 1 );

    if ~isempty( p )
        p.progress;
    end
    
    MaxCubatureSerialLoop = dynareOBC.MaxCubatureSerialLoop;
    
    WarningGenerated = false;

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
