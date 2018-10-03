function HookDisableClearWarning( MODFileBaseName )
    DisableClearWarning;
    CurrentFolder = cd;
    WarningState = warning( 'off', 'MATLAB:MKDIR:DirectoryExists' );
    try
        MKDirStatus = mkdir( MODFileBaseName );
        if MKDirStatus
            cd( MODFileBaseName );
            MKDirStatus = mkdir( 'hooks' );
            if MKDirStatus
                cd( 'hooks' );
                copyfile( which( 'DisableClearWarning' ), 'priorprocessing.m', 'f' );
            end
        end
    catch
    end
    cd( CurrentFolder );
    warning( WarningState );
end
