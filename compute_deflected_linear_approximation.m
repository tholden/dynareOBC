% By Alexander Meyer-Gohde. Slight modifications by Tom Holden

function [deflect_]=compute_deflected_linear_approximation(M_,options_,oo_,ModeRSS1OrMean2)

if ModeRSS1OrMean2 > 2
    disp('Incompatible mode')
    deflect_=[];
    return
end

[numeric_version] = return_dynare_version(dynare_version);
if numeric_version >= 4.4 
    nstatic = M_.nstatic;
    nspred = M_.nspred; % note M_.nspred = M_.npred+M_.nboth;
    % nboth = M_.nboth;
    nfwrd = M_.nfwrd;
else
    nstatic = oo_.dr.nstatic;
    nspred = oo_.dr.npred;
    % nboth = oo_.dr.nboth;
    nfwrd = oo_.dr.nfwrd;
end

if options_.order>=3
    if options_.pruning == 0
        oo_ = full_block_dr_new(oo_,M_,options_);
    end
end
if options_.order>=2
    if isempty(options_.qz_criterium)==1
        options_.qz_criterium=1.000001;
    end
    state_var =  lyapunov_symm(oo_.dr.ghx(nstatic+1:nstatic+nspred,:),oo_.dr.ghu(nstatic+1:nstatic+nspred,:)*M_.Sigma_e*oo_.dr.ghu(nstatic+1:nstatic+nspred,:)',2-options_.qz_criterium,options_.lyapunov_complex_threshold);
end

if options_.order>=1
    deflect_.y=oo_.dr.ys(oo_.dr.order_var);
    deflect_.y_x=oo_.dr.ghx;
    deflect_.y_u=oo_.dr.ghu;
end
if options_.order>=2
    %accumulate=(eye(M_.endo_nbr)-deflect_.y_y)\eye(size(speye(M_.endo_nbr)));%inv(eye(M_.endo_nbr)-deflect_.y_y);
    if ModeRSS1OrMean2==2
        x_2=(eye(nspred)-oo_.dr.ghx(nstatic+1:nstatic+nspred,:))\(oo_.dr.ghuu(nstatic+1:nstatic+nspred,:)*vec(M_.Sigma_e)+oo_.dr.ghxx(nstatic+1:nstatic+nspred,:)*vec(state_var)+oo_.dr.ghs2(nstatic+1:nstatic+nspred,:));
        y_2=[oo_.dr.ghx(1:nstatic,:)*x_2+oo_.dr.ghuu(1:nstatic,:)*vec(M_.Sigma_e)+oo_.dr.ghxx(1:nstatic,:)*vec(state_var)+oo_.dr.ghs2(1:nstatic,:);x_2;oo_.dr.ghx(nstatic+nspred+1:M_.endo_nbr,:)*x_2+oo_.dr.ghuu(nstatic+nspred+1:M_.endo_nbr,:)*vec(M_.Sigma_e)+oo_.dr.ghxx(nstatic+nspred+1:M_.endo_nbr,:)*vec(state_var)+oo_.dr.ghs2(nstatic+nspred+1:M_.endo_nbr,:)];
        deflect_.y=deflect_.y+0.5*y_2;
    elseif ModeRSS1OrMean2==1
        x_2=(eye(nspred)-oo_.dr.ghx(nstatic+1:nstatic+nspred,:))\(oo_.dr.ghs2(nstatic+1:nstatic+nspred,:));
        y_2=[oo_.dr.ghx(1:nstatic,:)*x_2+oo_.dr.ghs2(1:nstatic,:);x_2;oo_.dr.ghx(nstatic+nspred+1:M_.endo_nbr,:)*x_2+oo_.dr.ghs2(nstatic+nspred+1:M_.endo_nbr,:)];
        deflect_.x_2=x_2;
        %y_2_alt=(eye(M_.endo_nbr)-[zeros(M_.endo_nbr,nstatic),oo_.dr.ghx,zeros(M_.endo_nbr,nfwrd)])\oo_.dr.ghs2;
        %max(max(abs(y_2_alt-y_2)))
        deflect_.y=deflect_.y+0.5*y_2;
    end
end
if options_.order==3 && ModeRSS1OrMean2 > 0
    deflect_.y_x=deflect_.y_x+0.5*(oo_.dr.ghxx*kron(x_2,eye(nspred))+2*(oo_.dr.g_1(:,1:nspred)-oo_.dr.ghx));
    deflect_.y_u=deflect_.y_u+0.5*(oo_.dr.ghxu*kron(x_2,eye(M_.exo_nbr))+2*(oo_.dr.g_1(:,1+nspred:end)-oo_.dr.ghu));
end
deflect_.y=deflect_.y(oo_.dr.inv_order_var);
deflect_.y_y=[zeros(M_.endo_nbr,nstatic),deflect_.y_x,zeros(M_.endo_nbr,nfwrd)];
deflect_.y_y=deflect_.y_y(oo_.dr.inv_order_var,oo_.dr.inv_order_var);
deflect_.y_e=deflect_.y_u(oo_.dr.inv_order_var,:);
