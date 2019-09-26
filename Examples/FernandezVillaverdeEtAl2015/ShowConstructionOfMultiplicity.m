dynareOBC NKIRF ShockScale=0 SkipFirstSolutions=1 DisplayBoundsSolutionProgress

y = [ % Copied from the output of the previous command.
    12.6234334992405
    8.65513443740347
    5.90835581637955
    4.01317965739057
    2.71027546440804
    1.81818401976494
    1.21019634867135
    0.798034215189704
    0.520346800313054
    0.334613898154862
    0.211455666612509
    0.130640301472461
    0.0782879835145113
    0.0449163602485306
    0.0240769909314169
    0.0114059542243325
    0.00396398632642918
    ];

T = 30;
Ts = length( y );

M = dynareOBC_.MMatrix( 1 : T, 1 : Ts );

figure;

subplot( 1, 3, 1 );
plot( M );

subplot( 1, 3, 2 );
plot( M .* y.' );

subplot( 1, 3, 3 );
plot( 1 : T, M * y, 'k-', 1 : T, ones( 1, T ) * -log( PI_STEADY / beta_STEADY ), 'r-' );
