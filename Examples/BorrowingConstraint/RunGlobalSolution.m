clear all; %#ok<CLALL>
coder -build GlobalSolution.prj;
[ V, X, PP, BS, XB, Bv, Av, beta, mu, rho, sigma, Ybar, R ] = GlobalSolution_mex;
save GlobalResults.mat;
