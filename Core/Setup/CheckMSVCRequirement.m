function DLLInstalled = CheckMSVCRequirement( MajorVersion, DesiredBuild, Platform, URL, dynareOBCPath, SavePath, Repair )
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
        fprintf( '\n' );
        disp( [ 'Running ' SavePath '.' ] );
        fprintf( '\n' );
        if Repair
            RepairString = ' /repair';
        else
            RepairString = '';
        end
        system( [ 'start "Installing DynareOBC requirement" /wait "' dynareOBCPath '/Extern/Requirements/' SavePath '" /passive /norestart' RepairString ] );
        if ~Repair
            CheckMSVCRequirement( MajorVersion, DesiredBuild, Platform, URL, dynareOBCPath, SavePath, true );
        end
        DLLInstalled = true;
    else
        DLLInstalled = false;
    end
end
