DataFile = 'UnboundedProductivityEstimation.xlsx';

beta = 0.99;
gamma = 5;
gBar = 0.005;
rho = 0.95;
sigma = 0.007;

RunLength = 1000;
BurnIn = 100;

T = RunLength + BurnIn;

gPath = zeros( T, 1 );
rPath = zeros( T, 1 );
epsilon = randn( T, 1 );

g = gBar;
r = gamma * gBar -log( beta );

for t = 1 : T
	g = ( 1 - rho ) * gBar + rho * g + sigma * epsilon( t );
	mu = ( 1 - rho ) * gBar + rho * g;
	r = -log( beta ) + gamma * mu - gamma ^ 2 * sigma ^ 2 / 2;
	rPath( t ) = r;
	gPath( t ) = g;
end

gPath = gPath( BurnIn + 1 : end, 1 );
rPath = rPath( BurnIn + 1 : end, 1 );

[ XLSStatus, XLSSheets ] = xlsfinfo( DataFile );
if isempty( XLSStatus )
    error( 'The given estimation data is in a format that cannot be read.' );
end
if length( XLSSheets ) < 2
    error( 'The data file does not contain a spreadsheet with observations and a spreadsheet with parameters.' );
end
XLSDataSheetName = XLSSheets{1};
[ Status, Message ] = xlswrite( DataFile, rPath, XLSDataSheetName, [ 'A2:A' int2str( RunLength + 1 ) ] );
if ~Status
    error( Message );
end
