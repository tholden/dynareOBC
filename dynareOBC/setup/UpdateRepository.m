function UpdateRepository( directory, remote )
%
%   Copyright (c) 2013 Mark Mikofski, 2015 Tom Holden

% Git.init is a static method (so is clone) for obvious reasons
initCMD = org.eclipse.jgit.api.Git.init;

%% change message to reinitialized if gitDir already exists
msg = 'Initialized';
if exist( fullfile( directory, JGit.GIT_DIR ), 'dir' )==7
    msg = 'Reinitialized';
end
%% set directory
folder = java.io.File( directory );
% Java always makes relative paths in matlab userpath
if ~folder.isAbsolute
    folder = java.io.File( pwd, directory ); % folder relative to pwd
end
initCMD.setDirectory( folder );
%% call
git = initCMD.call;
%% output message
gitDir = git.getRepository.getDirectory;
fprintf('%s empty Git repository in %s\n',msg,char(gitDir));

config = git.getRepository.getConfig;

OriginSet = isempty( config.getString( 'remote', 'origin', 'url' ) );

tmp = directory;
if tmp( end ) == '\' || tmp( end ) == '/'
    tmp = tmp( 1:(end-1) );
end
[ ~, RepositoryName ] = fileparts( tmp );

if OriginSet
    disp( [ 'Setting new ' RepositoryName ' Git origin to: ' remote ] );
    config.setString( 'remote', 'origin', 'url', remote );
    config.save;
    disp( [ 'Downloading the latest ' RepositoryName ' files.' ] );
    JGit.fetch( 'gitDir', directory );
    disp( [ 'Updating local ' RepositoryName ' files from the downloaded ones.' ] );
    resetCMD = git.reset;
    resetCMD.setMode( org.eclipse.jgit.reset.ResetType.HARD );
    resetCMD.setProgressMonitor( com.mikofski.jgit4matlab.MATLABProgressMonitor );
    resetCMD.call;
else
    disp( [ 'Merging any local changes with the latest ' RepositoryName ' files.' ] );
    JGit.pull( 'gitDir', directory );
end
