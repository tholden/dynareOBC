function parsed_argopts = parseFetch(argopts)
%PARSEFETCH Parse fetch arguments and options.
%   Copyright (c) 2013 Mark Mikofski
parsed_argopts = {};
%% options
dictionary = { ...
    'dryRun',{'--dry-run'},true; ...
    'prune',{'-p','--prune'},true; ...
    'tags',{'-t','--tags'},true;
    'noTags',{'-n','--no-tags'},true};
[options,argopts] = parseOpts(argopts,dictionary);
%% other options
% filter other options and/or double-hyphen
[argopts] = filterOpts(argopts);
%% parse
% no argument or option checks - jgit checks args/opts
% setDryRun
if options(1).('dryRun')
    parsed_argopts = [parsed_argopts,'setDryRun',true];
end
% setRemoveDeletedRefs
if options(1).('prune')
    parsed_argopts = [parsed_argopts,'prune',true];
end
% tags
if options(1).('tags')
    parsed_argopts = [parsed_argopts,'tagOpt','FETCH_TAGS'];
elseif options(1).('noTags')
    parsed_argopts = [parsed_argopts,'prune','NO_TAGS'];
end
% remote
if ~isempty(argopts)
    parsed_argopts = [parsed_argopts,'remote',argopts(1)];
end
% refspecs
if argopts>2
    parsed_argopts = [parsed_argopts,'refSpecs',{argopts(2:end)}];
else
    parsed_argopts = [parsed_argopts,'refSpecs',argopts(2)];
end
end
