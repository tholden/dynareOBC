function parsed_argopts = parsePush(argopts)
%PARSEPUSH Parse push arguments and options.
%   Copyright (c) 2013 Mark Mikofski
parsed_argopts = {};
%% options
dictionary = { ...
    'dryRun',{'-n','--dry-run'},true; ...
    'force',{'-f','--force'},true; ...
    'all',{'--all'},true; ...
    'tags',{'--tags'},true; ...
    };
[options,argopts] = parseOpts(argopts,dictionary);
%% other options
% filter other options and/or double-hyphen
argopts = filterOpts(argopts);
%% parse
% no argument or option checks - jgit checks args/opts
% dryRun
if options(1).('dryRun')
    parsed_argopts = [parsed_argopts,'setDryRun',true];
end
% force
if options(1).('force')
    parsed_argopts = [parsed_argopts,'setForce',true];
end
% all
if options(1).('all')
    parsed_argopts = [parsed_argopts,'setPushAll',true];
end
% tags
if options(1).('tags')
    parsed_argopts = [parsed_argopts,'setPushTags',true];
end
% remote
if isempty(argopts)
    return
elseif numel(argopts)>=1
    parsed_argopts = [parsed_argopts,'remote',argopts(1)];
end
% refs
if numel(argopts)==2
    parsed_argopts = [parsed_argopts,'ref',argopts(2)];
elseif numel(argopts)>2
    parsed_argopts = [parsed_argopts,'ref',{argopts(2:end)}];
end
end
