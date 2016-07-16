function [residual, g1, g2, g3] = news_SW03_dynamic(y, x, params, steady_state, it_)
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

residual = zeros(71, 1);
T62 = 1/(1+params(17)*params(3));
T109 = (-params(8))*(1-params(4))/(1-params(4)-params(9));
T113 = params(8)*params(9)/(1-params(4)-params(9));
T164 = (1-params(19))*(1-params(19))/params(19);
T247 = 1/(1+params(3)*params(15));
T266 = params(12)*params(11)/(1-params(11))-1;
T270 = 1/((1+params(3))*params(10)*T266/(1-params(10)));
T272 = params(10)*T266/(1-params(10));
T294 = T266*params(10)/(1-params(10))*params(10)*params(3)*params(14)+T266*params(10)/(1-params(10))+T266*params(14)*params(3)*params(10);
lhs =y(69);
rhs =params(22)*y(9)+(1-params(22))*(params(20)*y(63)+params(23)*y(73))+0.01*y(35);
residual(1)= lhs-rhs;
lhs =y(36);
rhs =params(1)*y(38)+(1-params(1))*y(47)-y(74);
residual(2)= lhs-rhs;
lhs =y(37);
rhs =y(38)*1/params(18);
residual(3)= lhs-rhs;
lhs =y(38);
rhs =y(47)+y(45)-y(39);
residual(4)= lhs-rhs;
lhs =y(39);
rhs =y(37)+y(13);
residual(5)= lhs-rhs;
lhs =y(43);
rhs =T62*(params(17)*y(2)+params(3)*y(110)+1/params(7)*y(40));
residual(6)= lhs-rhs;
lhs =y(40);
rhs =(-y(41))-y(76)+y(109)+(1-params(3)*(1-params(2)))*y(107)+params(3)*(1-params(2))*y(108)+y(79);
residual(7)= lhs-rhs;
lhs =y(41);
rhs =y(109)+y(52)-y(111)-y(76);
residual(8)= lhs-rhs;
lhs =y(41);
rhs =T109*y(42)+T113*y(85);
residual(9)= lhs-rhs;
lhs =y(44);
rhs =y(42)*params(5)+y(43)*params(6)+y(77);
residual(10)= lhs-rhs;
lhs =y(44);
rhs =params(16)*(y(74)+params(1)*y(39)+(1-params(1))*y(45));
residual(11)= lhs-rhs;
residual(12) = y(36);
lhs =y(47);
rhs =(-y(41))-y(78)+y(45)*params(12);
residual(13)= lhs-rhs;
lhs =y(48);
rhs =y(46);
residual(14)= lhs-rhs;
lhs =y(49);
rhs =y(3)+y(112)-y(49)+T164*y(51);
residual(15)= lhs-rhs;
lhs =y(50);
rhs =y(52)-y(111);
residual(16)= lhs-rhs;
lhs =y(51);
rhs =y(45)-y(49);
residual(17)= lhs-rhs;
residual(18) = y(46);
lhs =y(53);
rhs =params(1)*y(55)+(1-params(1))*y(64)-y(74);
residual(19)= lhs-rhs;
lhs =y(54);
rhs =1/params(18)*y(55);
residual(20)= lhs-rhs;
lhs =y(55);
rhs =y(64)+y(62)-y(56);
residual(21)= lhs-rhs;
lhs =y(56);
rhs =y(54)+y(15);
residual(22)= lhs-rhs;
lhs =y(60);
rhs =y(81)+T62*(params(17)*y(5)+params(3)*y(116)+1/params(7)*y(57));
residual(23)= lhs-rhs;
lhs =y(57);
rhs =y(79)+(-y(58))-y(76)+y(115)+(1-params(3)*(1-params(2)))*y(113)+params(3)*(1-params(2))*y(114);
residual(24)= lhs-rhs;
lhs =y(58);
rhs =y(69)+y(115)-y(117)-y(76);
residual(25)= lhs-rhs;
lhs =y(58);
rhs =T109*y(59)+T113*y(87);
residual(26)= lhs-rhs;
lhs =y(61);
rhs =y(77)+params(5)*y(59)+params(6)*y(60);
residual(27)= lhs-rhs;
lhs =y(61);
rhs =params(16)*(y(74)+params(1)*y(56)+(1-params(1))*y(62));
residual(28)= lhs-rhs;
lhs =y(63);
rhs =y(82)+T247*(params(3)*y(117)+y(6)*params(15)+(1-params(13))*(1-params(3)*params(13))/params(13)*y(53));
residual(29)= lhs-rhs;
lhs =y(64);
rhs =T270*(T272*y(7)+params(3)*T272*y(118)+y(6)*T266*params(14)*params(10)/(1-params(10))-y(63)*T294+y(117)*params(3)*params(10)*(T266+T266*params(10)/(1-params(10)))+(1-params(3)*params(10))*(y(78)+y(64)+y(58)-params(12)*y(62)))+y(83);
residual(30)= lhs-rhs;
lhs =y(65);
rhs =y(8)+y(119)-y(65)+T164*y(67)+0.0*(y(12)+params(3)*y(120)-y(74)*(1+params(3)));
residual(31)= lhs-rhs;
lhs =y(66);
rhs =y(64);
residual(32)= lhs-rhs;
lhs =y(67);
rhs =y(62)-y(65);
residual(33)= lhs-rhs;
lhs =y(70);
rhs =y(69)-y(9);
residual(34)= lhs-rhs;
lhs =y(71);
rhs =y(6);
residual(35)= lhs-rhs;
lhs =y(72);
rhs =y(10);
residual(36)= lhs-rhs;
lhs =y(68);
rhs =y(72)+y(63)+y(71)+y(11);
residual(37)= lhs-rhs;
lhs =y(73);
rhs =y(61)-y(44);
residual(38)= lhs-rhs;
residual(39) = y(75);
residual(40) = y(74);
residual(41) = y(76);
residual(42) = y(77);
residual(43) = y(78);
residual(44) = y(79);
residual(45) = y(80);
residual(46) = y(81);
residual(47) = y(82);
residual(48) = y(83);
lhs =y(84);
rhs =y(13)*(1-params(2))+y(2)*params(2);
residual(49)= lhs-rhs;
lhs =y(85);
rhs =params(4)*y(14)+(1-params(4))*y(1);
residual(50)= lhs-rhs;
lhs =y(86);
rhs =(1-params(2))*y(15)+params(2)*y(5);
residual(51)= lhs-rhs;
lhs =y(87);
rhs =params(4)*y(16)+(1-params(4))*y(4);
residual(52)= lhs-rhs;
lhs =y(88);
rhs =x(it_, 1);
residual(53)= lhs-rhs;
lhs =y(89);
rhs =y(17);
residual(54)= lhs-rhs;
lhs =y(90);
rhs =y(18);
residual(55)= lhs-rhs;
lhs =y(91);
rhs =y(19);
residual(56)= lhs-rhs;
lhs =y(92);
rhs =y(20);
residual(57)= lhs-rhs;
lhs =y(93);
rhs =y(21);
residual(58)= lhs-rhs;
lhs =y(94);
rhs =y(22);
residual(59)= lhs-rhs;
lhs =y(95);
rhs =y(23);
residual(60)= lhs-rhs;
lhs =y(96);
rhs =y(24);
residual(61)= lhs-rhs;
lhs =y(97);
rhs =y(25);
residual(62)= lhs-rhs;
lhs =y(98);
rhs =y(26);
residual(63)= lhs-rhs;
lhs =y(99);
rhs =y(27);
residual(64)= lhs-rhs;
lhs =y(100);
rhs =y(28);
residual(65)= lhs-rhs;
lhs =y(101);
rhs =y(29);
residual(66)= lhs-rhs;
lhs =y(102);
rhs =y(30);
residual(67)= lhs-rhs;
lhs =y(103);
rhs =y(31);
residual(68)= lhs-rhs;
lhs =y(104);
rhs =y(32);
residual(69)= lhs-rhs;
lhs =y(105);
rhs =y(33);
residual(70)= lhs-rhs;
lhs =y(106);
rhs =y(34);
residual(71)= lhs-rhs;
if nargout >= 2,
  g1 = zeros(71, 121);

  %
  % Jacobian matrix
  %

T3 = (-1);
  g1(1,63)=(-((1-params(22))*params(20)));
  g1(1,9)=(-params(22));
  g1(1,69)=1;
  g1(1,73)=(-((1-params(22))*params(23)));
  g1(1,35)=(-0.01);
  g1(2,36)=1;
  g1(2,38)=(-params(1));
  g1(2,47)=(-(1-params(1)));
  g1(2,74)=1;
  g1(3,37)=1;
  g1(3,38)=(-(1/params(18)));
  g1(4,38)=1;
  g1(4,39)=1;
  g1(4,45)=T3;
  g1(4,47)=T3;
  g1(5,37)=T3;
  g1(5,39)=1;
  g1(5,13)=T3;
  g1(6,40)=(-(T62*1/params(7)));
  g1(6,2)=(-(params(17)*T62));
  g1(6,43)=1;
  g1(6,110)=(-(params(3)*T62));
  g1(7,107)=(-(1-params(3)*(1-params(2))));
  g1(7,40)=1;
  g1(7,108)=(-(params(3)*(1-params(2))));
  g1(7,41)=1;
  g1(7,109)=T3;
  g1(7,76)=1;
  g1(7,79)=T3;
  g1(8,41)=1;
  g1(8,109)=T3;
  g1(8,111)=1;
  g1(8,52)=T3;
  g1(8,76)=1;
  g1(9,41)=1;
  g1(9,42)=(-T109);
  g1(9,85)=(-T113);
  g1(10,42)=(-params(5));
  g1(10,43)=(-params(6));
  g1(10,44)=1;
  g1(10,77)=T3;
  g1(11,39)=(-(params(1)*params(16)));
  g1(11,44)=1;
  g1(11,45)=(-((1-params(1))*params(16)));
  g1(11,74)=(-params(16));
  g1(12,36)=1;
  g1(13,41)=1;
  g1(13,45)=(-params(12));
  g1(13,47)=1;
  g1(13,78)=1;
  g1(14,46)=T3;
  g1(14,48)=1;
  g1(15,3)=T3;
  g1(15,49)=2;
  g1(15,112)=T3;
  g1(15,51)=(-T164);
  g1(16,111)=1;
  g1(16,50)=1;
  g1(16,52)=T3;
  g1(17,45)=T3;
  g1(17,49)=1;
  g1(17,51)=1;
  g1(18,46)=1;
  g1(19,53)=1;
  g1(19,55)=(-params(1));
  g1(19,64)=(-(1-params(1)));
  g1(19,74)=1;
  g1(20,54)=1;
  g1(20,55)=(-(1/params(18)));
  g1(21,55)=1;
  g1(21,56)=1;
  g1(21,62)=T3;
  g1(21,64)=T3;
  g1(22,54)=T3;
  g1(22,56)=1;
  g1(22,15)=T3;
  g1(23,57)=(-(T62*1/params(7)));
  g1(23,5)=(-(params(17)*T62));
  g1(23,60)=1;
  g1(23,116)=(-(params(3)*T62));
  g1(23,81)=T3;
  g1(24,113)=(-(1-params(3)*(1-params(2))));
  g1(24,57)=1;
  g1(24,114)=(-(params(3)*(1-params(2))));
  g1(24,58)=1;
  g1(24,115)=T3;
  g1(24,76)=1;
  g1(24,79)=T3;
  g1(25,58)=1;
  g1(25,115)=T3;
  g1(25,117)=1;
  g1(25,69)=T3;
  g1(25,76)=1;
  g1(26,58)=1;
  g1(26,59)=(-T109);
  g1(26,87)=(-T113);
  g1(27,59)=(-params(5));
  g1(27,60)=(-params(6));
  g1(27,61)=1;
  g1(27,77)=T3;
  g1(28,56)=(-(params(1)*params(16)));
  g1(28,61)=1;
  g1(28,62)=(-((1-params(1))*params(16)));
  g1(28,74)=(-params(16));
  g1(29,53)=(-((1-params(13))*(1-params(3)*params(13))/params(13)*T247));
  g1(29,6)=(-(params(15)*T247));
  g1(29,63)=1;
  g1(29,117)=(-(params(3)*T247));
  g1(29,82)=T3;
  g1(30,58)=(-(T270*(1-params(3)*params(10))));
  g1(30,62)=(-(T270*(1-params(3)*params(10))*(-params(12))));
  g1(30,6)=(-(T270*T266*params(14)*params(10)/(1-params(10))));
  g1(30,63)=(-(T270*(-T294)));
  g1(30,117)=(-(T270*params(3)*params(10)*(T266+T266*params(10)/(1-params(10)))));
  g1(30,7)=(-(T270*T272));
  g1(30,64)=1-T270*(1-params(3)*params(10));
  g1(30,118)=(-(T270*params(3)*T272));
  g1(30,78)=(-(T270*(1-params(3)*params(10))));
  g1(30,83)=T3;
  g1(31,8)=T3;
  g1(31,65)=2;
  g1(31,119)=T3;
  g1(31,67)=(-T164);
  g1(31,12)=(-0.0);
  g1(31,74)=(-(0.0*(-(1+params(3)))));
  g1(31,120)=(-(params(3)*0.0));
  g1(32,64)=T3;
  g1(32,66)=1;
  g1(33,62)=T3;
  g1(33,65)=1;
  g1(33,67)=1;
  g1(34,9)=1;
  g1(34,69)=T3;
  g1(34,70)=1;
  g1(35,6)=T3;
  g1(35,71)=1;
  g1(36,10)=T3;
  g1(36,72)=1;
  g1(37,63)=T3;
  g1(37,68)=1;
  g1(37,71)=T3;
  g1(37,11)=T3;
  g1(37,72)=T3;
  g1(38,44)=1;
  g1(38,61)=T3;
  g1(38,73)=1;
  g1(39,75)=1;
  g1(40,74)=1;
  g1(41,76)=1;
  g1(42,77)=1;
  g1(43,78)=1;
  g1(44,79)=1;
  g1(45,80)=1;
  g1(46,81)=1;
  g1(47,82)=1;
  g1(48,83)=1;
  g1(49,2)=(-params(2));
  g1(49,13)=(-(1-params(2)));
  g1(49,84)=1;
  g1(50,1)=(-(1-params(4)));
  g1(50,14)=(-params(4));
  g1(50,85)=1;
  g1(51,5)=(-params(2));
  g1(51,15)=(-(1-params(2)));
  g1(51,86)=1;
  g1(52,4)=(-(1-params(4)));
  g1(52,16)=(-params(4));
  g1(52,87)=1;
  g1(53,121)=T3;
  g1(53,88)=1;
  g1(54,17)=T3;
  g1(54,89)=1;
  g1(55,18)=T3;
  g1(55,90)=1;
  g1(56,19)=T3;
  g1(56,91)=1;
  g1(57,20)=T3;
  g1(57,92)=1;
  g1(58,21)=T3;
  g1(58,93)=1;
  g1(59,22)=T3;
  g1(59,94)=1;
  g1(60,23)=T3;
  g1(60,95)=1;
  g1(61,24)=T3;
  g1(61,96)=1;
  g1(62,25)=T3;
  g1(62,97)=1;
  g1(63,26)=T3;
  g1(63,98)=1;
  g1(64,27)=T3;
  g1(64,99)=1;
  g1(65,28)=T3;
  g1(65,100)=1;
  g1(66,29)=T3;
  g1(66,101)=1;
  g1(67,30)=T3;
  g1(67,102)=1;
  g1(68,31)=T3;
  g1(68,103)=1;
  g1(69,32)=T3;
  g1(69,104)=1;
  g1(70,33)=T3;
  g1(70,105)=1;
  g1(71,34)=T3;
  g1(71,106)=1;

if nargout >= 3,
  %
  % Hessian matrix
  %

  g2 = sparse([],[],[],71,14641);
if nargout >= 4,
  %
  % Third order derivatives
  %

  g3 = sparse([],[],[],71,1771561);
end
end
end
end
