clear all; %#ok<CLALL>
coder -build GlobalSolution.prj;
[ V, C, CB, W, kv, alpha, beta, nu, theta ] = GlobalSolution_mex;
save GlobalResults.mat;
