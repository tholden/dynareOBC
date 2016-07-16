function [residual, g1, g2, g3] = news_bkw2012_dynamic(y, x, params, steady_state, it_)
%
% Status : Computes dynamic model for Dynare
%
% Inputs :
%   y         [#dynamic variables by 1] double    vector of endogenous variables in the order stored
%                                                 in M_.lead_lag_incidence; see the Manual
%   x         [nperiods by M_.exo_nbr] double     matrix of exogenous variables (in declaration order)
%                                                 for all simulation periods
%   steady_state  [M_.endo_nbr by 1] double       vector of steady state values
%   params    [M_.param_nbr by 1] double          vector of parameter values in declaration order
%   it_       scalar double                       time period for exogenous variables for which to evaluate the model
%
% Outputs:
%   residual  [M_.endo_nbr by 1] double    vector of residuals of the dynamic model equations in order of 
%                                          declaration of the equations.
%                                          Dynare may prepend auxiliary equations, see M_.aux_vars
%   g1        [M_.endo_nbr by #dynamic variables] double    Jacobian matrix of the dynamic model equations;
%                                                           rows: equations in order of declaration
%                                                           columns: variables in order stored in M_.lead_lag_incidence
%   g2        [M_.endo_nbr by (#dynamic variables)^2] double   Hessian matrix of the dynamic model equations;
%                                                              rows: equations in order of declaration
%                                                              columns: variables in order stored in M_.lead_lag_incidence
%   g3        [M_.endo_nbr by (#dynamic variables)^3] double   Third order derivative matrix of the dynamic model equations;
%                                                              rows: equations in order of declaration
%                                                              columns: variables in order stored in M_.lead_lag_incidence
%
%
% Warning : this file is generated automatically by Dynare
%           from model file (.mod)

%
% Model equations
%

residual = zeros(24, 1);
Pi__ = exp(y(22));
Pi_LEAD__ = exp(y(46));
Pi_STEADY__ = exp(params(6));
kappa__ = params(5)/2*(Pi__-1)^2;
kappa_STEADY__ = params(5)/2*(Pi_STEADY__-1)^2;
c__ = log(1-kappa__-params(9))+y(21);
c_LEAD__ = log(1-params(5)/2*(Pi_LEAD__-1)^2-params(9))+y(45);
h__ = y(21)-y(23);
w__ = params(1)*c__+params(2)*h__-log(1-params(10));
re__ = params(6)+(-log(params(3)))-y(24);
y_STEADY__ = 1/(params(1)+params(2))*(log((1-params(10))*(1+params(5)*Pi_STEADY__*(Pi_STEADY__-1)*(1-params(3))/params(4)))-params(1)*log(1-kappa_STEADY__-params(9)));
gdp__ = y(21)+log(1-kappa__);
gdp_STEADY__ = log(1-kappa_STEADY__)+y_STEADY__;
T117 = params(4)/params(5);
lhs =y(25);
rhs =0.05000000000000004*(re__+params(7)*(y(22)-params(6))+params(8)*(gdp__-gdp_STEADY__))+0.95*y(1)+0.01*y(20);
residual(1)= lhs-rhs;
lhs =1;
rhs =params(3)*exp(y(24)+y(25)-y(46)+params(1)*(c__-c_LEAD__));
residual(2)= lhs-rhs;
lhs =Pi__*(Pi__-1);
rhs =T117*(exp(w__-y(23))-1)+Pi_LEAD__*(Pi_LEAD__-1)*params(3)*exp(y(45)+y(24)+params(1)*(c__-c_LEAD__)-y(21));
residual(3)= lhs-rhs;
residual(4) = y(24);
residual(5) = y(23);
lhs =y(26);
rhs =x(it_, 1);
residual(6)= lhs-rhs;
lhs =y(27);
rhs =y(2);
residual(7)= lhs-rhs;
lhs =y(28);
rhs =y(3);
residual(8)= lhs-rhs;
lhs =y(29);
rhs =y(4);
residual(9)= lhs-rhs;
lhs =y(30);
rhs =y(5);
residual(10)= lhs-rhs;
lhs =y(31);
rhs =y(6);
residual(11)= lhs-rhs;
lhs =y(32);
rhs =y(7);
residual(12)= lhs-rhs;
lhs =y(33);
rhs =y(8);
residual(13)= lhs-rhs;
lhs =y(34);
rhs =y(9);
residual(14)= lhs-rhs;
lhs =y(35);
rhs =y(10);
residual(15)= lhs-rhs;
lhs =y(36);
rhs =y(11);
residual(16)= lhs-rhs;
lhs =y(37);
rhs =y(12);
residual(17)= lhs-rhs;
lhs =y(38);
rhs =y(13);
residual(18)= lhs-rhs;
lhs =y(39);
rhs =y(14);
residual(19)= lhs-rhs;
lhs =y(40);
rhs =y(15);
residual(20)= lhs-rhs;
lhs =y(41);
rhs =y(16);
residual(21)= lhs-rhs;
lhs =y(42);
rhs =y(17);
residual(22)= lhs-rhs;
lhs =y(43);
rhs =y(18);
residual(23)= lhs-rhs;
lhs =y(44);
rhs =y(19);
residual(24)= lhs-rhs;
if nargout >= 2,
  g1 = zeros(24, 47);

  %
  % Jacobian matrix
  %

T247 = params(1)*(-(params(5)/2*exp(y(22))*2*(Pi__-1)))/(1-kappa__-params(9));
T268 = params(1)*(-((-(params(5)/2*exp(y(46))*2*(Pi_LEAD__-1)))/(1-params(5)/2*(Pi_LEAD__-1)^2-params(9))));
  g1(1,21)=(-(0.05000000000000004*params(8)));
  g1(1,22)=(-(0.05000000000000004*(params(7)+params(8)*(-(params(5)/2*exp(y(22))*2*(Pi__-1)))/(1-kappa__))));
  g1(1,24)=0.05000000000000004;
  g1(1,1)=(-0.95);
  g1(1,25)=1;
  g1(1,20)=(-0.01);
  g1(2,21)=(-(params(3)*params(1)*exp(y(24)+y(25)-y(46)+params(1)*(c__-c_LEAD__))));
  g1(2,45)=(-(params(3)*exp(y(24)+y(25)-y(46)+params(1)*(c__-c_LEAD__))*(-params(1))));
  g1(2,22)=(-(params(3)*exp(y(24)+y(25)-y(46)+params(1)*(c__-c_LEAD__))*T247));
  g1(2,46)=(-(params(3)*exp(y(24)+y(25)-y(46)+params(1)*(c__-c_LEAD__))*((-1)+T268)));
  g1(2,24)=(-(params(3)*exp(y(24)+y(25)-y(46)+params(1)*(c__-c_LEAD__))));
  g1(2,25)=(-(params(3)*exp(y(24)+y(25)-y(46)+params(1)*(c__-c_LEAD__))));
  g1(3,21)=(-(T117*(params(1)+params(2))*exp(w__-y(23))+Pi_LEAD__*(Pi_LEAD__-1)*params(3)*exp(y(45)+y(24)+params(1)*(c__-c_LEAD__)-y(21))*(params(1)-1)));
  g1(3,45)=(-(Pi_LEAD__*(Pi_LEAD__-1)*params(3)*exp(y(45)+y(24)+params(1)*(c__-c_LEAD__)-y(21))*(1-params(1))));
  g1(3,22)=exp(y(22))*(Pi__-1)+exp(y(22))*Pi__-(T117*exp(w__-y(23))*T247+Pi_LEAD__*(Pi_LEAD__-1)*params(3)*exp(y(45)+y(24)+params(1)*(c__-c_LEAD__)-y(21))*T247);
  g1(3,46)=(-(exp(y(46))*(Pi_LEAD__-1)*params(3)*exp(y(45)+y(24)+params(1)*(c__-c_LEAD__)-y(21))+Pi_LEAD__*(exp(y(46))*params(3)*exp(y(45)+y(24)+params(1)*(c__-c_LEAD__)-y(21))+(Pi_LEAD__-1)*params(3)*exp(y(45)+y(24)+params(1)*(c__-c_LEAD__)-y(21))*T268)));
  g1(3,23)=(-(T117*exp(w__-y(23))*((-params(2))-1)));
  g1(3,24)=(-(Pi_LEAD__*(Pi_LEAD__-1)*params(3)*exp(y(45)+y(24)+params(1)*(c__-c_LEAD__)-y(21))));
  g1(4,24)=1;
  g1(5,23)=1;
  g1(6,47)=(-1);
  g1(6,26)=1;
  g1(7,2)=(-1);
  g1(7,27)=1;
  g1(8,3)=(-1);
  g1(8,28)=1;
  g1(9,4)=(-1);
  g1(9,29)=1;
  g1(10,5)=(-1);
  g1(10,30)=1;
  g1(11,6)=(-1);
  g1(11,31)=1;
  g1(12,7)=(-1);
  g1(12,32)=1;
  g1(13,8)=(-1);
  g1(13,33)=1;
  g1(14,9)=(-1);
  g1(14,34)=1;
  g1(15,10)=(-1);
  g1(15,35)=1;
  g1(16,11)=(-1);
  g1(16,36)=1;
  g1(17,12)=(-1);
  g1(17,37)=1;
  g1(18,13)=(-1);
  g1(18,38)=1;
  g1(19,14)=(-1);
  g1(19,39)=1;
  g1(20,15)=(-1);
  g1(20,40)=1;
  g1(21,16)=(-1);
  g1(21,41)=1;
  g1(22,17)=(-1);
  g1(22,42)=1;
  g1(23,18)=(-1);
  g1(23,43)=1;
  g1(24,19)=(-1);
  g1(24,44)=1;

if nargout >= 3,
  %
  % Hessian matrix
  %

  g2 = sparse([],[],[],24,2209);
if nargout >= 4,
  %
  % Third order derivatives
  %

  g3 = sparse([],[],[],24,103823);
end
end
end
end
