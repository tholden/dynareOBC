function add(files,varargin)
%JGIT.ADD Add files to the index.
%   JGIT.ADD(FILES) adds the file or files given by the string or cell-string
%   FILES to the index.
%   JGIT.ADD(FILES,PARAMETER,VALUE,...) uses any combination of the following
%   PARAMETER, VALUE pairs.
%   'update' <logical> [false] Only stage tracked files. New files will not be
%       staged.
%   'gitDir' <char> [PWD] Add to index of the repository in specified folder.
%
%   For more information see also
%   <a href="http://git-scm.com/docs/git-add">Git Add Documentation</a>
%   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/AddCommand.html">JGit Git API Class AddCommand</a>
%
%   Example:
%       JGIT.ADD('myfile.m') % add 'myfile.m' to index
%       JGIT.ADD({'myclass.m','myfun.m') % add 'myclass.m' and 'myfun.m'
%
%   See also JGIT, COMMIT
%
%   Copyright (c) 2013 Mark Mikofski

%% check inputs
p = inputParser;
p.addRequired('files',@(x)validatefiles(x))
p.addParamValue('update',false,@(x)validateattributes(x,{'logical'},{'scalar'}))
p.addParamValue('gitDir',pwd,@(x)validateattributes(x,{'char'},{'row'}))
p.parse(files,varargin{:})
gitDir = p.Results.gitDir;
gitAPI = JGit.getGitAPI(gitDir);
addCMD = gitAPI.add;
%% add files
if iscellstr(p.Results.files)
    for n = 1:numel(p.Results.files)
        addCMD.addFilepattern(p.Results.files{n});
    end
elseif ischar(p.Results.files)
    addCMD.addFilepattern(p.Results.files);
end
%% set update
if p.Results.update
    addCMD.setUpdate(true);
end
%% call
addCMD.call;
end

function tf = validatefiles(files)
if ~iscellstr(files)
    validateattributes(files,{'char'},{'row'})
end
tf = true;
end
