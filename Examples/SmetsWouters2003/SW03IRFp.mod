// Derived from:

    //**************************************************************************
    // A New Comparative Approach to Macroeconomic Modeling and Policy Analysis
    //
    // Volker Wieland, Tobias Cwik, Gernot J. Mueller, Sebastian Schmidt and 
    // Maik Wolters
    //
    // Working Paper, 2009
    //**************************************************************************

    // Model: EA_SW03

    // Further references:
    // Smets, F., and R. Wouters. 2003. "An Estimated Stochastic Dynamic General Equilibrium Model of the Euro Area."
    // Journal of the European Economic Association 1(5), pp. 1123-1175.

    // Last edited: 10/09/07 by S. Schmidt


var mcf zcapf rkf kf pkf muf cf invef yf labf pinff wf pf emplf rrf effortf
    rf mc zcap rk k pk mu c inve y lab pinf w empl ww effort pinf4 r dr 
    pinfLAG1 pinfLAG2 ygap a as b g ls qs ms sinv spinf sw 
    kpf habf kp hab yobs cobs pobs robs;
var p;

varexo ea eas epsilon_b eg els eqs einv epinf ew em;

parameters calfa ctou cbeta chab ccs cinvs csadjcost 
           csigma chabb cprobw clandaw csigl cprobp cindw cindp cfc cinvdyn 
           czcap csadjlab crpi crdpi crr cry crdy crhoa crhoas crhob crhog 
           crhols crhoinv 
           cscaleea cscaleeas cscaleeb cscaleeg cscaleels cscaleinv 
           cscaleem cscaleqs
           cscaleepinf cscaleew;

calfa       = 0.3;
ctou        = 0.025;
cbeta       = 0.99;
chab        = 0;
ccs         = 0.6;
cinvs       = 0.22;

csadjcost   = 6.7711;
csigma      = 1.3533;
chabb       = 0.5732;
cprobw      = 0.7367;
clandaw     = 1.5;
csigl       = 2.3995;
cprobp      = 0.9082;
cindw       = 0.7627;
cindp       = 0.4694;

cfc         = 1.4077;
cinvdyn     = 1;
czcap       = 0.1690;
csadjlab    = 0.5990;

// reaction function
crpi        = 1.6841;
crdpi       = 0.1398;
crr         = 0.9613;
cry         = 0.0988;
crdy        = 0.1586;

// AR(1) shocks
crhoa       = 0.8232;
crhoas      = 0.9238;
crhob       = 0.8545;
crhog       = 0.9493;
crhols      = 0.8894;
crhoinv     = 0.9273;

// scaling factor of the innovations
cscaleea    = 0.5978;
cscaleeas   = 0.0165;
cscaleeb    = 0.3361;
cscaleeg    = 0.3247;
cscaleels   = 3.5197;
cscaleinv   = 0.0851;
cscaleem    = 0.0808;
cscaleqs    = 0.6043;
cscaleepinf = 0.1602;
cscaleew    = 0.2892;

model;

p = p(-1) + pinf - STEADY_STATE(pinf);

r = max( -log( 1.021605136 ) * 100, crr*r(-1) + (1-crr)*(as + crpi* pinf + cry*ygap)+crdpi*(pinf-pinf(-1))+crdy*(ygap-ygap(-1))+ms);
// The exact value of the ZLB doesn't matter for the sake of existence calculations.
// Here we take the mean value from the Fagan Henry and Mestre 2001 dataset, over the data period used by Smets Wouters (2003).

mcf      =   calfa*rkf + (1-calfa)*wf - a;
zcapf    =   (1/czcap)*rkf;
rkf      =   wf + labf - kf;
kf       =   kpf(-1) + zcapf;
invef    =   (1/(1+cinvdyn*cbeta))*((cinvdyn*invef(-1) + cbeta*invef(+1)) + (1/csadjcost)*pkf + 0*( sinv - 0 * cbeta * sinv(+1) )  );
pkf      = - muf - 1*b + muf(+1) + (1-cbeta*(1-ctou))*rkf(+1) + 0*(1-cbeta*(1-ctou))*zcapf(+1) + cbeta*(1-ctou)*pkf(+1) + qs;
muf      =   muf(+1) + rf - pinff(+1) - b;
muf      = - csigma*((1-chab)/(1-chab-chabb))*cf + csigma*(chabb/(1-chab-chabb))*habf;
yf       =   ccs*cf + cinvs*invef + g;
yf       =   cfc*(calfa*kf + (1-calfa)*labf + a);
mcf      = - 0*0 - 0*(1+cbeta*cindp)*(1/((1-cprobp)*(1-cbeta*cprobp)/(cprobp)))*spinf;
wf       = - 1*muf - 1*ls + csigl*labf;
pf       =   0*pf(-1) + pinff;
emplf    =   emplf(-1) + 1*emplf(+1)- 1*emplf + ((1-csadjlab)*(1-csadjlab)/csadjlab)*effortf;
rrf      =   rf - pinff(+1);
effortf  =   labf - emplf;
pinff    =   0;
mc       =   calfa*rk+(1-calfa)*w - a - 0;
zcap     =   (1/czcap)*rk - 0*(1/czcap)*pk;
rk       =   w + lab - k;
k        =   kp(-1) + zcap;
inve     =   (1/(1+cinvdyn*cbeta))*((cinvdyn*inve(-1) + cbeta*inve(+1)) + (1/csadjcost)*pk + 1*( sinv - 0 * cbeta * sinv(+1) )  );
pk       = - mu - 1*b - 0*(1-crhols)*ls - 0*0+mu(+1) + 0*b(+1) + (1-cbeta*(1-ctou))*rk(+1) + 0*(1-cbeta*(1-ctou))*zcap(+1)
             + cbeta*(1-ctou)*pk(+1) + qs + 0*sinv;
mu       =   mu(+1) + r - pinf(+1) - b + 0*b(+1) - 0 - 0*(1-crhols)*ls;
mu       = - csigma*((1-chab)/(1-chab-chabb))*c + csigma*(chabb/(1-chab-chabb))*hab;
y        =   ccs*c + cinvs*inve + g + 0;
y        =   cfc*(calfa*k + (1-calfa)*lab + a + 0);
pinf     =   0*as + (1/(1+cbeta*cindp))*((cbeta)*(pinf(+1) - 0*as(+1)) + (cindp)*(pinf(-1) - 0*as(-1)) 
             + ((1-cprobp)*(1-cbeta*cprobp)/(cprobp))*(mc+0) + 0*0.1*0)+ spinf;
w        =   ((1/(((1+cbeta)*cprobw*((clandaw/(1-clandaw))*csigl-1+0)/(1-cprobw))+0+0*cprobw*cbeta*(0-1))))
             *(((cprobw*((clandaw/(1-clandaw))*csigl-1+0))/(1-cprobw)+0+0*(0-1))*w(-1)
             + (cbeta)*((cprobw*((clandaw/(1-clandaw))*csigl-1+0))/(1-cprobw))*w(+1)
             + (cindw)*(cprobw/(1-cprobw))*((clandaw/(1-clandaw))*csigl-1+0)*(pinf(-1)-0*as(-1))
             - (cindw*cbeta*cprobw*(cprobw/(1-cprobw))*((clandaw/(1-clandaw))*csigl-1+0)
             + (cprobw/(1-cprobw))*((clandaw/(1-clandaw))*csigl-1+0)
             + cprobw*cbeta*cindw*((clandaw/(1-clandaw))*csigl-1))*(pinf - 0*as)
             + (cbeta*cprobw)*(((cprobw/(1-cprobw))*((clandaw/(1-clandaw))*csigl-1+0))
             + ((clandaw/(1-clandaw))*csigl-1))*(pinf(+1) - 0*as(+1))
             + (1-cbeta*cprobw)*(w + 1*mu + 1*ls - 0*effort - csigl*(1/(1-0))*lab + csigl*(0/(1-0))*lab(-1)))
             + 0*(1/(1+cbeta))*1*ls + 1*sw;
empl     =   empl(-1) + 1*empl(+1) - 1*empl - 0*r + 0*pinf(+1) + 0*csadjlab*effort + ((1-csadjlab)*(1-csadjlab)/csadjlab)*effort
             + 0.0*(a(-1) + cbeta*a(+1) - (1+cbeta)*a);
ww       =   w + 0*(lab - empl);
effort   =   lab - empl;
dr       =   r - r(-1);
pinfLAG1 =   pinf(-1);
pinfLAG2 =   pinfLAG1(-1);
pinf4    =   pinf + pinfLAG1 + pinfLAG2 + pinfLAG2(-1);
ygap     =   y - yf;
as       =   crhoas*as(-1) + cscaleeas*eas;
a        =   crhoa*a(-1) + cscaleea*ea;
b        =   crhob*b(-1) - cscaleeb*epsilon_b;
g        =   crhog*g(-1) - cscaleeg*eg;
ls       =   crhols*ls(-1) + cscaleels*els;
sinv     =   crhoinv*sinv(-1) - cscaleinv*einv;
ms       =   cscaleem*em; //Monetary policy innovation
qs       =   -cscaleqs*eqs;
spinf    =   -cscaleepinf*epinf;
sw       =   -cscaleew*ew;
kpf      =   (1-ctou)*kpf(-1) + ctou*invef(-1);
habf     =   chab*habf(-1) + (1-chab)*cf(-1);
kp       =   (1-ctou)*kp(-1) + ctou*inve(-1);
hab      =   chab*hab(-1) + (1-chab)*c(-1);

#scale = 1 / 100;
yobs = y * scale;
cobs = c * scale;
pobs = p * scale;
robs = r / 100 + log( 1.021605136 );

end;

shocks;

var ea       = 1;   //Productivity Shock
var eas      = 1;   //Inflation Objective Shock
var epsilon_b= 1;   //Consumption Preference Shock
var eg       = 1;   //Fiscal Policy Shock
var els      = 1;   //Labor Supply Shock
var einv     = 1;   //Investment Shock
var em       = 1;   //Monetary Innovation
var eqs      = 1;   //Equity Premium Shock
var epinf    = 1;   //Price Mark Up Shock
var ew       = 1;   //Wage Mark Up Shock

end;

steady_state_model;

mcf = 0;
zcapf = 0;
rkf = 0;
kf = 0;
pkf = 0;
muf = 0;
cf = 0;
invef = 0;
yf = 0;
labf = 0;
pinff = 0;
wf = 0;
pf = 0;
emplf = 0;
rrf = 0;
effortf = 0;
rf = 0;
mc = 0;
zcap = 0;
rk = 0;
k = 0;
pk = 0;
mu = 0;
c = 0;
inve = 0;
y = 0;
lab = 0;
pinf = 0;
w = 0;
empl = 0;
ww = 0;
effort = 0;
pinf4 = 0;
r = 0;
dr = 0;
pinfLAG1 = 0;
pinfLAG2 = 0;
ygap = 0;
a = 0;
as = 0;
b = 0;
g = 0;
ls = 0;
qs = 0;
ms = 0;
sinv = 0;
spinf = 0;
sw = 0;
kpf = 0;
habf = 0;
kp = 0;
hab = 0;

yobs = 0;
cobs = 0;
piobs = 0;
robs = log( 1.021605136 );
p = 0;

end;

steady;

check;

stoch_simul( order=1, irf=40, periods=0, irf_shocks = ( epsilon_b ) ) yobs cobs pobs robs;
