function results = pull(varargin)
%JGIT.PULL Pull from remote repository
%   JGIT.PULL(PARAMETER,VALUE,...) uses any combination of the
%   following PARAMETER, VALUE pairs.
%   'setRebase' <logical> [false] use rebase.
%   'progressMonitor' <ProgressMonitor> [MATLABProgressMonitor] Display progress.
%   'gitDir' <char> [PWD] Applies to the repository in specified folder.
%
%   For more information see also
%   <a href="https://www.kernel.org/pub/software/scm/git/docs/git-pull.html">Git Pull Documentation</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/PullCommand.html">JGit Git API Class PullCommand</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/PullResult.html">JGit Git API Class PullResult</a>
%
%   Example:
%       JGIT.PULL % pull
%       JGIT.PULL('setRebase',true) % use rebase
%
%   See also JGIT, MERGE, CLONE
%
%   Copyright (c) 2013 Mark Mikofski

%% Constants
% TODO: move all constants to JGIT class definition.
% Merge status
CONFLICTING = javaMethod('valueOf','org.eclipse.jgit.api.MergeResult$MergeStatus','CONFLICTING');
%% check inputs
p = inputParser;
p.addParamValue('setRebase',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('progressMonitor',com.mikofski.jgit4matlab.MATLABProgressMonitor,@(x)isjava(x))
p.addParamValue('gitDir',pwd,@(x)validateattributes(x,{'char'},{'row'}))
p.parse(varargin{:})
gitDir = p.Results.gitDir;
gitAPI = JGit.getGitAPI(gitDir);
pullCMD = gitAPI.pull;
%% repository
repo = gitAPI.getRepository;
%% set rebase
if p.Results.setRebase
    pullCMD.setRebase(true);
end
%% set progressMonitor
pullCMD.setProgressMonitor(p.Results.progressMonitor);
%% call
% UserInfoSshSessionFactory is a customized SshSessionFactory that
% configures a CredentialProvider to provide SSH passphrase for Jsch and
% registers itself as the default instance of SshSessionFactory.
com.mikofski.jgit4matlab.UserInfoSshSessionFactory;
pullResult = pullCMD.call;
fprintf('%s\n',char(pullResult.getMergeResult.getMergeStatus))
%% results
if nargout>0
    results = pullResult;
end
%% status
mergeResult = pullResult.getMergeResult;
if ~isempty(mergeResult)
    s = mergeResult.getMergeStatus;
    if s.isSuccessful
        return
    elseif s.equals(CONFLICTING)
        % get conflicts
        conflicts = mergeResult.getConflicts; % hashmap of paths: [mergeConflict][line#]
        paths = conflicts.keySet.toArray; % array of paths with conflicts
        % write a BASE file if it exists
        base = mergeResult.getBase; % RevCommit common base for merged commits
        baseTree = base.getTree; % RevTree
        mergeCommits = mergeResult.getMergedCommits; % array of RevCommits of merged commits
        local = mergeCommits(1);remote = mergeCommits(2); % RevCommit, assume [local,remove]
        localTree = local.getTree;remoteTree = remote.getTree; % RevTree
        for p = 1:numel(paths)
            % base paths
            writeConflictPath(repo,paths(p),baseTree,'BASE');
            % local paths
            writeConflictPath(repo,paths(p),localTree,'LOCAL');
            % remote paths
            writeConflictPath(repo,paths(p),remoteTree,'REMOTE');
            % backup conflict markers
            copyfile(paths(p),[paths(p),'.orig']);
        end
    end
end
end

function writeConflictPath(repo,path,tree,commit)
treewalk = org.eclipse.jgit.treewalk.TreeWalk.forPath(repo,path,tree);
fileOS = java.io.FileOutputStream([path,'.',commit]);
if ~isempty(treewalk)
    repo.open(treewalk.getObjectId(0)).copyTo(fileOS)
end
% if treewalk is empty, path is /dev/null, so file is empty
fileOS.close;
end
