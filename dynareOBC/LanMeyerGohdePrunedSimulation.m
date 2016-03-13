function [ simulations, dr ] = LanMeyerGohdePrunedSimulation( M, dr, shock_sequence, simul_length, pruning_order, use_cached_nlma_values, initial_state, call_back, call_back_arg )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% pruning_abounds.m
%
% This file implements all of the second and third order pruning algorithms
% documented in "Pruning in Perturbation DSGE Models" by Hong Lan and 
% Alexander Meyer-Gohde.
%
% The pruning algorithms are called by setting the option pruning_type:
%
% For second order approximations (options_.order=2 in Dynare)
% pruning_type = 
%'kim_et_al' :  The second order algorithm of 
%               KIM, J., S. KIM, E. SCHAUMBURG, AND C. A. SIMS (2008): 
%               “Calculating and Using Second-Order Accurate Solutions of 
%               Discrete Time Dynamic Equilibrium Models,?Journal of 
%               Economic Dynamics and Control, 32(11), 3397?414.
%
%'den_haan_de_wind' : The second order algorithm of DEN HAAN, W. J., AND J.
%                     DE WIND (2012): “Nonlinear and Stable Perturbation 
%                     Based Approximations", Journal of Economic Dynamics 
%                     and Control, 36(10), 1477?497.
%
%'lan_meyer-gohde' : The second order algorithm of LAN, H., AND A. 
%                    MEYER-GOHDE(2013): “Solving DSGE Models with a 
%                    Nonlinear Moving Average", Journal of Economic 
%                    Dynamics and Control, 37(12), 2643-2667.
%
%
% For third order approximations (options_.order=3 in Dynare)
% pruning_type = 
%'andreasen' : The third order algorithm of ANDREASEN, M. M. (2012): “On 
%              the Effects of Rare Disasters and Uncertainty Shocks for 
%              Risk Premia in Non-Linear DSGE Models", Review of Economic 
%              Dynamics, 15(3), 295?16.
%
%'fernandez-villaverde_et_al' : The third order algorithm of 
%               FERNANDEZ-VILLAVERDE, J., P. A. GUERRO N-QUINTANA, J. 
%               RUBIO-RAMI REZ, AND M. URIBE (2011): “Risk Matters: The 
%               Real Effects of Volatility Shocks", American Economic
%               Review, 101(6), 2530?1.
%
%'den_haan_de_wind' : The third order algorithm of DEN HAAN, W. J., AND J.
%                     DE WIND (2012): “Nonlinear and Stable Perturbation 
%                     Based Approximations", Journal of Economic Dynamics 
%                     and Control, 36(10), 1477?497.
%
%'lan_meyer-gohde' : The second order algorithm of LAN, H., AND A. 
%                    MEYER-GOHDE(2013): “Solving DSGE Models with a 
%                    Nonlinear Moving Average", Journal of Economic 
%                    Dynamics and Control, 37(12), 2643 ? 2667.
%
%THIS VERSION: 1.1.0 March 13, 2014
%
%Copyright: Hong Lan and Alexander Meyer-Gohde
%
%You are free to use/modify/redistribute this program so long as original
%authorship credit is given and you in no way impinge on its free
%distribution
%This software is provided as is with no guarantees of any kind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
%--------------------------------------------------------------------------
% 0.1. Dynare version check
%--------------------------------------------------------------------------
  % Starting in Dynare 4.4.0, the following fields are no longer in oo_.dr, 
  % they can be found in M_
    nstatic = M.nstatic;
    nspred = M.nspred; % note M_.nspred = M_.npred+M_.nboth;

  % Build state variable selector
    select_state = nstatic+1:nstatic+nspred;

%--------------------------------------------------------------------------
% 0.2. Set up initial value of the state and pre-allocate memory
%--------------------------------------------------------------------------
    
    simul_length_p1 = simul_length + 1;
    
    simulation_first = zeros(M.endo_nbr,simul_length_p1);
    if pruning_order >= 2
        simulation_second = zeros(M.endo_nbr,simul_length_p1);
        if pruning_order >= 3
            simulation_third = zeros(M.endo_nbr,simul_length_p1);
            simulation_first_sigma_2 = zeros(M.endo_nbr,simul_length_p1);
        end
    end
    
    if nargin < 6
        use_cached_nlma_values = 0;
    end
    if nargin >= 7
        simulation_first( :, 1 ) = initial_state.first( dr.order_var );
        if pruning_order >= 2
            simulation_second( :, 1 ) = initial_state.second( dr.order_var );
            if pruning_order >= 3
                simulation_third( :, 1 ) = initial_state.third( dr.order_var );
                simulation_first_sigma_2( :, 1 ) = initial_state.first_sigma_2( dr.order_var );
            end
        end
    end
    
%--------------------------------------------------------------------------
% 1. Simulate first order solution for all the algorithms
%--------------------------------------------------------------------------
  if pruning_order == 1
    E = shock_sequence;
    for t=2:simul_length_p1
      simulation_first(:,t)=dr.ghx*simulation_first(select_state,t-1)+dr.ghu*E(:,t-1);
       if nargin >= 9
          call_back(call_back_arg);
       end
    end
    simulations.first=simulation_first(dr.inv_order_var,2:simul_length_p1);
    simulations.constant=dr.ys;
    simulations.total=bsxfun( @plus, simulations.first, simulations.constant );
  end

%--------------------------------------------------------------------------
% 2. Simulate second order pruned solutions
%--------------------------------------------------------------------------
  if pruning_order == 2
    
            if use_cached_nlma_values
                ghs2_nlma = dr.ghs2_nlma;
            else
              % Compute nlma's y_sigma^2
                ghs2_state_nlma = (eye(nspred)-dr.ghx(nstatic+1:nstatic+nspred,:))\(dr.ghs2(nstatic+1:nstatic+nspred,:));
                ghs2_nlma = [ dr.ghx(1:nstatic,:)*ghs2_state_nlma+dr.ghs2(1:nstatic,:)
                              ghs2_state_nlma
                              dr.ghx(nstatic+nspred+1:M.endo_nbr,:)*ghs2_state_nlma+dr.ghs2(nstatic+nspred+1:M.endo_nbr,:)]; 
              % Save results
              if nargout > 1
                dr.ghs2_state_nlma = ghs2_state_nlma;
                dr.ghs2_nlma = ghs2_nlma;
              end
            end
          % Simulation
            E = shock_sequence;
            for t = 2:simul_length_p1
                simulation_first(:,t)=dr.ghx*simulation_first(select_state,t-1)+dr.ghu*E(:,t-1);
                exe = alt_kron(E(:,t-1),E(:,t-1));
                sxe = alt_kron(simulation_first(select_state,t-1),E(:,t-1));
                sxs = alt_kron(simulation_first(select_state,t-1),simulation_first(select_state,t-1));
                simulation_second(:,t) = dr.ghx*simulation_second(select_state,t-1)...
                                         +(1/2)*( dr.ghxx*sxs+2*dr.ghxu*sxe+dr.ghuu*exe );
               if nargin >= 9
                  call_back(call_back_arg);
               end
            end
            simulations.first = simulation_first(dr.inv_order_var,2:simul_length_p1);
            simulations.second = simulation_second(dr.inv_order_var,2:simul_length_p1);
            simulations.constant = dr.ys + 0.5*ghs2_nlma(dr.inv_order_var,:);
            simulations.total = bsxfun( @plus, simulations.second + simulations.first, simulations.constant );
  end

%--------------------------------------------------------------------------
% 3. Simulate third order pruned solutions
%--------------------------------------------------------------------------
  if pruning_order==3
     % assert( options.pruning ~= 0, 'This function requires options_.pruning = true.' );
     
           if use_cached_nlma_values
               ghs2_nlma = dr.ghs2_nlma;
               ghuss_nlma = dr.ghuss_nlma;
               ghxss_nlma = dr.ghxss_nlma;
           else
             % Compute nlma's y_sigma^2
               ghs2_state_nlma = (eye(nspred)-dr.ghx(nstatic+1:nstatic+nspred,:))\(dr.ghs2(nstatic+1:nstatic+nspred,:));
               ghs2_nlma = [ dr.ghx(1:nstatic,:)*ghs2_state_nlma+dr.ghs2(1:nstatic,:)
                             ghs2_state_nlma
                             dr.ghx(nstatic+nspred+1:M.endo_nbr,:)*ghs2_state_nlma+dr.ghs2(nstatic+nspred+1:M.endo_nbr,:)]; 
             % Compute nlma's y_sigma^2e and y_sigma^2y^state
               % y_sigma^2e           
                 ghuss_nlma = dr.ghuss + dr.ghxu*alt_kron(ghs2_state_nlma,eye(M.exo_nbr));
               % y_sigma^2y^state
                 ghxss_nlma = dr.ghxss + dr.ghxx*alt_kron(ghs2_state_nlma,eye(nspred));
             % Save results
             if nargout > 1
               dr.ghs2_state_nlma = ghs2_state_nlma;
               dr.ghs2_nlma = ghs2_nlma;
               dr.ghuss_nlma = ghuss_nlma;
               dr.ghxss_nlma = ghxss_nlma;
             end
           end
         % Simulation
           E = shock_sequence;
           for t = 2:simul_length_p1
               simulation_first(:,t)=dr.ghx*simulation_first(select_state,t-1)+dr.ghu*E(:,t-1);
               exe = alt_kron(E(:,t-1),E(:,t-1));
               sxe = alt_kron(simulation_first(select_state,t-1),E(:,t-1));
               sxs = alt_kron(simulation_first(select_state,t-1),simulation_first(select_state,t-1));
               simulation_second(:,t) = dr.ghx*simulation_second(select_state,t-1)...
                                        +(1/2)*( dr.ghxx*sxs+2*dr.ghxu*sxe+dr.ghuu*exe );
               simulation_first_sigma_2(:,t) = dr.ghx*simulation_first_sigma_2(select_state,t-1)...
                                              +(1/2)*(ghuss_nlma*E(:,t-1)+ghxss_nlma*simulation_first(select_state,t-1));
               simulation_third(:,t) = dr.ghx*simulation_third(select_state,t-1)...
                                       +(1/6)*(dr.ghxxx*alt_kron(simulation_first(select_state,t-1),sxs)+dr.ghuuu*alt_kron(E(:,t-1),exe))...
                                       +(1/2)*(dr.ghxxu*alt_kron(sxs,E(:,t-1))+dr.ghxuu*alt_kron(simulation_first(select_state,t-1),exe))...
                                       +dr.ghxx*alt_kron(simulation_second(select_state,t-1),simulation_first(select_state,t-1))...
                                       +dr.ghxu*alt_kron(simulation_second(select_state,t-1),E(:,t-1));
               if nargin >= 9
                  call_back(call_back_arg);
               end
           end
           simulations.first = simulation_first(dr.inv_order_var,2:simul_length_p1);
           simulations.second = simulation_second(dr.inv_order_var,2:simul_length_p1);      
           simulations.first_sigma_2 = simulation_first_sigma_2(dr.inv_order_var,2:simul_length_p1);
           simulations.third = simulation_third(dr.inv_order_var,2:simul_length_p1);
           simulations.constant = dr.ys + 0.5*ghs2_nlma(dr.inv_order_var,:);
           simulations.total = bsxfun( @plus, simulations.third +simulations.first_sigma_2 + simulations.second + simulations.first, simulations.constant );
  end
