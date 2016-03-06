clear all; %#ok<CLALL>
coder -build GlobalSolution.prj;
[ V, C, CB, kv, av, alpha, beta, nu, theta, rho, sigma ] = GlobalSolution_mex;
save GlobalResults.mat;
