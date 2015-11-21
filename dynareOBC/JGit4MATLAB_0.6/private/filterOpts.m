function [argopts,paths] = filterOpts(argopts)
%FILTEROPTS Filter out options from literal arguments.
%   Copyright (c) 2013 Mark Mikofski
%% other options
% double-hyphen is used to indicate the last option,
% arguments after lastopt are interpreted literaly.
lastopt = ~cumsum(strcmp('--',argopts)); % last option
options = strncmp('-',argopts(lastopt),1); % catches strncmp('--',argopts(lastopt),2)
if any(options)
    warning('jgit:unsupportedOption','Unsupported options.')
    unsupported_options = argopts(options);
    fprintf(2,'\t%s\n',unsupported_options{:});
    argopts(options) = []; % pop options
end
%% separate paths
% double-hyphen is also used to separate commits from paths
paths = {}; % paths
if nargout>1
    % return paths
    if any(strcmp('--',argopts))
        % paths
        lastopt = logical(cumsum(strcmp('--',argopts))); % last option
        paths = argopts(lastopt); % arguments after double-hyphen
        paths(1) = []; % pop double-hyphen
        argopts(lastopt) = []; % pop paths
    end
    % else there is no double-hyphen, all argsopts no paths
else
    % ignore double-hyphen, all argsopts no paths
    argopts(strcmp('--',argopts)) = []; % pop double-hyphen
end
