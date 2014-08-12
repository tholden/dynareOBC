function [ LogLinear, dynareOBC_ ] = ProcessStochSimulCommand( StochSimulCommand, dynareOBC_ )

    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=((\(|\(.*\W)irf\=))\d+', 'once' );
    if ~isempty( startindex )
        dynareOBC_.IRFPeriods = str2double( StochSimulCommand( startindex:endindex ) );
    end
    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=((\(|\(.*\W)periods\=))\d+', 'once' );
    if ~isempty( startindex )
        dynareOBC_.SimulationPeriods = str2double( StochSimulCommand( startindex:endindex ) );
    end
    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=((\(|\(.*\W)drop\=))\d+', 'once' );
    if ~isempty( startindex )
        dynareOBC_.SimulationDrop = str2double( StochSimulCommand( startindex:endindex ) );
    end
    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=((\(|\(.*\W)order\=))\d+', 'once' );
    if ~isempty( startindex )
        dynareOBC_.Order = str2double( StochSimulCommand( startindex:endindex ) );
    end
    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=((\(|\(.*\W)replic\=))\d+', 'once' );
    if ~isempty( startindex )
        dynareOBC_.Replications = str2double( StochSimulCommand( startindex:endindex ) );
    end
    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=((\(|\(.*\W)irf_shocks\=\())\s*\w+(\s*\,?\s*\w+)*\s*(?=\))', 'once' );
    if ~isempty( startindex )
        dynareOBC_.IRFShocks = StringSplit( StochSimulCommand( startindex:endindex ), { ' ', ',' } );
    end
    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=(^\w*(\(.*\))?\s*))(\w+(\s|\,|\;)+)*$', 'once' );
    if ~isempty( startindex )
        dynareOBC_.VarList = StringSplit( StochSimulCommand( startindex:endindex ), { ' ', ',', ';' } );
    end
    startindex = regexp( StochSimulCommand, '(?<=(\(|\(.*\W))nograph', 'once' );
    if ~isempty( startindex )
        dynareOBC_.NoGraph = 1;
    end
    startindex = regexp( StochSimulCommand, '(?<=(\(|\(.*\W))nodisplay', 'once' );
    if ~isempty( startindex )
        dynareOBC_.NoDisplay = 1;
    end
    startindex = regexp( StochSimulCommand, '(?<=(\(|\(.*\W))nomoments', 'once' );
    if ~isempty( startindex )
        dynareOBC_.NoMoments = 1;
    end
    startindex = regexp( StochSimulCommand, '(?<=(\(|\(.*\W))nocorr', 'once' );
    if ~isempty( startindex )
        dynareOBC_.NoCorr = 1;
    end
    startindex = regexp( StochSimulCommand, '(?<=(\(|\(.*\W))loglinear', 'once' );
    LogLinear = ~isempty( startindex );
    
end
