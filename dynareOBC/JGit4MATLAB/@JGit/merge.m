function results = merge(include,varargin)
%JGIT.MERGE Merge commit with current head.
%   JGIT.MERGE(INCLUDE) sets references and ID's of commits to merge.
%   JGIT.MERGE(INCLUDE,PARAMETER,VALUE,...) uses any combination of the
%   following PARAMETER, VALUE pairs.
%   'name' <char> Name of the merged commit (EG: --message).
%   'fastForward' <FastForwardMode> ['FF'] Set fast forward mode.
%       Options are 'FF','FF_ONLY' and 'NO_FF'.
%   'squash' <logical> [false] If true do not commit or move HEAD.
%   'commit' <logical> [true] Automatically commit after a successful merge.
%   'strategy' <MergeStrategy> Set the merge strategy to use. Options
%       are 'OURS', 'RECURSIVE', 'RESOLVE', 'SIMPLE_TWO_WAY_IN_CORE' and 'THEIRS'.
%   'gitDir' <char> [PWD] Applies to the repository in specified folder.
%
%   For more information see also
%   <a href="https://www.kernel.org/pub/software/scm/git/docs/git-merge.html">Git Merge Documentation</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/MergeCommand.html">JGit Git API Class MergeCommand</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/MergeResult.html">JGit Git API Class MergeResult</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/MergeCommand.FastForwardMode.html">JGit Git API Class MergeCommand FastForwardMode</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/merge/MergeStrategy.html">JGit Git API Class MergeStrategy</a>
%
%   Example:
%       JGIT.MERGE('feature') % merge 'feature' branch into current head
%       JGIT.MERGE('fad9663b23d59332fd5387ba6f506c54167a6707')
%       JGIT.MERGE('feature', 'name', 'merge feature into master') % add commit message
%       JGIT.MERGE('feature','setSquash',true) % merge but don't commit or move head
%
%   See also JGIT, FETCH, CHECKOUT
%
%   Copyright (c) 2013 Mark Mikofski

%% Tasks
% TODO: include should be paramValue, not required, and should be char or
% cellstring, even though JGit can't do octopus now, it may in future, and
% making include optional will make adding abort easier, since abort has no
% arguments.
% TODO: add --abort option. Check repository state, MERGING? then use
% 'git reset --hard HEAD'
%% constants
% TODO: move all constants to JGIT class definition.
% Merge status
CONFLICTING = javaMethod('valueOf','org.eclipse.jgit.api.MergeResult$MergeStatus','CONFLICTING');
% Fast Forward Modes
FF = javaMethod('valueOf','org.eclipse.jgit.api.MergeCommand$FastForwardMode','FF');
FF_ONLY = javaMethod('valueOf','org.eclipse.jgit.api.MergeCommand$FastForwardMode','FF_ONLY');
NO_FF = javaMethod('valueOf','org.eclipse.jgit.api.MergeCommand$FastForwardMode','NO_FF');
%% Merge Strategies
OURS = org.eclipse.jgit.merge.MergeStrategy.OURS;
RECURSIVE = org.eclipse.jgit.merge.MergeStrategy.RECURSIVE;
RESOLVE = org.eclipse.jgit.merge.MergeStrategy.RESOLVE;
SIMPLE_TWO_WAY_IN_CORE = org.eclipse.jgit.merge.MergeStrategy.SIMPLE_TWO_WAY_IN_CORE;
THEIRS = org.eclipse.jgit.merge.MergeStrategy.THEIRS;
%% check inputs
p = inputParser;
p.addRequired('include',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('name','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('squash',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('commit',true,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('fastForward','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('strategy','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('gitDir',pwd,@(x)validateattributes(x,{'char'},{'row'}))
p.parse(include,varargin{:})
gitDir = p.Results.gitDir;
gitAPI = JGit.getGitAPI(gitDir);
mergeCMD = gitAPI.merge;
%% repository
repo = gitAPI.getRepository;
%% include
if ~isempty(p.Results.name)
    mergeCMD.include(p.Results.name, repo.resolve(p.Results.include));
else
    mergeCMD.include(repo.resolve(p.Results.include));
end
%% set fast forward mode
if ~isempty(p.Results.fastForward)
    switch upper(p.Results.fastForward)
        case 'FF'
            mergeCMD.setFastForward(FF);
        case 'FF_ONLY'
            mergeCMD.setFastForward(FF_ONLY);
        case 'NO_FF'
            mergeCMD.setFastForward(NO_FF);
        otherwise
            error('jgit:merge:badFFmode', ...
                'Stages are ''FF'', ''FF_ONLY'' or ''NO_FF''.')
    end
end
%% set squash
if p.Results.squash
    mergeCMD.setSquash(true);
end
%% set commit
% default is true, only set if false
if ~p.Results.commit
    mergeCMD.setCommit(false);
end
%% set fast forward mode
if ~isempty(p.Results.strategy)
    switch upper(p.Results.strategy)
        case 'OURS'
            mergeCMD.setStrategy(OURS);
        case 'RECURSIVE'
            mergeCMD.setStrategy(RECURSIVE);
        case 'RESOLVE'
            mergeCMD.setStrategy(RESOLVE);
        case 'SIMPLE_TWO_WAY_IN_CORE'
            mergeCMD.setStrategy(SIMPLE_TWO_WAY_IN_CORE);
        case 'THEIRS'
            mergeCMD.setStrategy(THEIRS);
        otherwise
            error('jgit:merge:badMergeStrategy', ...
                ['Valid strategies: ''OURS'', ''RECURSIVE'', ''RESOLVE'',', ...
                ' ''SIMPLE_TWO_WAY_IN_CORE'' or ''THEIRS''.'])
    end
end
%% call CMD
mergeResult = mergeCMD.call;
fprintf('%s\n',char(mergeResult.getMergeStatus))
%% results
if nargout>0
    results = mergeResult;
end
%% status
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

function writeConflictPath(repo,path,tree,commit)
treewalk = org.eclipse.jgit.treewalk.TreeWalk.forPath(repo,path,tree);
fileOS = java.io.FileOutputStream([path,'.',commit]);
if ~isempty(treewalk)
    repo.open(treewalk.getObjectId(0)).copyTo(fileOS)
end
% if treewalk is empty, path is /dev/null, so file is empty
fileOS.close;
end
