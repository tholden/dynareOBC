function parsed_argopts = parseLog(argopts)
%PARSELOG Parse log arguments and options.
%   Copyright (c) 2013 Mark Mikofski
parsed_argopts = {};
%% options
dictionary = { ...
    'maxCount',{'-n','--max-count'},false; ...
    'skip',{'--skip'},false; ...
    'all',{'--all'},true};
[options,argopts] = parseOpts(argopts,dictionary);
%% other options
% filter other options and/or double-hyphen
[argopts,path] = filterOpts(argopts);
%% parse
% no argument or option checks - jgit checks args/opts
% maxCount
if ~isempty(argopts) && isnumeric(argopts{1})
    parsed_argopts = [parsed_argopts,'maxCount',argopts(1)];
    argopts(1) = []; % pop maxCount as argument
elseif options(1).('maxCount')
    if isnumeric(options(2).('maxCount'){1})
        parsed_argopts = [parsed_argopts,'maxCount',options(2).('maxCount')];
    else
        parsed_argopts = [parsed_argopts,'maxCount',str2double(options(2).('maxCount'))];
    end
end
% skip
if options(1).('skip')
    parsed_argopts = [parsed_argopts,'skip',str2double(options(2).('skip'))];
end
% path
if ~isempty(path)
    parsed_argopts = [parsed_argopts,'path',path];
end
% all
if options(1).('all')
    parsed_argopts = [parsed_argopts,'all',true];
end
% revision range
Nargopts = numel(argopts); % number of argopts
if Nargopts==1
    range = regexp(argopts{1},'(?<since>.*)\.\.(?<until>.*)','names');
    if ~isempty(range)
        if ~isempty(range.since)
            parsed_argopts = [parsed_argopts,'since',range.since];
        end
        if ~isempty(range.until)
            parsed_argopts = [parsed_argopts,'until',range.until];
        end
    elseif strncmp('^',argopts,1);
        parsed_argopts = [parsed_argopts,'not',argopts{1}(2:end)];
    else
        parsed_argopts = [parsed_argopts,'add',argopts];
    end
elseif Nargopts>1
    notRevIdx = strncmp('^',argopts,1);
    notRev = cellfun(@(x)x(2:end),argopts(notRevIdx),'UniformOutput',false);
    % pass notRev and revs as cell strings, if more than one
    % don't add argument if notRev or revs is empty
    numNotRev = numel(notRev); % number of ^REV
    if numNotRev
        parsed_argopts = [parsed_argopts,'not',{notRev}];
    elseif numNotRev==1
        parsed_argopts = [parsed_argopts,'not',notRev];
    end
    Nrevs = Nargopts-numNotRev; % number of revs to include w/o --not (or ^)
    if Nrevs>1
        parsed_argopts = [parsed_argopts,'add',{argopts(~notRevIdx)}];
    elseif Nrevs==1
        parsed_argopts = [parsed_argopts,'add',argopts(~notRevIdx)];
    end
end
end
