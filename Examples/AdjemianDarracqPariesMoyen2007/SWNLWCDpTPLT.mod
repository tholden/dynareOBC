// Derived from code kindly provided by Stephane Moyen.
// Original header comment follows.

//*************************************************************
// Optimal Monetary Policy in a DSGE Model of the Euro Area
// Welfare cost distrirutions opt rules vs estimated rule
//
// Moyen S. and Darracq-Paries M.
//
// May 16, 2006
//*************************************************************

var
    WELFARE_CE
    TCU Q C K I L PIE W  PTILD
    UC R
    Dp ZP1 ZP2 Dw ZW1 ZW2
    WELFARE
    WELFAREF
    WELFAREC
    Y MC R_K
    SI SI1
    ATCU ATCU1
    AP
    AW
    UCbis
    EE_A EE_B EE_G EE_L EE_I EE_Q PIE_BAR EE_P EE_W
    UCbisF UCF MCF R_KF WF QF IF TCUF KF LF YF CF RF ZW1F ZW2F DwF SIF SI1F ATCUF
    PIEobs Robs Yobs Cobs Iobs Lobs
    RFobs YFobs CFobs IFobs LFobs
    OGobs Eobs Wobs PIEWobs
    RR YY CC PIPI LL
    ;
var PP;

varexo
    E_A E_B E_G E_L E_I E_P E_Q E_W
    E_R
    ;

parameters
    alpha czcap beta phi_i tau sig_c h phi_y gamma_w xi_w gamma_p xi_p
    sig_l r_dpi r_pie r_dy r_y rho rho_a rho_b rho_g rho_l rho_i
    xie mu muw Abar subv subvw
    LSS RSS R_KSS WSS KSS ISS YSS GSS CSS ZP1SS ZP2SS MCSS ZW1SS ZW2SS ZW1SSF ZW2SSF
    UCSS UCFSS L_BAR WELFARESS  TCUSS ATCUSS
    ATCU1SS UCbisSS tauwSS tauSS WTILDSS WELFARECSS
    size;

// Estimated parameters
rho_a	=	0.9942	;
rho_b	=	0.8738	;
rho_g	=	0.9720	;
rho_l	=	0.9696	;
rho_i	=	0.9500	;
phi_i	=	4.7522	;
sig_c	=	1.9614	;
h	    =	0.4209	;
xi_w	=	0.7496	;
sig_l	=	1.5027	;
xi_p	=	0.9089	;
xie  	=	0.8436	;
gamma_w	=	0.2512	;
gamma_p	=	0.2196	;
czcap	=	0.7807	;
r_pie	=	1.5657  ;
r_dpi	=	0.2021  ;
rho	    =	0.8794  ;
r_y	    =	0.0970  ;
r_dy	=	0.2030  ;

// Steady state tax rates

tauSS = 0.0;
tauwSS = 0.0;

// Steady state markups
mu = 1.3*(1-tauSS);
muw = 1.5*(1-tauwSS) ;

// If we want to cancel the mean effect in the welfare we have to set:
//subv = 1-1/mu*(1-tauSS) ;
//subvw = 1-1/ muw*(1-tauwSS);
//else
subv = 0;
subvw = 0;

Abar = 1;
size = 1;
alpha=.3;
beta=.99;
tau=0.025;
GSS = 0.18;
TCUSS = 1;
LSS = 1;
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
UCbisSS = size*(CSS - h*CSS)^(-sig_c);
UCSS = (1-beta*h)*UCbisSS;
UCFSS = UCSS;
ZP1SS = UCSS*MCSS*YSS/(1-beta*xi_p);
ZP2SS = (1-tauSS)*UCSS*YSS/(1-beta*xi_p);
L_BAR = (1-tauwSS)*WSS^(sig_l*muw/(1-muw))*UCSS*WTILDSS/(muw*(1-subvw))*(LSS)^(-sig_l)/size;
ZW1SS = size*L_BAR*LSS^(1+sig_l)*WSS^(muw*(1+sig_l)/(muw-1))/(1-beta*xi_w);
ZW2SS = (1-tauwSS)*UCSS*LSS*WSS^(muw/(muw-1))/(1-beta*xi_w);
ZW1SSF = size*L_BAR*LSS^(1+sig_l)*WSS^(muw*(1+sig_l)/(muw-1));
ZW2SSF = (1-tauwSS)*UCSS*LSS*WSS^(muw/(muw-1));
WELFARESS = (size*(CSS - h*CSS)^(1-sig_c)/(1-sig_c) - size*L_BAR*LSS^(1+sig_l)/(1+sig_l))/(1-beta);
ATCUSS = 1/czcap*R_KSS*(exp(czcap*(TCUSS-1))-1);
ATCU1SS = R_KSS*exp(czcap*(TCUSS-1));
WELFARECSS = size*((CSS - h*CSS)^(1-sig_c)/(1-sig_c)) /(1- beta);

model;

    WELFARE = exp(EE_B)*size*((C - h*C(-1))^(1-sig_c)/(1-sig_c)
                            - L_BAR*exp(-EE_L)*Dw*(L)^(1+sig_l)/(1+sig_l) )+ beta * WELFARE(1) ;

    WELFAREC = exp(EE_B)*size*(C - h*C(-1))^(1-sig_c)/(1-sig_c) + beta * WELFAREC(1) ;


    WELFAREF = exp(EE_B)*size*((CF - h*CF(-1))^(1-sig_c)/(1-sig_c)
                            - L_BAR*exp(-EE_L)*DwF*(LF)^(1+sig_l)/(1+sig_l)) + beta * WELFAREF(1) ;

    /////////////////////////////////////////// Flexible price ///////////////////////////////////////////////////
    
              ATCUF = 1/czcap*R_KSS*(exp(czcap*(TCUF-1))-1);
              SIF = phi_i/2*(IF/IF(-1)-1)^2;
              SI1F = phi_i*(IF/IF(-1)-1);
              R_KF = R_KSS*exp(czcap*(TCUF-1));
              MCF = (R_KF)^alpha*WF^(1-alpha)/(alpha^alpha*(1-alpha)^(1-alpha))*exp(-EE_A);
              UCF = UCF(1)*beta*(1+RF);
              UCbisF = exp(EE_B)*size*(CF - h*CF(-1))^(-sig_c);
              UCF = UCbisF - beta*h*UCbisF(1);
              QF*(1 - SIF - IF/IF(-1)*SI1F)*exp(EE_I) + beta*QF(1)*UCF(1)/UCF*SI1F(1)*(IF(1)/IF)^2*exp(EE_I(1)) = 1;
              //QF = exp(0*EE_Q)* beta*UCF(1)/UCF*(QF(1)*(1-tau) + TCUF(1)*R_KF(1) - ATCUF(1));
              QF = exp(EE_Q)* beta*UCF(1)/UCF*(QF(1)*(1-tau) + TCUF(1)*R_KF(1) - ATCUF(1));
              KF = (1-tau)*KF(-1)+(1 - phi_i/2*(IF/IF(-1)-1)^2)*IF*exp(EE_I) ;
              LF*WF=(1-alpha)/alpha *(R_KF*TCUF*KF(-1));
              (1-tauSS)*exp(0*EE_P)/(mu*(1-subv)) = MCF;
              // (1-tauSS)*exp(EE_P)/(mu*(1-subv)) = MCF;
              YF = CF + IF + GSS*YSS*exp(EE_G) + ATCUF*KF(-1);
              YF = Abar*(TCUF*KF(-1))^alpha*LF^(1-alpha)*exp(EE_A) - (phi_y-1)*YSS ;
              (muw*(1-subvw)*ZW1F/ZW2F)^(-1/(muw*(1+sig_l)-1)) = WF^(1/(1-muw));
              ZW1F = exp(EE_B)*L_BAR*exp(-EE_L)*LF^(1+sig_l)*WF^((1+sig_l)*muw/(muw-1));
              ZW2F = (1-tauwSS)*exp(0*EE_W)*UCF*LF*WF^(muw/(muw-1));
              // ZW2F = (1-tauwSS)*exp(EE_W)*UCF*LF*WF^(muw/(muw-1));
              DwF = WF^((1+sig_l)*muw/(muw-1))*(muw*(1-subvw)*ZW1F/ZW2F)^(-muw*(1+sig_l)/(muw*(1+sig_l)-1));

    // Adjunct variables

    UCbis = exp(EE_B)*size*(C - h*C(-1))^(-sig_c);

    ATCU = 1/czcap*R_KSS*(exp(czcap*(TCU-1))-1);

    ATCU1 = R_KSS*exp(czcap*(TCU-1));

    SI = phi_i/2*(I/I(-1)-1)^2;

    SI1 = phi_i*(I/I(-1)-1);

    AP = (1+PIE)*(1+PIE(-1))^(-gamma_p) * (1+0*PIE_BAR)^(gamma_p-1);

    AW = (1+PIE)*(1+PIE(-1))^(-gamma_w) * (1+0*PIE_BAR)^(gamma_w-1);

    MC = (ATCU1)^alpha*W^(1-alpha)/(alpha^alpha*(1-alpha)^(1-alpha))*exp(-EE_A);

    Y = C + I + GSS*YSS*exp(EE_G) + ATCU*K(-1);

    R_K = ATCU1;

    // Equilibrium conditions

    (1+PIE(1))*UC= UC(1)*beta*(1+R);                                                                      //EQ R

    UC = UCbis - beta*h*UCbis(1);                                                                       //EQ 1

    Q = exp(EE_Q)* beta*UC(1)/UC*(Q(1)*(1-tau) + TCU(1)*ATCU1(1) - ATCU(1) + 0*EE_Q);                            // EQ 2

    Q*(1 - SI - I/I(-1)*SI1)*exp(EE_I) + beta*Q(1)*UC(1)/UC*SI1(1)*(I(1)/I)^2*exp(EE_I(1)) = 1;         // EQ 3

    K =  (1-tau)*K(-1)+(1 - SI)*I*exp(EE_I);                                                            // EQ 4

    L*W=(1-alpha)/alpha*(ATCU1*TCU*K(-1));                                                              // EQ 5

    Dp = (1-xi_p)*(PTILD)^(-mu/(mu-1)) + xi_p*Dp(-1)*AP^(mu/(mu-1));                                    // EQ 6

    PTILD =  mu*(1-subv)*ZP1/ZP2;                                                                        // EQ 7

    PTILD^(1/(1-mu))*(1 - xi_p) = 1 - xi_p *AP^(1/(mu-1));                                              // EQ 8

    ZP1 = UC*MC*Y + beta*xi_p * AP(1)^(mu/(mu-1))*ZP1(1);                                               // EQ 9

    ZP2 = (1-tauSS)*exp(EE_P)*UC*Y + beta*xi_p * AP(1)^(1/(mu-1))*ZP2(1);                   // EQ 10                                      // EQ 10

    (1-xi_w)*(muw*(1-subvw)*ZW1/ZW2)^(-1/(muw*(1+sig_l)-1)) = W^(1/(1-muw)) - xi_w*W(-1)^(1/(1-muw))*AW^(-1/(1-muw));   // EQ 11

    ZW1 = exp(EE_B)*exp(-EE_L)*size*L_BAR*L^(1+sig_l)*W^((1+sig_l)*muw/(muw-1))
          + beta*xi_w*AW(1)^((1+sig_l)*muw/(muw-1))*ZW1(1);                                             // EQ 12

    ZW2 = (1-tauwSS)*exp(EE_W)*UC*L*W^(muw/(muw-1)) + beta*xi_w * AW(1)^(1/(muw-1))*ZW2(1) ;   // EQ 13                       // EQ 13

    // WTILD = muw*(1-subvw)*ZW1/ZW2;                                                                      //EQ 14

    Dw = (1-xi_w)*W^((1+sig_l)*muw/(muw-1))* (muw*(1-subvw)*ZW1/ZW2)^(-muw*(1+sig_l)/(muw*(1+sig_l)-1))
           + xi_w*Dw(-1)*(W/W(-1))^((1+sig_l)*muw/(muw-1))*AW^((1+sig_l)*muw/(muw-1)) ;                 // EQ 15


    Dp*Y = Abar*(TCU*K(-1))^alpha*L^(1-alpha)*exp(EE_A) - (phi_y-1)*YSS ;                               // EQ 16

    PIEWobs = PIEobs + Wobs - Wobs(-1) ;
    PIEobs = 100*PIE;
    Robs = 100*((1+R)/(1+RSS)-1);
    Yobs = 100*log(Y/YSS);
    Cobs = 100*log(C/CSS);
    Iobs = 100*log(I/ISS);
    Lobs = 100*log(L/LSS);
    Wobs = 100*log(W/WSS);
    OGobs = Yobs-YFobs;

    RFobs = 100*((1+RF)/(1+RSS)-1);
    YFobs = 100*log(YF/YSS);
    CFobs = 100*log(CF/CSS);
    IFobs = 100*log(IF/ISS);
    LFobs = 100*log(LF/LSS);
    Eobs = 0.5*Eobs(-1) + 0.5*Eobs(1) + (1-xie)*(1-beta*xie)/(xie)*(Lobs - Eobs);

    // Monetary policy

    PP = PP(-1) + PIPI;

    // The exact value of the ZLB doesn't matter for the sake of existence calculations.
    // Here we take the mean value from the Fagan Henry and Mestre 2001 dataset, over the data period used by Smets Wouters (2003).
    Robs = max( -log( 1.021605136 ) * 100, PIE_BAR + r_dpi*((PIEobs- PIE_BAR)-(PIEobs(-1)- PIE_BAR(-1)))
                  +(1-rho)*( r_pie*(PIEobs(-1) - PIE_BAR(-1))+r_y*(Yobs(-1) - 0*YFobs(-1)))
                  +r_dy*(Yobs - 0*YFobs -(Yobs(-1) - 0*YFobs(-1)))
                  +rho*(Robs(-1)-PIE_BAR(-1))
                  +E_R + 1 * min( -1e-8, 100 * PP ) );
                  
    // shocks

    PIE_BAR = 0 ;// E_PIE_BAR/100
    EE_A = rho_a*EE_A(-1) + E_A/100;
    EE_B = rho_b*EE_B(-1) - E_B/100 ;
    EE_G = rho_g*EE_G(-1) + E_G/100 ;
    EE_L = rho_l*EE_L(-1) + E_L/100 ;
    EE_I = rho_i*EE_I(-1) + E_I/100 ;
    EE_P = 0*EE_P(-1) + E_P/100/(((1-xi_p)*(1-beta*xi_p)/(xi_p))) ;
    EE_Q = 0*EE_Q(-1) + E_Q/100 ;
    EE_W = 0*EE_W(-1) + E_W/100/((1/(1+beta))*(((1-beta*xi_w)*(1-xi_w))/(((1+((muw*sig_l)/(muw-1))))*xi_w))) ;

    // Welfare cost: we take the flexible price equilibrium as the reference policy

    WELFARE_CE = log( ((WELFARE+L_BAR*LF)/(WELFAREF+L_BAR*LF))^(1/(1-sig_c)) );
    RR = log( 1 + ( Robs + log( 1.021605136 ) * 100 ) / 100 );
    YY = log( Y / YSS );
    CC = log( C / CSS );
    PIPI = log( 1 + PIE );
    LL = log( L / LSS );

end;

steady_state_model;

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
    SI1 = 0;
    SIF = 0;
    SI1F = 0;
    ATCU = 0 ;
    ATCUF = 0;
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
    OGobs=0;
    Eobs=0;
    Wobs=0;
    PIEWobs=0;
    
    WELFARE_CE = 0;
    RR = log( 1 + ( Robs + log( 1.021605136 ) * 100 ) / 100 );
    YY = 0;
    CC = 0;
    PIPI = 0;
    LL = 0;

    PP = 0;

end;

shocks;

    // Efficient shocks
    var E_A;
    stderr 0.5640;
    var E_B;
    stderr 2.1191;
    var E_G;
    stderr 1.8379;
    var E_L;
    stderr 3.7088;
    var E_I;
    stderr 1.0029;

    // Originally inefficient shocks, but made efficient in this version.

    var E_Q;
    stderr 6.3809;

    // Inefficient shocks

    var E_P;
    stderr 0.2826;
    var E_W;
    stderr 0.1949;

    //Monetary Policy shocks

    //var E_PIE_BAR;
    //stderr  0.0;
    var E_R;
    stderr 0.1830;

end;

stoch_simul( order=1, irf = 40, periods = 0, irf_shocks = ( E_B ) ) YY CC WELFARE_CE PP PIPI RR;
