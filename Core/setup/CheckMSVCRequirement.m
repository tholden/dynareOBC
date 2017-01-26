function DLLInstalled = CheckMSVCRequirement( MajorVersion, DesiredBuild, Platform, URL, dynareOBCPath, SavePath, UnzipPath )
    Build = int32( 0 );
    try
        Build = winqueryreg( 'HKEY_LOCAL_MACHINE', [ 'SOFTWARE\Microsoft\VisualStudio\' MajorVersion  '\VC\Runtimes\' Platform '\' ], 'Bld' );
    catch
    end
    if Build < int32( DesiredBuild )
        try
            Build = winqueryreg( 'HKEY_LOCAL_MACHINE', [ 'SOFTWARE\Wow6432Node\Microsoft\VisualStudio\' MajorVersion '\VC\Runtimes\' Platform '\' ], 'Version' );
        catch
        end
    end
    if Build < int32( DesiredBuild )
        if ~exist( [ dynareOBCPath '/Core/requirements/' SavePath ], 'file' )
            fprintf( '\n' );
            disp( [ 'Downloading ' SavePath '.' ] );
            fprintf( '\n' );
            aria_urlwrite( dynareOBCPath, URL, [ dynareOBCPath '/Core/requirements/' SavePath ] );
        end
        if nargin > 5
            if ~exist( [ dynareOBCPath '/Core/requirements/' UnzipPath ], 'file' )
                fprintf( '\n' );
                disp( [ 'Extracting files from ' SavePath '.' ] );
                fprintf( '\n' );
                unzip( [ dynareOBCPath '/Core/requirements/' SavePath ], fileparts( [ dynareOBCPath '/Core/requirements/' UnzipPath ] ) );
            end
            ExePath = UnzipPath;
        else
            ExePath = SavePath;
        end
        fprintf( '\n' );
        disp( [ 'Running ' ExePath '.' ] );
        fprintf( '\n' );
        system( [ 'start "Installing dynareOBC requirement" /wait "' dynareOBCPath '/Core/requirements/' ExePath '" /passive /norestart' ] );
        DLLInstalled = true;
    else
        DLLInstalled = false;
    end
end
