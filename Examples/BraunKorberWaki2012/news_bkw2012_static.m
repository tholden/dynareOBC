function [residual, g1, g2, g3] = news_bkw2012_static(y, x, params)
%
% Status : Computes static model for Dynare
%
% Inputs : 
%   y         [M_.endo_nbr by 1] double    vector of endogenous variables in declaration order
%   x         [M_.exo_nbr by 1] double     vector of exogenous variables in declaration order
%   params    [M_.param_nbr by 1] double   vector of parameter values in declaration order
%
% Outputs:
%   residual  [M_.endo_nbr by 1] double    vector of residuals of the static model equations 
%                                          in order of declaration of the equations.
%                                          Dynare may prepend or append auxiliary equations, see M_.aux_vars
%   g1        [M_.endo_nbr by M_.endo_nbr] double    Jacobian matrix of the static model equations;
%                                                       columns: variables in declaration order
%                                                       rows: equations in order of declaration
%   g2        [M_.endo_nbr by (M_.endo_nbr)^2] double   Hessian matrix of the static model equations;
%                                                       columns: variables in declaration order
%                                                       rows: equations in order of declaration
%   g3        [M_.endo_nbr by (M_.endo_nbr)^3] double   Third derivatives matrix of the static model equations;
%                                                       columns: variables in declaration order
%                                                       rows: equations in order of declaration
%
%
% Warning : this file is generated automatically by Dynare
%           from model file (.mod)

residual = zeros( 24, 1);

%
% Model equations
%

Pi__ = exp(y(2));
Pi_LEAD__ = exp(y(2));
Pi_STEADY__ = exp(params(6));
kappa__ = params(5)/2*(Pi__-1)^2;
kappa_STEADY__ = params(5)/2*(Pi_STEADY__-1)^2;
c__ = log(1-kappa__-params(9))+y(1);
c_LEAD__ = y(1)+log(1-params(5)/2*(Pi_LEAD__-1)^2-params(9));
h__ = y(1)-y(3);
w__ = params(1)*c__+params(2)*h__-log(1-params(10));
re__ = params(6)+(-log(params(3)))-y(4);
y_STEADY__ = 1/(params(1)+params(2))*(log((1-params(10))*(1+params(5)*Pi_STEADY__*(Pi_STEADY__-1)*(1-params(3))/params(4)))-params(1)*log(1-kappa_STEADY__-params(9)));
gdp__ = y(1)+log(1-kappa__);
gdp_STEADY__ = log(1-kappa_STEADY__)+y_STEADY__;
T111 = params(4)/params(5);
lhs =y(5);
rhs =0.05000000000000004*(re__+params(7)*(y(2)-params(6))+params(8)*(gdp__-gdp_STEADY__))+y(5)*0.95+0.01*x(1);
residual(1)= lhs-rhs;
lhs =1;
rhs =params(3)*exp(y(4)+y(5)-y(2)+params(1)*(c__-c_LEAD__));
residual(2)= lhs-rhs;
lhs =Pi__*(Pi__-1);
rhs =T111*(exp(w__-y(3))-1)+Pi_LEAD__*(Pi_LEAD__-1)*params(3)*exp(y(1)+y(4)+params(1)*(c__-c_LEAD__)-y(1));
residual(3)= lhs-rhs;
residual(4) = y(4);
residual(5) = y(3);
lhs =y(6);
rhs =x(1);
residual(6)= lhs-rhs;
lhs =y(7);
rhs =x(1);
residual(7)= lhs-rhs;
lhs =y(8);
rhs =x(1);
residual(8)= lhs-rhs;
lhs =y(9);
rhs =x(1);
residual(9)= lhs-rhs;
lhs =y(10);
rhs =x(1);
residual(10)= lhs-rhs;
lhs =y(11);
rhs =x(1);
residual(11)= lhs-rhs;
lhs =y(12);
rhs =x(1);
residual(12)= lhs-rhs;
lhs =y(13);
rhs =x(1);
residual(13)= lhs-rhs;
lhs =y(14);
rhs =x(1);
residual(14)= lhs-rhs;
lhs =y(15);
rhs =x(1);
residual(15)= lhs-rhs;
lhs =y(16);
rhs =x(1);
residual(16)= lhs-rhs;
lhs =y(17);
rhs =x(1);
residual(17)= lhs-rhs;
lhs =y(18);
rhs =x(1);
residual(18)= lhs-rhs;
lhs =y(19);
rhs =x(1);
residual(19)= lhs-rhs;
lhs =y(20);
rhs =x(1);
residual(20)= lhs-rhs;
lhs =y(21);
rhs =x(1);
residual(21)= lhs-rhs;
lhs =y(22);
rhs =x(1);
residual(22)= lhs-rhs;
lhs =y(23);
rhs =x(1);
residual(23)= lhs-rhs;
lhs =y(24);
rhs =x(1);
residual(24)= lhs-rhs;
if ~isreal(residual)
  residual = real(residual)+imag(residual).^2;
end
if nargout >= 2,
  g1 = zeros(24, 24);

  %
  % Jacobian matrix
  %

T222 = (-(params(5)/2*exp(y(2))*2*(Pi__-1)))/(1-kappa__-params(9));
T229 = params(1)*(T222-(-(params(5)/2*exp(y(2))*2*(Pi_LEAD__-1)))/(1-params(5)/2*(Pi_LEAD__-1)^2-params(9)));
  g1(1,1)=(-(0.05000000000000004*params(8)));
  g1(1,2)=(-(0.05000000000000004*(params(7)+params(8)*(-(params(5)/2*exp(y(2))*2*(Pi__-1)))/(1-kappa__))));
  g1(1,4)=0.05000000000000004;
  g1(1,5)=0.05000000000000004;
  g1(2,2)=(-(params(3)*exp(y(4)+y(5)-y(2)+params(1)*(c__-c_LEAD__))*((-1)+T229)));
  g1(2,4)=(-(params(3)*exp(y(4)+y(5)-y(2)+params(1)*(c__-c_LEAD__))));
  g1(2,5)=(-(params(3)*exp(y(4)+y(5)-y(2)+params(1)*(c__-c_LEAD__))));
  g1(3,1)=(-(T111*(params(1)+params(2))*exp(w__-y(3))));
  g1(3,2)=exp(y(2))*(Pi__-1)+exp(y(2))*Pi__-(T111*exp(w__-y(3))*params(1)*T222+exp(y(2))*(Pi_LEAD__-1)*params(3)*exp(y(1)+y(4)+params(1)*(c__-c_LEAD__)-y(1))+Pi_LEAD__*(exp(y(2))*params(3)*exp(y(1)+y(4)+params(1)*(c__-c_LEAD__)-y(1))+(Pi_LEAD__-1)*params(3)*exp(y(1)+y(4)+params(1)*(c__-c_LEAD__)-y(1))*T229));
  g1(3,3)=(-(T111*exp(w__-y(3))*((-params(2))-1)));
  g1(3,4)=(-(Pi_LEAD__*(Pi_LEAD__-1)*params(3)*exp(y(1)+y(4)+params(1)*(c__-c_LEAD__)-y(1))));
  g1(4,4)=1;
  g1(5,3)=1;
  g1(6,6)=1;
  g1(7,7)=1;
  g1(8,8)=1;
  g1(9,9)=1;
  g1(10,10)=1;
  g1(11,11)=1;
  g1(12,12)=1;
  g1(13,13)=1;
  g1(14,14)=1;
  g1(15,15)=1;
  g1(16,16)=1;
  g1(17,17)=1;
  g1(18,18)=1;
  g1(19,19)=1;
  g1(20,20)=1;
  g1(21,21)=1;
  g1(22,22)=1;
  g1(23,23)=1;
  g1(24,24)=1;
  if ~isreal(g1)
    g1 = real(g1)+2*imag(g1);
  end
if nargout >= 3,
  %
  % Hessian matrix
  %

  g2 = sparse([],[],[],24,576);
if nargout >= 4,
  %
  % Third order derivatives
  %

  g3 = sparse([],[],[],24,13824);
end
end
end
end
