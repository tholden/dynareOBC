function simulations = CustomLanMeyerGohdePrunedSimulation( nstatic, nspred, endo_nbr, dr, shock_sequence, simul_length, pruning_order, initial_state )
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
  % Starting in Dynare 4.4.0, the following fields are no longer in dr, 
  % they can be found in M_
    % nstatic = M_.nstatic;
    % nspred = M_.nspred; % note M_.nspred = M_.npred+M_.nboth;
    % nboth = M_.nboth;
    % nfwrd = M_.nfwrd;

    % Build state variable selector
    select_state = nstatic+1:nstatic+nspred;

%--------------------------------------------------------------------------
% 0.2. Set up initial value of the state and pre-allocate memory
%--------------------------------------------------------------------------
    
    simul_length_p1 = simul_length + 1;
    
    simulation_first = zeros(endo_nbr,simul_length_p1);
    if pruning_order >= 2
        simulation_second = zeros(endo_nbr,simul_length_p1);
        if pruning_order >= 3
            simulation_third = zeros(endo_nbr,simul_length_p1);
            simulation_first_sigma_2 = zeros(endo_nbr,simul_length_p1);
        end
    end
    
    simulation_first( :, 1 ) = initial_state.first( dr.order_var );
    if pruning_order >= 2
        simulation_second( :, 1 ) = initial_state.second( dr.order_var );
        if pruning_order >= 3
            simulation_third( :, 1 ) = initial_state.third( dr.order_var );
            simulation_first_sigma_2( :, 1 ) = initial_state.first_sigma_2( dr.order_var );
        end
    end
     
%--------------------------------------------------------------------------
% 1. Simulate first order solution for all the algorithms
%--------------------------------------------------------------------------
  if pruning_order == 1
    E = shock_sequence;
    for t=2:simul_length_p1
      simulation_first(:,t)=dr.ghx*simulation_first(select_state,t-1)+dr.ghu*E(:,t-1);
    end
    simulations.first=simulation_first(dr.inv_order_var,2:simul_length_p1);
    simulations.constant=dr.ys;
    simulations.total = coder.nullcopy( zeros( length( dr.ys ), simul_length ) );
    simulations.total=simulations.first+repmat(simulations.constant,[1 simul_length]);
    return;
  end

%--------------------------------------------------------------------------
% 2. Simulate second order pruned solutions
%--------------------------------------------------------------------------
  if pruning_order == 2
    
            ghs2_nlma = dr.ghs2_nlma;
          % Simulation
            E = shock_sequence;
            for t = 2:simul_length_p1
                simulation_first(:,t)=dr.ghx*simulation_first(select_state,t-1)+dr.ghu*E(:,t-1);
                exe = alt_kron_stripped(E(:,t-1),E(:,t-1));
                sxe = alt_kron_stripped(simulation_first(select_state,t-1),E(:,t-1));
                sxs = alt_kron_stripped(simulation_first(select_state,t-1),simulation_first(select_state,t-1));
                simulation_second(:,t) = dr.ghx*simulation_second(select_state,t-1)...
                                         +(1/2)*( dr.ghxx*sxs+2*dr.ghxu*sxe+dr.ghuu*exe );
            end
            simulations.first = simulation_first(dr.inv_order_var,2:simul_length_p1);
            simulations.second = simulation_second(dr.inv_order_var,2:simul_length_p1);
            simulations.constant = dr.ys + 0.5*ghs2_nlma(dr.inv_order_var,:);
            simulations.total = coder.nullcopy( zeros( length( dr.ys ), simul_length ) );
            simulations.total = simulations.second + simulations.first...
                                 +repmat( simulations.constant,[1 simul_length] );
                             
                             return;
  end

%--------------------------------------------------------------------------
% 3. Simulate third order pruned solutions
%--------------------------------------------------------------------------
  if pruning_order==3
      
               ghs2_nlma = dr.ghs2_nlma;
               ghuss_nlma = dr.ghuss_nlma;
               ghxss_nlma = dr.ghxss_nlma;
         % Simulation
           E = shock_sequence;
           for t = 2:simul_length_p1
               simulation_first(:,t)=dr.ghx*simulation_first(select_state,t-1)+dr.ghu*E(:,t-1);
               exe = alt_kron_stripped(E(:,t-1),E(:,t-1));
               sxe = alt_kron_stripped(simulation_first(select_state,t-1),E(:,t-1));
               sxs = alt_kron_stripped(simulation_first(select_state,t-1),simulation_first(select_state,t-1));
               simulation_second(:,t) = dr.ghx*simulation_second(select_state,t-1)...
                                        +(1/2)*( dr.ghxx*sxs+2*dr.ghxu*sxe+dr.ghuu*exe );
               simulation_first_sigma_2(:,t) = dr.ghx*simulation_first_sigma_2(select_state,t-1)...
                                              +(1/2)*(ghuss_nlma*E(:,t-1)+ghxss_nlma*simulation_first(select_state,t-1));
               simulation_third(:,t) = dr.ghx*simulation_third(select_state,t-1)...
                                       +(1/6)*(dr.ghxxx*alt_kron_stripped(simulation_first(select_state,t-1),sxs)+dr.ghuuu*alt_kron_stripped(E(:,t-1),exe))...
                                       +(1/2)*(dr.ghxxu*alt_kron_stripped(sxs,E(:,t-1))+dr.ghxuu*alt_kron_stripped(simulation_first(select_state,t-1),exe))...
                                       +dr.ghxx*alt_kron_stripped(simulation_second(select_state,t-1),simulation_first(select_state,t-1))...
                                       +dr.ghxu*alt_kron_stripped(simulation_second(select_state,t-1),E(:,t-1));
           end
           simulations.first = simulation_first(dr.inv_order_var,2:simul_length_p1);
           simulations.second = simulation_second(dr.inv_order_var,2:simul_length_p1);      
           simulations.first_sigma_2 = simulation_first_sigma_2(dr.inv_order_var,2:simul_length_p1);
           simulations.third = simulation_third(dr.inv_order_var,2:simul_length_p1);
           simulations.constant = dr.ys + 0.5*ghs2_nlma(dr.inv_order_var,:);
           simulations.total = coder.nullcopy( zeros( length( dr.ys ), simul_length ) );
           simulations.total = simulations.third +simulations.first_sigma_2 + simulations.second + simulations.first...
                               +repmat( simulations.constant,[1 simul_length] );
                           
                           return;
      
  end
