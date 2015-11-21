function init(varargin)
%JGIT.INIT Create an empty git repository or reinitalize an existing one.
%   JGIT.INIT(PARAMETER,VALUE,...) uses any combination of the following
%   PARAMETER, VALUE pairs.
%   'bare' <logical> [false] Initialize a bare repository.
%   'directory' <char> [PWD] Create repository in specified directory.
%
%   For more information see also
%   <a href="https://www.kernel.org/pub/software/scm/git/docs/git-init.html">Git Init Documentation</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/InitCommand.html">JGit Git API Class InitCommand</a>
%
%   Example:
%       JGIT.INIT('directory','repositories/myRepo')
%
%   See also JGIT, CLONE, PULL
%
%   Copyright (c) 2013 Mark Mikofski

%% check inputs
p = inputParser;
p.addParamValue('bare',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('directory',pwd,@(x)validateattributes(x,{'char'},{'row'}))
p.parse(varargin{:})
% Git.init is a static method (so is clone) for obvious reasons
initCMD = org.eclipse.jgit.api.Git.init;
%% bare repository
if p.Results.bare
    initCMD.setBare(true);
end
%% change message to reinitialized if gitDir already exists
msg = 'Initialized';
if exist(fullfile(p.Results.directory,JGit.GIT_DIR),'dir')==7
    msg = 'Reinitialized';
end
%% set directory
folder = java.io.File(p.Results.directory);
% Java always makes relative paths in matlab userpath
if ~folder.isAbsolute
    cwd = pwd; % get current directory
    folder = java.io.File(cwd,p.Results.directory); % folder relative to cwd
end
initCMD.setDirectory(folder);
%% call
git = initCMD.call;
%% output message
gitDir = git.getRepository.getDirectory;
fprintf('%s empty Git repository in %s\n',msg,char(gitDir))
end
