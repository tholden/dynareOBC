OBCToolkit
==========

A toolkit for handling occasionally binding constraints with dynare, by Tom Holden.

Requirements (to be installed and added to your Matlab path):
 * Matlab version R2013a or later, or a fully compatible clone.
 * The MATLAB Optimization toolbox, or a fully compatible clone.
 * dynare, version 4.4 or later, from: http://www.dynare.org/download/dynare-stable
 * Tom Holden's fork of Hong Lan and Alexander Meyer-Gohde's nonlinear moving average toolkit,
   available from: https://github.com/tholden/nlma

dynareOBC incorporates code by Alexander Meyer-Gohde for calculating risky first order approximations.
More information is contained in his paper describing the algorithm, available here:
http://enim.wiwi.hu-berlin.de/vwl/wtm2/mitarbeiter/meyer-gohde/stochss_main.pdf.
dynareOBC also incorporates code taken from the aforementioned nonlinear moving average toolkit,
by Hong Lan and Alexander Meyer-Gohde.

Usage: dynareOBC FILENAME[.mod,.dyn] [OPTIONS]

dynareOBC executes instruction included in the conventional dynare mod file, FILENAME.mod.

Unlike dynare, dynareOBC can handle simulation of models containing non-differentiable functions.
Note:
 * dynareOBC approximates the non-differentiable function in levels. Thus if r and pi are the
   endogenous variables of interest: "r = max( 0, 0.005 + 1.5 * pi );" will be more accurate than:
   "exp(R) = max( 1, exp( 0.005 + 1.5 * pi ) );".
 * dynareOBC may produce strange results on models with an indeterminate steady-state, so caution
   should be taken when using the STEADY\_STATE command. The initval or steady\_state\_model blocks
   should not be used to attempt to pin down a steady-state, since these will be ignored by dynareOBC
   in later steps of its solution procedure.

[OPTIONS] include:
 * accuracy=0|1|2 (default: 1)
      If accuracy<2, dynareOBC solves under the simplifying assumption that agents are perpetually
      surprised by the bounds. Much faster, but inaccurate if the bound is hit regularly.
      With accuracy=0, dynareOBC additionally assumes that agents act in a perfect-foresight manner
      with respect to "shadow shocks".
       * removenegativequadratureweights
            Zeros all negative quadrature weights, when accuracy>0. May or may not improve accuracy.
       * forceequalquadratureweights
            Uses equal quadrature weights, when accuracy>0. May or may not improve accuracy.
       * orderfivequadrature
            Use a degree 5 quadrature rule, rather than the default degree 3 one, when accuracy>0.
       * pseudoorderfivequadrature
            Use a pseduo degree 5 quadrature rule instead, when accuracy>0.
       * maxintegrationdimension=NUMBER (default: infinity)
            The maximum dimension over which to integrate, when accuracy>0. Setting this to 0 makes
            accuracy=1 equivalent to accuracy=0
       * firstorderconditionalcovariance
            When accuracy>0 and order>1 (possibly with firstorderaroundrss or firstorderaroundmean),
            by default, dynareOBC uses a second order approximation of the conditional covariance.
            This option specifies that a first order approximation should be used instead.
       * shadowshocknumbermultiplier=NUMBER (default: the order of approximation)
            The number of shocks with which to approximate the distribution of each shadow shock
            innovation, when accuracy=2.
       * shadowapproxmiatingorder=NUMBER (default: the order of approximation)
            The order with which to approximate the expected component of each shadow shock, when
            accuracy=2.
       * regressionbasesamplesize=NUMBER (default: 1000)
            The base sample size for the regression used within the accuracy=2, semi-global
            approximation loop.
       * regressionsamplesizemultiplier=NUMBER (default: 30)
            The number by which the regression sample size increases for each additional regressor,
            within the accuracy=2, semi-global approximation loop.
       * maxiterations=NUMBER (default: 1000)
            The maximum number of iterations of the accuracy=2 fixed-point algorithm.
       * densityaccuracy=NUMBER (default: 10)
            The density of the regression residuals when accuracy=2 will be evaluated on a grid with
            2^NUMBER points.
       * densityestimationsimulationlengthmultipler=NUMBER (default: 10)
            The multiplier on the length of simulation to use for matching the shadow shock density.
       * resume
            Resumes an interrupted semi-global solution iteration, when accuracy=2.
 * timetoescapebounds=NUMBER (default: 10)
      The number of periods following a shock after which the model is expected to be away from any
      occasionally binding constraints. When accuracy>0, this also controls the number of periods of
      uncertainty over which we integrate.
 * timetoreturntosteadystate=NUMBER (default: requested IRF length)
      The number of periods in which to verify that the constraints are not being violated.
 * firstorderaroundrss
      Takes a linear approximation around the risky steady state of the non-linear model.
      If specifying this option, you should set order=2 or order=3 in your mod file.
 * firstorderaroundmean
      Takes a linear approximation around the ergodic mean of the non-linear model.
      If specifying this option, you should set order=2 or order=3 in your mod file.
 * algorithm=0|1|2|3 (default: 0)
      If algorithm=0, an arbitrary solution is returned when there are several. If algorithm=1, a linear
      programming problem is solved first, which will increase the likelihood that the same solution is
      always returned, without guaranteeing this. When algorithm>1, the specific solution determined by
      the objective option is returned. If algorithm=2 then this is guaranteed via homotopy, and when
      algorithm=3, this is guaranteed via the solution of a quadratically constrained quadratic
      programming problem.
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
 * nosparse
      By default, dynareOBC replaces all of the elements of the decision rules by sparse matrices, as
      this generally speeds up dynareOBC. This option prevents dynareOBC from doing this.
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
