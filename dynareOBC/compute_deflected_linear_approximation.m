% By Alexander Meyer-Gohde. Slight modifications by Tom Holden

function [deflect_]=compute_deflected_linear_approximation(M,options,oo,ModeRSS1OrMean2)

if ModeRSS1OrMean2 > 2
    disp('Incompatible mode')
    deflect_=[];
    return
end

[numeric_version] = return_dynare_version(dynare_version);
if numeric_version >= 4.4 
    nstatic = M.nstatic;
    nspred = M.nspred; % note M_.nspred = M_.npred+M_.nboth;
    % nboth = M_.nboth;
    nfwrd = M.nfwrd;
else
    nstatic = oo.dr.nstatic;
    nspred = oo.dr.npred;
    % nboth = oo_.dr.nboth;
    nfwrd = oo.dr.nfwrd;
end

if options.order>=3
    if options.pruning == 0
        oo = full_block_dr_new(oo,M,options);
    end
end
if options.order>=2
    if isempty(options.qz_criterium)==1
        options.qz_criterium=1.000001;
    end
    state_var =  lyapunov_symm(oo.dr.ghx(nstatic+1:nstatic+nspred,:),oo.dr.ghu(nstatic+1:nstatic+nspred,:)*M.Sigma_e*oo.dr.ghu(nstatic+1:nstatic+nspred,:)',2-options.qz_criterium,options.lyapunov_complex_threshold,0);
end

if options.order>=1
    deflect_.y=oo.dr.ys(oo.dr.order_var);
    deflect_.y_x=oo.dr.ghx;
    deflect_.y_u=oo.dr.ghu;
end
if options.order>=2
    %accumulate=(eye(M_.endo_nbr)-deflect_.y_y)\eye(size(speye(M_.endo_nbr)));%inv(eye(M_.endo_nbr)-deflect_.y_y);
    if ModeRSS1OrMean2==2
        x_2=(eye(nspred)-oo.dr.ghx(nstatic+1:nstatic+nspred,:))\(oo.dr.ghuu(nstatic+1:nstatic+nspred,:)*vec(M.Sigma_e)+oo.dr.ghxx(nstatic+1:nstatic+nspred,:)*vec(state_var)+oo.dr.ghs2(nstatic+1:nstatic+nspred,:));
        y_2=[oo.dr.ghx(1:nstatic,:)*x_2+oo.dr.ghuu(1:nstatic,:)*vec(M.Sigma_e)+oo.dr.ghxx(1:nstatic,:)*vec(state_var)+oo.dr.ghs2(1:nstatic,:);x_2;oo.dr.ghx(nstatic+nspred+1:M.endo_nbr,:)*x_2+oo.dr.ghuu(nstatic+nspred+1:M.endo_nbr,:)*vec(M.Sigma_e)+oo.dr.ghxx(nstatic+nspred+1:M.endo_nbr,:)*vec(state_var)+oo.dr.ghs2(nstatic+nspred+1:M.endo_nbr,:)];
        deflect_.y=deflect_.y+0.5*y_2;
    elseif ModeRSS1OrMean2==1
        x_2=(eye(nspred)-oo.dr.ghx(nstatic+1:nstatic+nspred,:))\(oo.dr.ghs2(nstatic+1:nstatic+nspred,:));
        y_2=[oo.dr.ghx(1:nstatic,:)*x_2+oo.dr.ghs2(1:nstatic,:);x_2;oo.dr.ghx(nstatic+nspred+1:M.endo_nbr,:)*x_2+oo.dr.ghs2(nstatic+nspred+1:M.endo_nbr,:)];
        deflect_.x_2=x_2;
        %y_2_alt=(eye(M_.endo_nbr)-[zeros(M_.endo_nbr,nstatic),oo_.dr.ghx,zeros(M_.endo_nbr,nfwrd)])\oo_.dr.ghs2;
        %max(max(abs(y_2_alt-y_2)))
        deflect_.y=deflect_.y+0.5*y_2;
    end
end
if options.order==3 && ModeRSS1OrMean2 > 0
    deflect_.y_x=deflect_.y_x+0.5*(oo.dr.ghxx*kron(x_2,eye(nspred))+2*(oo.dr.g_1(:,1:nspred)-oo.dr.ghx));
    deflect_.y_u=deflect_.y_u+0.5*(oo.dr.ghxu*kron(x_2,eye(M.exo_nbr))+2*(oo.dr.g_1(:,1+nspred:end)-oo.dr.ghu));
end
deflect_.y=deflect_.y(oo.dr.inv_order_var);
deflect_.y_y=[zeros(M.endo_nbr,nstatic),deflect_.y_x,zeros(M.endo_nbr,nfwrd)];
deflect_.y_y=deflect_.y_y(oo.dr.inv_order_var,oo.dr.inv_order_var);
deflect_.y_e=deflect_.y_u(oo.dr.inv_order_var,:);
