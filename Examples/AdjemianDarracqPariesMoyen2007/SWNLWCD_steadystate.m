% computes the steady state of ramst.mod analyticaly. 
% [stephane.adjemian@ens.fr 06-21-2006]
function [ys,check] = SWNLRamseyIRest_steadystate(ys,exe)
  global M_ options_ oo_
  
  mu = 0;     % These initializations are needed because mu,beta and alpha are fonctions of a
  beta = 0;   % matlab toolbox!
  alpha = 0;  % 
  
  
  %%$$ DON'T CHANGE THIS PART
  NumberOfParameters = M_.param_nbr;
  for i = 1:NumberOfParameters
    paramname = deblank(M_.param_names(i,:)); 
    eval([ paramname ' = M_.params(' int2str(i) ');']);    
  end
  check = 0;
  %%$$END.
  
  
  MCSS = (1-tauSS)/(mu*(1-subv));
  phi_y= mu*(1-subv);
  RSS = 1/beta - 1;
  R_KSS = 1/beta - (1-tau);
  WSS = (MCSS*R_KSS^(-alpha)*alpha^alpha*(1-alpha)^(1-alpha))^(1/(1-alpha));
  WTILDSS = (WSS^(1/(1-muw)))^(1-muw*(1+sig_l)); 
  KSS = alpha/(1-alpha)*WSS/R_KSS*LSS;
  ISS = tau*KSS;
  YSS = KSS^alpha*LSS^(1-alpha) / phi_y;
  CSS = YSS - ISS - GSS*YSS;
  UCbisSS = (CSS - h*CSS)^(-sig_c);
  UCSS = (1-beta*h)*UCbisSS;
  UCFSS = UCSS;
  ZP1SS = UCSS*MCSS*YSS/(1-beta*xi_p);
  ZP2SS = (1-tauSS)*UCSS*YSS/(1-beta*xi_p);
  L_BAR = (1-tauwSS)*WSS^(sig_l*muw/(1-muw))*UCSS*WTILDSS/(muw*(1-subvw))*(LSS)^(-sig_l);
  ZW1SS = L_BAR*LSS^(1+sig_l)*WSS^(muw*(1+sig_l)/(muw-1))/(1-beta*xi_w);
  ZW2SS = (1-tauwSS)*UCSS*LSS*WSS^(muw/(muw-1))/(1-beta*xi_w);
  ZW1SSF = L_BAR*LSS^(1+sig_l)*WSS^(muw*(1+sig_l)/(muw-1));
  ZW2SSF = (1-tauwSS)*UCSS*LSS*WSS^(muw/(muw-1));
  WELFARESS = ((CSS - h*CSS)^(1-sig_c)/(1-sig_c) - L_BAR*LSS^(1+sig_l)/(1+sig_l))/(1-beta);
  ATCUSS = 1/czcap*R_KSS*(exp(czcap*(TCUSS-1))-1);
  ATCU1SS = R_KSS*exp(czcap*(TCUSS-1));
  ATCU2SS = czcap*R_KSS*exp(czcap*(TCUSS-1));
  
  R=RSS;
  RF=RSS;
TCU = 1 ;
TCUF = 1 ;
ATCU1=R_KSS;
R_K = R_KSS;
R_KF = R_KSS; 
Q = 1 ;
QF = 1 ;
C = CSS ;
CF = CSS ;
K = KSS;
KF = KSS;
I = ISS ;
IF = ISS ;
Y = YSS ;
YF = YSS ;
L = LSS ;
LF = LSS;
PIE = 0 ;
W = WSS ;
WF = WSS ;
UC = UCSS ;
UCF = UCSS;
MC = MCSS;
MCF = MCSS;
UCbis = UCbisSS;
UCbisF = UCbisSS;
Dp = 1;
ZP1 = ZP1SS;
ZP2 = ZP2SS;
Dw = 1 ;
DwF = 1 ;
ZW1 = ZW1SS;
ZW2 = ZW2SS;
ZW1F = ZW1SSF;
ZW2F = ZW2SSF;
AP = 1;
AW = 1;
WELFARE = WELFARESS;
Ropt=RSS;
TCUopt = 1 ;
ATCU1opt=R_KSS;
R_Kopt = R_KSS;
Qopt = 1 ;
Copt = CSS ;
Kopt = KSS;
Iopt = ISS ;
Yopt = YSS ;
Lopt = LSS ;
Loptrule = 1/((1-beta)*(1+sig_l));
Lestim = 1/((1-beta)*(1+sig_l));

PIEopt = 0 ;
Wopt = WSS ;
UCopt = UCSS ;
MCopt = MCSS;
UCbisopt = UCbisSS;
Dpopt = 1;
ZP1opt = ZP1SS;
ZP2opt = ZP2SS;
Dwopt = 1 ;
ZW1opt = ZW1SS;
ZW2opt = ZW2SS;
APopt = 1;
AWopt = 1;
WELFAREopt = WELFARESS;
WELFAREF = WELFARESS;
WELFAREC = WELFARECSS;
EE_A = 0;
EE_B = 0;
EE_G = 0;
EE_L = 0;
EE_I = 0; 
EE_P = 0;
EE_Q = 0;
EE_W = 0;
PIE_BAR = 0;
SI = 0;
SIopt = 0;
SI1 = 0;
SI1opt = 0;
SIF = 0;
SI1F = 0;
ATCU = 0 ;
ATCUopt = 0 ;
ATCUF = 0;
ATCU1 = R_KSS ;
ATCU1opt = R_KSS ;
PIEobs = 0; 
Robs = 0;
Yobs = 0;
Cobs = 0;
Iobs = 0;
Lobs = 0;
RFobs = 0;
YFobs = 0;
CFobs = 0;
IFobs = 0;
LFobs = 0;
PTILD = 1;
PIEobsopt = 0; 
Robsopt = 0;
Yobsopt = 0;
Cobsopt = 0;
Iobsopt = 0;
Lobsopt = 0;
PTILDopt = 1;
psi=0;
wc=0;
psi2=0;
wc2=0;
OGobs=0;
Eobs=0;
Wobs=0;
  PIEWobs=0;
  OGobsopt=0;
Eobsopt=0;
Wobsopt=0;
  PIEWobsopt=0;
  
  
  %% DON'T CHANGE THIS PART
  NumberOfEndogenousVariables = M_.endo_nbr;
  ys = zeros(NumberOfEndogenousVariables,1);
  for i = 1:NumberOfEndogenousVariables
    varname = deblank(M_.endo_names(i,:));
    eval(['ys(' int2str(i) ') = ' varname ';']);
  end
  %%$$END.
  
  
%   ysold = ys;
%   
%   
%   %%
%   %% This part is specific to the Ramsey lagrange multiplier
%   %%
%   
%   ssvar = cell(1);
% 
%   ssvar(1) = {'L1'};
%   ssvar(2) = {'L2'};
%   ssvar(3) = {'L3'};
%   ssvar(4) = {'L4'};
%   ssvar(5) = {'L5'};
%   ssvar(6) = {'L6'};
%   ssvar(7) = {'L7'};
%   ssvar(8) = {'L8'};
%   ssvar(9) = {'L9'};
%   ssvar(10) = {'L10'};
%   ssvar(11) = {'L11'};
%   ssvar(12) = {'L12'};
%   ssvar(13) = {'L13'};
%   ssvar(14) = {'L14'};
%   ssvar(15) = {'L15'};
%   ssvar(16) = {'L16'};
%   ssvar(17) = {'LR'};
% 
%   sseqn = [50:65,67];
%   
%   %% DON'T CHANGE THIS PART
%   nov   = length(ssvar);
%   indv  = zeros(nov,1);
%   for i = 1:nov
%     indv(i) = strmatch(ssvar(i),M_.endo_names,'exact');
%   end
%   x = [oo_.exo_steady_state;oo_.exo_det_steady_state];
%   eval(['[toto,rototo] = ' M_.fname '_static(ys,x);']);
%   sG = rototo(sseqn,indv);  
%   ys(indv) = ys(indv) - pinv(sG)*toto(sseqn);
  %%$$END.