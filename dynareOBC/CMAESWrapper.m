function [ x, f ] = CMAESWrapper( OptiFunction, x, lb, ub, varargin )
	cmaesOptions = cmaes;
	cmaesOptions.EvalParallel = 1;
	cmaesOptions.LBounds = lb;
	cmaesOptions.UBounds = ub;
	cmaesOptions.CMA.active = 1;
	for i = 1 : 2 : length( varargin )
		cmaesOptions.( varargin{ i } ) = varargin{ i + 1 };
	end
	sigma = ( ub - lb ) * 0.2;
	sigma( ~isfinite( sigma ) ) = 0.01;
	[~,~,~,~,~,best] = cmaes( @( XV ) parallel_wrapper( OptiFunction, XV ), x, sigma, cmaesOptions );
	x = best.x;
	f = best.f;
	
	fmincon( OptiFunction, OptiX0, [], [], [], [], OptiLB, OptiUB, [], optimset( 'algorithm', 'sqp', 'display', 'off', 'MaxFunEvals', Inf, 'MaxIter', Inf, 'TolX', sqrt( eps ), 'TolFun', sqrt( eps ), 'UseParallel', true, 'ObjectiveLimit', -Inf, varargin{:} ) )
end

