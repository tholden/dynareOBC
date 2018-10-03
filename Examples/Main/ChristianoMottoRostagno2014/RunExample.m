disp( 'This script illustrates the IRFs to 20 standard deviation shocks in the Christiano Motto Rostangno (2014) paper.' );

FigureHandles = findall( groot, 'Type', 'figure' );
OldFigures = zeros( length( FigureHandles ), 1 );
for i = 1 : length( FigureHandles )
    OldFigures( i ) = FigureHandles(i).Number;
end

dynareOBC cmr.mod ShockScale=20

FigureHandles = findall( groot, 'Type', 'figure' );
NewFigures1 = zeros( length( FigureHandles ), 1 );
for i = 1 : length( FigureHandles )
    NewFigures1( i ) = FigureHandles(i).Number;
end
NewFigures1 = setdiff( NewFigures1, OldFigures );

dynareOBC cmr.mod ShockScale=20 TimeToEscapeBounds=128 SkipQuickPCheck SkipFirstSolutions=1

FigureHandles = findall( groot, 'Type', 'figure' );
NewFigures2 = zeros( length( FigureHandles ), 1 );
for i = 1 : length( FigureHandles )
    NewFigures2( i ) = FigureHandles(i).Number;
end
NewFigures2 = setdiff( NewFigures2, [ OldFigures; NewFigures1 ] );

if length( NewFigures1 ) == length( NewFigures2 )
else
    disp( 'There was an unexpected number of figures. Did you close one while the code was running?' );
    disp( 'Skipping plotting of Christiano Motto Rostangno (2014) IRF comparison.' );
end
