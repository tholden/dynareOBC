function [ oo, dynareOBC ] = SimulationPreparation( M, oo, dynareOBC )
    rng( 'default' );

    if ~isempty( dynareOBC.IRFShocks )
        [ ~, dynareOBC.ShockSelect ] = ismember( dynareOBC.IRFShocks, cellstr( M.exo_names ) );
    else
        dynareOBC.ShockSelect = 1 : dynareOBC.OriginalNumVarExo;
    end
    if ~isfield( oo, 'irfs' ) || isempty( oo.irfs )
        oo.irfs = struct;
    end
end

