function [ oo_, dynareOBC_ ] = SimulationPreparation( M_, oo_, dynareOBC_ )
    if ~isempty( dynareOBC_.VarList )
        [ ~, dynareOBC_.VariableSelect ] = ismember( dynareOBC_.VarList, cellstr( M_.endo_names ) );
    else
        dynareOBC_.VariableSelect = 1 : dynareOBC_.OriginalNumVar;
    end
    if ~isempty( dynareOBC_.IRFShocks )
        [ ~, dynareOBC_.ShockSelect ] = ismember( dynareOBC_.IRFShocks, cellstr( M_.exo_names ) );
    else
        dynareOBC_.ShockSelect = 1 : dynareOBC_.OriginalNumVarExo;
    end
    if ~isfield( oo_, 'irfs' ) || isempty( oo_.irfs )
        oo_.irfs = struct;
    end
end

