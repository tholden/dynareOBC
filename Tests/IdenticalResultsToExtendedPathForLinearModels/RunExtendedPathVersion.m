try
    dynare ExtendedPathVersion.mod
catch
end
close all force;
delete ExtendedPathVersion*.mat *.log ExtendedPathVersion.m ExtendedPathVersion_*.*
rmdir ExtendedPathVersion s
ShockSequence = oo_.exo_simul';
EPEndoSequence = oo_.endo_simul(:,2:end);
save ExtendedPathResults.mat ShockSequence EPEndoSequence
