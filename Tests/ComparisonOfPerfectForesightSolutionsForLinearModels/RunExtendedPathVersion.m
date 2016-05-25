try
    dynare ExtendedPathVersion.mod
catch
end
close all force;
try
    delete ExtendedPathVersion*.mat *.log ExtendedPathVersion.m ExtendedPathVersion_*.*
catch
end
try
    rmdir ExtendedPathVersion s
catch
end
ShockSequence = oo_.exo_simul';
EPEndoSequence = oo_.endo_simul(:,2:end);
save ExtendedPathResults.mat ShockSequence EPEndoSequence
