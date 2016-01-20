function WarningStrings = UpdateRepository( Directory, GitDirectory, Remote )
    %
    %   Copyright (c) 2013-2015 Mark Mikofski, 2015 Tom Holden

    WarningStrings = {};
    
    ShortDefaultGitDirectory = [ Directory '.git' ];
    LongDefaultGitDirectory = [ ShortDefaultGitDirectory '/' ];

    if exist( ShortDefaultGitDirectory, 'file' ) == 2
        GitDirString = fileread( ShortDefaultGitDirectory );
        CurrentGitDirectory = regexp( GitDirString, '(?<=^\s*gitdir:\s*)\S+(?=\s*$)', 'lineanchors', 'once', 'match' );
    else
        CurrentGitDirectory = LongDefaultGitDirectory;
    end

    [ ~, RepositoryName ] = fileparts( Remote );

    if exist( CurrentGitDirectory, 'dir' ) == 7
        try
            RepoBuilder = org.eclipse.jgit.storage.file.FileRepositoryBuilder;

            RepoBuilder.readEnvironment;
            RepoBuilder.setWorkTree( GetJavaFile( Directory ) );
            RepoBuilder.setGitDir( GetJavaFile( CurrentGitDirectory ) );
            RepoBuilder.setMustExist( true );

            % call
            gitRepository = RepoBuilder.build;
            gitAPI = org.eclipse.jgit.api.Git( gitRepository );
            gitRepository = gitAPI.getRepository( );

            config = gitRepository.getConfig;
            RepoError = isempty( config.getString( 'remote', 'origin', 'url' ) );

            if RepoError
                disp( [ 'Old Git repository for ' RepositoryName ' did not have an origin URL. Recloning to repair.' ] );
            else
                pullCMD = gitAPI.pull;
                pullCMD.setProgressMonitor( com.mikofski.jgit4matlab.MATLABProgressMonitor );
                pullCMD.call;
                disp( [ 'Succesfully updated the latest files from the ' RepositoryName ' repository.' ] );
            end

        catch CaughtRepoError
            disp( [ 'Error ' CaughtRepoError.identifier 'accessing the Git repository for ' RepositoryName '. Details follow:' ] );
            disp( CaughtRepoError.message );
            RepoError = true; 
        end
        if RepoError
            DestinationGitDirectory = [ tempname '/' ];
            disp( [ 'Moving old Git directory from: ' CurrentGitDirectory ' to ' DestinationGitDirectory ] );
            WarningStrings = MoveFiles( WarningStrings, CurrentGitDirectory, DestinationGitDirectory );
            CurrentGitDirectory = [];
        end
    else
        CurrentGitDirectory = [];    
    end

    if isempty( CurrentGitDirectory )
        TemporaryLocation = [ tempname '/' ];
        
        cloneCMD = org.eclipse.jgit.api.Git.cloneRepository;
        cloneCMD.setDirectory( GetJavaFile( TemporaryLocation ) );
        cloneCMD.setBare( false );
        cloneCMD.setCloneAllBranches( false );
        cloneCMD.setCloneSubmodules( false );
        cloneCMD.setNoCheckout( false );
        cloneCMD.setProgressMonitor( com.mikofski.jgit4matlab.MATLABProgressMonitor );
        cloneCMD.setURI( Remote );
        cloneCMD.setBranch( 'master' );
        cloneCMD.call( );
        
        WarningStrings = MoveFiles( WarningStrings, [ TemporaryLocation '.git/' ], GitDirectory );
        WarningStrings = MoveFiles( WarningStrings, TemporaryLocation, Directory );
        
        CurrentGitDirectory = GitDirectory;
        
        if ~isempty( WarningStrings )
            disp( [ 'Possible problems cloning the latest files from the ' RepositoryName ' repository.' ] );
            disp( 'See the global variable UpdateWarningStrings for details, and try cloning manually to get the latest files, if necessary.' );
        else      
            disp( [ 'Succesfully cloned the latest files from the ' RepositoryName ' repository.' ] );
        end
    end

    SourceDestEqual = false;
    try
        movefile( CurrentGitDirectory, GitDirectory, 'f' );
    catch MoveError
        if strcmp( MoveError.identifier, 'MATLAB:MOVEFILE:SourceAndDestinationSame' )
            SourceDestEqual = true;
        else
            rethrow( MoveError );
        end
    end

    if ~SourceDestEqual
        FID = fopen( ShortDefaultGitDirectory, 'w' );
        fprintf( FID, 'gitdir: %s', relativepath( GitDirectory, Directory ) );
        fclose( FID );
    end

end
