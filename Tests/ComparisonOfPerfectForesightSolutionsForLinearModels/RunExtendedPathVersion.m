dynare ExtendedPathVersion.mod
close all force;
try
    delete ExtendedPathVersion*.mat *.log ExtendedPathVersion.m ExtendedPathVersion_*.*
catch Error
    disp( Error.message );
end
try
    rmdir ExtendedPathVersion s
catch Error
    disp( Error.message );
end
ShockSequence = oo_.exo_simul';
EPEndoSequence = oo_.endo_simul(:,2:end);
save ExtendedPathResults.mat ShockSequence EPEndoSequence
