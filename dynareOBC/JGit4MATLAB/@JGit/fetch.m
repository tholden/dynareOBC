function fetch(varargin)
%JGIT.FETCH Fetch from remote repository
%   JGIT.FETCH(PARAMETER,VALUE,...) uses any combination of the
%   following PARAMETER, VALUE pairs.
%   'refSpecs' <char|cellstr> sets ref specs used in fetch.
%   'setDryRun' <logical> Sets a dry run.
%   'remote' <char> Set remote.
%   'tagOpt' <char> Set tag option: AUTO_FOLLOW, FETCH_TAGS or NO_TAGS.
%   'prune' <logical> Remove deleted refs
%   'progressMonitor' <ProgressMonitor> [MATLABProgressMonitor] Display progress.
%   'gitDir' <char> [PWD] Applies to the repository in specified folder.
%
%   For more information see also
%   <a href="https://www.kernel.org/pub/software/scm/git/docs/git-fetch.html">Git Fetch Documentation</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/FetchCommand.html">JGit Git API Class FetchCommand</a>
%
%   Example - Fetch feature from upstream and checkout as upfeature:
%       JGIT.FETCH('remote','upstream','refSpecs','refs/heads/upfeature:refs/remotes/upstream/feature')
%       JGIT.CHECKOUT('refs/heads/upfeature')
%
%   See also JGIT, CHECKOUT, PULL
%
%   Copyright (c) 2013 Mark Mikofski

%% constants
AUTO_FOLLOW = org.eclipse.jgit.transport.TagOpt.AUTO_FOLLOW;
FETCH_TAGS = org.eclipse.jgit.transport.TagOpt.FETCH_TAGS;
NO_TAGS = org.eclipse.jgit.transport.TagOpt.NO_TAGS;
%% check inputs
p = inputParser;
p.addParamValue('refSpecs','',@(x)validateRefSpecs(x))
p.addParamValue('setDryRun',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('progressMonitor',com.mikofski.jgit4matlab.MATLABProgressMonitor,@(x)isjava(x))
p.addParamValue('remote','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('tagOpt','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('prune',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('gitDir',pwd,@(x)validateattributes(x,{'char'},{'row'}))
p.parse(varargin{:})
gitDir = p.Results.gitDir;
gitAPI = JGit.getGitAPI(gitDir);
fetchCMD = gitAPI.fetch;
%% repository
% repo = gitAPI.getRepository;
%% add refSpecs
if ~isempty(p.Results.refSpecs)
    % convert cellstring or string to Java List
    refSpecsList = java.util.ArrayList;
    if iscellstr(p.Results.refSpecs)
        for n = 1:numel(p.Results.refSpecs)
            refSpecsList.add(org.eclipse.jgit.transport.RefSpec(p.Results.refSpecs{n}));
        end
    elseif ischar(p.Results.refSpecs)
        refSpecsList.add(org.eclipse.jgit.transport.RefSpec(p.Results.refSpecs));
    end
    fetchCMD.setRefSpecs(refSpecsList); % pass list to fetch command
end
%% set dry run
if p.Results.setDryRun
    fetchCMD.setDryRun(true);
end
%% set progressMonitor
fetchCMD.setProgressMonitor(p.Results.progressMonitor);
%% set remote
if ~isempty(p.Results.remote)
    fetchCMD.setRemote(p.Results.remote);
end
%% set tag option
if ~isempty(p.Results.tagOpt)
    switch upper(p.Results.tagOpt)
        case 'AUTO_FOLLOW'
            fetchCMD.setTagOpt(AUTO_FOLLOW);
        case 'FETCH_TAGS'
            fetchCMD.setTagOpt(FETCH_TAGS);
        case 'NO_TAGS'
            fetchCMD.setTagOpt(NO_TAGS);
        otherwise
            error('jgit:fetch:badTagOpt', ...
                'Fetch tag options are ''AUTO_FOLLOW'', ''FETCH_TAGS'' or ''NO_TAGS''.')
    end
    fetchCMD.setRemote(p.Results.tag);
end
%% prune
if p.Results.prune
    fetchCMD.setRemoveDeletedRefs(true)
end
%% call
% UserInfoSshSessionFactory is a customized SshSessionFactory that
% configures a CredentialProvider to provide SSH passphrase for Jsch and
% registers itself as the default instance of SshSessionFactory.
com.mikofski.jgit4matlab.UserInfoSshSessionFactory;
fetchCMD.call;
end

function tf = validateRefSpecs(refspecs)
if ~iscellstr(refspecs)
    validateattributes(refspecs,{'char'},{'row'})
end
tf = true;
end
