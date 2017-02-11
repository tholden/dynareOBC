% `[ xMean, BestFitness, PersistentState, Iterations, NEvaluations ] = PACDMinimisation( FitnessFunction, xMean, LB, UB, A, b, PersistentState, Resume );`
% 
% Inputs:
%  * `FitnessFunction`: The objective function, a function handle.
%  * `xMean`: The initial point.
%  * `LB`: A lower bound on the search for `xMean`. Either empty, a scalar, or a vector of lower bounds by coordinate, with the same number of elements as xMean.
%  * `UB`: A lower bound on the search for `xMean`. Either empty, a scalar, or a vector of upper bounds by coordinate, with the same number of elements as xMean.
%  * `A`: The `A` matrix from the inequality `A*x <= b`. May be empty if `b` is also empty.
%  * `b`: The `b` vector from the inequality `A*x <= b`. May be empty if `b` is also empty.
%  * `PersistentState`: Some state that needs to be passed to the objective.
%  * `Resume`: Whether to resume the past run. A logical.
%  
%  Ouputs:
%  * `xMean`: The optimal point.
%  * `BestFitness`: The value of the objective at that point.
%  * `PersistentState`: The state at the best point.
%  * `Iterations`: The number of iterations performed.
%  * `NEvaluations`: The number of function evaluations performed. 
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

function [ xMean, BestFitness, PersistentState, Iterations, NEvaluations ] = PACDMinimisation( FitnessFunction, xMean, LB, UB, A, b, PersistentState, Resume )

    xMean = xMean(:);
    
    N = length( xMean );

    if isempty( LB )
        LB = -Inf( N, 1 );
    end
    if isempty( UB )
        UB = Inf( N, 1 );
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

    [ BestFitness, PersistentState ] = FitnessFunction( xMean, PersistentState, 1 );
    NEvaluations = 1;

    Iterations = 0;

    NPoints = 4 * N + 2 * N * ( N - 1 );
    
    alpha = zeros( N, NPoints );
    alpha( 1:N, 1:N ) = eye( N );
    alpha( 1:N, N + (1:N) ) = -eye( N );
    alpha( 1:N, 2*N + (1:N) ) = 2 * eye( N );
    alpha( 1:N, 3*N + (1:N) ) = -2 * eye( N );
    k = 4 * N;
    for i = 1 : N
        for j = ( i + 1 ) : N
            alpha( i, k + 1 ) =  1;
            alpha( j, k + 1 ) =  1;
            alpha( i, k + 2 ) =  1;
            alpha( j, k + 2 ) = -1;
            alpha( i, k + 3 ) = -1;
            alpha( j, k + 3 ) =  1;
            alpha( i, k + 4 ) = -1;
            alpha( j, k + 4 ) = -1;
            k = k + 4;
        end
    end
    assert( k == NPoints );
    assert( size( alpha, 2 ) == NPoints );
    
    disp( [ 'Using up to ' num2str( NPoints ) ' points per iteration.' ] );
    
    % -------------------- Generation Loop --------------------------------
    
    QuickMode = true;
    
    maxExtra = floor( sqrt( 4 * N + 9 / 4 ) - 3 / 2 );
    
    c1 = 0.5 / N;
    cmu = 0.5 / N;
    B = eye( N, N );
    firstAE = true;

    while true
        if Resume
            disp( 'Resuming from VariablesPACD.mat' );
            load VariablesPACD.mat;
            Resume = false;
        end
        Iterations = Iterations + 1;
        
        %%% Sample NPoints candidate solutions
        Sigma = eps ^ ( 1 / 3 ) * max( 1, abs( xMean ) );
        dSigma = diag( Sigma ); % shift along qix'th principal component, the computational complexity is linear
        
        if QuickMode
            disp( 'Quick search.' );
            CNPoints = 2 * N;
        else
            disp( 'Full search.' );
            CNPoints = NPoints;
        end
        
        x = zeros( N, CNPoints );
        for iPoint = 1 : CNPoints
            x( :, iPoint ) = clamp( xMean, dSigma * B * alpha( :, iPoint ), LB, UB, A, b );       % logic of AE would suggest B * dSigma, but this should scale better
        end
        x = unique( x', 'rows' )';
        
        [ Fit, TmpPersistentState ] = FitnessFunction( x, PersistentState, size( x, 2 ) );
        NEvaluations = NEvaluations + size( x, 2 );
        
        xDone = [ xMean, x ];
        [ Fit, sidxFit ] = sort( Fit );
        x = x( :, sidxFit );
        
        if Fit( 1 ) < BestFitness
            allx = x( :, 1 : N );
            allFit = Fit( 1 : N );
            
            if all( isfinite( allFit ) )
                if firstAE
                    ae = ACD_AEupdateFAST( [], allx, c1, cmu, 1 );    % initialize encoding
                    ae.B = B;
                    ae.Bo = ae.B;     % assuming the initial B is orthogonal
                    ae.invB = ae.B';  % assuming the initial B is orthogonal
                    firstAE = false;
                else 
                    ae = ACD_AEupdateFAST( ae, allx, c1, cmu, 1 );    % adapt encoding 
                end
                B = ae.B;
            end
        end
                
        ns = min( maxExtra, sum( Fit < BestFitness ) );
        xs = bsxfun( @minus, x( :, 1:ns ), xMean );

        NSucc = 0;
        xNew = xMean;
        
        while ns > 0
            
            BestFitness = Fit( 1 );
            NSucc = NSucc + 1;
            oxsNew = xNew - xMean;
            xNew = x( :, 1 );
            if ~isempty( TmpPersistentState )
                PersistentState = TmpPersistentState;
            end
            
            x = zeros( N, 0.5 * ns * ( ns + 1 ) + ns );
            k = 0;
            for i = 1 : ns
                k = k + 1;
                x( :, k ) = clamp( xMean, xs( :, i ) + oxsNew, LB, UB, A, b );
                for j = i : ns
                    k = k + 1;
                    x( :, k ) = clamp( xMean, xs( :, i ) + xs( :, j ), LB, UB, A, b );
                end
            end
            x = setdiff( unique( x', 'rows' ), xDone', 'rows' )';
            
            disp( 'Extra search.' );
            disp( [ ns size( x, 2 ) ] );
            
            [ Fit, TmpPersistentState ] = FitnessFunction( x, PersistentState, size( x, 2 ) );
            
            Fit( Fit > 0 ) = Inf;
            NEvaluations = NEvaluations + size( x, 2 );
            
            xDone = [ xDone, x ]; %#ok<AGROW>
            [ Fit, sidxFit ] = sort( Fit );
            x = x( :, sidxFit );

            ns = min( maxExtra, sum( Fit < BestFitness ) );
            xs = bsxfun( @minus, x( :, 1:ns ), xMean );
        
        end
        
        xMean = xNew;
        
        if isempty( PersistentState ) && ~isempty( TmpPersistentState )
            PersistentState = TmpPersistentState;
        end
        
        disp([ num2str(Iterations) ' ' num2str(NEvaluations) ' ' num2str(BestFitness) ' ' num2str(NSucc) ' ' num2str(min(Sigma)) ' ' num2str(norm(Sigma)) ' ' num2str(max(Sigma)) ]);
        
        save VariablesPACD.mat;

        if NSucc > 0
            QuickMode = true;
        elseif QuickMode
            if all( all( B == eye( N ) ) )
                QuickMode = false;
            end
            B = eye( N );
            firstAE = true;
        else
            break
        end

    end
end
