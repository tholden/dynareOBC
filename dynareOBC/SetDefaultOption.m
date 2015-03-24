function dynareOBC = SetDefaultOption( dynareOBC, Field, Value )

    if ~isfield( dynareOBC, Field ) || isempty( dynareOBC.( Field ) )
        dynareOBC.( Field ) = Value;
        return
    end

end
