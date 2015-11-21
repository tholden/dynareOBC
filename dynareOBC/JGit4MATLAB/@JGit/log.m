function log(varargin)
%JGIT.LOG Show the commit log.
%   JGIT.LOG(PARAMETER,VALUE,...) uses any combination of the following
%   PARAMETER, VALUE pairs.
%   'maxCount' <integer> [] Maximum count of commit logs to show.
%   'skip' <integer> [] Number of commits logs to skip.
%   'since' <char> [] Show log of newer commits since this commit.
%   'until' <char> [] Show log of older commits until this commit.
%   'path' <char|cellstr> [] Show log of files on specified paths.
%   'not' <char> [] Same as git --not start or ^start.
%   'start' <char> [] Mark start of traversal, same a until start.
%   'all' <logitcal> Add all refs as commits to start the graph traversal from.
%   'gitDir' <char> [PWD] Specify the folder in which Git Repo resides.
%
%   For more information see also
%   <a href="https://www.kernel.org/pub/software/scm/git/docs/git-log.html">Git Log Documentation</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/LogCommand.html">JGit Git API Class LogCommand</a>
%
%   Example:
%       JGIT.LOG('since','HEAD~5') % show last 5 commits
%
%   See also JGIT, STATUS
%
%   Copyright (c) 2013 Mark Mikofski

%% check inputs
p = inputParser;
p.addParamValue('maxCount',0,@(x)validateattributes(x,{'numeric'},{'integer', ...
    'nonnegative','scalar'}))
p.addParamValue('skip',0,@(x)validateattributes(x,{'numeric'},{'integer', ...
    'nonnegative','scalar'}))
p.addParamValue('since','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('until','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('path','',@(x)validatepaths(x))
p.addParamValue('add','',@(x)validatepaths(x))
p.addParamValue('not','',@(x)validatepaths(x))
p.addParamValue('all',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('gitDir',pwd,@(x)validateattributes(x,{'char'},{'row'}))
p.parse(varargin{:})
gitDir = p.Results.gitDir;
gitAPI = JGit.getGitAPI(gitDir);
logCMD = gitAPI.log;
%% set max count
if p.Results.maxCount>0
    logCMD.setMaxCount(p.Results.maxCount);
end
%% set skip
if p.Results.skip>0
    logCMD.setSkip(p.Results.skip);
end
%% set since and until
repo = gitAPI.getRepository;
if ~isempty(p.Results.since) && ~isempty(p.Results.until)
    since = repo.resolve(p.Results.since);
    until = repo.resolve(p.Results.until);
    logCMD.addRange(since,until);
elseif ~isempty(p.Results.since) && isempty(p.Results.until)
    since = repo.resolve(p.Results.since);
    HEAD = repo.resolve('HEAD');
    logCMD.addRange(since,HEAD);
elseif isempty(p.Results.since) && ~isempty(p.Results.until)
    start = repo.resolve(p.Results.until);
    logCMD.add(start);
end
%% set path
if iscellstr(p.Results.path)
    for n = 1:numel(p.Results.path)
        logCMD.addPath(p.Results.path{n});
    end
elseif ~isempty(p.Results.path)
    logCMD.addPath(p.Results.path);
end
%% set add
if iscellstr(p.Results.add)
    for n = 1:numel(p.Results.add)
        logCMD.add(repo.resolve(p.Results.add{n}));
    end
elseif ~isempty(p.Results.add)
    logCMD.add(repo.resolve(p.Results.add));
end
%% set not
if iscellstr(p.Results.not)
    for n = 1:numel(p.Results.not)
        logCMD.not(repo.resolve(p.Results.not{n}));
    end
elseif ~isempty(p.Results.not)
    logCMD.not(repo.resolve(p.Results.not));
end
%% all
if p.Results.all
    logCMD.all
end
%% no revision range
% this is the default - mark traversal start at HEAD
% end
%% call
revwalker = logCMD.call;
%% display log
commit = revwalker.next;
while ~isempty(commit)
    fprintf(2,'commit %s\n',char(commit.getName));
    author = commit.getAuthorIdent;
    fprintf('Author: %s <%s>\n',char(author.getName),char(author.getEmailAddress))
    fprintf('Date: %s\n',char(author.getWhen))
    fprintf('\n\t%s\n\n',strtrim(char(commit.getFullMessage)))
    commit = revwalker.next;
    prompt = '<ENTER to continue/Q-ENTER to quit>:';
    reply = input(prompt,'s');
    fprintf('%s',repmat(sprintf('\b'),numel(prompt)+numel(reply)+1,1))
    if strncmpi(reply,'q',1)
        break
    end
end
end

function tf = validatepaths(paths)
if ~iscellstr(paths)
    validateattributes(paths,{'char'},{'row'})
end
tf = true;
end
