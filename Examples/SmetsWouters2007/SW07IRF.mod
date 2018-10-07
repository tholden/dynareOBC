// Derived from files provided here: http://www.dynare.org/phpBB3/viewtopic.php?f=1&t=3750

// copy van usmodel_hist_dsge_f19_7_71

var   labobs robs pinfobs dy dc dinve dw  ewma epinfma  zcapf rkf kf pkf    cf invef yf labf wf rrf mc zcap rk k pk    c inve y lab pinf w r a  b g qs  ms  spinf sw kpf kp ;    

var y_obs c_obs pi_obs r_obs;

@#define IndividualShocks = 0

@#if IndividualShocks
varexo ea eb eg  eqs  em  epinf ew  ;  
@#else
varexo epsilon;
@#endif
 
parameters curvw cgy curvp constelab constepinf constebeta cmaw cmap calfa 
czcap csadjcost ctou csigma chabb cfc 
cindw cprobw cindp cprobp csigl clandaw 
crpi crdy cry crr 
crhoa crhoas crhob crhog crhols crhoqs crhoms crhopinf crhow  
ctrend cg;

curvw = 10;
cgy = 0.5261212194708431;
curvp = 10;
constelab = -0.1030651669858076;
constepinf = 0.8179822205381722;
constebeta = 0.1606541147132154;
cmaw = 0.8881459266182488;
cmap = 0.7448718466831306;
calfa = 0.1928004564181553;
czcap = 0.5472131292389921;
csadjcost = 5.488197009060616;
ctou = 0.025;
csigma = 1.395192897951439;
chabb = 0.7124006351787524;
cfc = 1.614979587976331;
cindw = 0.5919983094973862;
cprobw = 0.737541323772002;
cindp = 0.2283540191153491;
cprobp = 0.6562662602975502;
csigl = 1.9198838416864;
clandaw = 1.5;
crpi = 2.029467403441132;
crdy = 0.2229257080639476;
cry = 0.08468690532858184;
crr = 0.8153248720213849;
crhoa = 0.9587740953362461;
crhoas = 1;
crhob = 0.1824393451255601;
crhog = 0.9761614150464989;
crhols = 0.9928;
crhoqs = 0.7095693238736019;
crhoms = 0.1271314763130675;
crhopinf = 0.9038073405580113;
crhow = 0.9718537740244471;
ctrend = 0.432026374810516;
cg = 0.18;

model; 

    //include "usmodel_stst.mod"

        #cpie=1+constepinf/100;
        #cgamma=1+ctrend/100 ;
        #cbeta=1/(1+constebeta/100);

        #clandap=cfc;
        #cbetabar=cbeta*cgamma^(-csigma);
        #cr=cpie/(cbeta*cgamma^(-csigma));
        #crk=(cbeta^(-1))*(cgamma^csigma) - (1-ctou);
        #cw = (calfa^calfa*(1-calfa)^(1-calfa)/(clandap*crk^calfa))^(1/(1-calfa));
        //cw = (calfa^calfa*(1-calfa)^(1-calfa)/(clandap*((cbeta^(-1))*(cgamma^csigma) - (1-ctou))^calfa))^(1/(1-calfa));
        #cikbar=(1-(1-ctou)/cgamma);
        #cik=(1-(1-ctou)/cgamma)*cgamma;
        #clk=((1-calfa)/calfa)*(crk/cw);
        #cky=cfc*(clk)^(calfa-1);
        #ciy=cik*cky;
        #ccy=1-cg-cik*cky;
        #crkky=crk*cky;
        #cwhlc=(1/clandaw)*(1-calfa)/calfa*crk*cky/ccy;
        #cwly=1-crk*cky;

        #conster=(cr-1)*100;

    // flexible economy

        0*(1-calfa)*a + 1*a =  calfa*rkf+(1-calfa)*(wf)  ;
        zcapf =  (1/(czcap/(1-czcap)))* rkf  ;
        rkf =  (wf)+labf-kf ;
        kf =  kpf(-1)+zcapf ;
        invef = (1/(1+cbetabar*cgamma))* (  invef(-1) + cbetabar*cgamma*invef(1)+(1/(cgamma^2*csadjcost))*pkf ) +qs ;
        pkf = -rrf-0*b+(1/((1-chabb/cgamma)/(csigma*(1+chabb/cgamma))))*b +(crk/(crk+(1-ctou)))*rkf(1) +  ((1-ctou)/(crk+(1-ctou)))*pkf(1) ;
        cf = (chabb/cgamma)/(1+chabb/cgamma)*cf(-1) + (1/(1+chabb/cgamma))*cf(+1) +((csigma-1)*cwhlc/(csigma*(1+chabb/cgamma)))*(labf-labf(+1)) - (1-chabb/cgamma)/(csigma*(1+chabb/cgamma))*(rrf+0*b) + b ;
        yf = ccy*cf+ciy*invef+g  +  crkky*zcapf ;
        yf = cfc*( calfa*kf+(1-calfa)*labf +a );
        wf = csigl*labf   +(1/(1-chabb/cgamma))*cf - (chabb/cgamma)/(1-chabb/cgamma)*cf(-1) ;
        kpf =  (1-cikbar)*kpf(-1)+(cikbar)*invef + (cikbar)*(cgamma^2*csadjcost)*qs ;

    // sticky price - wage economy

        mc =  calfa*rk+(1-calfa)*(w) - 1*a - 0*(1-calfa)*a ;
        zcap =  (1/(czcap/(1-czcap)))* rk ;
        rk =  w+lab-k ;
        k =  kp(-1)+zcap ;
        inve = (1/(1+cbetabar*cgamma))* (  inve(-1) + cbetabar*cgamma*inve(1)+(1/(cgamma^2*csadjcost))*pk ) +qs ;
        pk = -r+pinf(1)-0*b +(1/((1-chabb/cgamma)/(csigma*(1+chabb/cgamma))))*b + (crk/(crk+(1-ctou)))*rk(1) +  ((1-ctou)/(crk+(1-ctou)))*pk(1) ;
        c = (chabb/cgamma)/(1+chabb/cgamma)*c(-1) + (1/(1+chabb/cgamma))*c(+1) +((csigma-1)*cwhlc/(csigma*(1+chabb/cgamma)))*(lab-lab(+1)) - (1-chabb/cgamma)/(csigma*(1+chabb/cgamma))*(r-pinf(+1) + 0*b) +b ;
        y = ccy*c+ciy*inve+g  +  1*crkky*zcap ;
        y = cfc*( calfa*k+(1-calfa)*lab +a );
        pinf =  (1/(1+cbetabar*cgamma*cindp)) * ( cbetabar*cgamma*pinf(1) +cindp*pinf(-1) 
           +((1-cprobp)*(1-cbetabar*cgamma*cprobp)/cprobp)/((cfc-1)*curvp+1)*(mc)  )  + spinf ; 
        w =  (1/(1+cbetabar*cgamma))*w(-1)
           +(cbetabar*cgamma/(1+cbetabar*cgamma))*w(1)
           +(cindw/(1+cbetabar*cgamma))*pinf(-1)
           -(1+cbetabar*cgamma*cindw)/(1+cbetabar*cgamma)*pinf
           +(cbetabar*cgamma)/(1+cbetabar*cgamma)*pinf(1)
           +(1-cprobw)*(1-cbetabar*cgamma*cprobw)/((1+cbetabar*cgamma)*cprobw)*(1/((clandaw-1)*curvw+1))*
           (csigl*lab + (1/(1-chabb/cgamma))*c - ((chabb/cgamma)/(1-chabb/cgamma))*c(-1) -w) 
           + 1*sw ;
        r =  max( -conster, crpi*(1-crr)*pinf
           +cry*(1-crr)*(y-yf)     
           +crdy*(y-yf-y(-1)+yf(-1))
           +crr*r(-1)
           +ms  );

    @#if !IndividualShocks
        #ea    = 0.451788281662122 * 3.55515886805135 * epsilon;
        #eb    = 0.242460701013770 * 2.70266536991112 * epsilon;
        #eg    = 0.520010319208288 * 1.63122368058574 * epsilon;
        #eqs   = 0.450106906080831 * 4.43054037338488 * epsilon;
        #em    = 0.239839325484002 * 2.81419385410711 * epsilon;
        #epinf = 0.141123850778673 * 3.18699420535093 * epsilon;
        #ew    = 0.244391601233500 * 4.14331499076251 * epsilon;
    @#endif

        a = crhoa*a(-1)  + ea;
        b = crhob*b(-1) - eb;
        g = crhog*(g(-1)) - eg + cgy*ea;
        qs = crhoqs*qs(-1) - eqs;
        ms = crhoms*ms(-1) - em;
        spinf = crhopinf*spinf(-1) + epinfma - cmap*epinfma(-1);
          epinfma=-epinf;
        sw = crhow*sw(-1) + ewma - cmaw*ewma(-1) ;
          ewma=-ew; 
        kp =  (1-cikbar)*kp(-1)+cikbar*inve + cikbar*cgamma^2*csadjcost*qs ;

    // measurment equations

        dy=y-y(-1)+ctrend;
        dc=c-c(-1)+ctrend;
        dinve=inve-inve(-1)+ctrend;
        dw=w-w(-1)+ctrend;
        pinfobs = 1*(pinf) + constepinf;
        robs =    1*(r) + conster;
        labobs = lab + constelab;

        y_obs = y / 100;
        c_obs = c / 100;
        pi_obs = pinfobs / 100;
        r_obs = robs / 100;

end; 

shocks;
    @#if IndividualShocks
        var ea;
        stderr 0.451788281662122;
        var eb;
        stderr 0.242460701013770;
        var eg;
        stderr 0.520010319208288;
        var eqs;
        stderr 0.450106906080831;
        var em;
        stderr 0.239839325484002;
        var epinf;
        stderr 0.141123850778673;
        var ew;
        stderr 0.244391601233500;
    @#else
        var epsilon = 1;
    @#endif
end;

steady_state_model;
    labobs = -0.1030651669858076;
    robs = 1.589136485993303;
    pinfobs = 0.8179822205381722;
    dy = 0.432026374810516;
    dc = 0.432026374810516;
    dinve = 0.432026374810516;
    dw = 0.432026374810516;
    ewma = 0;
    epinfma = 0;
    zcapf = 0;
    rkf = 0;
    kf = 0;
    pkf = 0;
    cf = 0;
    invef = 0;
    yf = 0;
    labf = 0;
    wf = 0;
    rrf = 0;
    mc = 0;
    zcap = 0;
    rk = 0;
    k = 0;
    pk = 0;
    c = 0;
    inve = 0;
    y = 0;
    lab = 0;
    pinf = 0;
    w = 0;
    r = 0;
    a = 0;
    b = 0;
    g = 0;
    qs = 0;
    ms = 0;
    spinf = 0;
    sw = 0;
    kpf = 0;
    kp = 0;
y_obs = 0;
c_obs = 0;
pi_obs = pinfobs / 100;
r_obs = robs / 100;
end;

steady;

check;

stoch_simul( order = 1, periods = 0, irf = 40 ) y_obs c_obs pi_obs r_obs;
