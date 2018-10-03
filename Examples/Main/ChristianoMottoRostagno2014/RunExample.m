disp( 'This script illustrates the IRFs to 20 standard deviation shocks in the Christiano Motto Rostangno (2014) paper.' );

    FigureHandles = findall( groot, 'Type', 'figure' );
    OldFigures = zeros( length( FigureHandles ), 1 );
    for i = 1 : length( FigureHandles )
        OldFigures( i ) = FigureHandles(i).Number;
    end
    save State.mat OldFigures

dynareOBC cmr.mod ShockScale=20

    load State.mat
    FigureHandles = findall( groot, 'Type', 'figure' );
    NewFigures1 = zeros( length( FigureHandles ), 1 );
    for i = 1 : length( FigureHandles )
        NewFigures1( i ) = FigureHandles(i).Number;
    end
    NewFigures1 = setdiff( NewFigures1, OldFigures );
    save State.mat OldFigures NewFigures1

dynareOBC cmr.mod ShockScale=20 TimeToEscapeBounds=512 SkipQuickPCheck SkipFirstSolutions=1 DisplayBoundsSolutionProgress

    load State.mat
    FigureHandles = findall( groot, 'Type', 'figure' );
    NewFigures2 = zeros( length( FigureHandles ), 1 );
    for i = 1 : length( FigureHandles )
        NewFigures2( i ) = FigureHandles(i).Number;
    end
    NewFigures2 = setdiff( NewFigures2, [ OldFigures; NewFigures1 ] );

    if length( NewFigures1 ) == length( NewFigures2 )
        for i = 1 : length( NewFigures1 )
            Fig1 = figure( NewFigures1( i ) );
            Fig2 = figure( NewFigures2( i ) );
            figure;
            Axes1 = get( Fig1, 'children' );
            Axes2 = get( Fig2, 'children' );
            assert( length( Axes1 ) == 4 );
            assert( length( Axes2 ) == 4 );
            for j = 1 : 4
                copyobj( get( Axes1( j ), 'children' ), subplot( 2, 4, j ) );
                copyobj( get( Axes2( j ), 'children' ), subplot( 2, 4, j + 4 ) );
            end
            close( Fig1 );
            close( Fig2 );
        end
    else
        disp( 'There was an unexpected number of figures. Did you close one while the code was running?' );
        disp( 'Skipping plotting of Christiano Motto Rostangno (2014) IRF comparison.' );
    end
