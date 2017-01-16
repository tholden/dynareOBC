% `[ xMean, BestFitness, Iterations, NEvaluations ] = ACD( FitnessFunction, xMean, sigma, LB, UB, A, b, MaxEvaluations, StopFitness, HowOftenUpdateRotation, Order, NonProductSearchDimension, ProductSearchDimension, Parallel );`
% 
% Inputs:
%  * `FitnessFunction`: The objective function, a function handle.
%  * `xMean`: The initial point.
%  * `Sigma`: The initial search radius. Either a scalar, or a vector of search radiuses by coordinate, with the same number of elements as xMean.
%  * `MinSigma`: The minimum search radius. The search will stop when all coordinates of sigma are below this value. Either a scalar, or a vector of minimum search radiuses by coordinate, with the same number of elements as xMean.
%  * `LB`: A lower bound on the search for `xMean`. Either empty, a scalar, or a vector of lower bounds by coordinate, with the same number of elements as xMean.
%  * `UB`: A lower bound on the search for `xMean`. Either empty, a scalar, or a vector of upper bounds by coordinate, with the same number of elements as xMean.
%  * `A`: The `A` matrix from the inequality `A*x <= b`. May be empty if `b` is also empty.
%  * `b`: The `b` vector from the inequality `A*x <= b`. May be empty if `b` is also empty.
%  * `MaxEvaluations`: The maximum number of total function evaluations. (Set to `Inf` if this is empty.)
%  * `StopFitness`: The terminal fitness. (Set to `-Inf` if this is empty.)
%  * `HowOftenUpdateRotation`: How often the rotation should be updated. On problems with slow objective functions, this should be equal to `1`. Larger values may speed up computation if the objective function is very fast.
%  * `Order`: Determines the number of points to use to search along each group of NonProductSearchDirection directions. A (small) non-negative integer.
%  * `NonProductSearchDimension`: NonProductSearchDimension*ProductSearchDimension determines how many dimensions to search in simultaneously. A (small) positive integer.
%  * `ProductSearchDimension`: NonProductSearchDimension*ProductSearchDimension determines how many dimensions to search in simultaneously. A (small) positive integer.
%  * `PersistentState`: Some state that needs to be passed to the objective.
%  * `Resume`: Whether to resume the past run. A logical.
%  
%  Ouputs:
%   * `xMean`: The optimal point.
%   * `BestFitness`: The value of the objective at that point.
%   * `Iterations`: The number of iterations performed.
%   * `NEvaluations`: The number of function evaluations performed. 
% 
% ---------------------------------------------------------------
% Adaptive Coordinate Descent. To be used under the terms of the BSD license 
% Author : Ilya Loshchilov, Marc Schoenauer, Michele Sebag, 2012.  
% Further work: Tom Holden, 2016, 2017. See: https://github.com/tholden/ParallelFastNonLinearACD
% e-mail: ilya.loshchilov@gmail.com marc.schoenauer@inria.fr michele.sebag@lri.fr 
% URL:http://www.lri.fr/~ilya
% REFERENCE: Loshchilov, I., Schoenauer, M. , Sebag, M. (2011). Adaptive Coordinate Descent. 
%    N. Krasnogor et al. (eds.)
%    Genetic and Evolutionary Computation Conference (GECCO) 2012,
%    Proceedings, ACM.  http://hal.inria.fr/docs/00/58/75/34/PDF/AdaptiveCoordinateDescent.pdf
% This source code includes the Adaptive Encoding procedure by Nikolaus Hansen, 2008
% ---------------------------------------------------------------

function [ xMean, BestFitness, PersistentState, Iterations, NEvaluations ] = ACDMinimisation( FitnessFunction, xMean, Sigma, MinSigma, LB, UB, A, b, MaxEvaluations, StopFitness, HowOftenUpdateRotation, Order, NonProductSearchDimension, ProductSearchDimension, PersistentState, Resume )

    %%% parameters
    k_succ = 0.5;       
    k_unsucc = 0.5;
    
    xMean = xMean(:);
    
    NonProductSearchDimension = max( 1, floor( NonProductSearchDimension ) ); %integer >=1
    ProductSearchDimension = max( 1, floor( ProductSearchDimension ) ); %integer >=1
    SearchDimension = NonProductSearchDimension * ProductSearchDimension;
    
    N = length( xMean );
    assert( N >= SearchDimension, 'The problem dimension should be weakly greater than NonProductSearchDimension * ProductSearchDimension.' );    
    
    if isempty( Sigma )
        Sigma = ones( N, 1 );
    end
    if isempty( MinSigma )
        MinSigma = ones( N, 1 ) * sqrt( eps );
    end
    if isempty( LB )
        LB = -Inf( N, 1 );
    end
    if isempty( UB )
        UB = Inf( N, 1 );
    end
    if length( MinSigma ) == 1
        MinSigma = repmat( MinSigma, N, 1 );
    end
    if length( LB ) == 1
        LB = repmat( LB, N, 1 );
    end
    if length( UB ) == 1
        UB = repmat( UB, N, 1 );
    end
    if isempty( A )
        A = zeros( 0, N );
    end
    if isempty( b )
        b = zeros( 0, 1 );
    end
    if isempty( MaxEvaluations )
        MaxEvaluations = Inf;
    end
    if isempty( StopFitness )
        StopFitness = -Inf;
    end
    if isempty( Resume )
        Resume = false;
    end
    c1 = 0.5 / N;
    cmu = 0.5 / N;
    Order = max( 1, floor( Order ) ); %integer >=1
    HowOftenUpdateRotation = max( 1, floor( HowOftenUpdateRotation ) ); %integer >=1    

    Sigma = min( Sigma, ( UB - LB ) * 0.25 );

    BestFitness = 1e+30;
    NEvaluations = 0;

    B = eye(N,N);

    Iterations = 0;
    firstAE = true;
    ix = 0;
    somebetter = false;

    NoD = ceil( N / SearchDimension );
    
    UNPoints = 2 .^ ( NonProductSearchDimension + Order ) - 1;
    NPoints = UNPoints .^ ProductSearchDimension - 1;
    
    SobolPoints = nsobol( UNPoints, NonProductSearchDimension );
    assert( all( mean( SobolPoints ) < 1e-12 ) );
    SobolPoints = bsxfun( @minus, SobolPoints, mean( SobolPoints ) );
    RootCovSobolPoints = sqrtm( cov( SobolPoints ) );
    assert( std( diag( RootCovSobolPoints ) ) ./ mean( diag( RootCovSobolPoints ) ) < 1e-6 );
    SobolPoints = ( SobolPoints / RootCovSobolPoints )';
    assert( size( SobolPoints, 1 ) == NonProductSearchDimension );
    
    VAbsSobolPoints = unique( abs( SobolPoints(:) ), 'stable' );
    assert( size( VAbsSobolPoints, 2 ) == 1 );
    DVAbsSobolPoints = abs( bsxfun( @minus, VAbsSobolPoints, VAbsSobolPoints' ) ) + eye( length( VAbsSobolPoints ) );
    seps = sqrt( eps );
    [ fi, fj ] = find( DVAbsSobolPoints < seps );
    fij = unique( max( fi, fj ) );
    VAbsSobolPoints( fij ) = [];
    
    SobolPoints = SobolPoints ./ VAbsSobolPoints( 2 );
    VAbsSobolPoints = VAbsSobolPoints ./ VAbsSobolPoints( 2 );
    
    IdxSobolPoints = arrayfun( @(spc) find( abs( VAbsSobolPoints - abs( spc ) ) < seps, 1 ), SobolPoints );
    
    IdxCell_alpha = repmat( { 1 : UNPoints }, 1, ProductSearchDimension );
    [ IdxCell_alpha{:} ] = ndgrid( IdxCell_alpha{:} );
    AllIdxUalpha = cell2mat( cellfun( @(alphaCoord) reshape( alphaCoord( 2:end ), 1, NPoints ), IdxCell_alpha, 'UniformOutput', false )' );
    AllIdx_alpha = cell2mat( arrayfun( @( idx ) { IdxSobolPoints( :, idx ) }, AllIdxUalpha ) );
    [ ~, SortIdx_alpha ] = sortrows( [ sort( AllIdx_alpha, 1, 'descend' )', sort( AllIdxUalpha, 1, 'descend' )', ( 1 : NPoints )' ] );
    alpha = cell2mat( arrayfun( @( idx ) { SobolPoints( :, idx ) }, AllIdxUalpha( :, SortIdx_alpha ) ) );
    
    allx = NaN( N, NPoints*NoD );
    allf = NaN( 1, NPoints*NoD );

    disp( [ 'Using up to ' num2str( NPoints ) ' points per iteration.' ] );
    
    stream = RandStream( 'mt19937ar', 'Seed', 0 );
    ixPerm = randperm( stream, N );

    mu = 2 * SearchDimension + 2 * SearchDimension * ( SearchDimension - 1 );
    
    disp( 'Minimal alpha:' );
    disp( alpha( :, 1:mu ) );
    
    % -------------------- Generation Loop --------------------------------

    while (NEvaluations < MaxEvaluations) && (BestFitness > StopFitness)
        if Resume
            disp( 'Resuming from VariablesACD.mat' );
            load VariablesACD.mat;
            Resume = false;
        end
        Iterations = Iterations + 1;
        ix = ix + 1;
        if ix > NoD
            ix = 1;
            ixPerm = randperm( stream, N );
        end

        qIndices = ( ix - 1 ) * SearchDimension + ( 1 : SearchDimension );
        qIndices( qIndices > N ) = qIndices( qIndices > N ) - N;
        
        qix = ixPerm( qIndices );
        %%% Sample NPoints candidate solutions
        dx = bsxfun( @times, Sigma(qix,1)', B(:,qix) ); % shift along qix'th principal component, the computational complexity is linear
        
        x = zeros( N, NPoints );

        for iPoint = 1 : NPoints

            x( :, iPoint ) = clamp( xMean, dx * alpha( :, iPoint ), LB, UB, A, b );       % first point to test along qix'th principal component

        end
        [ Fit, TmpPersistentState ] = FitnessFunction( x, PersistentState, mu );
        NEvaluations = NEvaluations + NPoints;

        %%% Who is the next mean point?  
        lsucc = false;
        [ minFit, minFitLoc ] = min( Fit );
        if minFit < BestFitness
            BestFitness = minFit;
            xMean = x( :, minFitLoc );
            lsucc = true;
            if ~isempty( TmpPersistentState )
                PersistentState = TmpPersistentState;
            end
        end
        if isempty( PersistentState ) && ~isempty( TmpPersistentState )
            PersistentState = TmpPersistentState;
        end

        %%% Adapt step-size sigma depending on the success/unsuccess of the previous search
        foundAlpha = alpha( :, minFitLoc );
        
        if lsucc % increase the step-size
            Sigma(qix,1) = Sigma(qix,1) .* ( 1 + abs( foundAlpha ) * k_succ );
            somebetter = true;
        else            % decrease the step-size
            Sigma(qix,1) = Sigma(qix,1) * k_unsucc;
        end
        
        %%% Update archive 
        finiteFit = find( isfinite( Fit ) );
        finiteIndices = ( ix - 1 ) * NPoints + finiteFit;
        allx( :, finiteIndices ) = x( :, finiteFit );
        allf( 1, finiteIndices ) = Fit( finiteFit );
        
        if (ix == NoD) && somebetter && all( isfinite( allf ) ) %% we update our rotation matrix B every N=dimension iterations
            somebetter = false;

            [~, arindex] = sort(allf,2,'ascend');
            allxbest = allx(:,arindex(1:N));
            if firstAE
                ae = ACD_AEupdateFAST([], allxbest, c1, cmu,HowOftenUpdateRotation);    % initialize encoding
                ae.B = B;
                ae.Bo = ae.B;     % assuming the initial B is orthogonal
                ae.invB = ae.B';  % assuming the initial B is orthogonal
                firstAE = false;
            else 
                ae = ACD_AEupdateFAST(ae, allxbest, c1, cmu,HowOftenUpdateRotation);    % adapt encoding 
            end
            B = ae.B;
        end    
        
        if true % rem(Iterations,1000) == 0
            disp([ num2str(Iterations) ' ' num2str(NEvaluations) ' ' num2str(BestFitness) ' ' num2str(min(Sigma)) ' ' num2str(norm(Sigma)) ' ' num2str(max(Sigma)) ]);
        end
        
        save VariablesACD.mat;

        if all( Sigma < MinSigma )
            break
        end
    end
end
