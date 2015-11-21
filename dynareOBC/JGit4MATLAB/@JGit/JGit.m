classdef JGit < handle
    %JGIT A JGit wrapper for MATLAB
    %   JGIT, the first time it is called, downloads the latest version of
    %   "org.eclipse.jgit.jar", adds it to the MATLAB static Java class
    %   path and makes a backup of the existing "javaclasspath.txt" as
    %   "javaclasspath.JGitSaved". MATLAB must then be restarted for the
    %   changes to the MATLAB static Java class path to take effect.
    %
    %   For more information on MATLAB static Java class path see also
    %   <a href="http://www.mathworks.com/help/matlab/matlab_external/bringing-java-classes-and-methods-into-matlab-workspace.html#f111065">Bringing Java Classes into MATLAB Workspace: The Java Class Path: The Static Path</a>
    %
    %   JGIT has only class methods that call the corresponding command
    %   methods of the Git class in the org.eclipse.jgit.api package.
    %
    %   For more information on JGit and Git see also
    %   <a href="http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/Git.html">Class Git in org.eclipse.jgit.api package</a>
    %   <a href="http://eclipse.org/jgit/">JGit-eclipse</a>
    %   <a href="http://git-scm.com/docs">Git Reference</a>
    %   <a href="http://git-scm.com/">Git-SCM</a>
    %
    %   Usage:
    %       JGIT.METHOD(REQUIRED,PARAMETER,VALUES)
    %
    %   See `help JGIT.METHOD` for more information on a specific METHOD.
    %
    %   See also ADD, BRANCH, CHECKOUT, CLONE, COMMIT, DIFF, FETCH, INIT, LOG,
    %   MERGE, PULL, PUSH, STATUS, GETGITAPI, GETGITDIR, VALIDATEJAVACLASSPATH,
    %   DOWNLOADJGITJAR, GETEDITOR, SETUSERINFO, GETUSERINFO, SAVESSHPASSPHRASE
    %
    %   Version 0.6 - Falcon Release
    %   Copyright (c) 2013 Mark Mikofski
    %   <a href="http://mikofski.github.io/JGit4MATLAB/">JGit4MATLAB on Github Pages</a>
    
    %% constant properties
    properties (Constant)
        VALID = JGit.validateJavaClassPath
        EDITOR = JGit.getEDITOR % an editor
        GIT_DIR = '.git' % git repository folder
        JGIT = 'org.eclipse.jgit' % JGit package name
        % package with MATLABProgressMonitor, replaces \r with \b
        PROGRESSMONITOR = 'MATLABProgressMonitor'
        % package with UserInfoSshSessionFactory, a custom SshSessionFactory,
        % configures a CredentialProvider to provide SSH passphrase for Jsch,
        % registers itself as the default SshSessionFactory instance
        USERINFOSSHSESSIONFACTORY = 'UserInfoSshSessionFactory'
        VERFILE = fullfile(fileparts(mfilename('fullpath')),'version') % file storing JGit package version
        VERSION = strtrim(fileread(JGit.VERFILE)) % JGit version string
        USERHOME = org.eclipse.jgit.util.FS.DETECTED.userHome % user home
        GITCONFIG = '.gitconfig' % global git config file found in USERHOME
        JSCH_USERINFO = '.jsch-userinfo' % global Jsch userinfo file with SSH passphrase
    end
    %% static methods
    methods (Static)
        %% common methods
        add(files,gitDir)
        branch(cmd,newName,varargin)
        r = checkout(name,varargin)
        clone(uri,varargin)
        commit(varargin)
        diff(varargin)
        fetch(varargin)
        init(varargin)
        log(varargin)
        r = merge(include,varargin)
        r = pull(varargin)
        push(varargin)
        status(gitDir,fid,amend)
        %% JGIT4MATLAB methods
        function gitAPI = getGitAPI(gitDir)
            %JGIT.GETGITAPI Get an instance of the JGit API Git Class.
            %   JGIT.GITAPIOBJ = GETGITAPI returns GITAPIOBJ, an instance of
            %   the JGit API Git Class for the Git repository in the current
            %   directory.
            %   GITAPIOBJ = GETGITAPI(GITDIR) returns GITAPIOBJ for the Git
            %   repository in which GITDIR is located. GITDIR can be any
            %   folder in the repository.
            %   Throws GIT:NOTGITREPO if there is no .git folder in GITDIR
            %   or any of its parent folder.
            %
            %   See also: JGIT, GETGITDIR
            %
            %   Copyright (c) 2013 Mark Mikofski
            
            %% checkin inputs
            if nargin<1
                gitDir = pwd;
            end
            %% get gitDir
            gitDir = JGit.getGitDir(gitDir);
            assert(~isempty(gitDir),'jgit:notGitRepo', ...
                ['fatal: Not a git repository (or any of the parent', ...
                'directories): .git'])
            %% get Git API
            gitAPI = org.eclipse.jgit.api.Git.open(java.io.File(gitDir));
        end
        function gitDir = getGitDir(path)
            %JGIT.GETGITDIR Find the .git folder of the repository.
            %   GITDIR = JGIT.GETGITDIR(GITDIR) returns GITDIR, the .git folder
            %   for the Git repository in the current directory.
            %
            %   See also: JGIT, GETGITAPI
            %
            %   Copyright (c) 2013 Mark Mikofski
            
            %% create full path to gitDir
            gitDir = fullfile(path,JGit.GIT_DIR);
            %% walk directory tree to find gitDir
            s = dir(gitDir);
            while isempty(s)
                parent = fileparts(path);
                if strcmpi(path,parent)
                    gitDir = [];
                    break
                end
                path = parent;
                gitDir = fullfile(path,JGit.GIT_DIR);
                s = dir(gitDir);
            end
        end
        function valid = validateJavaClassPath
            %JGIT.VALIDATEJAVACLASSPATH Validate MATLAB static Java class path.
            %   VALID = JGIT.VALIDATEJAVACLASSPATH returns true if the JGit
            %   package jar-file is in the @JGit folder and on the MATLAB
            %   static Java class path. Downloads current version of JGit
            %   and/or adds it to the MATLAB static Java class path if false.
            %
            %   See also: JGIT, DOWNLOADJGITJAR, SETUSERINFO, GETUSERINFO,
            %   SAVESSHPASSPHRASE
            %
            %   Copyright (c) 2013 Mark Mikofski
            
            %% check JGit package jar-file in @JGit folder
            valid = true;
            githome =  fileparts(mfilename('fullpath'));
            jgitjar = fullfile(githome,[JGit.JGIT,'.jar']);
            pmjar = fullfile(githome,[JGit.PROGRESSMONITOR,'.jar']);
            SSHjar = fullfile(githome,[JGit.USERINFOSSHSESSIONFACTORY,'.jar']);
            if exist(jgitjar,'file')~=2
                valid = false;
                fprintf('JGit jar-file doesn''t exist. Downloading ...\n');
                [f,status] = JGit.downloadJGitJar(jgitjar);
                if status==1
                    fprintf('Saved as:\n\t%s.\n... Done.\n\n',f);
                else
                    error('jgit:validateJavaClassPath:downloadError', ...
                        'Download failed with status code %d.',status)
                end
            end
            %% check MATLAB static Java class path
            spath = javaclasspath('-static'); % static java class path
            if any(strcmp(spath,jgitjar)) && any(strcmp(spath,pmjar)) && ...
                    any(strcmp(spath,SSHjar))
                %% Yes, jar-files are on MATLAB static Java class path
                % return false if jar-file has just been downloaded even if
                % already on MATLAB static Java class path
                valid = valid && true;
            else
                %% No, jar-files are not on MATLAB static Java class path
                % check for file called "javaclasspath.txt"
                valid = false;
                javapath = fullfile(prefdir,'javaclasspath.txt');
                if exist(javapath,'file')~=2
                    %% no "javaclasspath.txt"
                    fprintf('"javaclasspath.txt" not detected. Writing to %s...\n', javapath);
                    try
                        fid = fopen(javapath,'wt');
                        fprintf(fid,'# JGit package\n%s\n',jgitjar,pmjar,SSHjar);
                        fclose(fid);
                        fprintf('... Done.\n\n');
                    catch ME
                        fclose(fid);
                        throw(ME)
                    end
                else
                    %% "javaclasspath.txt" already exists
                    try
                        fid = fopen(javapath,'r+t');
                        pathline = fgetl(fid);
                        foundJGit = strcmp(pathline,jgitjar);
                        foundPM = strcmp(pathline,pmjar);
                        foundSSH = strcmp(pathline,SSHjar);
                        while ~foundJGit || ~foundPM || ~foundSSH
                            if feof(fid)
                                copyfile(javapath,[javapath,'.JGitSaved'])
                                if ~foundJGit
                                    fprintf('JGit is not on static Java class path. Writing ...\n');
                                    fprintf(fid,'\n# JGit package\n%s\n',jgitjar);
                                    fprintf('... Done.\n\n');
                                end
                                if ~foundPM
                                    fprintf('ProgressMonitor is not on static Java class path. Writing ...\n');
                                    fprintf(fid,'\n# JGit package\n%s\n',pmjar);
                                    fprintf('... Done.\n\n');
                                end
                                if ~foundSSH
                                    fprintf('UserInfoSshSessionFactory is not on static Java class path. Writing ...\n');
                                    fprintf(fid,'\n# JGit package\n%s\n',SSHjar);
                                    fprintf('... Done.\n\n');
                                end
                                break
                            end
                            pathline = fgetl(fid);
                            foundJGit = foundJGit || strcmp(pathline,jgitjar);
                            foundPM = foundPM || strcmp(pathline,pmjar);
                            foundSSH = foundSSH || strcmp(pathline,SSHjar);
                        end
                        fclose(fid);
                    catch ME
                        fclose(fid);
                        throw(ME)
                    end
                end
            end
            %% restart message
            assert(valid,'jgit:noJGit', ...
                ['\n\t****************************\n', ...
                '\t** Please restart MATLAB. **\n', ...
                '\t****************************\n\n', ...
                'JGit has been downloaded and/or added to the MATLAB Java static\n', ...
                'path, but you must restart MATLAB for the changes to take effect.\n\n', ...
                'For more information see:\n', ...
                '<a href="http://www.mathworks.com/help/matlab/matlab_external/', ...
                'bringing-java-classes-and-methods-into-matlab-workspace.html#f111065">', ...
                'Bringing Java Classes into MATLAB Workspace: The Java Class Path: The Static Path</a>\n\n', ...
                '\n\t****************************************************************\n', ...
                '\t** If this is the first time you are using up JGIT4MATLAB ... **\n', ...
                '\t****************************************************************\n\n', ...
                '... please set your name and email in the global gitconfig file using ', ...
                'JGIT.SETUSERINFO(NAME,EMAIL).\n\n', ...
                'You should also download ', ...
                '<a href="http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html">', ...
                'PuTTY gen</a>, create a pair of SSH RSA keys in $HOME/.ssh, convert\n', ...
                'them to openSSH format and use JGIT.SSAVESSHPASSPHRASE(PASSPHRASE) ', ...
                'to save your passphrase.\n\nNote, it is not necessary to set a ', ...
                'passphrase. Also note, SSH keys are only required\nfor cloning, ', ...
                'pulling and pushing (to) private repositories with which you''ve ', ...
                'shared\nyour public key.'])
            %% check user info
            [name,email] = JGit.getUserInfo;
            try
                noUserInfo = name.isEmpty; % try Java, necessary if false
            catch
                noUserInfo = isempty(name); % try MATLAB, necessary if true
            end
            try
                noUserInfo = noUserInfo || email.isEmpty; % try Java, necessary if false
            catch
                noUserInfo = noUserInfo || isempty(email); % try MATLAB, necessary if true
            end
            if noUserInfo
                key = org.eclipse.jgit.lib.UserConfig.KEY;
                cnf = org.eclipse.jgit.lib.Config;
                usrcnf = cnf.get(key);
                name = usrcnf.getAuthorName;
                email = usrcnf.getAuthorEmail;
                warning('jgit:noUserInfo', ...
                    ['\nUser info in global .gitconfig file is missing or incomplete.\n', ...
                    'Please set user info using JGIT.SETUSERINFO(NAME,EMAIL), or\n' ...
                    'default values will be used for missing user name and/or email.\n', ...
                    '\tDEFAULT NAME:\t%s\n\tDEFAULT EMAIL:\t%s'],char(name),char(email))
            end
            % check SSH passphrase
            f = fullfile(char(JGit.USERHOME),JGit.JSCH_USERINFO); % savefile path
            if exist(f, 'file')~=2
                warning('jgit:noSSHpassphrase', ...
                    'Please use SAVESSHPASSPHRASE(PASSPHRASE) to save your passphrase.')
            end
        end
        function setUserInfo(name, email)
            %JGIT.SETUSERINFO Set global user config.
            %   JGIT.SETUSERINFO(NAME,EMAIL)
            %
            %   See also: JGIT, GETUSERINFO
            cnfile = java.io.File(JGit.USERHOME,JGit.GITCONFIG); % java File
            % create gitconfig obj and load it
            gitconfig = org.eclipse.jgit.storage.file.FileBasedConfig(cnfile, ...
                org.eclipse.jgit.util.FS.DETECTED);
            gitconfig.load % gitconfig obj must be loaded before calling set/get methods
            gitconfig.setString('user',[],'name',name); % set user name
            gitconfig.setString('user',[],'email',email); % set user email
            gitconfig.save;
        end
        function [name,email] = getUserInfo()
            %JGIT.GETUSERINFO Get global user config.
            %   [NAME,EMAIL] = JGIT.GETUSERINFO
            %
            %   See also: JGIT, SETUSERINFO
            cnfile = java.io.File(JGit.USERHOME,JGit.GITCONFIG); % java File
            % create gitconfig obj and load it
            gitconfig = org.eclipse.jgit.storage.file.FileBasedConfig(cnfile, ...
                org.eclipse.jgit.util.FS.DETECTED);
            gitconfig.load % gitconfig obj must be loaded before calling set/get methods
            name = gitconfig.getString('user',[],'name'); % get user name
            email = gitconfig.getString('user',[],'email'); % get user email
        end
        function [f,status] = saveSSHpassphrase(passphrase)
            %SETSSHPASSPHRASE Save SSH passphrase for JSch.
            %   [F,STATUS] = SAVESSHPASSPHRASE(PASSPHRASE)
            %   Save SSH passphrase in un-encrypted file, F, for Jsch
            %   custom CredentialProvider to use. STATUS == 1 if
            %   successful.
            %
            %   See also: JGIT, CLONE, FETCH, PULL, PUSH
            f = fullfile(char(JGit.USERHOME),JGit.JSCH_USERINFO); % savefile path
            fid = fopen(f,'wt'); % open file for writing text
            try
                fprintf(fid,'%s\n',passphrase); % write passphrase to file
                fclose(fid); % close file
            catch ME
                fclose(fid); % catch errors and close file
                throw(ME) % throw error
            end
            status = 1; % success
        end
        function [f,status] = downloadJGitJar(jgitjar)
            %JGIT.DOWNLOADJGITJAR Download the latest JGit jar file.
            %   [F,STATUS] = JGIT.DOWNLOADJGITJAR(JGITJAR) downloads JGit
            %   jar file using filename and path specified by JGITJAR.
            %   [F,STATUS] are the parameters returned by URLWRITE. Writes
            %   the version number in a file called 'version' in the @JGit
            %   folder if successful.
            %
            %   See also: JGIT, URLREAD, URLWRITE
            %
            %   Copyright (c) 2013 Mark Mikofski
            
            %% inputs
            % use org.eclipse.jgit as default
            githome =  fileparts(mfilename('fullpath'));
            if nargin<1
                jgitjar = fullfile(githome,[JGit.JGIT,'.jar']);
            end
            % copy old org.eclipse.jgit with version info as backup
            if exist(jgitjar,'file')==2
                oldver = fullfile(githome,'older-versions');
                if exist(oldver,'dir')~=7
                    mkdir(oldver)
                end
                oldver = fullfile(oldver,[JGit.JGIT,'-',JGit.VERSION,'-r.jar']);
                copyfile(jgitjar,oldver)
            end
            %% get version number and jar download url from eclipse
            ver = '[0-9].[0-9].[0-9].[0-9]{12}'; % regex for version number
            expr = ['<a href="(https://repo.eclipse.org/content/groups/releases/', ...
                '/org/eclipse/jgit/',JGit.JGIT,'/',ver,'-r/',JGit.JGIT,'-', ...
                ver,'-r.jar)">',JGit.JGIT,'.jar</a>']; % regex for url
            str = urlread('http://www.eclipse.org/jgit/download/');
            assert(~isempty(str),'jgit:downloadJGitJar:badURL', ...
                'Can''t read from jgit download page.')
            tokens = regexp(str,expr,'tokens'); % download url
            assert(~isempty(tokens{1}),'Please report JGit download path has changed.')
            version = regexp(tokens{1}{1},ver,'match'); % version
            assert(~isempty(version{1}),'Please report JGit version format has changed.')
            fprintf('\tVersion: %s\n',version{1}) % display version to download
            [f,status] = urlwrite(tokens{1}{1},jgitjar); % download jar-file
            %% write version number to file if successful
            if status==1
                try
                    fid = fopen(JGit.VERFILE,'wt');
                    fprintf(fid,'%s\n',version{1});
                catch ME
                    fclose(fid);
                    throw(ME)
                end
                fclose(fid);
            end
        end
        function editor = getEDITOR
            %JGIT.GETEDITOR Get the default system editor.
            %   EDITOR = JGIT.GETEDITOR returns 'notepad' if pc, 'textedit'
            %   if mac and 'gedit' if linux.
            %
            %
            %   See also: JGIT, COMMIT
            %
            %   Copyright (c) 2013 Mark Mikofski
            
            %% get computer type
            comp = computer;
            switch comp
                case {'PCWIN','PCWIN64'}
                    %% PC
                    editor = 'notepad';
                case 'MACI64'
                    %% MAC
                    editor = 'textedit';
                case {'GLNX86','GLNXA64'}
                    %% LINUX
                    editor = 'gedit';
                otherwise
                    %% Try is* if computer didn't work?
                    if ispc
                        %% PC
                        editor = 'notepad';
                    elseif ismac
                        %% MAC
                        editor = 'textedit';
                    elseif isunix
                        %% LINUX
                        editor = 'gedit';
                    else
                        %% no editor
                        error('jgit:noeditor','No editor found.')
                    end
            end
        end
    end
end
