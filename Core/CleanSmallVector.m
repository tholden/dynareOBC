function v = CleanSmallVector( v, ZeroTolerance )
    v( v <= ZeroTolerance ) = 1;
end
