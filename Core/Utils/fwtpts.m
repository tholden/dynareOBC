function [ Weights, Points, NumPoints, Integral ] = fwtpts( S, Order, TypeIsCube, f )
    % 
    %  [ WTS, PTS, INTCLS, Int ] = fwtpts( S, ORD, TYPE, f )
    %    Computes SPARSE-GRID FULLY SYMMETRIC RULE WEIGHTS and POINTS 
    %**************  PARAMETERS FOR fwtpts  
    %*****INPUT PARAMETERS
    %  S    Integer number of variables.
    %  Order  Integer order parameter, must not exceed 25(Norm) or 47(Cube),
    %           for rule with polynomial degree 2*ORD+1.
    %  TypeIsCube Boolean. false (default) uses a Gaussian weight over R^S, true uses a uniform weight over [-1,1]^S
    %   f   Optional parameter, if present, ftwpts, computes an approximation
    %        to the integral of f, using WTS and PTS; f is evaluated at N=INTCLS 
    %        points, with input as an SxN matrix.
    %******OUTPUT PARAMETERS
    %  Weights     Weight array size (1,INTCLS)
    %  Points      Point array size  (S,INTCLS)
    %  NumPoints   Integer number of function values needed for the rule
    %  Integral    Approximation to integral of f, using WTS and PTS.
    %************** Examples: 
    %    for degree 9 rule for 5 variables, Normal(Gaussian) weight function 
    %      [ W P N ] = fwtpts( 5, 4 ); disp([N W]),disp(P) 
    %    for degree 11 rule for 4 variables, over [-1,1]^S, weight = 1
    %      [ W P N ] = fwtpts( 4, 5, 'Cube' ); disp([N W]),disp(P) 
    %    for degree 11 rule for 4 variables, over [-1,1]^S, weight = 1
    %     applied to integrand f = exp(-sum(x)^2)       
    %      [ W P N I ] = fwtpts( 4, 5, 'Cube', @(x)exp(-sum(x).^2)); disp(I)
    %
    %   fwtpts COMPUTES WEIGHTS and POINTS for a FULLY SYMMETRIC rule for 
    %      inf     inf 
    %     I  ...  I     w(X) F(X) DX(S)...DX(2)DX(1),
    %     -inf    -inf     
    %
    %       with w(X) = EXP(-( X(1)^2 + ... + X(S)^2 )/2)/SQRT(2*PI)^S.
    %
    %  OR
    %      1       1 
    %     I  ...  I   F(X) DX(S)...DX(2)DX(1),
    %     -1      -1     
    %
    %    Author
    %      Alan Genz
    %      Department of Mathematics
    %      Washington State University
    %      Pullman, Washington 99164-3113  USA
    %      Email: alangenz@wsu.edu
    %    References:
    %      Alan Genz, Fully Symmetric Interpolatory Rules for Multiple
    %       Integrals, SIAM J. Numer. Anal. 23 (1986), pp. 1273-1283.
    %      Alan Genz and Bradley Keister: Fully Symmetric Interpolatory Rules 
    %      for Multiple Integrals over Infinite Regions with Gaussian Weight,
    %       J. Comp. Appl. Math. 71 (1996), pp. 299-309.
    %
    %***********************************************************************
    %

    persistent fwtptsCache

    if nargin < 3
        TypeIsCube = false;
    end

    if TypeIsCube
        Order = min( 47, Order );
    else
        Order = min( 25, Order );
    end

    FoundInCache = false;

    coder.varsize( 'Weights', [], [ false, true ] );
    Weights = zeros( 1, 0 );
    coder.varsize( 'Points', [], [ true, true ] );
    Points = zeros( S, 0 );
    
    NumPoints = 0;

    if isempty( fwtptsCache )
        coder.varsize( 'fwtptsCache', [], [ true, false ] );
        fwtptsCache = struct( 'InputParameters', [ 0, 0, 0 ], 'Weights', zeros( 1 , 0 ), 'Points', zeros( 0, 0 ) );
        coder.varsize( 'fwtptsCache(:).Weights', [], [ false, true ] );
        coder.varsize( 'fwtptsCache(:).Points', [], [ true, true ] );
    end

    InputParameters = [ S, Order, TypeIsCube ];
    for i = 1 : numel( fwtptsCache )
        if all( fwtptsCache( i ).InputParameters == InputParameters )
            Weights = fwtptsCache( i ).Weights;
            Points = fwtptsCache( i ).Points;
            NumPoints = numel( Weights );
            FoundInCache = true;
            break;
        end
    end

    if ~FoundInCache
        if TypeIsCube
            NZM = 32;
            %  
            %        Generators for 1 + 2 + 4 + 8 + 16 + 32 = 63 point degree
            %        95 rule, with degree 1, 3, 11, 23, and 47 imbedded rules.     
            %  
            G = zeros(1,32);
            T = zeros(1,32);
            T(1) = 2;
            G([ 1  2]) = [ 0                     .77459666924148337704];
            G([ 3  4]) = [ .96049126870802028342 .43424374934680255800];
            G([ 5  6]) = [ .99383196321275502221 .22338668642896688163];
            G([ 7  8]) = [ .62110294673722640294 .88845923287225699889];
            G([ 9 12]) = [ .99909812496766759750 .98153114955374010698];
            G([15 14]) = [ .92965485742974005664 .83672593816886873551];
            G([16 11]) = [ .70249620649152707861 .53131974364437562397];
            G([13 10]) = [ .33113539325797683309 .11248894313318662575];
            G([17 19]) = [ .99987288812035761194 .99720625937222195908];
            G([21 23]) = [ .98868475754742947994 .97218287474858179658];
            G([25 27]) = [ .94634285837340290515 .91037115695700429250];
            G([29 31]) = [ .86390793819369047715 .80694053195021761186];
            G([32 30]) = [ .73975604435269475868 .66290966002478059546];
            G([28 26]) = [ .57719571005204581484 .48361802694584102756];
            G([24 22]) = [ .38335932419873034692 .27774982202182431507];
            G([20 18]) = [ .16823525155220746498 .056344313046592789972];
            %
            T([ 2  4]) = [  0.66666666666666667     0.45714285714285714e-01 ];
            T([ 7  8]) = [ -0.28065213250398436e-03 0.13157729695421112e-03 ];
            T([13 14]) = [ -0.53949060310550432e-08 0.16409565802196882e-07 ];
            T([15 16]) = [ -0.12211217614373411e-07 0.52317265561235989e-08 ];
            T([25 26]) = [ -0.10141155834616524e-17 0.14345827598358802e-16 ];
            T([27 28]) = [ -0.56865230056143054e-16 0.11731814910797153e-15 ];
            T([29 30]) = [ -0.95580354100927967e-16 0.64242918014064288e-16 ];
            T([31 32]) = [ -0.12072769909636026e-16 0.19636450073868758e-17 ];
            Z = [0 0 1 0 2 1 0 0 4:-1:0 0 0 0 8:-1:0 zeros(1,7) 16:-1:1];
        else % Normal (Gaussian) weight function 
            %  
            %     Generators for 1 + 2 + 6 + 10 + 16 = 35 point degree 51 rule, 
            %       with degree 1, 5, 15 and 29 imbedded rules.     
            %
            G = zeros(1,18);
            NZM = 18;
            G([ 1, 2]) = [ 0,                     0.17320508075688773e1 ];
            G([ 3, 4]) = [ 0.41849560176727319e1, 0.74109534999454084e0 ];
            G([ 5, 6]) = [ 0.28612795760570581e1, 0.63633944943363700e1 ];
            G([ 7, 8]) = [ 0.12304236340273060e1, 0.51870160399136561e1 ];
            G([ 9,10]) = [ 0.25960831150492022e1, 0.32053337944991945e1 ];
            G([11,12]) = [ 0.90169397898903025e1, 0.24899229757996061e0 ];
            G([13,14]) = [ 0.79807717985905609e1, 0.22336260616769417e1 ];
            G([15,16]) = [ 0.71221067008046167e1, 0.36353185190372782e1 ];
            G([17,18]) = [ 0.56981777684881096e1, 0.47364330859522971e1 ];
            %  
            T = zeros(1,18);
            T([1:2 4:5]) = [ 1, 1, 6, -0.48378475125832451e2 ];
            T( 9:10) = [ 34020, -0.98606453173677489e6 ];
            T(16:17) = [ 0.12912054173706603e13, -0.11268664521456168e15 ];
            T(18   ) =   0.29248520348796280e16;  
            Z = [0 0 1 0 0 3:-1:0 0 5:-1:0 0 0 8:-1:1];
        end
        %
        %***  Calculate moments 
        %
        MOM = zeros(max(NZM,Order+1));
        MOM(1,1) = T(1);
        for L = 1 : NZM
            MP = 1;
            GLS = G(L)^2;
            for I = 2 : NZM
                GI = G(I-1);
                if I > L
                    GI = G(I);
                end
                MP = MP*( GLS - GI^2 );
                if I >= L
                    MOM(L,I) = T(I)/MP;
                end
            end
        end
        [ M, PRT, D ] = NXPART( 0, S );
        IC = 0;
        %
        %***  Begin loop for each D
        %      for each D find all distinct partitions M with |M| <= D
        %

        coder.varsize( 'PP', [], [ true, true ] );

        while D <= Order
            %     
            %***  Calculate the weight for partitions of M and 
            %***     fully symmetric point sets ( when necessary )
            %
            if D + sum(Z(M+1)) <= Order
                coder.varsize( 'PP', [], [ true, true ] );
                [ PP, SP ] = FULPTS( S, M, G ); 
                Weights = [ Weights, FULWGT( S, M, Order-D, MOM ) ];    %#ok<AGROW>
                Points = [ Points, PP ]; %#ok<AGROW>
                IC = IC + SP;
            end
            [ M, PRT, D ] = NXPART( PRT, S, M, D );
        end
        NumPoints = IC;
        
        ToCache = struct( 'InputParameters', InputParameters, 'Weights', Weights, 'Points', Points );
        
        fwtptsCache = [ fwtptsCache; ToCache ];
        
    end

    Integral = 0;
    if nargin > 3
        Integral = sum(Weights.*feval(f,Points));
    end

end


function wt = FULWGT( S, M, DM, MOM )
    %
    %***  Function to compute weight for partition M
    %
    KZ = DM;
    K = M;
    WS = zeros(1,S+1); 
    while true
        tI = 0;
        for I = 1 : S
            WS(1) = 1;
            tI = I;
            if KZ >= 0
                WS(I+1) = WS(I+1) + MOM(M(I)+1,K(I)+1)*WS(I);
                WS(I) = 0;
                K(I) = K(I) + 1;
                KZ = KZ - 1;
                break;
            end
            KZ = KZ + K(I) - M(I);
            K(I) = M(I);
        end
        if tI == S && K(S) == M(S)
            break;
        end
    end
    wt = WS(S+1)/2^sum(M>0);

end


function [ M, PRTCNT, MODM ] = NXPART( PIN, S, MI, MDI )
    %
    %*** Determine the next S partition of MDI
    %
    if PIN == 0
        M = zeros(1,S);
        PRTCNT = 1;
        MODM = 0;
    else
        PRTCNT = PIN + 1;
        MODM = MDI;
        M = MI;
        MSUM = M(1);
        for I = 2 : S
            MSUM = MSUM + M(I);
            if M(1) <= M(I) + 1
                M(I) = 0;
            else
                M(1) = MSUM - (I-1)*( M(I) + 1 );
                M(2:I) = M(I) + 1;
                return;
            end
        end
        M(1) = MSUM + 1;
        MODM = M(1);
    end
end


function [ PTS, SUMCLS ] = FULPTS( S, MN, G )
    %
    %***  To compute fully symmetric basic rule points for partition MN
    %
    M = MN;
    SUMCLS = 0;
    pr = true;
    coder.varsize( 'PTS', [], [ true, true ] );    
    PTS = zeros(S,0);
    % 
    %*******  Compute centrally symmetric sum points for permutation of M
    %
    while pr
        X = -G(M+1)';
        pr = false;
        ml = true;
        %
        %*******  Integration loop for M
        %
        while ml
            ml = false;
            SUMCLS = SUMCLS + 1;
            PTS = [ PTS, X ];  %#ok<AGROW>
            for I = 1 : S
                X(I) = -X(I);
                if X(I) > 0
                    ml = true;
                    break;
                end
            end
        end
        %*******  Find next distinct permutation of M and loop back
        %          to compute next centrally symmetric sum points
        %
        for I = 2 : S
            MI = M(I);
            if M(I-1) > MI
                IX = I - 1;
                if I > 2
                    LX = 0;
                    for L = 1 : IX/2
                        ML = M(L);
                        if ML <= MI
                            IX = IX - 1;
                        end
                        IL = I - L;
                        M(L) = M(IL);
                        M(IL) = ML;
                        if M(L) > MI
                            LX = L;
                        end
                    end
                    if M(IX) <= MI
                        IX = LX;
                    end
                end
                M(I) = M(IX);
                M(IX) = MI;
                pr = true;
                break;
            end
        end
    end
end
