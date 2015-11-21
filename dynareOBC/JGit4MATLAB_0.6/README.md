JGit4MATLAB
===========
JGit4MATLAB is a wrapper for JGit in MATLAB. It is meant to be used from the
command line.

Installation
------------
Download the full zip-file from [MATLAB Central File Exchange]
(http://www.mathworks.com/matlabcentral/fileexchange/), extract to your working
MATLAB folder, usually `C:\Users\<username>\Documents\MATLAB` and type `JGit`.
This will download the latest version of JGit and edit your Java class path file
called `javaclasspath.txt` that is also in your MATLAB working folder, making a
copy called `javaclasspath.txt.JGitSaved` of `javaclasspath.txt` if it already exists.

After this you must restart MATLAB for the changes to your MATLAB Java static
class path to take effect.

User Info
---------
Set your global gitconfig user name and email using the following:

    jgit setUserInfo '<John Doe>' <John.Doe@email.com>

You can retrieve your global gitconfig settings as well.

    [name,email] = JGit.getUserInfo

SSH
---
Create your SSH keys using [PuTTY gen]
(http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html)
and convert them to OpenSSH format. If you
set a passphrase, save it in `%HOME%\.jsch-userinfo` using the following:

    jgit saveSSHpassphrase <passphrase>

Usage
=====
In general usage is the same as in [Git](http://git-scm.com/docs/git-help) and
[`org.eclipse.jgit.api.Git`](http://download.eclipse.org/jgit/docs/latest/apidocs/).

    jgit <command> <args> <param> <key> ...
    JGit.command(args,param,key,...)

Commands & Args 
---------------

Add
---
Stage files to git repo.

    jgit add file 
    JGit.add({'list','of','files'})

Branch 
------
Create, delete, list and rename branches.

    JGit.branch('list') % list local branches 
    JGit.branch('list',[],'listMode','REMOTE') % list remote branches 
    JGit.branch('create','newFeature') % create "newFeature" branch 
    JGit.branch('rename','superFeature','oldNames','newFeature') 
    JGit.branch('create','remoteBranch', ... 
        'startPoint','refs/remotes/origin/remoteBranch', ... 
        'upstreamMode','TRACK') % track "remoteBranch" 
    JGit.branch('delete',[],'oldNames',{'superFeature','remoteBranch})

Checkout
--------
Check out a branch or commit, create a new branch or check out files from the
index.

    JGit.checkout('master') % checkout master 
    JGit.checkout([],'path',{'file2.m','file2.m'}) % check out files 
    JGit.checkout([],'startPoint','HEAD~1','path','file1.m') 
    JGit.checkout('newBranch','createBranch',true) create a new branch. 
    JGit.checkout('stable','createBranch',true, ... 
        'upstreamMode','SET_UPSTREAM','startPoint','origin/stable')

Clone
-----
Clone a remote repository.

    JGit.clone('git://github.com/eclipse/jgit.git', ... 
        'directory','repos/jgit')

Commit
------
Commit files to git repo. Any combination of commands will work. If `getenv('EDITOR')`
is empty then `notepad` is used. An empty commit message throws a Java JGit exception.

    JGit.commit
    JGit.commit('all',true)
    JGit.commit('message','your commit message')
    JGit.commit('amend',true)
    JGit.commit('author',{'name','email'})
    JGit.commit('committer',{'name','email'})

Diff
----
View changes.

    JGit.diff('previous','master',updated','feature', ... 
        'path',{'file1','file2},'difftool',true) % compare changes in file1 
        and file2 between "master" and "feature" branches using the MATLAB 
        visual comparison tool. 
    JGit.diff('chached',true) % compare HEAD to staged files.

Fetch
-----
Fetch changes from remote repository.

    jgit fetch remote upstream

Init
----
Initialize or reinitialize a Git repository.

    JGit.init('directory','repositories/myRepo')

Log
---
Return commit log. Any combination of commands will work. Commits are entered
as strings which can be SHA1 of the commit, HEAD~N, where N is the number of
commits from HEAD or as refs/heads/branch, where branch is the branch of the
commit. You can use 'since' and 'until' independently or together. 'Since' shows
commits newer than a given commit, and 'until' shows older commits. Commits are
always shown from newest to oldest. Push the enter key to advance and q+enter to
quit.

    JGit.log
    JGit.log('maxCount', 3) % show last 3 commits
    JGit.log('since','HEAD~5') % show last 5 commits
    JGit.log('until','HEAD~5') % show all except last 5 commits
    JGit.log('skip',3) % show commits starting 4 commits ago

Merge
-----
Merge refs.

    jgit merge ref

Pull
----
Pull from repository.

    jgit pull

Push
----
Push ref to remote.

    jgit push ref master remote origin

Status
------
Return status of git repo. Staged files are links which will open them in the
MATLAB editor.

    jgit status
    JGit.status

Other
-----
Create an `org.eclipse.jgit.api.Git` instance. With this you can do almost
anything. EG: `git.reset.setRef('HEAD').addPath('JGit.m').call` will unstage the
file `JGit.m` from the current commit.

    git = JGit.getGitAPI(gitDir) % create a Git instance for repo in gitDir

TODO
====
There are many porcelain functions that would be quick to implement:
`config`, `reset`, `tag`, `rebase`.

All functions should call `JGit.getGitAPI` class function. Then they can use that
instance to do whatever. For other methods, use the appropriate `org.eclipse.jgit`
package directly.

A GUI to mimic `gitk` and `git-gui`. GUI options for some porcelain commands like
log might also be nice. A log GUI that shows a banch graph would be especially nice.

To contribute, please clone the source at Github. Issues can also be posted on Github.

https://github.com/mikofski/JGit4MATLAB

For more information about the JGit API see their documentation.

http://download.eclipse.org/jgit/docs/latest/apidocs/org/eclipse/jgit/api/Git.html
