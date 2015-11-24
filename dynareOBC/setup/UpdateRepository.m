function UpdateRepository( Directory, GitDirectory, Remote )
    %
    %   Copyright (c) 2013-2015 Mark Mikofski, 2015 Tom Holden

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
                checkoutCMD = gitAPI.checkout;
                checkoutCMD.setAllPaths( true );
                checkoutCMD.setForce( false );
                checkoutCMD.setName( 'master' );
                checkoutCMD.call;
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
            MoveFiles( CurrentGitDirectory, DestinationGitDirectory );
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
        cloneCMD.setCloneSubmodules( true );
        cloneCMD.setNoCheckout( true );
        cloneCMD.setProgressMonitor( com.mikofski.jgit4matlab.MATLABProgressMonitor );
        cloneCMD.setURI( Remote );
        cloneCMD.setBranch( 'master' );
        cloneCMD.call( );
        
        MoveFiles( [ TemporaryLocation '.git/' ], GitDirectory );
        
        disp( [ 'Succesfully cloned the latest files from the ' RepositoryName ' repository.' ] );

        CurrentGitDirectory = GitDirectory;
        
        RepoBuilder = org.eclipse.jgit.storage.file.FileRepositoryBuilder;

        RepoBuilder.readEnvironment;
        RepoBuilder.setWorkTree( GetJavaFile( Directory ) );
        RepoBuilder.setGitDir( GetJavaFile( CurrentGitDirectory ) );
        RepoBuilder.setMustExist( true );

        gitRepository = RepoBuilder.build;
        gitAPI = org.eclipse.jgit.api.Git( gitRepository );
        checkoutCMD = gitAPI.checkout;
        checkoutCMD.setAllPaths( true );
        checkoutCMD.setForce( true );
        checkoutCMD.setName( 'master' );
        checkoutCMD.call;
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
