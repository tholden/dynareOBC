try
    dynare ExtendedPathVersion.mod
catch
end
close all force;
delete ExtendedPathVersion*.mat *.log ExtendedPathVersion.m ExtendedPathVersion_*.*
rmdir ExtendedPathVersion s
ShockSequence = oo_.exo_simul';
EPEndoSequenece = oo_.endo_simul;
save ExtendedPathResults.mat ShockSequence EPEndoSequenece
