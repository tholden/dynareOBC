function [ alpha, exitflag, ReturnPath ] = SolveBoundsProblem( V, dynareOBC )
    if all( V >= - dynareOBC.Tolerance )
        alpha = dynareOBC.ZeroVecS;
        exitflag = 1;
        ReturnPath = V;
        return
    end
    switch dynareOBC.Algorithm
        case 2
            [ alpha, exitflag, ReturnPath ] = SolveHomotopyProblem( V, dynareOBC );
        case 3
            [ alpha, exitflag, ReturnPath ] = SolveQCQPProblem( V, dynareOBC );
        otherwise
            if dynareOBC.CacheSize > 0
                [ alpha, exitflag, ReturnPath ] = SolveCachedQuadraticProgrammingProblem( V, dynareOBC );
            else
                [ alpha, exitflag, ReturnPath ] = SolveQuadraticProgrammingProblem( V, dynareOBC );
            end
    end
end
function [ alpha, exitflag, ReturnPath ] = SolveCachedQuadraticProgrammingProblem( V, dynareOBC )
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
        alphaHistory = zeros( dynareOBC.TimeToEscapeBounds, 0 );
    else
        if CacheElements >= dynareOBC.CacheSize
            CacheElements = dynareOBC.CacheSize - 1;
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
        [ alpha, exitflag, ReturnPath ] = SolveQuadraticProgrammingProblem( V, dynareOBC, max( 0, alphaStart ) );
    else
        exitflag = -1;
    end
    if exitflag < 0
        [ alpha, exitflag, ReturnPath ] = SolveQuadraticProgrammingProblem( V, dynareOBC );
    end
    VHistory( :, WritePosition ) = V;
    alphaHistory( :, WritePosition ) = alpha;
    if any( ZeroInvWeights )
        VHistory( :, ZeroInvWeights ) = V;
        alphaHistory( :, ZeroInvWeights ) = alpha;
    end
    CacheElements = CacheElements + 1;
    WritePosition = WritePosition + 1;
    if WritePosition > dynareOBC.CacheSize
        WritePosition = 1;
    end
end
