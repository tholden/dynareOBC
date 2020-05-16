function ClosePool( NoPoolClose )
   
    WarningState = warning( 'off', 'all' );
    
    if NoPoolClose
        
        try
            CurrentPool = gcp( 'nocreate' );
        catch
            CurrentPool = [];
        end
        
        if ~isempty( CurrentPool )
            spmd
                evalin( 'base', 'clear all;' ); %#ok<SPEVB>
            end
        end
        
    else
    
        try
            CurrentPool = gcp( 'nocreate' );
            delete( CurrentPool );
        catch
        end
        try        
            matlabpool close force; %#ok<DPOOL>
        catch
        end
    
    end
    
    warning( WarningState );
    
end
