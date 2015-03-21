dynareOBC: An OBC Toolkit
==========

dynareOBC: A toolkit for handling occasionally binding constraints with dynare, by Tom Holden.

Requirements (to be installed and added to your Matlab path):
 * Matlab version R2013a or later, or a fully compatible clone.
 * The MATLAB Optimization toolbox, or a fully compatible clone.
 * dynare, version 4.4 or later, from: http://www.dynare.org/download/dynare-stable

dynareOBC incorporates code by Alexander Meyer-Gohde for calculating risky first order approximations.
More information is contained in his paper describing the algorithm, available here:
http://enim.wiwi.hu-berlin.de/vwl/wtm2/mitarbeiter/meyer-gohde/stochss_main.pdf.
dynareOBC also incorporates code taken from the nonlinear moving average toolkit,
by Hong Lan and Alexander Meyer-Gohde.
Additionally, dynareOBC incorporates code for nested Gaussian cubature that is copyright Alan Genz
and Bradley Keister, 1996, code for LDL decompositions that is copyright Brian Borchers, 2002, and
code for displaying a progress bar that is copyright Antonio Cacho, "Stefan" and Jeremy Scheff, 2014.

Usage: dynareOBC FILENAME[.mod,.dyn] [OPTIONS]

dynareOBC executes instruction included in the conventional dynare mod file, FILENAME.mod.

Unlike dynare, dynareOBC can handle simulation of models containing non-differentiable functions.
Note:
 * dynareOBC approximates the non-differentiable function in levels. Thus if r and pi are the
   endogenous variables of interest: "r = max( 0, 0.005 + 1.5 * pi );" will be more accurate than:
   "exp(R) = max( 1, exp( 0.005 + 1.5 * pi ) );".
 * dynareOBC may produce strange results on models with an indeterminate steady-state, so caution
   should be taken when using the STEADY_STATE command. The initval or steady_state_model blocks
   should not be used to attempt to pin down a steady-state, since these will be ignored by dynareOBC
   in later steps of its solution procedure.

[OPTIONS] include:
 * global
      Without this, dynareOBC assumes agents realise that shocks may arrive in the near future which
      push them towards the bound, but they do not take into account the risk of hitting the bound
      in the far future. With the global option, dynareOBC assumes agents take into account the risk
      of hitting the bound at all horizons. Note that this is significantly slower.
       * shadowshocknumbermultiplier=NUMBER (default: the order of approximation)
            The number of shocks with which to approximate the distribution of each shadow shock
            innovation, when using global.
       * shadowapproximatingorder=NUMBER (default: the order of approximation)
            The order with which to approximate the expected component of each shadow shock, when
            using global.
       * maxiterations=NUMBER (default: 1000)
            The maximum number of iterations of the global fixed-point algorithm.
       * fixedpointacceleration
            Enables an accelerated fixed-point algorithm, when using global. Works only for very well
            behaved problems, when starting close to the solution.
       * resume
            Resumes an interrupted solution iteration, when using global.
 * maxcubaturedegree=NUMBER (default: 7)
      Specifies the degree of polynomial which will be integrated exactly in the highest degree,
      cubature performed. Values above 51 are treated as equal to 51.
       * cubatureaccuracy=NUMBER (default: 6)
            Specifies that the maximum acceptable change in the integrals is 10^(-NUMBER).
       * kappapriorparameter=NUMBER (default: 1)
            The rate of decay of the standard deviation of the error is given a Frechet distributed
            prior with shape parameter 1/NUMBER. Setting this to 0 disables the prior on kappa.
       * nostatisticalcubature
            Disables the statistical improvement to the cubature algorithm, which aggregates results
            of cubature at different degrees. Will generally reduce accuracy, but increase speed.
 * nocubature
      Speeds up dynareOBC by assuming that agents are "surprised" by the existence of the bound.
      At order=1, this is equivalent to a perfect foresight solution to the model.
 * fastcubature
      Causes dynareOBC to ignore the value specified in maxcubaturedegree, and to instead use a
      degree 3 rule without negative weights, but involving evaluations further from the origin.
 * maxcubaturedimension=NUMBER (default: infinity)
      The maximum dimension over which to integrate.
 * firstorderconditionalcovariance
      When order>1 (possibly with firstorderaroundrss or firstorderaroundmean), by default,
      dynareOBC uses a second order approximation of the conditional covariance.
      This option specifies that a first order approximation should be used instead.
 * timetoescapebounds=NUMBER (default: 10)
      The number of periods following a shock after which the model is expected to be away from any
      occasionally binding constraints. This also controls the number of periods of uncertainty over
      which we integrate.
 * timetoreturntosteadystate=NUMBER (default: requested IRF length)
      The number of periods in which to verify that the constraints are not being violated.
 * firstorderaroundrss
      Takes a linear approximation around the risky steady state of the non-linear model.
      If specifying this option, you should set order=2 or order=3 in your mod file.
 * firstorderaroundmean
      Takes a linear approximation around the ergodic mean of the non-linear model.
      If specifying this option, you should set order=2 or order=3 in your mod file.
 * algorithm=0|1|2|3 (default: 0)
      If algorithm=0, an arbitrary solution is returned when there are several.
      If algorithm=1, a linear programming problem is solved first, which will increase the likelihood
      that the same solution is always returned, without guaranteeing this.
      When algorithm>1, the specific solution determined by the objective option is returned.
      If algorithm=2 then this is guaranteed via homotopy.
      When algorithm=3, this is guaranteed via the solution of a QCQP problem.
       * homotopysteps=NUMSTEPS (default: 10)
            The number of homotopy steps to take when using algorithm=1.
       * objective=1|2 (default: 2)
            The norm of alpha to minimise when algorithm>0.
 * fastirfs
      Calculates a fast approximation to IRFs without any Monte-Carlo simulation.
      Without this option, dynareOBC calculates average IRFs.
 * irfsaroundzero
      By default, IRFs are centered around the risky steady state with the fastirfs option, or around
      the approximate mean without it. This option instead centers IRFs around 0.
 * shockscale=NUMBER
      Scale of shocks for IRFs.
 * mlvsimulationmode=0|1|2|3 (default: 0)
      If mlvsimulationmode=0, dynareOBC does not attempt to simulate the path of model local variables.
      If mlvsimulationmode>0, dynareOBC generates simulated paths and average impulse responses for each
      model local variable (MLV) which is used in the model, non-constant, non-forward looking, and not
      purely backwards looking.
      If mlvsimulationmode>1, dynareOBC additionally generates simulated paths and average impulse
      responses for each non-constant MLV, used in the model, containing forward looking terms.
      If mlvsimulationmode=2, then dynareOBC takes the expectation of each forward looking MLV using
      sparse cubature.
      If mlvsimulationmode=3, then dynareOBC takes the expectation of each forward looking MLV using
      Monte Carlo integration.
       * mlvsimulationcubaturedegree=NUMBER (default: 9)
            Specifies the degree of polynomial which should be integrated exactly, when mlvsimulationmode=1.
            Values above 51 are treated as equal to 51.
       * mlvsimulationsamples=NUMBER (default: 2000)
            Specifies the number of samples to use for Monte Carlo integration, when mlvsimulationmode=2.
 * nosparse
      By default, dynareOBC replaces all of the elements of the decision rules by sparse matrices, as
      this generally speeds up dynareOBC. This option prevents dynareOBC from doing this.
 * estimation
      Enables estimation of the model's parameters.
       * estimationdatafile=STRING (default: MOD-FILE-NAME.xlsx)
            Specifies the spreadsheet containing the data to estimate.
       * estimationfixedpointmaxiterations=NUMBER (default: 100)
            The maximum number of iterations used to evaluate the stationary distribution.
 * useficoxpress
      Performance of dynareOBC is higher when the FICO Xpress library is installed.
      This is available for free to academics from: https://community.fico.com/download.jspa
 * nocleanup
      Prevents the deletion of dynareOBC's temporary files. Useful for debugging.

See the dynare reference manual for other available options.

Note that dynareOBC only supports some of the options of stoch_simul, and no warning is generated
if it is used with an unsupported option. Currently supported options for stoch_simul are:
 * irf=NUMBER
 * periods=NUMBER
 * drop=NUMBER
 * order=1|2|3
 * replic=NUMBER
 * loglinear
 * irf_shocks
 * nograph
 * nodisplay
 * nomoments
 * nocorr

dynareOBC also supports a list of variables for simulation after the call to stoch_simul.
When mlvsimulationmode>0, this list can include the names of model local variables. Any MLV
included in this list will be simulated even if it does not meet the previous criteria.
