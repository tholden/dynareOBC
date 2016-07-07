function parsed_argopts = parseCheckout(argopts)
%PARSECHECKOUT Parse checkout arguments and options.
%   Copyright (c) 2013 Mark Mikofski
parsed_argopts = {};
%% options
dictionary = { ...
    'force',{'-f','--force'},true; ...
    'newBranch',{'-b'},true; ...
    'forceNew',{'-B'},true; ...
    'ours',{'--ours'},true; ...
    'theirs',{'--theirs'},true; ...
    'set_upstream',{'--set-upstream'},true; ...
    'track',{'-t','--track'},true; ...
    'no_track',{'--no-track'},true};
[options,argopts] = parseOpts(argopts,dictionary);
%% other options
% filter other options and/or double-hyphen
[argopts,paths] = filterOpts(argopts);
%% parse
% no argument or option checks - jgit checks args/opts
if options(1).('newBranch') || options(1).('forceNew')
    %% create
    if options(1).('newBranch') || options(1).('forceNew')
        parsed_argopts = [parsed_argopts,'createBranch',true];
    end
    if options(1).('forceNew') || options(1).('force')
        % force
        parsed_argopts = [parsed_argopts,'force',true];
    end
    % upstream mode
    if options(1).('set_upstream')
        % set-upstream
        parsed_argopts = [parsed_argopts,'upstreamMode','SET_UPSTREAM'];
    elseif options(1).('track')
        % track
        parsed_argopts = [parsed_argopts,'upstreamMode','TRACK'];
    elseif options(1).('no_track')
        % no-track
        parsed_argopts = [parsed_argopts,'upstreamMode','NO_TRACK'];
    end
    % branchname
    assert(~isempty(argopts),'jgit:parseCheckout','Specify branch name to create.')
    parsed_argopts = [argopts(1),parsed_argopts];
    % start-point
    if numel(argopts)>1
        parsed_argopts = [parsed_argopts,'startPoint',argopts(2)];
    end
elseif ~isempty(paths)
    %% checkout paths
    parsed_argopts = {[]}; % startPoint specifies commit when checking out paths
    if options(1).('ours')
        % stage ours
        parsed_argopts = [parsed_argopts,'stage','OURS'];
    elseif options(1).('theirs')
        % stage theirs
        parsed_argopts = [parsed_argopts,'stage','THEIRS'];
    end
    % force
    if options(1).('force')
        parsed_argopts = [parsed_argopts,'force',true];
    end
    % tree-ish
    if ~isempty(argopts)
        assert(numel(argopts)==1,'jgit:parseCheckout', ...
            ['error: pathspec %s did not match any file(s) known to git.\n', ...
            'Use "--" to separate paths from revisions, like this:\n', ...
            '"git <command> [<revision>...] -- [<file>...]"'],argopts{2})
        parsed_argopts = [parsed_argopts,'startPoint',argopts];
    end
    % paths
    if numel(paths)>1
        parsed_argopts = [parsed_argopts,'path',{paths}]; % cell string
    else
        parsed_argopts = [parsed_argopts,'path',paths]; % char
    end
else
    %% checkout commit-ish
    % force
    if options(1).('force')
        parsed_argopts = [parsed_argopts,'force',true];
    end
    if numel(argopts)>1,badOption = argopts{2};else badOption = {};end % bad option
    assert(numel(argopts)==1,'jgit:parseCheckout', ...
        ['error: pathspec %s did not match any file(s) known to git.\n', ...
        'Use "--" to separate paths from revisions, like this:\n', ...
        '"git <command> [<revision>...] -- [<file>...]"'],badOption)
    parsed_argopts = [argopts,parsed_argopts];
end
end
