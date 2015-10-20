function [ MinimumDeterminant, MinimumS, MinimumS0 ] = FullTest( TM, dynareOBC )

	T = int64( min( TM, dynareOBC.TimeToEscapeBounds ) );
	O = int64( 1 );
	Indices = O:T;
	M = dynareOBC.MMatrix( Indices, Indices );
	
	MinimumDeterminant = Inf;
	MinimumS = Inf;
	MinimumS0 = Inf;
	
	BreakFlag = false;
	
	LPOptions = optimoptions( @linprog, 'Algorithm', 'Dual-Simplex', 'Display', 'off', 'MaxIter', Inf, 'TolFun', 1e-9, 'TolCon', 1e-9 );

    for SetSize = Indices
		
		disp( [ 'Starting set size ' int2str( SetSize ) '.' ] );
		
		Set = O:SetSize;
		EndSet = Set + T - SetSize;
		
		f = [ zeros( SetSize, O ); -1 ];
		V0 = zeros( SetSize, O );
		V1 = ones( SetSize, O );
		LB = [ V0; -Inf ];
		UB = [ V1; Inf ];
		X0 = [ V0; 0 ];
		
		f0 = -V1;
				
		while true
		
			% Test Set
			
			MSub = M( Set, Set );
			
			MDet = det( MSub );
			MinimumDeterminant = min( MinimumDeterminant, MDet );
			
			[ ~, MS, Flag ] = linprog( f, [ -MSub, V1 ], V0, [], [], LB, UB, X0, LPOptions );
			if Flag ~= 1
				warning( 'dynareOBC:FullTestLinProgFail', 'Failed to solve one of the linear programming problems. This should never happen.' );
			end
			MinimumS = min( MinimumS, -MS );
			
			[ ~, MS0, Flag ] = linprog( f0, -MSub, V0, [], [], V0, V1, V0, LPOptions );
			if Flag ~= 1
				warning( 'dynareOBC:FullTestLinProgFail', 'Failed to solve one of the linear programming problems. This should never happen.' );
			end
			MinimumS0 = min( MinimumS0, -MS0 );

			% Early Exit
			
			if MinimumDeterminant < 1e-8 && MinimumS < 1e-8 && MinimumS0 < 1e-8
				BreakFlag = true;
				break;
			end
		
			% Increment Set
			
			K = find( Set == EndSet, O );
			
			if isempty( K )
				Set( end ) = Set( end ) + O;
			elseif K == 1
				break;
			else
				Set( ( K - O ):SetSize ) = ( Set( K - O ) + O ):( Set( K - O ) + O + SetSize - ( K - O ) );
			end
		
		end

		disp( [ 'Completed set size ' int2str( SetSize ) '. Current values:' ] );
		disp( [ MinimumDeterminant, MinimumS, MinimumS0 ] );
		
		if BreakFlag
			break;
		end
		
    end	
		
end

