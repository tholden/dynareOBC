function r = ptest( a )
    % Return r=1 if ‘a’ is a P-matrix (r=0 otherwise)
    % Derived from:
    % http://www.math.wsu.edu/faculty/tsat/files/tl_c.pdf
    nn = length(a);
    stack = a;
    r = true;
    num = 1;
    for n = nn : -1 : 1
        nnew = n - 1;
        newstack = zeros( nnew, 0 );
        newnum = 0;
        parfor k = 1 : num
            a = stack( :, ((k-1)*n+1):(k*n) ); %#ok<PFBNS>
            if a(1,1) <= 0
                r = r & 0;
            else
                if n > 1
                    b = zeros( nnew, nnew );
                    c = b;
                    for i = 2:n
                        d = a(i,1)/a(1,1);
                        for j = 2:n
                            b(i-1,j-1) = a(i,j);
                            c(i-1,j-1) = a(i,j)-d*a(1,j);
                        end
                    end
                    tmp = [ b, c ];
                    newstack = [ newstack, tmp ];
                    newnum = newnum + 2;
                else
                    continue;
                end
            end
        end
        if ~r
            return;
        end
        stack = newstack;
        num = newnum;
    end
end
