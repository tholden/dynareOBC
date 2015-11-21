function [options,argopts] = parseOpts(argopts,dictionary)
%PARSEOPTS Parse ARGOPTS according to a DICTIONARY.
%   DICTIONARY is an array of options definitions. Each row contains the
%   name of the option, the command-line options and a logical indicating
%   whether the option has an argument or is boolean.
%   PARSEOPTS returns, OPTIONS, a structure whose keys are the names of the
%   parsed options and whose values are a logical indicating whether the option
%   was given and its value if not boolean.
%
%   Example:
%
%       [opts,args] = parseOpts({'-a','-m','this is a commit message'}, ...
%           {'all',{'-a','--all'},true;'amend',{'--amend'},true; ...
%           'author',{'--author'},false;'message',{'-m','--message'},false});
%
%       opts = 2x1 struct array with fields:
%           fieldnames  opts(1) opts(2)
%           all:        true,   []
%           amend:      false,  []
%           author:     false,  []
%           message:    true,   {'this is a commit message'}
%
%       args = Empty cell array: 1-by-0
%   
%   Copyright (c) 2013 Mark Mikofski

% no arguments checks
Nopts = size(dictionary,1); % number of options
options = cell2struct(dictionary(:,2:3),dictionary(:,1));
% loop over option definitions
for n = 1:Nopts
    optDef = dictionary(n,:); % option definition
    name = optDef{1};commands = optDef{2};isBool = optDef{3}; 
    % loop over commands
    options(1).(name) = false;
    assert(~isempty(commands),'jgit:parseOpts')
    for cmd = commands
        options(1).(name) = options(1).(name) | strcmp(cmd,argopts);
    end
    % store value
    options(2).(name) = [];
    if ~isBool && any(options(1).(name))
        % leave argument string in cell array, easier to concatenate
        hasArgs = circshift(options(1).(name),[0,1]);
        args = argopts(hasArgs); % option arguments
        options(2).(name) = args(end); % only take the last arg if more than one
        argopts(hasArgs) = []; % pop option args
        options(1).(name)(hasArgs) = []; % pop option indices too
    end
    % pop options
    argopts(options(1).(name)) = [];
    % don't care about the option position
    options(1).(name) = any(options(1).(name)); % convert to scalar
end
end
