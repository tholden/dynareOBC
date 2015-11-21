function branch(cmd,newName,varargin)
%JGIT.BRANCH Create, delete, list and rename branches.
%   JGIT.BRANCH(CMD) sets branch command, CMD. Possible branch commands are
%   'create', 'delete', 'list' and 'rename'.
%   JGIT.BRANCH(CMD,NEWNAME) New name of created or renamed branch.
%   JGIT.BRANCH(CMD,NEWNAME,PARAMETER,VALUE,...) uses any combination of the
%   following PARAMETER, VALUE pairs. Use NEWNAME=[] for delete and list modes.
%   'force' <logical> [false] Force creation or deletion.
%   'startPoint' <char> ['HEAD'] Starting commit of branch.
%   'upstreamMode' <enum> Set branch to track upstream branch. Upstream
%       modes are 'NOTRACK', 'SET_UPSTREAM' and 'TRACK'.
%   'listMode' <enum> Set list mode for listing branches. List modes are
%       'ALL' and 'REMOTE'.
%   'oldNames' <char|cellstr> [''] Name of old branch(es) to be deleted or
%       renamed. If empty does nothing for delete, and for rename defaults to
%       currently checked out branch.
%   'gitDir' <char> [PWD] Applies to the repository in specified folder.
%
%   For more information see also
%   <a href="http://git-scm.com/docs/git-branch">Git Branch Documentation</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/CreateBranchCommand.html">JGit Git API Class CreateBranchCommand</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/DeleteBranchCommand.html">JGit Git API Class DeleteBranchCommand</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/ListBranchCommand.html">JGit Git API Class ListBranchCommand</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/RenameBranchCommand.html">JGit Git API Class RenameBranchCommand</a>
%
%   Example:
%       JGIT.BRANCH('list') % list local branches
%       JGIT.BRANCH('list',[],'listMode','REMOTE') % list remote branches
%       JGIT.BRANCH('create','newFeature') % create "newFeature" branch
%       JGIT.BRANCH('rename','superFeature','oldNames','newFeature')
%       JGit.branch('create','remoteBranch', ...
%           'startPoint','refs/remotes/origin/remoteBranch', ...
%           'upstreamMode','TRACK') % track "remoteBranch"
%       JGIT.BRANCH('delete',[],'oldNames',{'superFeature','remoteBranch'})
%
%   See also JGIT, CHECKOUT
%
%   Copyright (c) 2013 Mark Mikofski

%% constants
% TODO: move all constants to JGIT class definition.
NOTRACK = javaMethod('valueOf','org.eclipse.jgit.api.CreateBranchCommand$SetupUpstreamMode','NOTRACK');
SET_UPSTREAM = javaMethod('valueOf','org.eclipse.jgit.api.CreateBranchCommand$SetupUpstreamMode','SET_UPSTREAM');
TRACK = javaMethod('valueOf','org.eclipse.jgit.api.CreateBranchCommand$SetupUpstreamMode','TRACK');
ALL = javaMethod('valueOf','org.eclipse.jgit.api.ListBranchCommand$ListMode','ALL');
REMOTE = javaMethod('valueOf','org.eclipse.jgit.api.ListBranchCommand$ListMode','REMOTE');
%% check inputs
if (nargin<2 || isempty(newName)) && ...
        (strcmpi(cmd,'delete') || strcmpi(cmd,'list'))
    newName = 'n/a';
end
p = inputParser;
p.addRequired('cmd',@(x)validateCMD(x))
p.addRequired('newName',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('force',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('startPoint','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('upstreamMode','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('listMode','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('oldNames','',@(x)validateNames(x))
p.addParamValue('gitDir',pwd,@(x)validateattributes(x,{'char'},{'row'}))
p.parse(cmd,newName,varargin{:})
gitDir = p.Results.gitDir;
gitAPI = JGit.getGitAPI(gitDir);
%% set command
switch lower(p.Results.cmd)
    case 'create'
        %% CreateBranchCommand
        branchCMD = gitAPI.branchCreate;
        %% set name of the created branch
        branchCMD.setName(p.Results.newName);
        %% set force
        if p.Results.force
            branchCMD.setForce(true);
        end
        %% set starting point/commit
        if ~isempty(p.Results.startPoint)
            branchCMD.setStartPoint(p.Results.startPoint);
        end
        %% set upstream mode
        if ~isempty(p.Results.upstreamMode)
            switch upper(p.Results.upstreamMode)
                case 'NOTRACK'
                    branchCMD.setUpstreamMode(NOTRACK);
                case 'SET_UPSTREAM'
                    branchCMD.setUpstreamMode(SET_UPSTREAM);
                case 'TRACK'
                    branchCMD.setUpstreamMode(TRACK);
                otherwise
                    error('jgit:branch:badUpstreamMode', ...
                        'Create branch upstream modes are ''TRACK'', ''SET_UPSTREAM'' or ''NOTRACK''.')
            end
        end
    case 'delete'
        %% DeleteBranchCommand
        branchCMD = gitAPI.branchDelete;
        %% set force
        if p.Results.force
            branchCMD.setForce(true);
        end
        %% set name(s) of deleted branch(es)
        if ~isempty(p.Results.oldNames)
            branchCMD.setBranchNames(p.Results.oldNames);
        end
    case 'list'
        %% ListBranchCommand
        branchCMD = gitAPI.branchList;
        %% set listmode
        if ~isempty(p.Results.listMode)
            switch upper(p.Results.listMode)
                case 'ALL'
                    branchCMD.setListMode(ALL);
                case 'REMOTE'
                    branchCMD.setListMode(REMOTE);
                otherwise
                    error('jgit:branch:badListMode', ...
                        'List branch list modes are ''ALL'' or ''REMOTE''.')
            end
        end
    case 'rename'
        %% RenameBranchCommand
        branchCMD = gitAPI.branchRename;
        % set new name of the renamed branch
        branchCMD.setNewName(p.Results.newName);
        %% set name(s) of deleted branch(es)
        if ~isempty(p.Results.oldNames)
            assert(~iscellstr(p.Results.oldNames),'jgit:branch:rename', ...
                'For rename ''oldName'' should be a character string, not a cell string.')
            branchCMD.setOldName(p.Results.oldNames);
        end
    otherwise
        error('jgit:branch:badCmd', ...
            'Branch commands are ''create'', ''delete'', ''list'' or ''rename''.')
end
%% call
refs = branchCMD.call;
%% display list
if strcmpi(cmd,'list')
    list = refs.iterator;
    while list.hasNext;
        ref = list.next;
        if strncmpi(ref.getName,'refs/remotes/',13)
            name = char(ref.getName);
            fprintf(2,'  %s\n',name(14:end));
        else
            name = char(ref.getName);
            if strcmpi(gitAPI.getRepository.getBranch,name(12:end))
                fprintf('* <a href="matlab: fprintf(''%s''),JGit.status">%s</a>\n', ...
                    '>> JGit.status\n',name(12:end))
            else
                fprintf('  %s\n',name(12:end))
            end
        end
    end
elseif strcmpi(cmd,'create')
    fprintf('created branch: %s\n',char(refs.getName))
elseif strcmpi(cmd,'delete')
    list = refs.iterator;
    while list.hasNext;
        ref = list.next;
        fprintf('deleted branch: %s\n',ref)
    end
else
    fprintf('renamed branch: %s\n',char(refs.getName))
end
end

function tf = validateCMD(cmd)
validatestring(cmd,{'create','delete','list','rename'});
tf = true;
end

function tf = validateNames(names)
if ~iscellstr(names)
    validateattributes(names,{'char'},{'row'})
end
tf = true;
end
