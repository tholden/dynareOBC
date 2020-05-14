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
    CubatureWeights = 1 / NumPoints;
    
    Points = bsxfun( @plus, UnconstrainedReturnPath, RootConditionalCovariance * CubaturePoints );
    
    IrrelevantPoints = all( Points > 0 );

    Points( :, IrrelevantPoints ) = [];
    NumPoints = size( Points, 2 );
    
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
