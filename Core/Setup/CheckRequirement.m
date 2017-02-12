function DLLInstalled = CheckRequirement( GUID, DesiredVersion, URL, dynareOBCPath, SavePath, UnzipPath )
    Version = int32( 0 );
    try
        Version = winqueryreg( 'HKEY_LOCAL_MACHINE', [ 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{' GUID '}' ], 'Version' );
    catch
    end
    if Version < int32( DesiredVersion )
        try
            Version = winqueryreg( 'HKEY_LOCAL_MACHINE', [ 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{' GUID '}' ], 'Version' );
        catch
        end
    end
    if Version < int32( DesiredVersion )
        if ~exist( [ dynareOBCPath '/Extern/Requirements/' SavePath ], 'file' )
            fprintf( '\n' );
            disp( [ 'Downloading ' SavePath '.' ] );
            fprintf( '\n' );
            aria_urlwrite( dynareOBCPath, URL, [ dynareOBCPath '/Extern/Requirements/' SavePath ] );
        end
        if nargin > 5
            if ~exist( [ dynareOBCPath '/Extern/Requirements/' UnzipPath ], 'file' )
                fprintf( '\n' );
                disp( [ 'Extracting files from ' SavePath '.' ] );
                fprintf( '\n' );
                unzip( [ dynareOBCPath '/Extern/Requirements/' SavePath ], fileparts( [ dynareOBCPath '/Extern/Requirements/' UnzipPath ] ) );
            end
            ExePath = UnzipPath;
        else
            ExePath = SavePath;
        end
        fprintf( '\n' );
        disp( [ 'Running ' ExePath '.' ] );
        fprintf( '\n' );
        system( [ 'start "Installing dynareOBC requirement" /wait "' dynareOBCPath '/Extern/Requirements/' ExePath '" /passive /norestart' ] );
        DLLInstalled = true;
    else
        DLLInstalled = false;
    end
end
