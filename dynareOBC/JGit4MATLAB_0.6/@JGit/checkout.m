function results = checkout(name,varargin)
%JGIT.CHECKOUT Checkout a branch to the working tree.
%   JGIT.CHECKOUT(NAME) Specify the name of the branch or commit to check out,
%   or the new branch name.
%   JGIT.CHECKOUT(NAME,PARAMETER,VALUE,...) uses any combination of the following
%   PARAMETER, VALUE pairs.
%   'path' <char|cellstr> [''] Checkout PATH(S) from the index. If 'path' is
%       specified, NAME argument and 'createBranch' are ignored.
%   'getResults' <logical> [false] Return CheckoutResults Java class.
%   'allPaths' <logical> [false] Checkout all paths. If 'allPaths' is true,
%       NAME argument and 'createBranch' are ignored.
%   'createBranch' <logical> [false] Create new branch.
%   'force' <logical> [false] Checkout branch/commit or files from index
%       even if they differ from HEAD or have unmerged changes. Local
%       and unmerged changes are discarded.
%   'stage' <enum> Set stage for unmerged paths. Stages are 'BASE', 'OURS' or 'THEIRS'.
%   'startPoint' <char> '' Set the commit that should be checked out.
%       Default is HEAD.
%   'upstreamMode' <enum> Set branch to track upstream branch. Upstream
%       modes are 'NOTRACK', 'SET_UPSTREAM' and 'TRACK'.
%   'gitDir' <char> [PWD] Applies to the repository in specified folder.
%
%   For more information see also
%   <a href="http://git-scm.com/docs/git-checkout">Git Checkout Documentation</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/CheckoutCommand.html">JGit Git API Class CheckoutCommand</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/CheckoutResult.html">JGit Git API Class CheckoutResult</a>
%
%   Example:
%       JGIT.CHECKOUT('master') % checkout master
%       JGIT.CHECKOUT([],'path',{'file2.m','file2.m'}) % check out files
%       JGIT.CHECKOUT([],'startPoint','HEAD~1','path','file1.m')
%       JGIT.CHECKOUT('newBranch','createBranch',true) create a new branch.
%       JGIT.CHECKOUT('stable','createBranch',true,'upstreamMode','SET_UPSTREAM', ...
%           'startPoint','origin/stable') % create a new tracking branch
%
%   See also JGIT, BRANCH
%
%   Copyright (c) 2013 Mark Mikofski

%% constants
BASE = javaMethod('valueOf','org.eclipse.jgit.api.CheckoutCommand$Stage','BASE');
OURS = javaMethod('valueOf','org.eclipse.jgit.api.CheckoutCommand$Stage','OURS');
THEIRS = javaMethod('valueOf','org.eclipse.jgit.api.CheckoutCommand$Stage','THEIRS');
% TODO: move all constants to JGIT class definition.
NOTRACK = javaMethod('valueOf','org.eclipse.jgit.api.CreateBranchCommand$SetupUpstreamMode','NOTRACK');
SET_UPSTREAM = javaMethod('valueOf','org.eclipse.jgit.api.CreateBranchCommand$SetupUpstreamMode','SET_UPSTREAM');
TRACK = javaMethod('valueOf','org.eclipse.jgit.api.CreateBranchCommand$SetupUpstreamMode','TRACK');
%% check inputs
[~,pathCheckout] = fileparts(tempname);
if isempty(name) && (any(strcmpi('path', varargin)) || any(strcmpi('allPaths',varargin)))
    name = pathCheckout;
end
p = inputParser;
p.addRequired('name',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('path','',@(x)validatepaths(x))
p.addParamValue('getResults',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('allPaths',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('createBranch',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('force',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('stage','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('startPoint','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('upstreamMode','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('gitDir',pwd,@(x)validateattributes(x,{'char'},{'row'}))
p.parse(name,varargin{:})
gitDir = p.Results.gitDir;
gitAPI = JGit.getGitAPI(gitDir);
checkoutCMD = gitAPI.checkout;
%% set name
if ~strcmp(pathCheckout,p.Results.name)
    checkoutCMD.setName(p.Results.name);
end
%% add paths
if iscellstr(p.Results.path)
    for n = 1:numel(p.Results.path)
        checkoutCMD.addPath(p.Results.path{n});
    end
elseif ~isempty(p.Results.path)
    checkoutCMD.addPath(p.Results.path);
end
%% set allPaths
if p.Results.allPaths
    checkoutCMD.setAllPaths(true);
end
%% set createBranch
if p.Results.createBranch
    checkoutCMD.setCreateBranch(true);
end
%% set force
if p.Results.force
    checkoutCMD.setForce(true);
end
%% set stage
if ~isempty(p.Results.stage)
    switch upper(p.Results.stage)
        case 'BASE'
            checkoutCMD.setStage(BASE);
        case 'OURS'
            checkoutCMD.setStage(OURS);
        case 'THEIRS'
            checkoutCMD.setStage(THEIRS);
        otherwise
            error('jgit:checkout:badStage', ...
                'Stages are ''BASE'', ''OURS'' or ''THEIRS''.')
    end
end
%% set startPoint
if ~isempty(p.Results.startPoint)
    checkoutCMD.setStartPoint(p.Results.startPoint);
end
%% set upstream mode
if ~isempty(p.Results.upstreamMode)
    switch upper(p.Results.upstreamMode)
        case 'NOTRACK'
            checkoutCMD.setUpstreamMode(NOTRACK);
        case 'SET_UPSTREAM'
            checkoutCMD.setUpstreamMode(SET_UPSTREAM);
        case 'TRACK'
            checkoutCMD.setUpstreamMode(TRACK);
        otherwise
            error('jgit:checkout:badUpstreamMode', ...
                'Checkout upstream modes are ''TRACK'', ''SET_UPSTREAM'' or ''NOTRACK''.')
    end
end
%% call
checkoutCMD.call;
%% get results
if nargout>0 && p.Results.getResults
    results = checkoutCMD.getResult;
end
end

function tf = validatepaths(paths)
if ~iscellstr(paths)
    validateattributes(paths,{'char'},{'row'})
end
tf = true;
end
