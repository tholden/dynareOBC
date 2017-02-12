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
        
        try
            StartUpScript = fopen( [ CurrentFolder '/DynareOBCStartUpScriptPleaseDelete.m' ], 'w' );
            fprintf( StartUpScript, 'try;\nmatlabrc;\ncatch;\nend;\ntry;\nstartup;\ncatch;\nend;\ncd( ''%s'' );\npath( ''%s'' );\ndynareOBC %s %s\n', CurrentFolder, OriginalPath, InputFileName, strjoin( varargin ) );
            fclose( StartUpScript );
            system( [ 'start matlab.exe -sd "' CurrentFolder '" -r "cd( ''' CurrentFolder ''' );DynareOBCStartUpScriptPleaseDelete;delete DynareOBCStartUpScriptPleaseDelete;"' ] );
            system( [ 'taskkill /f /t /pid ' num2str( feature( 'getpid' ) ) ] );
        catch
            error( 'dynareOBC:RestartMATLAB', 'Please manually restart MATLAB.' );
        end
        
    else
        
        error( 'dynareOBC:RestartMATLAB', 'Please manually restart MATLAB.' );
    
    end
end
