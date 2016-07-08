function RestartMatlab( OriginalPath, CurrentFolder, InputFileName, varargin )
    Architecture = computer;
    if length( Architecture ) >= 5 && strcmp( Architecture( 1:5 ), 'PCWIN' )

        fprintf( '\n' );
        disp( 'dynareOBC needs to restart MATLAB. dynareOBC will attempt to continue after MATLAB is restarted.' );
        fprintf( '\n' );
        CancelString = input( 'Press return to continue, or c then return to cancel.', 's' );
        
        if strcmp( CancelString, 'c' );
            error( 'dynareOBC:RestartMATLAB', 'Please manually restart MATLAB.' );
        end
        
        system( [ 'start matlab.exe -sd "' CurrentFolder '" -r "try;matlabrc;catch;end;try;startup;catch;end; cd( ''' CurrentFolder ''' ); path( ''' OriginalPath ''' ); dynareOBC ' InputFileName ' ' strjoin( varargin ) '"' ] );
        system( [ 'taskkill /f /t /pid ' num2str( feature( 'getpid' ) ) ] ); 
        
    else
        
        error( 'dynareOBC:RestartMATLAB', 'Please manually restart MATLAB.' );
    
    end
end
