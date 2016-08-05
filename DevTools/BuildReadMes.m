cd ..;
OldPath = path;
try
    ReadMeText = fileread( 'README.md' );
    ReadMeText = strrep( ReadMeText, '`', '' );
    ReadMeText = strrep( ReadMeText, '**', '' );
    ReadMeLines = strsplit( ReadMeText, { '\f', '\n', '\r', '\v' }, 'CollapseDelimiters', false );
    FileID = fopen( 'ReadMe.txt', 'w' );
    for StrIdx = 1 : length( ReadMeLines )
        ReadMeLine = ReadMeLines{ StrIdx };
        SpaceString = regexp( ReadMeLine, '^\s*(\*\s*|\d+\.\s*)?', 'emptymatch', 'once', 'match' );
        SpaceLength = length( SpaceString );
        ReadMeLineWords = strsplit( ReadMeLine( SpaceLength+1:end ), { ' ', '\t' } );
        fprintf( FileID, '%s', SpaceString );
        LinePosition = SpaceLength;
        for WrdIdx = 1 : length( ReadMeLineWords )
            ReadMeLineWord = ReadMeLineWords{ WrdIdx };
            ReadMeLineWordLength = length( ReadMeLineWord );
            if LinePosition + 1 + ReadMeLineWordLength > 100 && SpaceLength + 1 + ReadMeLineWordLength <= 100
                SpaceString = regexprep( SpaceString, '\S', ' ' );
                fprintf( FileID, '\n%s', SpaceString );
                LinePosition = SpaceLength;
            end
            fprintf( FileID, '%s ', ReadMeLineWord );
            LinePosition = LinePosition + 1 + ReadMeLineWordLength;
        end
        fprintf( FileID, '\n' );
    end
    fclose( FileID );
    
    delete ReadMe.pdf;
    try
        addpath( 'C:\Program Files (x86)\Pandoc' );
    catch
    end
    !pandoc README.md -f markdown_github -o ReadMe.pdf -N --toc --wrap=none --latex-engine=xelatex -V papersize=A4 -V fontsize=10pt -V lang=en-GB -V documentclass=article -V margin-left=2.54cm -V margin-right=2.54cm -V margin-top=2.54cm -V margin-bottom=2.54cm -V mainfont=TeXGyrePagella -V sansfont=TeXGyreAdventor -V monofont=TeXGyreCursor -V links-as-notes -V colorlinks
catch Error
    disp( Error );
end
path( OldPath );
cd DevTools;
