function [ welfare_ce, welfare_ce_, welfare, welfare_ ] = GetWelfarePath( C, L, Ce, Le, beta, beta_STEADY, A_STEADY, Sg_STEADY, PI_STEADY, varepsilon, theta, vartheta, psi )

    % Calculates the percentage extra consumption you would have to give to the inhabitant of an economy with flexible prices to make them indifferent between being in their economy and being in the sticky price economy.
    % Since the flexible price economy does not have the price dispersion distortion, this number will usually be negative.

    PI_ = PI_STEADY;
    PI_STAR_ = ( (1 - theta * (1 / PI_)^(1 - varepsilon) ) / (1 - theta) )^(1/(1 - varepsilon));
    NU_ = ( ( 1 - theta) / (1 - theta * PI_ ^varepsilon) ) * PI_STAR_ ^(-varepsilon);
    W_ = A_STEADY * PI_STAR_ * ((varepsilon - 1) / varepsilon) * ( (1 - theta * beta_STEADY * PI_ ^varepsilon)/(1 - theta * beta_STEADY * PI_ ^(varepsilon-1)));
    C_ = (W_ /(psi * ((1/(1 - Sg_STEADY)) * NU_/ A_STEADY)^vartheta))^(1/(1 + vartheta));
    Y_ = (1 / (1 - Sg_STEADY)) * C_;
    L_ = Y_ * NU_ / A_STEADY;

    welfare_ = beta_STEADY / ( 1 - beta_STEADY ) * ( log( C_ ) - psi * L_ ^ ( 1 + vartheta ) / ( 1 + vartheta ) );
    ce_impact_multiplier_ = beta_STEADY / ( 1 - beta_STEADY );
    
    Le_ = ( 1 / psi * ( varepsilon - 1 ) / varepsilon / ( 1 - Sg_STEADY ) ) ^ ( 1 / ( 1 + vartheta ) );
    Ye_ = A_STEADY  * Le_;
    Ge_ = Sg_STEADY * Ye_;
    Ce_ = Ye_       - Ge_;
    
    welfare_e_ = beta_STEADY / ( 1 - beta_STEADY ) * ( log( Ce_ ) - psi * Le_ ^ ( 1 + vartheta ) / ( 1 + vartheta ) );
    welfare_ce_ = exp( ( welfare_ - welfare_e_ ) ./ ce_impact_multiplier_ );
    
    welfare = zeros( size( C ) );
    welfare_e = zeros( size( C ) );
    ce_impact_multiplier = zeros( size( C ) );

    welfare( end ) = beta( end ) * ( log( C( end ) ) - psi * L( end ) ^ ( 1 + vartheta ) / ( 1 + vartheta ) + welfare_ );
    welfare_e( end ) = beta( end ) * ( log( Ce( end ) ) - psi * Le( end ) ^ ( 1 + vartheta ) / ( 1 + vartheta ) + welfare_e_ );
    
    ce_impact_multiplier( end ) = beta( end ) * ( 1 + ce_impact_multiplier_ );
    
    for t = ( length( C ) - 1 ) : -1 : 1
        welfare( t ) = beta( t ) * ( log( C( t ) ) - psi * L( t ) ^ ( 1 + vartheta ) / ( 1 + vartheta ) + welfare( t + 1 ) );
        welfare_e( t ) = beta( t ) * ( log( Ce( t ) ) - psi * Le( t ) ^ ( 1 + vartheta ) / ( 1 + vartheta ) + welfare_e( t + 1 ) );
        ce_impact_multiplier( t ) = beta( t ) * ( 1 + ce_impact_multiplier( t + 1 ) );
    end
    
    welfare_ce = exp( ( welfare - welfare_e ) ./ ce_impact_multiplier );
    
end
