try
    load ExtendedPathResults.mat;
    addpath( [ fileparts( which( 'dynare' ) ) '\occbin' ] );
    [ ~, OBEndoSequence ] = solve_one_constraint( 'OccBinVersionSteady', 'OccBinVersionBound', 'd<-(1-beta)', 'd>-(1-beta)', ShockSequence', 'e', length( ShockSequence + 1000 ), 100 );
    beta = 0.99;
    OBEndoSequence = bsxfun( @plus, OBEndoSequence', [ 0; 0; 1 - beta; 1 - beta; 0 ] );
catch
    OBEndoSequence = [];
end
try
    close all force;
    delete OccBinVersion*.mat *.log OccBinVersion*.m OccBinVersion*_*.*
    rmdir OccBinVersionSteady s
    rmdir OccBinVersionBound s
catch
end
save OccBinResults.mat OBEndoSequence
