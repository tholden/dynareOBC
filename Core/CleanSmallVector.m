function v = CleanSmallVector( v, ZeroTolerance )
    v( any( v <= ZeroTolerance ) ) = 1;
end
