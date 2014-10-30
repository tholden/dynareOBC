function [ alpha, exitflag, ReturnPath ] = SolveBoundsProblem( V, dynareOBC_ )
    if all( V >= - dynareOBC_.Tolerance )
        alpha = dynareOBC_.ZeroVecS;
        exitflag = 1;
        ReturnPath = V;
        return
    end
    switch dynareOBC_.Algorithm
        case 2
            [ alpha, exitflag, ReturnPath ] = SolveHomotopyProblem( V, dynareOBC_ );
        case 3
            [ alpha, exitflag, ReturnPath ] = SolveQCQPProblem( V, dynareOBC_ );
        otherwise
            if dynareOBC_.CacheSize > 0
                [ alpha, exitflag, ReturnPath ] = SolveCachedQuadraticProgrammingProblem( V, dynareOBC_ );
            else
                [ alpha, exitflag, ReturnPath ] = SolveQuadraticProgrammingProblem( V, dynareOBC_ );
            end
    end
end
function [ alpha, exitflag, ReturnPath ] = SolveCachedQuadraticProgrammingProblem( V, dynareOBC_ )
    persistent VHistory;
    persistent alphaHistory;
    persistent VMean;
    persistent cholVCov;
    persistent CacheElements;
    persistent WritePosition;
    nV = length( V );
    if isempty( CacheElements ) || ( length( VMean ) ~= length( V ) )
        CacheElements = 0;
        WritePosition = 1;
    end
    if ( CacheElements == 0 )
        VMean = V;
        cholVCov = eye( nV );
        VHistory = zeros( nV, 0 );
        alphaHistory = zeros( dynareOBC_.TimeToEscapeBounds, 0 );
    else
        if CacheElements >= dynareOBC_.CacheSize
            CacheElements = dynareOBC_.CacheSize - 1;
        end
        InvNewCacheElements = 1 / ( 1 + CacheElements );
        VMean = CacheElements * InvNewCacheElements * VMean + InvNewCacheElements * V;
        cholVCov = cholupdate( sqrt( CacheElements * InvNewCacheElements ) * cholVCov, sqrt( InvNewCacheElements ) * ( V - VMean ) );
    end
    LastWarn = lastwarn;
    cholInvVCov = cholVCov' \ eye( nV );
    lastwarn( LastWarn );
    Distances = cholInvVCov * bsxfun( @minus, VHistory, V );
    InvWeights = sum( Distances .* Distances );
    ZeroInvWeights = InvWeights == 0;
    if any( ZeroInvWeights )
        alphaStart = mean( alphaHistory( :, ZeroInvWeights ), 2 );
    else
        Weights = 1 ./ InvWeights;
        alphaStart = sum( bsxfun( @times, Weights, alphaHistory ), 2 ) / sum( Weights, 2 );
    end
    if numel( alphaStart )
        [ alpha, exitflag, ReturnPath ] = SolveQuadraticProgrammingProblem( V, dynareOBC_, max( 0, alphaStart ) );
    else
        exitflag = -1;
    end
    if exitflag < 0
        [ alpha, exitflag, ReturnPath ] = SolveQuadraticProgrammingProblem( V, dynareOBC_ );
    end
    VHistory( :, WritePosition ) = V;
    alphaHistory( :, WritePosition ) = alpha;
    if any( ZeroInvWeights )
        VHistory( :, ZeroInvWeights ) = V;
        alphaHistory( :, ZeroInvWeights ) = alpha;
    end
    CacheElements = CacheElements + 1;
    WritePosition = WritePosition + 1;
    if WritePosition > dynareOBC_.CacheSize
        WritePosition = 1;
    end
end
