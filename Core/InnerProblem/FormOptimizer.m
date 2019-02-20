function dynareOBC = FormOptimizer( dynareOBC )

    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;

    if ns == 0
        return
    end
    
    omega = dynareOBC.Omega;

    if dynareOBC.FullHorizon
        InitTss = Ts;
    else
        InitTss = max( 1, dynareOBC.LargestPMatrix );
    end
    
    qn = sdpvar( size( dynareOBC.MMatrix, 1 ), 1 );
    qns = qn( dynareOBC.sIndices );
    ssIndices = dynareOBC.ssIndices;
    
    dynareOBC.Optimizer = cell( Ts, 1 );
    
    for Tss = InitTss : Ts        
        Output = sdpvar( Tss * ns + 1, 1 );     % [ yScaled; alpha ]
        yn = Output( 1 : ( end - 1 ), 1 );
        alpha = Output( end );

        z = binvar( Tss, ns );
        sum_z = sum( z, 2 );
        z = z(:);
        
        CssIndices = ssIndices{ Tss };
        
        Mc = dynareOBC.NormalizedSubMMatrices{ Tss };
        Msc = dynareOBC.NormalizedSubMsMatrices{ Tss };

        % q + M y >= 0, y' ( qs + Ms y ) = 0, y >= 0
        % q + D1^(-1) D1 M D2 D2^(-1) y >= 0, y' ( qs + D1s^(-1) D1s Ms D2 D2^(-1) y ) = 0, y >= 0
        % D1 q + D1 M D2 D2^(-1) y >= 0, y' D2^(-1)' D2 D1s^(-1) ( D1s qs + D1s Ms D2 D2^(-1) y ) = 0, D2^(-1) y >= 0
        % yn := D2^(-1) y, Mn := D1 M D2, Mns := D1s Ms D2, qn := D1 * q, qns := D1s * qs
        % qn + Mn yn >= 0, yn' D2 D1s^(-1) ( qns + Mns yn ) = 0, yn >= 0
        % qn + Mn yn >= 0, yn' ( qns + Mns yn ) = 0, yn >= 0
        
        if dynareOBC.FullHorizon || ( Tss == dynareOBC.LargestPMatrix )
            Constraints = [ 0 <= yn, yn <= z, 0 <= alpha, 0 <= alpha * qn + Mc * yn, alpha * qns( CssIndices ) + Msc * yn <= omega * ( 1 - z ) ];
        else
            Constraints = [ 0 <= yn, yn <= z, 0 <= alpha, 0 <= alpha * qn + Mc * yn, alpha * qns( CssIndices ) + Msc * yn <= omega * ( 1 - z ), sum_z( end ) >= 0.5 ];
        end
        if dynareOBC.LeadConstraint > 0
            zt = reshape( z, Tss, ns );
            Constraints = [ Constraints, zt( :, [ 1 : ( dynareOBC.LeadConstraint - 1 ), ( dynareOBC.LeadConstraint + 1 ) : ns ] ) >= -0.5 + repmat( zt( :, dynareOBC.LeadConstraint ), 1, ns - 1 ) ]; %#ok<AGROW>
        end
        Objective = -alpha;
        dynareOBC.Optimizer{ Tss } = optimizer( Constraints, Objective, dynareOBC.MILPOptions, qn, Output );
    end
    
    yalmip( 'clear' );
    
end
