function dynareOBC_ = SetDefaultOption( dynareOBC_, Field, Value )

    if ~isfield( dynareOBC_, Field ) || isempty( dynareOBC_.( Field ) )
        dynareOBC_.( Field ) = Value;
        return
    end

end
