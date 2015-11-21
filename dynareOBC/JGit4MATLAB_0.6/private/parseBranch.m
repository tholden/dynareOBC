function parsed_argopts = parseBranch(argopts)
%PARSEBRANCH Parse branch arguments and options.
%   Copyright (c) 2013 Mark Mikofski
parsed_argopts = {};
%% options
dictionary = { ...
    'force',{'-f','--force'},true; ...
    'set_upstream',{'--set-upstream'},true; ...
    'track',{'-t','--track'},true; ...
    'no_track',{'--no-track'},true; ...
    'delete',{'-d','--delete'},true; ...
    'forceDelete',{'-D'},true; ...
    'move',{'-m','--move'},true; ...
    'remotes',{'-r','--remotes'},true; ...
    'listAll',{'-a','--all'},true; ...
    'list',{'--list'},true};
[options,argopts] = parseOpts(argopts,dictionary);
%% other options
% filter other options and/or double-hyphen
argopts = filterOpts(argopts);
%% parse
% no argument or option checks - jgit checks args/opts
if options(1).('move')
    %% rename branch
    % new and old branch names
    assert(~isempty(argopts),'jgit:parseBranch','Specify new branch name.')
    assert(numel(argopts)==2,'jgit:parseBranch','Specify old branch name.')
    parsed_argopts = {'rename',argopts(1),'oldNames',argopts(2)};
elseif options(1).('delete') || options(1).('forceDelete')
    %% delete branch
    parsed_argopts = {'delete',[]};
    % force delete
    if options(1).('forceDelete')
        parsed_argopts = [parsed_argopts,'force',true];
    end
    % oldnames
    assert(~isempty(argopts),'jgit:parseBranch','Specify branch(s) to delete.')
    if numel(argopts)>1
        parsed_argopts = [parsed_argopts,'oldNames',{argopts}]; % cell string
    else
        parsed_argopts = [parsed_argopts,'oldNames',argopts]; % char
    end
elseif options(1).('remotes') || options(1).('listAll') || ...
        options(1).('list') || isempty(argopts)
    %% list branch
    parsed_argopts = {'list'};
    if options(1).('listAll')
        % all
        parsed_argopts = [parsed_argopts,{[]},'listMode','ALL'];
    elseif options(1).('remotes')
        % remotes
        parsed_argopts = [parsed_argopts,{[]},'listMode','REMOTE'];
    end
else % if any(set_upstream) || any(track) || any(no_track) && ~isempty(argopts)
    %% create branch
    if options(1).('set_upstream')
        % set-upstream
        parsed_argopts = {'upstreamMode','SET_UPSTREAM'};
    elseif options(1).('track')
        % track
        parsed_argopts = {'upstreamMode','TRACK'};
    elseif options(1).('no_track')
        % no-track
        parsed_argopts = {'upstreamMode','NO_TRACK'};
    end
    % force
    if options(1).('force')
        parsed_argopts = [parsed_argopts,'force',true];
    end
    % branchname
    assert(~isempty(argopts),'jgit:parseBranch','Specify branch name to create.')
    parsed_argopts = ['create',argopts(1),parsed_argopts];
    % start-point
    if numel(argopts)>2
        jgit_help('branch')
        return
    elseif numel(argopts)>1
        parsed_argopts = [parsed_argopts,'startPoint',argopts(2)];
    end
end
end
