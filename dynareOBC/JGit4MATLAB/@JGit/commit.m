function commit(varargin)
%JGIT.COMMIT Commit files to the repository.
%   JGIT.COMMIT(PARAMETER,VALUE,...) uses any combination of the following
%   PARAMETER, VALUE pairs.
%   'all' <logical> [false] Automatically stage files that have been modified or
%       deleted before commit.
%   'author' <cellstr 1x2> Set author name & email.
%   'committer' <cellstr 1x2> Set committer name & email.
%   'message' <char> [] Commit with the given message. An empty message will
%       start the editor given by GETENV(EDITOR) or JGIT.EDITOR.
%   'amend' <logical> [false] Amend the previous commit message.
%   'only' <char> [''] Commit dedicated path only.
%   'gitDir' <char> [PWD] Commit to repository in specified folder.
%
%   For more information see also
%   <a href="https://git-scm.com/docs/git-commit.html">Git Commit Documentation</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/CommitCommand.html">JGit Git API Class CommitCommand</a>
%
%   Example:
%       JGIT.COMMIT('all',true,'message','initial dump')
%
%   See also JGIT, ADD
%
%   Copyright (c) 2013 Mark Mikofski

% TODO: Need "detached state" warning

%% check inputs
p = inputParser;
p.addParamValue('all',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('author',{},@(x)validateattributes(x,{'cell'},{'numel',2}))
p.addParamValue('committer',{},@(x)validateattributes(x,{'cell'},{'numel',2}))
p.addParamValue('message','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('amend',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('only',{},@(x)validatefiles(x))
p.addParamValue('gitDir',pwd,@(x)validateattributes(x,{'char'},{'row'}))
p.parse(varargin{:})
gitDir = p.Results.gitDir;
gitAPI = JGit.getGitAPI(gitDir);
commitCMD = gitAPI.commit;
%% repository
repo = gitAPI.getRepository;
%% set all
if p.Results.all
    commitCMD.setAll(true);
end
%% set author and committer
if ~isempty(p.Results.author)
    commitCMD.setAuthor(p.Results.author{:});
end
if ~isempty(p.Results.committer)
    commitCMD.setCommitter(p.Results.committer{:});
end
%% amend commit
amendcommit = '';
if p.Results.amend
    commitCMD.setAmend(true);
    logCMD = gitAPI.log;
    revCommit = logCMD.setMaxCount(1).call;
    amendcommit = char(revCommit.next.getFullMessage);
end
%% merge message
if repo.getRepositoryState.equals(repo.getRepositoryState.MERGING_RESOLVED)
    if isempty(amendcommit)
        amendcommit = char(repo.readMergeCommitMsg);
    else
        amendcommit = [amendcommit,char(10),char(repo.readMergeCommitMsg)];
    end
end
%% only
if iscellstr(p.Results.only)
    for n = 1:numel(p.Results.only)
        commitCMD.setOnly(p.Results.only{n});
    end
elseif ischar(p.Results.only)
    commitCMD.setOnly(p.Results.only);
end
%% nothing to commit
% TODO: try replacing this with repo.getRepositoryState.canCheckout, &c.
statusCall = gitAPI.status.call;
if statusCall.isClean
    %% status message if clean
    fprintf('nothing to commit, working directory clean\n')
    return
else
    %% conflicting
%     conflicting = statusCall.getConflicting; 
    % FIXME: if conflicting and --all, need to change repo state
    %% staged files
    added = statusCall.getAdded;
    changed = statusCall.getChanged;
    removed = statusCall.getRemoved;
    %% tracked but not staged
    modified = statusCall.getModified;
    missing = statusCall.getMissing;
    %% untracked
    untracked = statusCall.getUntracked; % list of files that are not ignored, and not in the index.
    onlyModified = false(modified.size,1); % modified files listed at command line using --only
    iter = modified.iterator;
    for n = 1:modified.size
        onlyModified(n) = any(strcmp(iter.next,p.Results.only)); % only can be cellstr or char
    end
    %% quit commit show status
    % no staged files but modified files && ~setAll && ~any(onlyModified)
    % or not and untracked files
    if added.isEmpty && changed.isEmpty && removed.isEmpty && ... no staged files
            (((~modified.isEmpty || ~missing.isEmpty) && ~p.Results.all && ~any(onlyModified)) || ... but modified files and ~setAll && ~any(onlyModified)
            (modified.isEmpty && missing.isEmpty && ~untracked.isEmpty)) % or no modified files but untracked
        JGit.status
        return
    end
end
%% commit message
if ~isempty(p.Results.message)
    commitCMD.setMessage(p.Results.message);
else
    COMMIT_MSG = tempname;
    try
        fid = fopen(COMMIT_MSG,'wt');
        if ~isempty(amendcommit)
            fprintf(fid,amendcommit);
        end
        fprintf(fid,['\n# Please enter the commit message for your changes. Lines starting\n', ...
            '# with ''#'' will be ignored, and an empty message aborts the commit.\n']);
        JGit.status(gitDir,fid,p.Results.amend)
        fclose(fid);
    catch ME
        fclose(fid);
        throw(ME)
    end
    editor = getenv('EDITOR');
    if isempty(editor)
        editor = JGit.EDITOR;
    end
    status = system([editor,' ',COMMIT_MSG]);
    if ~status
        try
            fid = fopen(COMMIT_MSG,'rt');
            msg = fread(fid,'*char')';
            fclose(fid);
            delete(COMMIT_MSG)
        catch ME
            fclose(fid);
            throw(ME)
        end
        msglines = textscan(msg,'%s','Delimiter','\n','CommentStyle','#');
        msglines = msglines{1};
        msglines = [msglines,repmat({sprintf('\n')},numel(msglines),1)]';
        % strtrim removes whitespace incl. char([9 10 11 12 13 32])
        % char(10) == sprintf('\n')
        msg = strtrim([msglines{:}]);
        if isempty(msg)
            fprintf(2,'Aborting commit due to empty commit message.\n\n');
            return
        else
            commitCMD.setMessage(sprintf('%s\n',msg));
        end
    end
end
%% call
r = commitCMD.call;
branch = char(gitAPI.getRepository.getBranch);
abbrevSHA = char(r.abbreviate(7).name);
shortMsg = char(r.getShortMessage);
fprintf('[%s %s] %s\n',branch,abbrevSHA,shortMsg)
JGit.diff('previous','HEAD~1','showNameAndStatusOnly',true)
% [parse_jgit 05138e1] add parseFetch and add error for trying to checkout 2 branches, ha
%  4 files changed, 77 insertions(+)
%  create mode 100644 private/parseFetch.m
end

function tf = validatefiles(files)
if ~iscellstr(files)
    validateattributes(files,{'char'},{'row'})
end
tf = true;
end
