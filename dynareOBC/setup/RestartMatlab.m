function RestartMatlab( CurrentPath, InputFileName, varargin )
    fprintf( 1, '\n' );
    disp( 'dynareOBC needs to restart MATLAB. dynareOBC will attempt to continue after MATLAB is restarted.' );
    fprintf( 1, '\n' );
    input( 'Press return to continue, or Ctrl+C to cancel.' );
    system( [ 'start matlab.exe -sd "' CurrentPath '" -r "try;matlabrc;catch;end;try;startup;catch;end; dynareOBC ' InputFileName ' ' strjoin( varargin ) '"' ] );
    system( [ 'taskkill /f /t /pid ' num2str( feature( 'getpid' ) ) ] ); 
end
