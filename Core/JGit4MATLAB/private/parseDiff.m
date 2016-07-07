function parsed_argopts = parseDiff(argopts,difftool)
%PARSEDIFF Parse diff arguments and options.
%   Copyright (c) 2013 Mark Mikofski
parsed_argopts = {};
%% options
dictionary = { ...
    'cached',{'--cached'},true; ...
    'nameStatus',{'--name-status'},true; ...
    'contextLines',{'--inter-hunk-context'},false; ...
    'srcPrefix',{'--src-prefix'},false; ...
    'destPrefix',{'--dst-prefix'},false; ...
    'noPrefix',{'--no-prefix'},true};
[options,argopts] = parseOpts(argopts,dictionary);
%% other options
% filter other options and/or double-hyphen
[argopts,paths] = filterOpts(argopts);
%% parse
% no argument or option checks - jgit checks args/opts
% cached
if options(1).('cached')
    parsed_argopts = [parsed_argopts,'cached',true];
end
% nameStatus
if options(1).('nameStatus')
    parsed_argopts = [parsed_argopts,'showNameAndStatusOnly',true];
end
% contextLines
if options(1).('contextLines')
    parsed_argopts = [parsed_argopts,'contextLines',options(2).('contextLines')];
end
% srcPrefix
if options(1).('srcPrefix')
    parsed_argopts = [parsed_argopts,'srcPrefix',options(2).('srcPrefix')];
end
% destPrefix
if options(1).('destPrefix')
    parsed_argopts = [parsed_argopts,'destPrefix',options(2).('destPrefix')];
end
% noPrefix
if options(1).('noPrefix')
    parsed_argopts = [parsed_argopts,'srcPrefix',' '];
    parsed_argopts = [parsed_argopts,'destPrefix',' '];
end
% difftool
if difftool
    parsed_argopts = [parsed_argopts,'difftool',true];
end
% commit(s) -- path(s)
if isempty(argopts) && isempty(paths)
    % no commit(s) or paths(s)
    return
end
% ambiguous argument
if ~isempty(argopts), ambiguousArg = argopts{end};else ambiguousArg = [];end
assert(numel(argopts)<3,'jgit:parseDiff', ...
    ['fatal: ambiguous argument "%s": unknown revision or path not in the working tree.\n', ...
    'Use "--" to separate paths from revisions, like this:\n', ...
    '"git <command> [<revision>...] -- [<file>...]"'],ambiguousArg)
% paths
if numel(paths)>1
    parsed_argopts = [parsed_argopts,'path',{paths}]; % cell string
elseif ~isempty(paths)
    parsed_argopts = [parsed_argopts,'path',paths]; % char
end
% commits
if ~isempty(argopts)
    parsed_argopts = [parsed_argopts,'previous',argopts(1)]; % previous
end
if numel(argopts)>1
    parsed_argopts = [parsed_argopts,'updated',argopts(2)]; % updated
end
end
