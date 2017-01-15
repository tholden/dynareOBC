function ae = ACD_AEupdateFAST(ae, pop, c1, cmu, howOftenUpdateRotation)

% This code is based on the original Adaptive Encoding procedure (and code) 
% proposed by N. Hansen, see PPSN X paper for details.

% ---------------------------------------------------------------
% Adaptive encoding. To be used under the terms of the BSD license
% Author : Nikolaus Hansen, 2008.  
% e-mail: nikolaus.hansen AT inria.fr 
% URL:http://www.lri.fr/~hansen
% REFERENCE: Hansen, N. (2008). Adaptive Encoding: How to Render
%    Search Coordinate System Invariant. In Rudolph et al. (eds.)
%    Parallel Problem Solving from Nature, PPSN X,
%    Proceedings, Springer. http://hal.inria.fr/inria-00287351/en/
% ---------------------------------------------------------------

if nargin < 2 || isempty(pop)
  error('need two arguments, first can be empty');
end
  N = size(pop, 1);

  % initialize "object" 
  if isempty(ae) 
    % parameter setting
    ae.N = N; 
    ae.mu = size(pop, 2);
    ae.weights = ones(ae.mu, 1) / ae.mu; 
    ae.mucov = ae.mu; % for computing c1 and cmu
    if 11 < 3  % non-uniform weights, assumes a correct ordering of
               % input arguments
      ae.weights = log(ae.mu+1)-log(1:ae.mu)'; 
      ae.weights = ae.weights/sum(ae.weights); 
    end
    ae.alpha_p = 1; 
    ae.c1 = c1;
    ae.cmu = cmu;
 
    ae.cc = 1/sqrt(N); 

    % initialization
    ae.pc = zeros(N,1); 
    ae.pcmu = zeros(N,1); 
    ae.xmean = pop * ae.weights;
    ae.C = eye(N); 
    ae.Cold = ae.C;
    ae.diagD = ones(N,1); 
    ae.ps = 0;
    ae.iter = 1;
    return
  end % initialize object

  % begin Adaptive Encoding procedure
  ae.iter = ae.iter + 1;
  
  ae.xold = ae.xmean; 
  ae.xmean = pop * ae.weights;
 % ae.xmean = pop(:,1);
  updatePath = 1;
  
  if (updatePath == 1)
      % adapt the encoding
      dpath = ae.xmean-ae.xold;
      if (sum((ae.invB*dpath).^2) == 0)
          z = 0;
      else
          alpha0 = sqrt(N) / sqrt(sum((ae.invB*dpath).^2));
          z = alpha0 * dpath;
      end;
      ae.pc = (1-ae.cc)*ae.pc + sqrt(ae.cc*(2-ae.cc)) * z;
      S = ae.pc * ae.pc';

  %    
      ae.C = (1-ae.c1) * ae.C + ae.c1 * S;
  end;

  

if ((rem(ae.iter,howOftenUpdateRotation) == 0) || (ae.iter <= 2)) && 1
    
  if( sum(isnan(ae.C(:))) ) || sum(isinf(ae.C(:))  ) 
        ae.C = ae.Cold;
  end;
  ae.C = (triu(ae.C)+triu(ae.C,1)');
  
% tic
  [ae.Bo, EV] = eig(ae.C);
  EV = diag(EV);
%  toc/(2*N*N)
  if (1)% limit condition of C to 1e14 + 1
        cond = 1e14;
        if min(EV) <= 0
        	EV(EV<0) = 0;
        	tmp = max(EV)/cond;
        	ae.C = ae.C + tmp*eye(N,N); EV = EV + tmp*ones(N,1); 
        end
        if max(EV) > cond*min(EV) 
        	tmp = max(EV)/cond - min(EV);
        	ae.C = ae.C + tmp*eye(N,N); EV = EV + tmp*ones(N,1); 
        end
  end;
  
  ae.diagD = sqrt(EV); 
  if (min(EV) <= 0)
      return
  end;

  ae.B = ae.Bo * diag(ae.diagD);
  ae.invB = diag(1./ae.diagD) * ae.Bo';
  ae.Cold = ae.C;
end

end
