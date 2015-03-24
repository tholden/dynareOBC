function [ M, oo, dynareOBC ] = ReduceDecisionMatrices( M, oo, dynareOBC )

    LogicalSelectA = true( length( dynareOBC.SelectState ), 1 );
    LogicalSelectP = sparse( M.exo_nbr, 1 );
    LogicalSelectP( 1:dynareOBC.OriginalNumVarExo ) = true;
    oo.dr.ghu( :, ~LogicalSelectP ) = [];
    M.Sigma_e( :, ~LogicalSelectP ) = [];
    M.Sigma_e( ~LogicalSelectP, : ) = [];
    if dynareOBC.Order > 1
        LogicalSelectAP = alt_kron( LogicalSelectA, LogicalSelectP );
        LogicalSelectPP = alt_kron( LogicalSelectP, LogicalSelectP );
        oo.dr.ghxu( :, ~LogicalSelectAP ) = [];
        oo.dr.ghuu( :, ~LogicalSelectPP ) = [];
        if dynareOBC.Order > 2
            LogicalSelectAA = alt_kron( LogicalSelectA, LogicalSelectA );
            LogicalSelectAAP = alt_kron( LogicalSelectAA, LogicalSelectP );
            LogicalSelectAPP = alt_kron( LogicalSelectA, LogicalSelectPP );
            LogicalSelectPPP = alt_kron( LogicalSelectP, LogicalSelectPP );
            oo.dr.ghxxu( :, ~LogicalSelectAAP ) = [];
            oo.dr.ghxuu( :, ~LogicalSelectAPP ) = [];
            oo.dr.ghuuu( :, ~LogicalSelectPPP ) = [];
            oo.dr.ghuss_nlma( :, ~LogicalSelectP ) = [];
        end
    end
    assert( all( M.exo_names_orig_ord == 1:M.exo_nbr ) );
    M.exo_nbr = dynareOBC.OriginalNumVarExo;
    M.exo_names_orig_ord = 1:M.exo_nbr;
    
end
