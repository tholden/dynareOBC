function [ alpha, ConstraintVector ] = SolveLinearProgrammingProblem( V, dynareOBC_, SkipFullSolution, ForceZeroNow )
% Solves argmin OneVecS' * alpha such that V + M * alpha >= 0 and alpha >= 0

    T = dynareOBC_.InternalIRFPeriods;
    Ts = dynareOBC_.TimeToEscapeBounds;
    ns = dynareOBC_.NumberOfMax;
    Tolerance = dynareOBC_.Tolerance;
    M = dynareOBC_.MMatrix;

    ZeroVecS = dynareOBC_.ZeroVecS;
    TVecS = dynareOBC_.TVecS;

    if all( V >= 0 )
        alpha = ZeroVecS;
        ConstraintVector = V;
        return
    end
    
    if ForceZeroNow
        SkipFullSolution = false;
    end
    
    if dynareOBC_.UseFICOXpress && ~SkipFullSolution
        
        RowType = dynareOBC_.RowType;
        if ForceZeroNow
            RowType( 1 + ( 0:T:((ns-1)*T) ) ) = 'E';
        end
        alpha = max( 0, xprslp( TVecS, -M, V, RowType, ZeroVecS, [], xprsoptimset( dynareOBC_.LinProgOptions ) ) );
        
    else
        
        alpha = [];
        
    end
    if isempty( alpha )
        
        alpha = ZeroVecS;
        if SkipFullSolution || ( isfield( dynareOBC_.LinProgOptions, 'Algorithm' ) && strcmpi( dynareOBC_.LinProgOptions.Algorithm, 'active-set' ) )
            % Generate a sensible initial point, using domain knowledge.
            alpha = dynareOBC_.AlphaStart * max( 0, max( -V( dynareOBC_.SelectIndices ) ) );
            ConstraintVector = V + M * alpha;
            Indices = [ ];
            for conv_iter = 1 : ( Ts * ns )
                Indices = union( Indices, find( ConstraintVector < -Tolerance ) );
                InnerIndices = setdiff( dynareOBC_.InverseSelectIndices( Indices ), 0 );
                if isempty( Indices )
                    break;
                end
                old_alpha = alpha;
                alpha( InnerIndices ) = max( 0, alpha( InnerIndices ) - M( Indices, InnerIndices ) \ ConstraintVector( Indices ) );
                Indices = setdiff( Indices, find( alpha < Tolerance ) );
                ConstraintVector = V + M * alpha;
                if min( ConstraintVector ) >= -Tolerance || norm( old_alpha - alpha ) < Tolerance
                    break;
                end
            end
        end

        if ~SkipFullSolution
            if ForceZeroNow
                Meq = M( 1 + ( 0:T:((ns-1)*T) ), : );
                Veq = V( 1 + ( 0:T:((ns-1)*T) ), : );
                Mineq = M;
                Mineq( 1 + ( 0:T:((ns-1)*T) ), : ) = [];
                Vineq = V;
                V( 1 + ( 0:T:((ns-1)*T) ), : ) = [];
                alpha = max( 0, linprog( TVecS, -Mineq, Vineq, -Meq, Veq, ZeroVecS, [ ], alpha, dynareOBC_.LinProgOptions ) ); 
            else
                alpha = max( 0, linprog( TVecS, -M, V, [ ], [ ], ZeroVecS, [ ], alpha, dynareOBC_.LinProgOptions ) ); 
            end
        end
    
    end
    
    alpha = max( 0, alpha );
    
    ConstraintVector = V + M * alpha;
	if min( ConstraintVector ) < -100 * Tolerance
		warning( 'dynareOBC:LPP',  'Failed to solve linear programming problem.' );
	end
end

