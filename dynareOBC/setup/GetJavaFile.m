function JavaFile = GetJavaFile( File )
    % set directory
    JavaFile = java.io.File( File );
    % Java always makes relative paths in matlab userpath
    if ~JavaFile.isAbsolute
        JavaFile = java.io.File( pwd, File ); % folder relative to pwd
    end
end

