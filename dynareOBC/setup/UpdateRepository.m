function UpdateRepository( directory, gitDirectory, remote )
%
%   Copyright (c) 2013 Mark Mikofski, 2015 Tom Holden

% Git.init is a static method (so is clone) for obvious reasons
initCMD = org.eclipse.jgit.storage.file.FileRepositoryBuilder;

%% change message to reinitialized if gitDir already exists
msg = 'Initialized';
if exist( gitDirectory, 'dir' ) == 7
    msg = 'Reinitialized';
end
%% set directory
folder = java.io.File( directory );
% Java always makes relative paths in matlab userpath
if ~folder.isAbsolute
    folder = java.io.File( pwd, directory ); % folder relative to pwd
end

git_folder = java.io.File( gitDirectory );
% Java always makes relative paths in matlab userpath
if ~git_folder.isAbsolute
    git_folder = java.io.File( pwd, gitDirectory ); % folder relative to pwd
end

initCMD.setWorkTree( folder );
initCMD.setGitDir( git_folder );
% initCMD.readEnviroment;

%% call
gitRepository = initCMD.build;
gitAPI = org.eclipse.jgit.api.Git( gitRepository );
gitRepository = gitAPI.getRepository( );
%% output message
gitDir = gitRepository.getDirectory;
fprintf('%s Git repository in %s\n',msg,char(gitDir));

config = gitRepository.getConfig;

OriginSet = isempty( config.getString( 'remote', 'origin', 'url' ) );

[ ~, RepositoryName ] = fileparts( remote );

if OriginSet
    disp( [ 'Setting new ' RepositoryName ' Git origin to: ' remote ] );
    config.setString( 'remote', 'origin', 'url', remote );
    config.save;
    disp( [ 'Downloading the latest ' RepositoryName ' files.' ] );
    fetchCMD = gitAPI.fetch;
    fetchCMD.call;
    disp( [ 'Updating local ' RepositoryName ' files from the downloaded ones.' ] );
    resetCMD = gitAPI.reset;
    resetCMD.setMode( org.eclipse.jgit.reset.ResetType.HARD );
    resetCMD.setProgressMonitor( com.mikofski.jgit4matlab.MATLABProgressMonitor );
    resetCMD.call;
else
    disp( [ 'Merging any local changes with the latest ' RepositoryName ' files.' ] );
    pullCMD = gitAPI.pull;
    pullCMD.call;
end
