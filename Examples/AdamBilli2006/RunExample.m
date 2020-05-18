% Derived from code originally written by Shifu Jiang

addpath( '../FigureUtils' );

clear all; %#ok<CLALL>

InitialState = zeros( 7, 1 );
ShockSequence = zeros( 2, 1 );

save( 'InitialStateFile.mat', 'InitialState' );
save( 'ShockSequenceFile.mat', 'ShockSequence' );

ABFig2 = figure;
for j = 1 : 10
    subplot( 5, 2, j );
end
ABFig3 = figure;

Internal( ABFig2, ABFig3, 'dynareOBC AB06 InitialStateFile=InitialStateFile.mat ShockSequenceFile=ShockSequenceFile.mat NoCleanup NoRestorePath NoPoolClose NoClearAll Bypass' );
Internal( ABFig2, ABFig3, 'dynareOBC AB06 InitialStateFile=InitialStateFile.mat ShockSequenceFile=ShockSequenceFile.mat NoCleanup NoRestorePath NoPoolClose NoClearAll Cubature CubatureRegions=10 CubatureCATCHDegree=2' ); % PeriodsOfUncertainty=128

CurrentPool = gcp( 'nocreate' );
if ~isempty( CurrentPool )
    delete( CurrentPool );
end

dynareOBCCleanUp;

figure( ABFig2 );
Titles = { '$u\rightarrow y$', '$g\rightarrow y$', '$u\rightarrow \pi$', '$g\rightarrow \pi$', '$u\rightarrow i$', '$g\rightarrow i$', '$u\rightarrow \gamma^1$', '$g\rightarrow \gamma^1$', '$u\rightarrow \gamma^2$', '$g\rightarrow \gamma^2$' };
PrepareFigure( 40, Titles, true );
SaveFigure( [ 0.5, 1 ], 'ABFig2' );

figure( ABFig3 );
Titles = { '$g\rightarrow i$' };
PrepareFigure( 40, Titles, true );
SaveFigure( [ 0.5, 0.5 ], 'ABFig3' );

delete InitialStateFile.mat;
delete ShockSequenceFile.mat;

function Internal( ABFig2, ABFig3, CurrentToCall )

    global M_ options_ oo_ dynareOBC_
    
    M_         = [];
    options_   = [];
    oo_        = [];
    dynareOBC_ = [];

    CurrentPool = gcp( 'nocreate' );
    if ~isempty( CurrentPool )
        delete( CurrentPool );
    end
    
    eval( CurrentToCall );

    Nv = size(oo_.endo_simul,1);

    % g_scale = (-5.6:0.1:-4.6)/100;
    g_scale = (-10:0.1:10)/100;
    gshock_scale = g_scale ./ -0.01524;
    g_scale = g_scale * 100;
    
    policy_fun = zeros(Nv,size(gshock_scale,2));
    for ii = 1:size(gshock_scale,2)
        ShockSequence = [0;gshock_scale(ii)];
        save( 'ShockSequenceFile.mat', 'ShockSequence' );
        [ oo__, ~ ] = RunStochasticSimulation( M_, options_, oo_, dynareOBC_ );
        policy_fun(:,ii)=oo__.endo_simul;
        disp( ii );
    end
    
    figure( ABFig2 );
    
    hold on;
    y    = 100*policy_fun(1,:);
    pi   = 400*policy_fun(2,:);
    i    = 400*policy_fun(3,:);
    gam1 = 100*policy_fun(4,:);
    gam2 = 100*policy_fun(5,:);
    
    subplot(5,2,2);
    hold on;
    plot(g_scale,y);
    subplot(5,2,4);
    hold on;
    plot(g_scale,pi);
    subplot(5,2,6);
    hold on;
    plot(g_scale,i);
    subplot(5,2,8);
    hold on;
    plot(g_scale,gam1);
    subplot(5,2,10);
    hold on;
    plot(g_scale,gam2);

    u_scale = (-0.6:0.1:0.6)/100;
    ushock_scale = u_scale ./ -0.00154;
    u_scale = u_scale * 100;

    policy_fun = zeros(Nv,size(ushock_scale,2));
    for ii = 1:size(ushock_scale,2)
        ShockSequence = [ushock_scale(ii);0];
        save( 'ShockSequenceFile.mat', 'ShockSequence' );
        [ oo__, ~ ] = RunStochasticSimulation( M_, options_, oo_, dynareOBC_ );
        policy_fun(:,ii)=oo__.endo_simul;
        disp( ii );
    end
    
    figure( ABFig3 );

    hold on;
    plot(g_scale,i,'DisplayName','i');
    set( gca, 'XLim', [-5.6,-4.6] );

    figure( 1 );
    
    hold on;
    y    = 100*policy_fun(1,:);
    pi   = 400*policy_fun(2,:);
    i    = 400*policy_fun(3,:);
    gam1 = 100*policy_fun(4,:);
    gam2 = 100*policy_fun(5,:);
    
    subplot(5,2,1);
    hold on;
    plot(u_scale,y);
    subplot(5,2,3);
    hold on;
    plot(u_scale,pi);
    subplot(5,2,5);
    hold on;
    plot(u_scale,i);
    subplot(5,2,7);
    hold on;
    plot(u_scale,gam1);
    subplot(5,2,9);
    hold on;
    plot(u_scale,gam2);

end
