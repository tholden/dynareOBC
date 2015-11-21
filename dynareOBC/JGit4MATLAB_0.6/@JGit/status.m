function status(gitDir,fid,amend)
%JGIT.STATUS Return the status of the repository.
%   JGIT.STATUS(GITDIR) Specify the folder in which Git Repo resides.
%   JGIT.STATUS(GITDIR,FID) Output status to file identifier, FID.
%   JGIT.STATUS(GITDIR,FID,AMEND) Add "Initial commit" text to status.
%
%   For more information see also
%   <a href="https://www.kernel.org/pub/software/scm/git/docs/git-status.html">Git Status Documentation</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/StatusCommand.html">JGit Git API Class StatusCommand</a>
%
%   Example:
%       JGIT.STATUS
%
%   See also JGIT
%
%   Copyright (c) 2013 Mark Mikofski

%% Check inputs
if nargin<1
    gitDir = pwd;
end
if nargin<2
    fid = 1;
end
if nargin<3
    amend = false;
end
gitAPI = JGit.getGitAPI(gitDir);
%% call
statusCall = gitAPI.status.call;
%% display status
fmtStr = '# On branch %s\n';
fprintf(fid,fmtStr,char(gitAPI.getRepository.getBranch));
% if amended add "Initial commit" to status message
if amend
    fprintf(fid,'#\n# Initial commit\n#\n');
end
if statusCall.isClean
    %% status message if clean
    fprintf('nothing to commit, working directory clean\n')
else
    %% conflicting
    conflicting = statusCall.getConflicting; % list of conflicting files
    conflictingStageState = statusCall.getConflictingStageState; % map of conflicting files states
    if ~conflicting.isEmpty
        fprintf(fid,[ ...
            '# You have unmerged paths.\n', ...
            '#   (fix conflicts and run "git commit")\n', ...
            '#\n', ...
            '# Unmerged paths:\n', ...
            '#   (use "git add <file>..." to mark resolution)\n', ...
            '#\n']);
        if fid==1
            fmtStr = '#       <a href="matlab: edit(''%s'')">%s: %15s</a>\n';
        else
            fmtStr = '#       %s: %15s\n';
        end
        iter = conflictingStageState.entrySet.iterator;
        for n = 1:conflicting.size
            item = iter.next;
            value = lower(char(item.getValue.toString));key = item.getKey;
            if fid==1;str = {key,value,key};else str = {value,key};end
            fprintf(fid,fmtStr,str{:});
        end
        fprintf(fid,'#\n');
    end
    %% staged files
    added = statusCall.getAdded;
    changed = statusCall.getChanged;
    removed = statusCall.getRemoved;
    if ~added.isEmpty || ~changed.isEmpty || ~removed.isEmpty
        fprintf(fid,[ ...
            '# Changes to be committed:\n', ...
            '#   (use "git reset HEAD <file>..." to unstage)\n', ...
            '#\n']);
        if fid==1
            fmtStr = '#       <a href="matlab: edit(''%s'')">modified:   %s</a>\n';
        else
            fmtStr = '#       modified:   %s\n';
        end
        iter = changed.iterator;
        for n = 1:changed.size
            str = {iter.next};
            if fid==1;str = {str{1},str{1}};end
            fprintf(fid,fmtStr,str{:});
        end
        if fid==1
            fmtStr = '#       <a href="matlab: edit(''%s'')">new file:   %s</a>\n';
        else
            fmtStr = '#       new file:   %s\n';
        end
        iter = added.iterator;
        for n = 1:added.size
            str = {iter.next};
            if fid==1;str = {str{1},str{1}};end
            fprintf(fid,fmtStr,str{:});
        end
        if fid==1
            fmtStr = '#       <a href="matlab: edit(''%s'')">deleted:   %s</a>\n';
        else
            fmtStr = '#       deleted:    %s\n';
        end
        iter = removed.iterator;
        for n = 1:removed.size
            str = {iter.next};
            if fid==1;str = {str{1},str{1}};end
            fprintf(fid,fmtStr,str{:});
        end
        fprintf(fid,'#\n');
    end
    %% tracked but not staged
    modified = statusCall.getModified;
    missing = statusCall.getMissing;
    if ~modified.isEmpty || ~missing.isEmpty
        fprintf(fid,'# Changes not staged for commit:\n');
        if ~missing.isEmpty
            fprintf(fid,'#   (use "git add/rm <file>..." to update what will be committed)\n');
        else
            fprintf(fid,'#   (use "git add <file>..." to update what will be committed)\n');
        end
        fprintf(fid,[ ...
            '#   (use "git checkout -- <file>..." to discard changes in working directory)\n', ...
            '#\n']);
        if fid==1,fid = 2;end % print in red
        fmtStr = '#       modified:   %s\n';
        iter = modified.iterator;
        for n = 1:modified.size
            fprintf(fid,fmtStr,iter.next);
        end
        fmtStr = '#       deleted:    %s\n';
        iter = missing.iterator;
        for n = 1:missing.size
            fprintf(fid,fmtStr,iter.next);
        end
        if fid==2,fid = 1;end
        fprintf(fid,'#\n');
    end
    %% untracked
    untracked = statusCall.getUntracked; % list of files that are not ignored, and not in the index.
    if ~untracked.isEmpty
        fprintf(fid,[ ...
            '# Untracked files:\n', ...
            '#   (use "git add <file>..." to include in what will be committed)\n', ...
            '#\n']);
        fmtStr = '#       %s\n';
        if fid==1,fid = 2;end % print in red
        iter = untracked.iterator;
        for n = 1:untracked.size
            fprintf(fid,fmtStr,iter.next);
        end
        if fid==2,fid = 1;end
        fprintf(fid,'#\n');
    end
    %% summary line
    % only add to status call, not to commit message
    if added.isEmpty && changed.isEmpty && removed.isEmpty
        if ~modified.isEmpty || ~missing.isEmpty
            if fid==1
                fprintf(fid,'no changes added to commit (use "git add" and/or "git commit -a")\n');
            end
        elseif ~untracked.isEmpty
            if fid==1
                fprintf(fid,'nothing added to commit but untracked files present (use "git add" to track)\n');
            end
        end
    end
end
end
