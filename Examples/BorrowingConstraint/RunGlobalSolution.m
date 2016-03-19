clear all; %#ok<CLALL>
coder -build GlobalSolution.prj;
[ V, X, XB, Bv, Av, beta, mu, rho, sigma, Ybar, R, PP ] = GlobalSolution_mex;
save GlobalResults.mat;
