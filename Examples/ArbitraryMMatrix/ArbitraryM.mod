@#define T = 5

parameters zero;
zero = 0;

varexo e;

var a b;

@#for j in 1 : T
    @#for k in 1 : T
        parameters M_@{j}_@{k};
        M_@{j}_@{k} = 2 ^ @{j} * 3 ^ @{k};
    @#endfor
@#endfor

@#for j in 0 : T
    @#for k in 0 : T
        var c_@{j}_@{k};
    @#endfor
@#endfor

model;
    a = max( 0, b ) + e;
    a = 1 +
        @#for j in 1 : T
            @#for k in 1 : T
                + M_@{j}_@{k} * ( c_@{j-1}_@{k-1} - c_@{j}_@{k} )
            @#endfor
        @#endfor
    ;

    c_0_0 = a - b;
    @#for k in 1 : T
        c_0_@{k} = c_0_@{k-1}(+1);
    @#endfor

    @#for j in 1 : T
        @#for k in 0 : T
            c_@{j}_@{k} = c_@{j-1}_@{k}(-1);
        @#endfor
    @#endfor
end;

steady_state_model;
    a = 1;
    b = 1;
    @#for j in 0 : T
        @#for k in 0 : T
            c_@{j}_@{k} = 0;
        @#endfor
    @#endfor
end;

shocks;
    var e = 1;
end;

steady;
check;

stoch_simul( order = 1, irf = @{T + 1} );
