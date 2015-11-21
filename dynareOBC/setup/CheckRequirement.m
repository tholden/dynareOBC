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
        if ~exist( [ dynareOBCPath '/dynareOBC/requirements/' SavePath ], 'file' )
            skipline( );
            disp( [ 'Downloading ' SavePath '.' ] );
            skipline( );
            aria_urlwrite( dynareOBCPath, URL, [ dynareOBCPath '/dynareOBC/requirements/' SavePath ] );
        end
        if nargin > 5
            if ~exist( [ dynareOBCPath '/dynareOBC/requirements/' UnzipPath ], 'file' )
                skipline( );
                disp( [ 'Extracting files from ' SavePath '.' ] );
                skipline( );
                unzip( [ dynareOBCPath '/dynareOBC/requirements/' SavePath ], fileparts( [ dynareOBCPath '/dynareOBC/requirements/' UnzipPath ] ) );
            end
            ExePath = UnzipPath;
        else
            ExePath = SavePath;
        end
        skipline( );
        disp( [ 'Running ' ExePath '.' ] );
        skipline( );
        system( [ 'start "Installing dynareOBC requirement" /wait "' dynareOBCPath '/dynareOBC/requirements/' ExePath '" /passive /norestart' ] );
        DLLInstalled = true;
    else
        DLLInstalled = false;
    end
end
