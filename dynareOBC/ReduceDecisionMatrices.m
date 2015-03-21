function [ M_, oo_, dynareOBC_ ] = ReduceDecisionMatrices( M_, oo_, dynareOBC_ )

    LogicalSelectA = true( length( dynareOBC_.SelectState ), 1 );
    LogicalSelectP = sparse( M_.exo_nbr, 1 );
    LogicalSelectP( 1:dynareOBC_.OriginalNumVarExo ) = true;
    oo_.dr.ghu( :, ~LogicalSelectP ) = [];
    M_.Sigma_e( :, ~LogicalSelectP ) = [];
    M_.Sigma_e( ~LogicalSelectP, : ) = [];
    if dynareOBC_.Order > 1
        LogicalSelectAP = alt_kron( LogicalSelectA, LogicalSelectP );
        LogicalSelectPP = alt_kron( LogicalSelectP, LogicalSelectP );
        oo_.dr.ghxu( :, ~LogicalSelectAP ) = [];
        oo_.dr.ghuu( :, ~LogicalSelectPP ) = [];
        if dynareOBC_.Order > 2
            LogicalSelectAA = alt_kron( LogicalSelectA, LogicalSelectA );
            LogicalSelectAAP = alt_kron( LogicalSelectAA, LogicalSelectP );
            LogicalSelectAPP = alt_kron( LogicalSelectA, LogicalSelectPP );
            LogicalSelectPPP = alt_kron( LogicalSelectP, LogicalSelectPP );
            oo_.dr.ghxxu( :, ~LogicalSelectAAP ) = [];
            oo_.dr.ghxuu( :, ~LogicalSelectAPP ) = [];
            oo_.dr.ghuuu( :, ~LogicalSelectPPP ) = [];
            oo_.dr.ghuss_nlma( :, ~LogicalSelectP ) = [];
        end
    end
    assert( all( M_.exo_names_orig_ord == 1:M_.exo_nbr ) );
    M_.exo_nbr = dynareOBC_.OriginalNumVarExo;
    M_.exo_names_orig_ord = 1:M_.exo_nbr;
    
end
