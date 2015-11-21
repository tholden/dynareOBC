function clone(uri,varargin)
%JGIT.CLONE Clone a repository into a new working directory.
%   JGIT.CLONE(URI) makes a clone of the repo found at URI in the current
%   folder. The cloned repo is named the same as the repo found at the URI.
%   JGIT.CLONE(URI,PARAMETER,VALUE,...) uses any combination of the following
%   PARAMETER, VALUE pairs.
%   'bare' <logical> [false] Clone into a bare repository.
%   'branch' <char> [master] Initial branch to checkout.
%   'branchesToClone' <cellstr> [master] Clone specified branches.
%   'cloneAllBranches' <logical> [false] Clone all branches.
%   'cloneSubmodules' <logical> [false] Initialize and update submodules.
%   'directory' <char> [uriish.humanish] Clone into specified directory.
%   'noCheckout' <logical> [false] Don't checkout any branch after cloning.
%   'progressMonitor' <ProgressMonitor> [MATLABProgressMonitor] Display progress.
%   'remote' <char> [origin] Name of remote to track of upstream repository.
%
%   For more information see also
%   <a href="https://git-scm.com/docs/git-clone.html">Git Clone Documentation</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/CloneCommand.html">JGit Git API Class CloneCommand</a>
%
%   Example:
%       JGIT.CLONE('git://github.com/eclipse/jgit.git','directory','repos/jgit')
%
%   See also JGIT, INIT, PULL
%
%   Copyright (c) 2013 Mark Mikofski

%% check inputs
p = inputParser;
p.addRequired('uri',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('bare',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('branch','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('branchesToClone',{},@(x)validateattributes(x,{'cell'},{'nonempty'}))
p.addParamValue('cloneAllBranches',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('cloneSubmodules',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('directory','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('noCheckout',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('progressMonitor',com.mikofski.jgit4matlab.MATLABProgressMonitor,@(x)isjava(x))
p.addParamValue('remote','',@(x)validateattributes(x,{'char'},{'row'}))
p.parse(uri,varargin{:})
% Git.init is a static method (so is clone) for obvious reasons
cloneCMD = org.eclipse.jgit.api.Git.cloneRepository;
%% set URI
cloneCMD.setURI(p.Results.uri);
%% bare repository
if p.Results.bare
    cloneCMD.setBare(true);
end
%% set branch
if ~isempty(p.Results.branch)
    cloneCMD.setBranch(p.Results.branch);
end
%% set branches to clone
if ~isempty(p.Results.branchesToClone)
    cloneCMD.setBranchesToClone(p.Results.branchesToClone);
end
%% bare cloneAllBranches
if p.Results.cloneAllBranches
    cloneCMD.setCloneAllBranches(true);
end
%% bare cloneSubmodules
if p.Results.cloneSubmodules
    cloneCMD.setCloneSubmodules(true);
end
%% set directory
% Java always makes relative paths in matlab userpath
if isempty(p.Results.directory)
    humanDir = org.eclipse.jgit.transport.URIish(p.Results.uri).getHumanishName;
    cwd = pwd; % get current directory
    folder = java.io.File(cwd,humanDir); 
else
    folder = java.io.File(p.Results.directory);
    if ~folder.isAbsolute
        cwd = pwd; % get current directory
        folder = java.io.File(cwd,p.Results.directory); % folder relative to cwd
    end
end
% put cloned repo in correct folder
cloneCMD.setDirectory(folder);
%% bare noCheckout
if p.Results.noCheckout
    cloneCMD.setNoCheckout(true);
end
%% set progressMonitor
cloneCMD.setProgressMonitor(p.Results.progressMonitor);
%% set remote
if ~isempty(p.Results.remote)
    cloneCMD.setRemote(p.Results.remote);
end
%% call
% UserInfoSshSessionFactory is a customized SshSessionFactory that
% configures a CredentialProvider to provide SSH passphrase for Jsch and
% registers itself as the default instance of SshSessionFactory.
com.mikofski.jgit4matlab.UserInfoSshSessionFactory;
cloneCMD.call;
end