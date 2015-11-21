function parsed_argopts = parseCommit(argopts)
%PARSECOMMIT Parse commit arguments and options.
%   Copyright (c) 2013 Mark Mikofski
parsed_argopts = {};
%% options
dictionary = { ...
    'all',{'-a','--all'},true; ...
    'amend',{'--amend'},true; ...
    'message',{'-m','--message'},false; ...
    'author',{'--author'},false};
[options,argopts] = parseOpts(argopts,dictionary);
%% other options
% filter other options and/or double-hyphen
argopts = filterOpts(argopts);
%% parse
% no argument or option checks - jgit checks args/opts
% all
if options(1).('all')
    parsed_argopts = [parsed_argopts,'all',true];
end
% amend
if options(1).('amend')
    parsed_argopts = [parsed_argopts,'amend',true];
end
% message
if options(1).('message')
    parsed_argopts = [parsed_argopts,'message',options(2).('message')];
end
% author
if options(1).('author')
    % store message content, split author name and email
    authorNameEmail = regexp(options(2).('author'),'(.+) <(.+)>','tokens');
    assert(~isempty(authorNameEmail),'jgit:parseCommit', ...
        'Specify an explicit author using the standard A U Thor <author@example.com> format.')
    authorNameEmail = authorNameEmail{1}; % extract the tokens, they are nested cells
    parsed_argopts = [parsed_argopts,'author',authorNameEmail];
end
% only files on command line
if numel(argopts)>0
    parsed_argopts = [parsed_argopts,'only',{argopts}];
end
end
