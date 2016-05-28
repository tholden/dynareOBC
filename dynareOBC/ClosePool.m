function ClosePool
   
    WarningState = warning( 'off', 'all' );
    try
        CurrentPool = gcp( 'nocreate' );
        delete( CurrentPool );
    catch
    end
    try        
        matlabpool close force; %#ok<DPOOL>
    catch
    end
    warning( WarningState );
    
end
