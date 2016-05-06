function dynareOBC = FormOptimizer( dynareOBC )

    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;

    if ns == 0
        return
    end
    
    M = dynareOBC.MMatrix;
    Ms = dynareOBC.MsMatrix;
    omega = dynareOBC.Omega;

    if dynareOBC.FullHorizon
        InitTss = Ts;
    else
        InitTss = 1;
    end
    
    qScaled = sdpvar( size( M, 1 ), 1 );
    qsScaled = qScaled( dynareOBC.sIndices );
    ssIndices = dynareOBC.ssIndices;
    
    dynareOBC.Optimizer = cell( Ts, 1 );
    
    for Tss = InitTss : Ts        
        Output = sdpvar( Tss * ns + 1, 1 );     % [ yScaled; alpha ]
        yScaled = Output( 1 : ( end - 1 ), 1 );
        alpha = Output( end );

        z = binvar( Tss, ns );
        sum_z = sum( z, 2 );
        z = z(:);
        
        CssIndices = ssIndices{ Tss };

        Constraints = [ 0 <= yScaled, yScaled <= z, 0 <= alpha, 0 <= alpha * qScaled + M( :, CssIndices ) * yScaled, alpha * qsScaled( CssIndices ) + Ms( CssIndices, CssIndices ) * yScaled <= omega * ( 1 - z ), sum_z( end ) >= 0.5 ];
        Objective = -alpha;
        dynareOBC.Optimizer{ Tss } = optimizer( Constraints, Objective, dynareOBC.MILPOptions, qScaled, Output );
    end
    
    yalmip( 'clear' );
    
end
