function [ left, right ] = GetScope( string, index )
    left = ScopeSearch( string, index, -1 );
    right = ScopeSearch( string, index, 1 );
end
