function argopts = splitShortOptions(argopts)
%SPLITSHORTOPTIONS Split short options with multiple commands
%   Copyright (c) 2013 Mark Mikofski
shortOpts = ~strncmp('--',argopts,2) & strncmp('-',argopts,1); % only short options
Ncmd = (cellfun(@numel,argopts)-1).*shortOpts; % number of commands per short op
has_multi = Ncmd>1; % are there any multi-command short options?
Nmulti = sum(has_multi.*(Ncmd-1)); % number of multi option commands
Nargs = numel(argopts); % number of arguments and options
nextra = [0,cumsum(has_multi.*(Ncmd-1))]; % index offset from splitting short options
newargs = cell(1,Nargs+Nmulti); % allocate a new cell array for options
% loop over argopts
for n = 1:Nargs
    if has_multi(n)
        %% split short options
        for m = 1:Ncmd(n)
            % check last option for integers arg
            if ~isnan(str2double(argopts{n}(m+1:end)))
                newargs{n+nextra(n)+m-1} = str2double(argopts{n}(m+1:end));
                Ndigits = (Ncmd(n)+1-m); % offset by number of digits
                nextra = nextra-Ndigits+1;newargs(end-Ndigits+2:end) = [];
                break
            elseif strcmp('-',argopts{n}(m+1))
                newargs{n+nextra(n)+m-1} = '-';
            else
                newargs{n+nextra(n)+m-1} = ['-',argopts{n}(m+1)];
            end
        end
    elseif shortOpts(n) && ~isnan(str2double(argopts{n}(2)))
        newargs{n+nextra(n)} = str2double(argopts{n}(2));
    else
        %% not multi
        newargs(n+nextra(n)) = argopts(n);
    end
end
%% replace argopts with newopts
argopts = newargs;
end
