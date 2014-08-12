function q = ApproximateInverseCDFMaxGaussians( n, p )
    % https://math.stackexchange.com/questions/89030/expectation-of-the-maximum-of-gaussian-random-variables
    expN1 = 0.36787944117144232159552377016146;
    nInv = 1 / n;
    mu = norminv( 1 - nInv );
    sigma = norminv( 1 - nInv * expN1 ) - mu;
    q = mu - sigma * log( -log(p) );
end

