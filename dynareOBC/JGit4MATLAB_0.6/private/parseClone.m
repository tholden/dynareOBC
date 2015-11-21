function parsed_argopts = parseClone(argopts)
%PARSECLONE Parse clone arguments and options.
%   Copyright (c) 2013 Mark Mikofski
parsed_argopts = {};
%% options
dictionary = { ...
    'bare',{'--bare'},true; ...
    'origin',{'-o','--origin'},false; ...
    'branch',{'-b','--branch'},false; ...
    'recursive',{'--recursive','--recurse-submodules'},true; ...
    'noCheckout',{'-n','--no-checkout'},true};
% Git doesn't have anything like clone [all] branches &
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
% branch
if options(1).('branch')
    parsed_argopts = [parsed_argopts,'branch',options(2).('branch')];
end
% name remote
if options(1).('origin')
    parsed_argopts = [parsed_argopts,'remote',options(2).('origin')];
end
% submodules
if options(1).('recursive')
    parsed_argopts = [parsed_argopts,'cloneSubmodules',true];
end
% no-checkout
if options(1).('noCheckout')
    parsed_argopts = [parsed_argopts,'noCheckout',true];
end
% uri-ish
assert(~isempty(argopts),'jgit:parseClone','Specify repository to clone.')
parsed_argopts = [argopts(1),parsed_argopts];
% directory
if numel(argopts)>2
    jgit_help('clone')
    return
elseif numel(argopts)>1
    parsed_argopts = [parsed_argopts,'directory',argopts(2)];
end
end
