function DLLInstalled = CheckMSVCRequirement( MajorVersion, DesiredBuild, Platform, URL, dynareOBCPath, SavePath, UnzipPath )
    Build = int32( 0 );
    try
        Build = winqueryreg( 'HKEY_LOCAL_MACHINE', [ 'SOFTWARE\Microsoft\VisualStudio\' MajorVersion  '\VC\Runtimes\' Platform '\' ], 'Bld' );
    catch
    end
    if Build < int32( DesiredBuild )
        try
            Build = winqueryreg( 'HKEY_LOCAL_MACHINE', [ 'SOFTWARE\Wow6432Node\Microsoft\VisualStudio\' MajorVersion '\VC\Runtimes\' Platform '\' ], 'Bld' );
        catch
        end
    end
    if Build < int32( DesiredBuild )
        if ~exist( [ dynareOBCPath '/Extern/Requirements/' SavePath ], 'file' )
            fprintf( '\n' );
            disp( [ 'Downloading ' SavePath '.' ] );
            fprintf( '\n' );
            aria_urlwrite( dynareOBCPath, URL, [ dynareOBCPath '/Extern/Requirements/' SavePath ] );
        end
        if nargin > 6
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
        system( [ 'start "Installing DynareOBC requirement" /wait "' dynareOBCPath '/Extern/Requirements/' ExePath '" /passive /norestart' ] );
        
        if DesiredBuild == 26429
            % Double check that install took place.
            Build = int32( 0 );
            try
                Build = winqueryreg( 'HKEY_LOCAL_MACHINE', [ 'SOFTWARE\Microsoft\VisualStudio\' MajorVersion  '\VC\Runtimes\' Platform '\' ], 'Bld' );
            catch
            end
            if Build < int32( DesiredBuild )
                try
                    Build = winqueryreg( 'HKEY_LOCAL_MACHINE', [ 'SOFTWARE\Wow6432Node\Microsoft\VisualStudio\' MajorVersion '\VC\Runtimes\' Platform '\' ], 'Bld' );
                catch
                end
            end
            if Build < int32( DesiredBuild )
                fprintf( '\n' );
                disp( 'Due to a bug in the latest MSVC redistributable, the redistributable is not being detected. As a result, we will now install the required registry key.' );
                fprintf( '\n' );
                system( [ 'start "Correcting registry" /wait regedit "' dynareOBCPath '/Core/Setup/MSVCDetectionFix_' Platform '.reg"' ] );
            end
        end
        DLLInstalled = true;
    else
        DLLInstalled = false;
    end
end
