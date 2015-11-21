function parsed_argopts = parseInit(argopts)
%PARSEINIT Parse init arguments and options.
%   Copyright (c) 2013 Mark Mikofski
parsed_argopts = {};
%% options
dictionary = { ...
    'bare',{'--bare'},true};
% Git doesn't have anything like init [all] branches &
% --[no-]single-branch is not the same thing
[options,argopts] = parseOpts(argopts,dictionary);
%% other options
% filter other options and/or double-hyphen
argopts = filterOpts(argopts);
%% parse
% no argument or option checks - jgit checks args/opts
% bare
if options(1).('bare')
    parsed_argopts = [parsed_argopts,'bare',true];
end
% directory
if numel(argopts)>1
    jgit_help('init')
    return
elseif ~isempty(argopts)
    parsed_argopts = [parsed_argopts,'directory',argopts];
end
end
