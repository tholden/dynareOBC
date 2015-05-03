function FileText = ProcessModFileText( FileText )
    % remove comments and latex, imperfect, but should be fine in practice
    FileText = regexprep( FileText, '/\*.*?\*/', '' );
    FileText = regexprep( FileText, '^(.*?)(//|%)(.*)$', '$1', 'lineanchors', 'dotexceptnewline' );
    FileText = regexprep( FileText, '\$.*?\$', '', 'dotexceptnewline' );
    % some mathematical normalisation
    FileText = regexprep( FileText, '(\-\-)+', '\+' );
    FileText = regexprep( FileText, '\+*\-\+*', '\-' );
    FileText = regexprep( FileText, '\++', '\+' );
    FileText = strrep( FileText, '(+', '(' );
    % redo spacing and line breaks (every line should end with a ; after this, and ;s will only be at the end of lines)
    FileText = regexprep( FileText, '\s+', ' ' );
    FileText = regexprep( FileText, '[ ]*;+[ ]*', ';\n' );
    % remove some unnecessary space
    FileText = regexprep( FileText, '[ ]*([\(\)\+\-\*\/\^\>\<\=\!\,\[\]\#]+)[ ]*', '$1' );
    FileText = regexprep( FileText, '^ | $', '', 'lineanchors' );
    FileText = regexprep( FileText, '[\n\r]+', '\n' );
    FileText = regexprep( FileText, '(^\s+|\s+$)', '' );
end

