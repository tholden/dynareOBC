function X = HigherOrderSobol( Dimension, Size, Smoothness, AddZeroPoint )
    % Higher order Sobol sequence
    % Derived from https://quasirandomideas.wordpress.com/2010/06/17/how-to-generate-higher-order-sobol-points-in-matlab-and-some-numerical-examples/
    % Create a higher order Sobol sequence.
    % 2^Size:       number of points
    % Dimension:    dimension of final point set
    % Smoothness:   interlacing factor
    % AddZeroPoint: whether to add a point at 0
    % X Output Sobol sequence
    
    SmoothnessMax = min( 50, floor( 52 / Size ) );
    
    if nargin < 3
        Smoothness = SmoothnessMax;
    else
        Smoothness = min( Smoothness, SmoothnessMax );
    end
    
    if nargin < 4
        AddZeroPoint = false;
    end
    
    Smoothness = max( 1, Smoothness );

    persistent HigherOrderSobolCache

    % coder.varsize( 'X', [], [ true, true ] );
    % X = zeros( Dimension, 0 ); %#ok<PREALL>

    FileName = 'HigherOrderSobolCache.mat';
    
    if isempty( HigherOrderSobolCache )
        FoundFile = false;

        if exist( FileName, 'file' ) == 2
            LoadedFile = load( FileName );
            if isstruct( LoadedFile ) && isfield( LoadedFile, 'HigherOrderSobolCache' ) && ~isempty( LoadedFile.HigherOrderSobolCache )
                HigherOrderSobolCache = LoadedFile.HigherOrderSobolCache;
                FoundFile = true;
            end
        end
        
        if ~FoundFile
            % coder.varsize( 'HigherOrderSobolCache', [], [ true, false ] );
            HigherOrderSobolCache = struct( 'InputParameters', [ 0, 0, 0, 0 ], 'X', zeros( 0, 0 ) );
            % coder.varsize( 'HigherOrderSobolCache(:).X', [], [ true, true ] );
        end
    end

    InputParameters = [ Size, Dimension, Smoothness, AddZeroPoint ];
    for i = 1 : numel( HigherOrderSobolCache )
        if all( HigherOrderSobolCache( i ).InputParameters == InputParameters )
            X = HigherOrderSobolCache( i ).X;
            return
        end
    end
        
    N = pow2( Size ); % Number of points;
    P = sobolset( Smoothness * Dimension ); % Get Sobol sequence;
    SobolPoints = net( P, N ); % Get net from Sobol sequence with N points;

    % Create binary representation of digits;

    if Smoothness == 1
        X = SobolPoints.';
    else
        Z = SobolPoints.' * N;
        X = zeros( Dimension, N );
        for j = 1 : Dimension
            for i = 1 : Size
                for k = 1 : Smoothness
                    X( j, : ) = bitset( X(j,:), (Size*Smoothness+1) - k - (i-1)*Smoothness, bitget( Z((j-1)*Smoothness+k,:), (Size+1) - i ) );
                end
            end
        end
        X = X * pow2( -Size * Smoothness );
    end

    for i = 1 : Dimension

        X( i, : ) = PerformSearch( X( i, : ), AddZeroPoint );

    end

    if AddZeroPoint
        X = [ zeros( Dimension, 1 ), X ];
    end
    
    StdX = std( X, [], 2 );
    [ ~, IdxSortStdX ] = sort( StdX, 'descend' );
    X = X( IdxSortStdX, : );

    assert( all( abs( mean( X, 2 ) ) < sqrt( eps ) ), 'ESTNLSS:HigherOrderSobol:Uncentered', 'Result was not centred.' );
    
    ToCache = struct( 'InputParameters', InputParameters, 'X', X );

    HigherOrderSobolCache = [ HigherOrderSobolCache; ToCache ];
    
    save( FileName, 'HigherOrderSobolCache' );

end

function BestXCandidate = PerformSearch( Xi, AddZeroPoint )

    BatchSize = 1;
    
    BestMinPenalty = Inf;
    BestXCandidate = [];
    
    SortedXi = sort( Xi );
    DSortedXi = diff( [ SortedXi( end ) - 1, SortedXi ] );
    MinPossiblePenalties = -norminv( 0.5 * DSortedXi );
    
    Possible = 1 : length( Xi );
    
    while true

        Current = Possible( 1 : min( BatchSize, end ) );
        NumCurrent = numel( Current );
        
        if NumCurrent == 0
            break
        end
        
        Possible( 1:NumCurrent ) = [];

        XiMat = bsxfun( @minus, Xi, SortedXi( Current ).' );
        XiMat = XiMat - floor( XiMat );

        uiMax = 1 - max( XiMat, [], 2 );
        f = Inf( NumCurrent, 1 );
        vi = 0.5 * ones( NumCurrent, 1 );
        idxStillGoing = 1 : NumCurrent;

        k = 0;
        while ~isempty( idxStillGoing )
            of = f;
            vic = vi( idxStillGoing );
            [ f, dfdv, df2dv2 ] = GetResid( vic, XiMat( idxStillGoing, : ), uiMax( idxStillGoing ) );
            Step = max( -0.5 * vic, min( 0.5 * ( 1 - vic ), ( ( -2 ) .* ( f .* dfdv ) ) ./ ( 2 .* ( dfdv .* dfdv ) - f .* df2dv2 ) ) );
            vi( idxStillGoing ) = vic + Step;
            RelStillGoing = ( abs( Step ) > max( 1, abs( vi( idxStillGoing ) ) ) * eps ) & ( abs( f ) < abs( of ) );
            f = f( RelStillGoing );
            idxStillGoing = idxStillGoing( RelStillGoing );
            k = k + 1;
        end

        ui = uiMax .* vi;

        assert( all( isfinite( ui ) ), 'ESTNLSS:HigherOrderSobol:SolutionFailure', 'Failed to solve for a rotation.' );

        NewXCandidates = norminv( bsxfun( @plus, XiMat, ui ) );

        if AddZeroPoint
            TmpCandidates = [ zeros( NumCurrent, 1 ), NewXCandidates ];
        else
            TmpCandidates = NewXCandidates;
        end

        Penalty = max( abs( TmpCandidates ), [], 2 );

        [ MinPenalty, IdxMinPenalty ] = min( Penalty );

        if MinPenalty < BestMinPenalty
            BestXCandidate = NewXCandidates( IdxMinPenalty, : );
            BestMinPenalty = MinPenalty;
            
            NoLongerPossible = find( BestMinPenalty <= MinPossiblePenalties );
            Possible = setdiff( Possible, NoLongerPossible );
        end
        
        BatchSize = 2 * BatchSize;

    end

end

function [ f, dfdv, df2dv2 ] = GetResid( v, X, uMax )

    % N = size( X, 2 );

    u = uMax .* v;
    
    X = max( eps, min( 1 - eps, bsxfun( @plus, X, u ) ) );
    % dXdv = repmat( uMax, 1, N );
    % dX2dv2 = repmat( uMax, 1, N );
    
    X = -1.4142135623730950488 .* erfcinv( 2 * X ); % = norminv( X );
    tmp = exp( 0.5 .* ( X .* X ) );
    dXdv = 2.5066282746310005024 .* bsxfun( @times, uMax, tmp ); % = dxdv ./ normpdf( Y );
    dX2dv2 = dXdv .* ( 1 + X .* dXdv );
    
    f = sum( X, 2 );
    dfdv = sum( dXdv, 2 );
    df2dv2 = sum( dX2dv2, 2 );
    
end
