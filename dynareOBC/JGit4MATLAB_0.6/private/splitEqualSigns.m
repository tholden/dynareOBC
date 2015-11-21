function argopts = splitEqualSigns(argopts)
%SPLITEQUALSIGNS Split long options with equal signs into 2 args
%   Copyright (c) 2013 Mark Mikofski
eqs_idx = strfind(argopts,'='); % indices of equal signs in arguments with them
has_eqs = ~cellfun(@isempty,eqs_idx) & strncmp('--',argopts,2); % must be a long option
Neqs = sum(has_eqs); % number of long options with equal signs
nextra = [0,cumsum(has_eqs)]; % index offset from splitting long options with equal signs
Nargs = numel(argopts); % number of arguments and options
newargs = cell(1,Nargs+Neqs); % allocate a new cell array for options
% loop over argopts
for n = 1:Nargs
    if has_eqs(n)
        %% split long option and its argument
        newargs{n+nextra(n)} = argopts{n}(1:eqs_idx{n}(1)-1);
        newargs{n+1+nextra(n)} = argopts{n}(eqs_idx{n}(1)+1:end);
    else
        %% no equal sign
        newargs{n+nextra(n)} = argopts{n};
    end
end
%% replace argopts with newopts
argopts = newargs;
end
