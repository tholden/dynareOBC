function push(varargin)
%JGIT.PUSH Push commits.
%   JGIT.PUSH(PARAMETER,VALUE,...) uses any combination of the
%   following PARAMETER, VALUE pairs.
%   'ref' <char> sets references and ID's of commits to push.
%   'refSpecs' <char|cellstr> sets ref specs used in push.
%   'setDryRun' <logical> Sets a dry run.
%   'setForce' <logical> Sets force push.
%   'setPushAll' <logical> Push all branches.
%   'setPushTags' <logical> Push tags.
%   'remote' <char> Set remote.
%   'progressMonitor' <ProgressMonitor> [MATLABProgressMonitor] Display progress.
%   'gitDir' <char> [PWD] Applies to the repository in specified folder.
%
%   For more information see also
%   <a href="https://www.kernel.org/pub/software/scm/git/docs/git-push.html">Git Push Documentation</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/PushCommand.html">JGit Git API Class PushCommand</a>
%
%   Example:
%       JGIT.PUSH('ref','feature') % push 'feature' ref to default remote
%       JGIT.PUSH('ref','fad9663b23d59332fd5387ba6f506c54167a6707')
%       JGIT.PUSH('ref','feature', 'remote', 'upstream') % push upstream
%       JGIT.PUSH('ref','feature','setForce',true) % force push master to default
%
%   See also JGIT, COMMIT
%
%   Copyright (c) 2013 Mark Mikofski

%% constants
REJECTED_NONFASTFORWARD = javaMethod('valueOf', ...
    'org.eclipse.jgit.transport.RemoteRefUpdate$Status','REJECTED_NONFASTFORWARD');
%% check inputs
p = inputParser;
p.addParamValue('ref','',@(x)validateRefs(x))
p.addParamValue('refSpecs','',@(x)validateRefs(x))
p.addParamValue('setDryRun',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('setForce',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('setPushAll',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('setPushTags',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('progressMonitor',com.mikofski.jgit4matlab.MATLABProgressMonitor,@(x)isjava(x))
p.addParamValue('remote','',@(x)validateattributes(x,{'char'},{'row'}))
p.addParamValue('gitDir',pwd,@(x)validateattributes(x,{'char'},{'row'}))
p.parse(varargin{:})
gitDir = p.Results.gitDir;
gitAPI = JGit.getGitAPI(gitDir);
pushCMD = gitAPI.push;
%% repository
% repo = gitAPI.getRepository;
%% add ref
if ~isempty(p.Results.ref)
    if iscellstr(p.Results.ref)
        for n = 1:numel(p.Results.ref)
            pushCMD.add(p.Results.ref{n});
        end
    elseif ischar(p.Results.ref)
        pushCMD.add(p.Results.ref);
    end
end
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
    pushCMD.setRefSpecs(refSpecsList); % pass list to push command
end
%% set dry run
if p.Results.setDryRun
    pushCMD.setDryRun(true);
end
%% set force
if p.Results.setForce
    pushCMD.setForce(true);
end
%% set push all
if p.Results.setPushAll
    pushCMD.setPushAll(true);
end
%% set push tags
if p.Results.setPushTags
    pushCMD.setPushTags(true);
end
%% set progressMonitor
pushCMD.setProgressMonitor(p.Results.progressMonitor);
%% set remote
if ~isempty(p.Results.remote)
    pushCMD.setRemote(p.Results.remote);
end
%% call
% UserInfoSshSessionFactory is a customized SshSessionFactory that
% configures a CredentialProvider to provide SSH passphrase for Jsch and
% registers itself as the default instance of SshSessionFactory.
com.mikofski.jgit4matlab.UserInfoSshSessionFactory;
r = pushCMD.call;
rArray = r.toArray;
for nResult = 1:r.size
    result = rArray(nResult);
    remoteUpdate = result.getRemoteUpdates;
    remoteUpdateArray = remoteUpdate.toArray;
    for nRemote = 1:remoteUpdate.size
        remoteN = remoteUpdateArray(nRemote);
        if remoteN.getStatus.equals(REJECTED_NONFASTFORWARD)
            error('JGit:push',[ ...
                'To %s\n', ...
                ' ! [rejected]        %s -> %s (fetch first)\n', ...
                'error: failed to push some refs to "%s"\n', ...
                'hint: Updates were rejected because the remote contains work that you do\n', ...
                'hint: not have locally. This is usually caused by another repository pushing\n', ...
                'hint: to the same ref. You may want to first integrate the remote changes\n', ...
                'hint: (e.g., "jgit pull ...") before pushing again.\n'],char(result.getURI), ...
                char(remoteN.getRemoteName),char(remoteN.getSrcRef),char(result.getURI))
        else
            fprintf('%s\n',char(remoteN.getStatus))
        end
    end  
end
end

function tf = validateRefs(refs)
if ~iscellstr(refs)
    validateattributes(refs,{'char'},{'row'})
end
tf = true;
end
