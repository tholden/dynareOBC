function parsed_argopts = parseMerge(argopts)
%PARSEMERGE Parse merge arguments and options.
%   Copyright (c) 2013 Mark Mikofski
parsed_argopts = {};
%% options
dictionary = { ...
    'commit',{'--commit'},true; ...
    'noCommit',{'--no-commit'},true; ...
    'fastForward',{'--ff'},true; ...
    'noFastForward',{'--no-ff'},true; ...
    'onlyFastForward',{'--ff-only'},true; ...
    'squash',{'--squash'},true; ...
    'strategy',{'-s','--strategy'},false; ...
    'message',{'-m','--message'},false};
[options,argopts] = parseOpts(argopts,dictionary);
%% other options
% filter other options and/or double-hyphen
[argopts] = filterOpts(argopts);
%% parse
% no argument or option checks - jgit checks args/opts
% TODO: add abort otion
% commit or no commit
if options(1).('commit')
    parsed_argopts = [parsed_argopts,'commit',true];
elseif options(1).('noCommit')
    parsed_argopts = [parsed_argopts,'commit',false];
end
% FF mode
if options(1).('fastForward')
    % fast forward
    parsed_argopts = [parsed_argopts,'fastForward','FF'];
elseif options(1).('noFastForward')
    % no fast forward
    parsed_argopts = [parsed_argopts,'fastForward','FF_ONLY'];
elseif options(1).('onlyFastForward')
    % fast forward only
    parsed_argopts = [parsed_argopts,'fastForward','NO_FF'];
end
% squash
if options(1).('squash')
    parsed_argopts = [parsed_argopts,'squash',true];
end
% strategy
if options(1).('strategy')
    parsed_argopts = [parsed_argopts,'strategy',options(2).('strategy')];
end
% message
if options(1).('message')
    parsed_argopts = [parsed_argopts,'name',options(2).('message')];
end
% commit
assert(numel(argopts)==1, 'jgit:parseMerge','Specify single commit to merge.')
parsed_argopts = [argopts,parsed_argopts];
end
