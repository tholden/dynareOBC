function [ LogLinear, dynareOBC ] = ProcessStochSimulCommand( StochSimulCommand, dynareOBC )

    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=((\(|\(.*\W)irf\=))\d+', 'once' );
    if ~isempty( startindex )
        dynareOBC.IRFPeriods = str2double( StochSimulCommand( startindex:endindex ) );
    end
    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=((\(|\(.*\W)periods\=))\d+', 'once' );
    if ~isempty( startindex )
        dynareOBC.SimulationPeriods = str2double( StochSimulCommand( startindex:endindex ) );
    end
    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=((\(|\(.*\W)drop\=))\d+', 'once' );
    if ~isempty( startindex )
        dynareOBC.SimulationDrop = str2double( StochSimulCommand( startindex:endindex ) );
    end
    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=((\(|\(.*\W)order\=))\d+', 'once' );
    if ~isempty( startindex )
        dynareOBC.Order = str2double( StochSimulCommand( startindex:endindex ) );
    end
    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=((\(|\(.*\W)replic\=))\d+', 'once' );
    if ~isempty( startindex )
        dynareOBC.Replications = str2double( StochSimulCommand( startindex:endindex ) );
    end
    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=((\(|\(.*\W)irf_shocks\=\())\s*\w+(\s*\,?\s*\w+)*\s*(?=\))', 'once' );
    if ~isempty( startindex )
        dynareOBC.IRFShocks = StringSplit( StochSimulCommand( startindex:endindex ), { ' ', ',' } );
    end
    [ startindex, endindex ] = regexp( StochSimulCommand, '(?<=(^\w*(\(.*\))?\s*))(\w+(\s|\,|\;)+)*$', 'once' );
    if ~isempty( startindex )
        dynareOBC.VarList = StringSplit( StochSimulCommand( startindex:endindex ), { ' ', ',', ';' } );
    end
    startindex = regexp( StochSimulCommand, '(?<=(\(|\(.*\W))nograph', 'once' );
    if ~isempty( startindex )
        dynareOBC.NoGraph = 1;
    end
    startindex = regexp( StochSimulCommand, '(?<=(\(|\(.*\W))nodisplay', 'once' );
    if ~isempty( startindex )
        dynareOBC.NoDisplay = 1;
    end
    startindex = regexp( StochSimulCommand, '(?<=(\(|\(.*\W))nomoments', 'once' );
    if ~isempty( startindex )
        dynareOBC.NoMoments = 1;
    end
    startindex = regexp( StochSimulCommand, '(?<=(\(|\(.*\W))nocorr', 'once' );
    if ~isempty( startindex )
        dynareOBC.NoCorr = 1;
    end
    startindex = regexp( StochSimulCommand, '(?<=(\(|\(.*\W))loglinear', 'once' );
    LogLinear = ~isempty( startindex );
    
end
