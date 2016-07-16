function [residual, g1, g2, g3] = news_SW03_static(y, x, params)
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

residual = zeros( 71, 1);

%
% Model equations
%

T55 = 1/(1+params(17)*params(3));
T95 = (-params(8))*(1-params(4))/(1-params(4)-params(9));
T99 = params(8)*params(9)/(1-params(4)-params(9));
T135 = (1-params(19))*(1-params(19))/params(19);
T234 = params(12)*params(11)/(1-params(11))-1;
T238 = 1/((1+params(3))*params(10)*T234/(1-params(10)));
T240 = params(10)*T234/(1-params(10));
T260 = T234*params(10)/(1-params(10))*params(10)*params(3)*params(14)+T234*params(10)/(1-params(10))+T234*params(14)*params(3)*params(10);
lhs =y(34);
rhs =y(34)*params(22)+(1-params(22))*(params(20)*y(28)+params(23)*y(38))+0.01*x(1);
residual(1)= lhs-rhs;
lhs =y(1);
rhs =params(1)*y(3)+(1-params(1))*y(12)-y(39);
residual(2)= lhs-rhs;
lhs =y(2);
rhs =y(3)*1/params(18);
residual(3)= lhs-rhs;
lhs =y(3);
rhs =y(12)+y(10)-y(4);
residual(4)= lhs-rhs;
lhs =y(4);
rhs =y(2)+y(49);
residual(5)= lhs-rhs;
lhs =y(8);
rhs =T55*(y(8)*params(17)+y(8)*params(3)+1/params(7)*y(5));
residual(6)= lhs-rhs;
lhs =y(5);
rhs =y(6)+(-y(6))-y(41)+y(3)*(1-params(3)*(1-params(2)))+y(5)*params(3)*(1-params(2))+y(44);
residual(7)= lhs-rhs;
lhs =y(6);
rhs =y(6)+y(17)-y(11)-y(41);
residual(8)= lhs-rhs;
lhs =y(6);
rhs =T95*y(7)+T99*y(50);
residual(9)= lhs-rhs;
lhs =y(9);
rhs =y(7)*params(5)+y(8)*params(6)+y(42);
residual(10)= lhs-rhs;
lhs =y(9);
rhs =params(16)*(y(39)+params(1)*y(4)+(1-params(1))*y(10));
residual(11)= lhs-rhs;
residual(12) = y(1);
lhs =y(12);
rhs =(-y(6))-y(43)+y(10)*params(12);
residual(13)= lhs-rhs;
lhs =y(13);
rhs =y(11);
residual(14)= lhs-rhs;
lhs =y(14);
rhs =y(14)+y(14)-y(14)+T135*y(16);
residual(15)= lhs-rhs;
lhs =y(15);
rhs =y(17)-y(11);
residual(16)= lhs-rhs;
lhs =y(16);
rhs =y(10)-y(14);
residual(17)= lhs-rhs;
residual(18) = y(11);
lhs =y(18);
rhs =params(1)*y(20)+(1-params(1))*y(29)-y(39);
residual(19)= lhs-rhs;
lhs =y(19);
rhs =1/params(18)*y(20);
residual(20)= lhs-rhs;
lhs =y(20);
rhs =y(29)+y(27)-y(21);
residual(21)= lhs-rhs;
lhs =y(21);
rhs =y(19)+y(51);
residual(22)= lhs-rhs;
lhs =y(25);
rhs =y(46)+T55*(params(17)*y(25)+params(3)*y(25)+1/params(7)*y(22));
residual(23)= lhs-rhs;
lhs =y(22);
rhs =y(44)+y(23)+(-y(23))-y(41)+(1-params(3)*(1-params(2)))*y(20)+params(3)*(1-params(2))*y(22);
residual(24)= lhs-rhs;
lhs =y(23);
rhs =y(34)+y(23)-y(28)-y(41);
residual(25)= lhs-rhs;
lhs =y(23);
rhs =T95*y(24)+T99*y(52);
residual(26)= lhs-rhs;
lhs =y(26);
rhs =y(42)+params(5)*y(24)+params(6)*y(25);
residual(27)= lhs-rhs;
lhs =y(26);
rhs =params(16)*(y(39)+params(1)*y(21)+(1-params(1))*y(27));
residual(28)= lhs-rhs;
lhs =y(28);
rhs =y(47)+1/(1+params(3)*params(15))*(y(28)*params(3)+y(28)*params(15)+y(18)*(1-params(13))*(1-params(3)*params(13))/params(13));
residual(29)= lhs-rhs;
lhs =y(29);
rhs =T238*(y(29)*T240+y(29)*params(3)*T240+y(28)*T234*params(14)*params(10)/(1-params(10))-y(28)*T260+y(28)*params(3)*params(10)*(T234+T234*params(10)/(1-params(10)))+(1-params(3)*params(10))*(y(43)+y(29)+y(23)-params(12)*y(27)))+y(48);
residual(30)= lhs-rhs;
lhs =y(30);
rhs =y(30)+y(30)-y(30)+T135*y(32)+0.0*(y(39)+y(39)*params(3)-y(39)*(1+params(3)));
residual(31)= lhs-rhs;
lhs =y(31);
rhs =y(29);
residual(32)= lhs-rhs;
lhs =y(32);
rhs =y(27)-y(30);
residual(33)= lhs-rhs;
residual(34) = y(35);
lhs =y(36);
rhs =y(28);
residual(35)= lhs-rhs;
lhs =y(37);
rhs =y(36);
residual(36)= lhs-rhs;
lhs =y(33);
rhs =y(37)+y(37)+y(28)+y(36);
residual(37)= lhs-rhs;
lhs =y(38);
rhs =y(26)-y(9);
residual(38)= lhs-rhs;
residual(39) = y(40);
residual(40) = y(39);
residual(41) = y(41);
residual(42) = y(42);
residual(43) = y(43);
residual(44) = y(44);
residual(45) = y(45);
residual(46) = y(46);
residual(47) = y(47);
residual(48) = y(48);
lhs =y(49);
rhs =y(49)*(1-params(2))+y(8)*params(2);
residual(49)= lhs-rhs;
lhs =y(50);
rhs =params(4)*y(50)+(1-params(4))*y(7);
residual(50)= lhs-rhs;
lhs =y(51);
rhs =(1-params(2))*y(51)+params(2)*y(25);
residual(51)= lhs-rhs;
lhs =y(52);
rhs =params(4)*y(52)+(1-params(4))*y(24);
residual(52)= lhs-rhs;
lhs =y(53);
rhs =x(1);
residual(53)= lhs-rhs;
lhs =y(54);
rhs =x(1);
residual(54)= lhs-rhs;
lhs =y(55);
rhs =x(1);
residual(55)= lhs-rhs;
lhs =y(56);
rhs =x(1);
residual(56)= lhs-rhs;
lhs =y(57);
rhs =x(1);
residual(57)= lhs-rhs;
lhs =y(58);
rhs =x(1);
residual(58)= lhs-rhs;
lhs =y(59);
rhs =x(1);
residual(59)= lhs-rhs;
lhs =y(60);
rhs =x(1);
residual(60)= lhs-rhs;
lhs =y(61);
rhs =x(1);
residual(61)= lhs-rhs;
lhs =y(62);
rhs =x(1);
residual(62)= lhs-rhs;
lhs =y(63);
rhs =x(1);
residual(63)= lhs-rhs;
lhs =y(64);
rhs =x(1);
residual(64)= lhs-rhs;
lhs =y(65);
rhs =x(1);
residual(65)= lhs-rhs;
lhs =y(66);
rhs =x(1);
residual(66)= lhs-rhs;
lhs =y(67);
rhs =x(1);
residual(67)= lhs-rhs;
lhs =y(68);
rhs =x(1);
residual(68)= lhs-rhs;
lhs =y(69);
rhs =x(1);
residual(69)= lhs-rhs;
lhs =y(70);
rhs =x(1);
residual(70)= lhs-rhs;
lhs =y(71);
rhs =x(1);
residual(71)= lhs-rhs;
if ~isreal(residual)
  residual = real(residual)+imag(residual).^2;
end
if nargout >= 2,
  g1 = zeros(71, 71);

  %
  % Jacobian matrix
  %

  g1(1,28)=(-((1-params(22))*params(20)));
  g1(1,34)=1-params(22);
  g1(1,38)=(-((1-params(22))*params(23)));
  g1(2,1)=1;
  g1(2,3)=(-params(1));
  g1(2,12)=(-(1-params(1)));
  g1(2,39)=1;
  g1(3,2)=1;
  g1(3,3)=(-(1/params(18)));
  g1(4,3)=1;
  g1(4,4)=1;
  g1(4,10)=(-1);
  g1(4,12)=(-1);
  g1(5,2)=(-1);
  g1(5,4)=1;
  g1(5,49)=(-1);
  g1(6,5)=(-(T55*1/params(7)));
  g1(6,8)=1-T55*(params(17)+params(3));
  g1(7,3)=(-(1-params(3)*(1-params(2))));
  g1(7,5)=1-params(3)*(1-params(2));
  g1(7,41)=1;
  g1(7,44)=(-1);
  g1(8,11)=1;
  g1(8,17)=(-1);
  g1(8,41)=1;
  g1(9,6)=1;
  g1(9,7)=(-T95);
  g1(9,50)=(-T99);
  g1(10,7)=(-params(5));
  g1(10,8)=(-params(6));
  g1(10,9)=1;
  g1(10,42)=(-1);
  g1(11,4)=(-(params(1)*params(16)));
  g1(11,9)=1;
  g1(11,10)=(-((1-params(1))*params(16)));
  g1(11,39)=(-params(16));
  g1(12,1)=1;
  g1(13,6)=1;
  g1(13,10)=(-params(12));
  g1(13,12)=1;
  g1(13,43)=1;
  g1(14,11)=(-1);
  g1(14,13)=1;
  g1(15,16)=(-T135);
  g1(16,11)=1;
  g1(16,15)=1;
  g1(16,17)=(-1);
  g1(17,10)=(-1);
  g1(17,14)=1;
  g1(17,16)=1;
  g1(18,11)=1;
  g1(19,18)=1;
  g1(19,20)=(-params(1));
  g1(19,29)=(-(1-params(1)));
  g1(19,39)=1;
  g1(20,19)=1;
  g1(20,20)=(-(1/params(18)));
  g1(21,20)=1;
  g1(21,21)=1;
  g1(21,27)=(-1);
  g1(21,29)=(-1);
  g1(22,19)=(-1);
  g1(22,21)=1;
  g1(22,51)=(-1);
  g1(23,22)=(-(T55*1/params(7)));
  g1(23,25)=1-T55*(params(17)+params(3));
  g1(23,46)=(-1);
  g1(24,20)=(-(1-params(3)*(1-params(2))));
  g1(24,22)=1-params(3)*(1-params(2));
  g1(24,41)=1;
  g1(24,44)=(-1);
  g1(25,28)=1;
  g1(25,34)=(-1);
  g1(25,41)=1;
  g1(26,23)=1;
  g1(26,24)=(-T95);
  g1(26,52)=(-T99);
  g1(27,24)=(-params(5));
  g1(27,25)=(-params(6));
  g1(27,26)=1;
  g1(27,42)=(-1);
  g1(28,21)=(-(params(1)*params(16)));
  g1(28,26)=1;
  g1(28,27)=(-((1-params(1))*params(16)));
  g1(28,39)=(-params(16));
  g1(29,18)=(-(1/(1+params(3)*params(15))*(1-params(13))*(1-params(3)*params(13))/params(13)));
  g1(29,28)=1-1/(1+params(3)*params(15))*(params(3)+params(15));
  g1(29,47)=(-1);
  g1(30,23)=(-(T238*(1-params(3)*params(10))));
  g1(30,27)=(-(T238*(1-params(3)*params(10))*(-params(12))));
  g1(30,28)=(-(T238*(params(3)*params(10)*(T234+T234*params(10)/(1-params(10)))+T234*params(14)*params(10)/(1-params(10))-T260)));
  g1(30,29)=1-T238*(1-params(3)*params(10)+T240+params(3)*T240);
  g1(30,43)=(-(T238*(1-params(3)*params(10))));
  g1(30,48)=(-1);
  g1(31,32)=(-T135);
  g1(32,29)=(-1);
  g1(32,31)=1;
  g1(33,27)=(-1);
  g1(33,30)=1;
  g1(33,32)=1;
  g1(34,35)=1;
  g1(35,28)=(-1);
  g1(35,36)=1;
  g1(36,36)=(-1);
  g1(36,37)=1;
  g1(37,28)=(-1);
  g1(37,33)=1;
  g1(37,36)=(-1);
  g1(37,37)=(-2);
  g1(38,9)=1;
  g1(38,26)=(-1);
  g1(38,38)=1;
  g1(39,40)=1;
  g1(40,39)=1;
  g1(41,41)=1;
  g1(42,42)=1;
  g1(43,43)=1;
  g1(44,44)=1;
  g1(45,45)=1;
  g1(46,46)=1;
  g1(47,47)=1;
  g1(48,48)=1;
  g1(49,8)=(-params(2));
  g1(49,49)=1-(1-params(2));
  g1(50,7)=(-(1-params(4)));
  g1(50,50)=1-params(4);
  g1(51,25)=(-params(2));
  g1(51,51)=1-(1-params(2));
  g1(52,24)=(-(1-params(4)));
  g1(52,52)=1-params(4);
  g1(53,53)=1;
  g1(54,54)=1;
  g1(55,55)=1;
  g1(56,56)=1;
  g1(57,57)=1;
  g1(58,58)=1;
  g1(59,59)=1;
  g1(60,60)=1;
  g1(61,61)=1;
  g1(62,62)=1;
  g1(63,63)=1;
  g1(64,64)=1;
  g1(65,65)=1;
  g1(66,66)=1;
  g1(67,67)=1;
  g1(68,68)=1;
  g1(69,69)=1;
  g1(70,70)=1;
  g1(71,71)=1;
  if ~isreal(g1)
    g1 = real(g1)+2*imag(g1);
  end
if nargout >= 3,
  %
  % Hessian matrix
  %

  g2 = sparse([],[],[],71,5041);
if nargout >= 4,
  %
  % Third order derivatives
  %

  g3 = sparse([],[],[],71,357911);
end
end
end
end
