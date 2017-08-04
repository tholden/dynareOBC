% The below code is derived from the QD C++ library.

% QD is Copyright (c) 2003-2009, The Regents of the University of California, through Lawrence Berkeley National Laboratory (subject to receipt of any required approvals from U.S. Dept. of Energy) All rights reserved.

% QD is distributed under the following license:

% 1. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
% (1) Redistributions of source code must retain the copyright notice, this list of conditions and the following disclaimer.
% (2) Redistributions in binary form must reproduce the copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
% (3) Neither the name of the University of California, Lawrence Berkeley National Laboratory, U.S. Dept. of Energy nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
% 2. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 3. You are under no obligation whatsoever to provide any bug fixes, patches, or upgrades to the features, functionality or performance of the source code ("Enhancements") to anyone; however, if you choose to make your Enhancements available either publicly, or directly to Lawrence Berkeley National Laboratory, without imposing a separate written license agreement for such Enhancements, then you hereby grant the following license: a non-exclusive, royalty-free perpetual license to install, use, modify, prepare derivative works, incorporate into other computer software, distribute, and sublicense such enhancements or derivative works thereof, in binary and source code form.

% The implementation of the LUP decomposition and the backslack operator here is derived from Cleve Moler's code from "Numerical Computing with MATLAB".

% "Numerical Computing with MATLAB" is Copyright (c) 2004, Cleve Moler and Copyright (c) 2016, The MathWorks, Inc.

% "Numerical Computing with MATLAB" is distributed under the following license:

% 1. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
% (1) Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
% (2) Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
% (3) In all cases, the software is, and all modifications and derivatives of the software shall be, licensed to you solely for use in conjunction with MathWorks products and service offerings.
% 2. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 

classdef DoubleDouble
    properties ( SetAccess = private, GetAccess = private )
        v1
        v2
    end
    
    properties ( Constant, GetAccess = private )
        InverseFactorial = [
            1.66666666666666657e-01,  9.25185853854297066e-18;
            4.16666666666666644e-02,  2.31296463463574266e-18;
            8.33333333333333322e-03,  1.15648231731787138e-19;
            1.38888888888888894e-03, -5.30054395437357706e-20;
            1.98412698412698413e-04,  1.72095582934207053e-22;
            2.48015873015873016e-05,  2.15119478667758816e-23;
            2.75573192239858925e-06, -1.85839327404647208e-22;
            2.75573192239858883e-07,  2.37677146222502973e-23;
            2.50521083854417202e-08, -1.44881407093591197e-24;
            2.08767569878681002e-09, -1.20734505911325997e-25;
            1.60590438368216133e-10,  1.25852945887520981e-26;
            1.14707455977297245e-11,  2.06555127528307454e-28;
            7.64716373181981641e-13,  7.03872877733453001e-30;
            4.77947733238738525e-14,  4.39920548583408126e-31;
            2.81145725434552060e-15,  1.65088427308614326e-31;
        ];        
    end
    
    methods
        function v = DoubleDouble( in1, in2 )
            if nargin >= 2
                [ v.v1, v.v2 ] = DoubleDouble.Normalize( double( in1 ), double( in2 ) );
            elseif nargin == 1
                if isa( in1, 'DoubleDouble' )
                    v.v1 = in1.v1;
                    v.v2 = in1.v2;
                else
                    v.v1 = double( in1 );
                    v.v2 = zeros( size( in1 ) );
                end
            end
        end
        
        function v = double( v )
            v = v.v1;
        end
        
        function v = isreal( v )
            v = isreal( v.v1 ) && isreal( v.v2 );
        end
        
        function v = isfinite( v )
            v = isfinite( v.v1 ) & isfinite( v.v2 );
        end
        
        function v = isinf( v )
            v = isinf( v.v1 ) | isinf( v.v2 );
        end
        
        function v = isnan( v )
            v = isnan( v.v1 ) | isnan( v.v2 );
        end
        
        function v = real( v )
            v.v1 = real( v.v1 );
            v.v2 = real( v.v2 );
        end
        
        function v = imag( v )
            v.v1 = imag( v.v1 );
            v.v2 = imag( v.v2 );
        end
        
        function v = conj( v )
            v.v1 = conj( v.v1 );
            v.v2 = conj( v.v2 );
        end
        
        function disp( v )
            if isempty( v.v1 )
                disp( '     []' );
            else
                disp( v.v1 );
            end
            disp( '     +' );
            if isempty( v.v2 )
                disp( '     []' );
            else
                disp( v.v2 );
            end
        end
        
        function [ v, varargout ] = size( v, varargin )
            v = size( v.v1, varargin{:} );
            if nargout > 1
                varargout = num2cell( v( 2:end ) );
                v = v( 1 );
            end
        end
        
        function v = numel( v )
            v = numel( v.v1 );
        end
        
        function n = numArgumentsFromSubscript( v, s, IndexingContext )
            n = numArgumentsFromSubscript( v.v1, s, IndexingContext );
        end
        
        function v = repmat( v, varargin )
            v = DoubleDouble.Make( repmat( v.v1, varargin{:} ), repmat( v.v2, varargin{:} ) );
        end
        
        function v = isequal( a, b, varargin )
            if any( size( a ) ~= size( b ) )
                v = false;
                return
            end
            v = a == b;
            v = all( v(:) );
            if nargin > 2
                for i = 1 : length( varargin )
                    if ~v
                        break
                    end
                    v = v && isequal( a, varargin{i} );
                end
            end
        end
        
        function v = isempty( v )
            v = isempty( v.v1 );
        end
        
        function v = diag( v )
            v = DoubleDouble.Make( diag( v.v1 ), diag( v.v2 ) );
        end
        
        function v = tril( v, k )
            if nargin < 2
                v = DoubleDouble.Make( tril( v.v1 ), tril( v.v2 ) );
            else
                v = DoubleDouble.Make( tril( v.v1, k ), tril( v.v2, k ) );
            end
        end
        
        function v = triu( v, k )
            if nargin < 2
                v = DoubleDouble.Make( triu( v.v1 ), triu( v.v2 ) );
            else
                v = DoubleDouble.Make( triu( v.v1, k ), triu( v.v2, k ) );
            end
        end
        
        function v = plus( a, b )
            v = DoubleDouble.Plus( a, b );
        end
        
        function v = minus( a, b )
            v = DoubleDouble.Minus( a, b );
        end
        
        function v = uminus( v )
            v.v1 = -v.v1;
            v.v2 = -v.v2;
        end
        
        function v = uplus( v )
        end
        
        function v = times( a, b )
            v = DoubleDouble.Times( a, b );
        end
                
        function v = mtimes( a, b )
            v = DoubleDouble.MTimes( a, b );
        end
        
        function v = rdivide( a, b )
            v = DoubleDouble.RDivide( a, b );
        end
                
        function v = ldivide( a, b )
            v = DoubleDouble.LDivide( a, b );
        end
        
        function v = mldivide( a, v )
            v = DoubleDouble.MLDivide( a, v );
        end
        
        function v = mrdivide( v, a )
            v = DoubleDouble.MRDivide( v, a );
        end
        
        function v = power( a, b )
            if ~isa( a, 'DoubleDouble' )
                a = DoubleDouble( a );
            end
            v = exp( b .* log( a ) );
        end
        
        function v = lt( a, b )
            if isa( a, 'DoubleDouble' )
                a1 = a.v1;
                a2 = a.v2;
            else
                a1 = a;
                a2 = 0;
            end
            if isa( b, 'DoubleDouble' )
                b1 = b.v1;
                b2 = b.v2;
            else
                b1 = b;
                b2 = 0;
            end
            v = ( a1 < b1 ) | ( ( a1 == b1 ) & ( a2 < b2 ) );
        end
        
        function v = gt( a, b )
            if isa( a, 'DoubleDouble' )
                a1 = a.v1;
                a2 = a.v2;
            else
                a1 = a;
                a2 = 0;
            end
            if isa( b, 'DoubleDouble' )
                b1 = b.v1;
                b2 = b.v2;
            else
                b1 = b;
                b2 = 0;
            end
            v = ( a1 > b1 ) | ( ( a1 == b1 ) & ( a2 > b2 ) );
        end
        
        function v = le( a, b )
            if isa( a, 'DoubleDouble' )
                a1 = a.v1;
                a2 = a.v2;
            else
                a1 = a;
                a2 = 0;
            end
            if isa( b, 'DoubleDouble' )
                b1 = b.v1;
                b2 = b.v2;
            else
                b1 = b;
                b2 = 0;
            end
            v = ( a1 < b1 ) | ( ( a1 == b1 ) & ( a2 <= b2 ) );
        end
        
        function v = ge( a, b )
            if isa( a, 'DoubleDouble' )
                a1 = a.v1;
                a2 = a.v2;
            else
                a1 = a;
                a2 = 0;
            end
            if isa( b, 'DoubleDouble' )
                b1 = b.v1;
                b2 = b.v2;
            else
                b1 = b;
                b2 = 0;
            end
            v = ( a1 > b1 ) | ( ( a1 == b1 ) & ( a2 >= b2 ) );
        end
        
        function v = ne( a, b )
            if isa( a, 'DoubleDouble' )
                a1 = a.v1;
                a2 = a.v2;
            else
                a1 = a;
                a2 = 0;
            end
            if isa( b, 'DoubleDouble' )
                b1 = b.v1;
                b2 = b.v2;
            else
                b1 = b;
                b2 = 0;
            end
            v = ( a1 ~= b1 ) | ( a2 ~= b2 );
        end
        
        function v = eq( a, b )
            if isa( a, 'DoubleDouble' )
                a1 = a.v1;
                a2 = a.v2;
            else
                a1 = a;
                a2 = 0;
            end
            if isa( b, 'DoubleDouble' )
                b1 = b.v1;
                b2 = b.v2;
            else
                b1 = b;
                b2 = 0;
            end
            v = ( a1 == b1 ) & ( a2 == b2 );
        end
        
        function v = colon( a, d, b )
            if nargin < 3
                b = d;
                d = 1;
            end
            if ~isa( a, 'DoubleDouble' )
                a = DoubleDouble( a );
            end
            if ~isa( b, 'DoubleDouble' )
                b = DoubleDouble( b );
            end
            if ~isa( d, 'DoubleDouble' )
                d = DoubleDouble( d );
            end
            c = double( floor( ( b - a ) ./ d ) );
            v = a + ( 0:c ) .* d;
        end
        
        function v = ctranspose( v )
            v.v1 = v.v1';
            v.v2 = v.v2';
        end
        
        function v = transpose( v )
            v.v1 = v.v1.';
            v.v2 = v.v2.';
        end
        
        function v = horzcat( a, b, varargin )
            if nargin > 2
                v = horzcat( horzcat( a, b ), varargin{:} );
            else
                if ~isa( a, 'DoubleDouble' )
                    a = DoubleDouble( a );
                end
                if ~isa( b, 'DoubleDouble' )
                    b = DoubleDouble( b );
                end
                x1 = horzcat( [ a.v1, b.v1 ] );
                x2 = horzcat( [ a.v2, b.v2 ] );
                v = DoubleDouble.Make( x1, x2 );
            end
        end
        
        function v = vertcat( a, b, varargin )
            if nargin > 2
                v = vertcat( vertcat( a, b ), varargin{:} );
            else
                if ~isa( a, 'DoubleDouble' )
                    a = DoubleDouble( a );
                end
                if ~isa( b, 'DoubleDouble' )
                    b = DoubleDouble( b );
                end
                x1 = vertcat( [ a.v1; b.v1 ] );
                x2 = vertcat( [ a.v2; b.v2 ] );
                v = DoubleDouble.Make( x1, x2 );
            end
        end
        
        function v = subsref( v, s )
            v = DoubleDouble.Make( subsref( v.v1, s ), subsref( v.v2, s ) );
        end
        
        function v = subsasgn( v, s, b )
            if ~isa( v, 'DoubleDouble' )
                v = DoubleDouble( v );
            end
            if ~isa( b, 'DoubleDouble' )
                b = DoubleDouble( b );
            end
            v.v1 = subsasgn( v.v1, s, b.v1 );
            v.v2 = subsasgn( v.v2, s, b.v2 );
        end
        
        function v = subsindex( v )
            v = v.v1;
        end
        
        function v = sum( v, dim )
            if nargin < 2
                dim = [];
            end
            v = DoubleDouble.Sum( v, dim );
        end
        
        function v = prod( v, dim )
            if nargin < 2
                dim = [];
            end
            v = DoubleDouble.Prod( v, dim );
        end
        
        function [ v, i ] = max( a, b, dim )
            if nargin < 3
                dim = [];
                if nargin < 2
                    b = [];
                end
            end
            if nargout < 2
                v = DoubleDouble.Max( a, b, dim );
            else
                [ v, i ] = DoubleDouble.Max( a, b, dim );
            end
        end
        
        function [ v, i ] = min( a, b, dim )
            if nargin < 3
                dim = [];
                if nargin < 2
                    b = [];
                end
            end
            if nargout < 2
                v = DoubleDouble.Min( a, b, dim );
            else
                [ v, i ] = DoubleDouble.Min( a, b, dim );
            end
        end
        
        function v = cumsum( v, dim )
            if nargin < 2
                dim = [];
            end
            v = DoubleDouble.CumSum( v, dim );
        end
        
        function v = cumprod( v, dim )
            if nargin < 2
                dim = [];
            end
            v = DoubleDouble.CumProd( v, dim );
        end
        
        function v = cummax( v, dim )
            if nargin < 3
                dim = [];
            end
            v = DoubleDouble.CumMax( v, dim );
        end
        
        function v = cummin( v, dim )
            if nargin < 3
                dim = [];
            end
            v = DoubleDouble.CumMin( v, dim );
        end
        
        function v = dot( a, b, dim )
            if nargin < 3
                dim = [];
            end
            v = DoubleDouble.Dot( a, b, dim );
        end
        
        function v = abs( v )
            Select = v.v1 < 0;
            v.v1( Select ) = -v.v1( Select );
            v.v2( Select ) = -v.v2( Select ); 
        end
        
        function v = sign( v )
            v = sign( v.v1 );
        end
        
        function v = floor( v )
            x1 = floor( v.v1 );
            x2 = zeros( size( x1 ) );
            Select = x1 == v.v1;
            x2( Select ) = floor( v.v2( Select ) );
            [ x1, x2 ] = DoubleDouble.Normalize( x1, x2 );
            v = DoubleDouble.Make( x1, x2 );
        end
        
        function v = ceil( v )
            x1 = ceil( v.v1 );
            x2 = zeros( size( x1 ) );
            Select = x1 == v.v1;
            x2( Select ) = ceil( v.v2( Select ) );
            [ x1, x2 ] = DoubleDouble.Normalize( x1, x2 );
            v = DoubleDouble.Make( x1, x2 );
        end
        
        function v = fix( v )
            x1 = fix( v.v1 );
            x2 = zeros( size( x1 ) );
            Select = x1 == v.v1;
            x2( Select ) = fix( v.v2( Select ) );
            [ x1, x2 ] = DoubleDouble.Normalize( x1, x2 );
            v = DoubleDouble.Make( x1, x2 );
        end
        
        function v = round( v )
            x1 = round( v.v1 );
            x2 = zeros( size( x1 ) );
            Select = x1 == v.v1;
            x2( Select ) = round( v.v2( Select ) );
            Select = ( ~Select ) & ( abs( x1 - v.v1 ) == 0.5 ) & ( v.v2 < 0 );
            x2( Select ) = x2( Select ) - 1;
            [ x1, x2 ] = DoubleDouble.Normalize( x1, x2 );
            v = DoubleDouble.Make( x1, x2 );
        end
        
        function v = realsqrt( v )
            Select = v < 0;
            v.v1( Select ) = NaN;
            v.v2( Select ) = NaN;
            Select = v > 0;
            x = 1 ./ sqrt( v.v1( Select ) );
            vx = v.v1( Select ) .* x;
            t = DoubleDouble.Make( v.v1( Select ), v.v2( Select ) ) - DoubleDouble.Times( vx, vx );
            t = DoubleDouble.Plus( vx, t.v1 .* ( x * 0.5 ) );
            v.v1( Select ) = t.v1;
            v.v2( Select ) = t.v2;
        end
        
        function v = sqrt( v )
            x = 1 ./ sqrt( v.v1 );
            vx = v.v1 .* x;
            v = v - DoubleDouble.Times( vx, vx );
            v = DoubleDouble.Plus( vx, v.v1 .* ( x * 0.5 ) );
        end
        
        function v = exp( v )
            % Strategy:  We first reduce the size of x by noting that
            % exp(kr + m * log(2)) = 2^m * exp(r)^k
            % where m and k are integers.  By choosing m appropriately
            % we can make |kr| <= log(2) / 2 = 0.347.  Then exp(r) is 
            % evaluated using the familiar Taylor series.  Reducing the 
            % argument substantially speeds up the convergence.
            k = 512.0;
            inv_k = 1.0 / k;
            log_2 = 6.931471805599452862e-01;
            log_2e = 2.319046813846299558e-17;

            m = floor( v.v1 ./ log_2 + 0.5 );
            r = TimesPowerOf2( v - DoubleDouble.Make( log_2, log_2e ) .* m, inv_k );

            p = r .* r;
            s = r + TimesPowerOf2( p, 0.5 );
            p = p .* r;
            t = p .* DoubleDouble.Make( DoubleDouble.InverseFactorial( 1, 1 ), DoubleDouble.InverseFactorial( 1, 2 ) );
            for i = 2:15
                s = s + t;
                p = p .* r;
                t = p .* DoubleDouble.Make( DoubleDouble.InverseFactorial( i, 1 ), DoubleDouble.InverseFactorial( i, 2 ) );
                if all( abs( t.v1 ) <= inv_k .* DoubleDouble.eps )
                    break
                end
            end

            s = s + t;

            s = TimesPowerOf2( s, 2.0 ) + s .* s;
            s = TimesPowerOf2( s, 2.0 ) + s .* s;
            s = TimesPowerOf2( s, 2.0 ) + s .* s;
            s = TimesPowerOf2( s, 2.0 ) + s .* s;
            s = TimesPowerOf2( s, 2.0 ) + s .* s;
            s = TimesPowerOf2( s, 2.0 ) + s .* s;
            s = TimesPowerOf2( s, 2.0 ) + s .* s;
            s = TimesPowerOf2( s, 2.0 ) + s .* s;
            s = TimesPowerOf2( s, 2.0 ) + s .* s;
            s = s + 1.0;
            
            twoPm = 2 .^ m;
            
            v = TimesPowerOf2( s, twoPm );
        end
        
        function x = log( v )
            x = DoubleDouble.Make( log( v.v1 ), zeros( size( v.v1 ) ) );
            x = x + v .* exp( -x ) - 1.0;
            x = x + v .* exp( -x ) - 1.0; % slightly paranoid, but does correct e.g. log(exp(DoubleDouble(-40)))
        end
        
        function [ v, U, p ] = lu( v, type )
            [ m, n ] = size( v );
            p = 1 : m;

            for k = 1 : min( m, n )

                % Find index of largest element below diagonal in k-th column
                [ ~, midx ] = max( abs( DoubleDouble.Make( v.v1( k:m, k ), v.v2( k:m, k ) ) ) );
                midx = midx + k - 1;

                % Skip elimination if column is zero
                if v.v1( midx, k ) ~= 0 || v.v2( midx, k ) ~= 0

                    % Swap pivot row
                    if midx ~= k
                        v.v1( [ k midx ], : ) = v.v1( [ midx k ], : );
                        v.v2( [ k midx ], : ) = v.v2( [ midx k ], : );
                        p( [ k midx ] ) = p( [ midx k ] );
                    end

                    % Compute multipliers
                    i = k + 1 : m;
                    [ v.v1( i, k ), v.v2( i, k ) ] = DoubleDouble.DDDividedByDD( v.v1( i, k ), v.v2( i, k ), v.v1( k, k ), v.v2( k, k ) );

                    % Update the remainder of the matrix
                    j = k + 1 : n;
                    % A( i, j ) = A( i, j ) - A( i, k ) .* A( k, j );
                    [ t1, t2 ] = DoubleDouble.DDTimesDD( v.v1( i, k ), v.v2( i, k ), v.v1( k, j ), v.v2( k, j ) );
                    [ v.v1( i, j ), v.v2( i, j ) ] = DoubleDouble.DDPlusDD( v.v1( i, j ), v.v2( i, j ), -t1, -t2 );
                end
            end

            if nargout > 1
                % Separate result
                L = tril( v, -1 ) + eye( m, n, 'DoubleDouble' );
                U = triu( v );
                if n > m
                    L.v1 = L.v1( :, 1:m );
                    L.v2 = L.v2( :, 1:m );
                elseif n < m
                    U.v1 = U.v1( 1:n, : );
                    U.v2 = U.v2( 1:n, : );
                end
                v = L;

                if nargout > 2 
                    if nargin < 2 || ~strcmp( type, 'vector' )
                        pp = eye( m );
                        pp = pp( p, : );
                        p = pp;
                    end
                else
                    invp( p ) = 1 : m;
                    v.v1 = v.v1( invp, : );
                    v.v2 = v.v2( invp, : );
                end
            end            
        end
        
        function v = det( v )
            [ m, n ] = size( v );
            if m ~= n
                throw( MException( 'MATLAB:square', 'Matrix must be square.' ) );
            end
            [ ~, u, P ] = lu( v );
            DetP = det( P );
            if DetP > 0
                v = prod( diag( u ) );
            elseif DetP < 0
                v = -prod( diag( u ) );
            else
                v = DoubleDouble.Make( NaN, NaN );
            end            
        end         
        
        function v = inv( v )
            n = size( v, 1 );
            v = v \ DoubleDouble.Make( eye( n ), zeros( n ) );
        end
        
        function [ v, p ] = chol( v, type )
            [ v, d ] = ldl( v, 'vector_d' );
            v = v .* sqrt( d.' );
            if any( d < 0 )
                p = 1;
            else
                p = 0;
            end
            if nargin < 2 || strcmp( type, 'upper' )
                v = v.';
            end
        end
        
        function [ L, d ] = ldl( A, type )
            [ m, n ] = size( A );
            assert( m == n );
            L = DoubleDouble.Make( eye( n ), zeros( n ) );
            x1 = zeros( 1, n );
            x2 = x1;
            t1 = x1;
            t2 = x1;
            d = DoubleDouble.Make( x1, x1 );
            x1( 1 ) = A.v1( 1, 1 );
            x2( 1 ) = A.v2( 1, 1 );
            d.v1( 1 ) = x1( 1 );
            d.v2( 1 ) = x2( 1 );
            idxs = 2 : n;
            [ L.v1( idxs, 1 ), L.v2( idxs, 1 ) ] = DoubleDouble.DDDividedByDD( A.v1( idxs, 1 ), A.v2( 2 : n, 1 ), x1( 1 ), x2( 1 ) );
            for j = 2 : n
                idxs = 1 : j - 1;
                [ x1( idxs ), x2( idxs ) ] = DoubleDouble.DDTimesDD( conj( L.v1( j, idxs ) ), conj( L.v2( j, idxs ) ), d.v1( idxs ), d.v2( idxs ) );
                [ t1( idxs ), t2( idxs ) ] = DoubleDouble.DDTimesDD( L.v1( j, idxs ), L.v2( j, idxs ), x1( idxs ), x2( idxs ) );
                t = sum( DoubleDouble.Make( t1( idxs ), t2( idxs ) ) );
                [ x1( j ), x2( j ) ] = DoubleDouble.DDPlusDD( A.v1( j, j ), A.v2( j, j ), -t.v1, -t.v2 );
                d.v1( j ) = x1( j );
                d.v2( j ) = x2( j );
                if j < n
                    jdxs = j + 1 : n;
                    [ s1, s2 ] = DoubleDouble.DDTimesDD( L.v1( jdxs, idxs ), L.v2( jdxs, idxs ), x1( idxs ), x2( idxs ) );
                    tt = sum( DoubleDouble.Make( s1, s2 ), 2 );
                    [ t1( jdxs ), t2( jdxs ) ] = DoubleDouble.DDPlusDD( A.v1( jdxs, j ), A.v2( jdxs, j ), -tt.v1, -tt.v2 );
                    [ L.v1( jdxs, j ), L.v2( jdxs, j ) ] = DoubleDouble.DDDividedByDD( t1( jdxs ), t2( jdxs ), x1( j ), x2( j ) );
                end
            end
            if nargin < 2 || ~strcmp( type, 'vector_d' )
                d = diag( d );
            else
                d = d.';
            end
        end
    end

    methods ( Static )
        function v = IsEqualWithExpansion( a, b, varargin )
            v = a == b;
            v = all( v(:) );
            if nargin > 2
                for i = 1 : length( varargin )
                    if ~v
                        break
                    end
                    v = v && IsEqualWithExpansion( a, varargin{i} );
                end
            end
        end
        
        function v = ones( varargin )
            v = DoubleDouble.Make( ones( varargin{:}, 'double' ), zeros( varargin{:}, 'double' ) );
        end
        
        function v = zeros( varargin )
            v = DoubleDouble.Make( zeros( varargin{:}, 'double' ), zeros( varargin{:}, 'double' ) );
        end
        
        function v = eye( varargin )
            v = DoubleDouble.Make( eye( varargin{:}, 'double' ), zeros( varargin{:}, 'double' ) );
        end
        
        function v = nan( varargin )
            v = DoubleDouble.Make( nan( varargin{:}, 'double' ), nan( varargin{:}, 'double' ) );
        end
        
        function v = inf( varargin )
            v = DoubleDouble.Make( inf( varargin{:}, 'double' ), inf( varargin{:}, 'double' ) );
        end
        
        function v = eps( v )
            e = 4.93038065763132e-32;
            if nargin == 0
                v = DoubleDouble.Make( e, 0 );
            else
                v = DoubleDouble( v );
                v = abs( v );
                v = DoubleDouble.Times( v, e );
            end
        end
        
        function v = rand( varargin )
            t = rand( varargin{:}, 'double' );
            v = DoubleDouble.Make( t, eps( t ) .* ( rand( varargin{:}, 'double' ) - 0.5 ) );
        end
        
        function v = randn( varargin )
            t = randn( varargin{:}, 'double' );
            v = DoubleDouble.Make( t, eps( t ) .* ( rand( varargin{:}, 'double' ) - 0.5 ) );
        end
        
        function v = randi( imax, varargin )
            v = DoubleDouble.Make( randi( imax, varargin{:}, 'double' ), zeros( varargin{:}, 'double' ) );
        end
        
        function v = Plus( a, b )
            if isa( a, 'DoubleDouble' )
                if isa( b, 'DoubleDouble' )
                    [ x1, x2 ] = DoubleDouble.DDPlusDD( a.v1, a.v2, b.v1, b.v2 );
                else
                    [ x1, x2 ] = DoubleDouble.DDPlusDouble( a.v1, a.v2, double( b ) );
                end
            else
                if isa( b, 'DoubleDouble' )
                    [ x1, x2 ] = DoubleDouble.DDPlusDouble( b.v1, b.v2, double( a ) );
                else
                    [ x1, x2 ] = DoubleDouble.DoublePlusDouble( double( a ), double( b ) );
                end
            end
            v = DoubleDouble.Make( x1, x2 );
        end
        
        function v = Minus( a, b )
            if isa( a, 'DoubleDouble' )
                if isa( b, 'DoubleDouble' )
                    [ x1, x2 ] = DoubleDouble.DDPlusDD( a.v1, a.v2, -b.v1, -b.v2 );
                else
                    [ x1, x2 ] = DoubleDouble.DDPlusDouble( a.v1, a.v2, -double( b ) );
                end
            else
                if isa( b, 'DoubleDouble' )
                    [ x1, x2 ] = DoubleDouble.DDPlusDouble( -b.v1, -b.v2, double( a ) );
                else
                    [ x1, x2 ] = DoubleDouble.DoublePlusDouble( double( a ), -double( b ) );
                end
            end
            v = DoubleDouble.Make( x1, x2 );
        end
        
        function v = Times( a, b )
            if isa( a, 'DoubleDouble' )
                if isa( b, 'DoubleDouble' )
                    [ x1, x2 ] = DoubleDouble.DDTimesDD( a.v1, a.v2, b.v1, b.v2 );
                else
                    [ x1, x2 ] = DoubleDouble.DDTimesDouble( a.v1, a.v2, double( b ) );
                end
            else
                if isa( b, 'DoubleDouble' )
                    [ x1, x2 ] = DoubleDouble.DDTimesDouble( b.v1, b.v2, double( a ) );
                else
                    [ x1, x2 ] = DoubleDouble.DoubleTimesDouble( double( a ), double( b ) );
                end
            end
            v = DoubleDouble.Make( x1, x2 );
        end
        
        function v = MTimes( a, b )
            R = size( a, 1 );
            C = size( b, 2 );
            v = DoubleDouble.Make( zeros( R, C ), zeros( R, C ) );
            if isa( b, 'DoubleDouble' )
                for c = 1 : C
                    t = DoubleDouble.Sum( a .* DoubleDouble.Make( b.v1( :, c ).', b.v2( :, c ).' ), 2 );
                    v.v1( :, c ) = t.v1;
                    v.v2( :, c ) = t.v2;
                end
            else
                for c = 1 : C
                    t = DoubleDouble.Sum( a .* b( :, c ).', 2 );
                    v.v1( :, c ) = t.v1;
                    v.v2( :, c ) = t.v2;
                end
            end
        end
        
        function v = RDivide( a, b )
            if isa( a, 'DoubleDouble' )
                if isa( b, 'DoubleDouble' )
                    [ x1, x2 ] = DoubleDouble.DDDividedByDD( a.v1, a.v2, b.v1, b.v2 );
                else
                    [ x1, x2 ] = DoubleDouble.DDDividedByDouble( a.v1, a.v2, double( b ) );
                end
            else
                if isa( b, 'DoubleDouble' )
                    da = double( a );
                    [ x1, x2 ] = DoubleDouble.DDDividedByDD( da, zeros( size( da ) ), b.v1, b.v2 );
                else
                    [ x1, x2 ] = DoubleDouble.DoubleDividedByDouble( double( a ), double( b ) );
                end
            end
            v = DoubleDouble.Make( x1, x2 );
        end
        
        function v = LDivide( b, a )
            if isa( a, 'DoubleDouble' )
                if isa( b, 'DoubleDouble' )
                    [ x1, x2 ] = DoubleDouble.DDDividedByDD( a.v1, a.v2, b.v1, b.v2 );
                else
                    [ x1, x2 ] = DoubleDouble.DDDividedByDouble( a.v1, a.v2, double( b ) );
                end
            else
                if isa( b, 'DoubleDouble' )
                    da = double( a );
                    [ x1, x2 ] = DoubleDouble.DDDividedByDD( da, zeros( size( da ) ), b.v1, b.v2 );
                else
                    [ x1, x2 ] = DoubleDouble.DoubleDividedByDouble( double( a ), double( b ) );
                end
            end
            v = DoubleDouble.Make( x1, x2 );
        end
        
        function v = MLDivide( a, v )
            if ~isa( v, 'DoubleDouble' )
                v = DoubleDouble( v );
            end
            assert( size( a, 1 ) == size( v, 1 ) );
            if size( a, 1 ) > size( a, 2 )
                v = DoubleDouble.MLDivide( a.' * a, a.' * v );
                return
            elseif size( a, 1 ) < size( a, 2 )
                % This is the minimum norm solution rather than the standard mldivide one.
                v = a.' * DoubleDouble.MLDivide( a * a.', v );
                return
            end
            if DoubleDouble.IsEqualWithExpansion( triu( a, 1 ), 0 )
                % Lower triangular
                v = ForwardElimination( v, a );
                return
            elseif DoubleDouble.IsEqualWithExpansion( tril( a, -1 ), 0 )
                % Upper triangular
                v = BackSubstitution( v, a );
                return
            elseif DoubleDouble.IsEqualWithExpansion( a, a' )
                [ L, d ] = ldl( a, 'vector_d' );
                if all( all( isfinite( L ) ) ) && all( isfinite( d ) )
                    % Positive definite
                    v = ForwardElimination( v, L );
                    v = v ./ d;
                    v = BackSubstitution( v, L' );
                    return
                end
            end
            % Triangular factorization
            [ L, U, p ] = lu( a, 'vector' );
            
            % Permutation and forward elimination
            v.v1 = v.v1( p, : );
            v.v2 = v.v2( p, : );
            v = ForwardElimination( v, L );

            % Back substitution
            v = BackSubstitution( v, U );
        end
        
        function v = MRDivide( v, a )
            v = DoubleDouble.MLDivide( a', v' )';
        end
        
        function s = Sum( v, dim )
            if isa( v, 'DoubleDouble' )
                if nargin < 2 || isempty( dim )
                    dim = find( size( v.v1 ) > 1, 1 );
                    if isempty( dim )
                        dim = 1;
                    end
                end
                Size = size( v.v1 );
                Length = Size( dim );
                Blocks = num2cell( Size );
                Blocks{ dim } = ones( Length, 1 );
                x1 = mat2cell( v.v1, Blocks{:} );
                x2 = mat2cell( v.v2, Blocks{:} );
                s = DoubleDouble.Make( x1{ 1 }, x2{ 1 } );
                for i = 2 : Length
                    s = DoubleDouble.Plus( s, DoubleDouble.Make( x1{ i }, x2{ i } ) );
                end
            else
                if nargin < 2 || isempty( dim )
                    dim = find( size( v ) > 1, 1 );
                    if isempty( dim )
                        dim = 1;
                    end
                end
                Size = size( v );
                Length = Size( dim );
                Blocks = num2cell( Size );
                Blocks{ dim } = ones( Length, 1 );
                x = mat2cell( v, Blocks{:} );
                s = x{ 1 };
                for i = 2 : Length
                    s = DoubleDouble.Plus( s, x{ i } );
                end
            end
        end
        
        function c = CumSum( v, dim )
            if isa( v, 'DoubleDouble' )
                if nargin < 2 || isempty( dim )
                    dim = find( size( v.v1 ) > 1, 1 );
                    if isempty( dim )
                        dim = 1;
                    end
                end
                Size = size( v.v1 );
                Length = Size( dim );
                Blocks = num2cell( Size );
                Blocks{ dim } = ones( Length, 1 );
                x1 = mat2cell( v.v1, Blocks{:} );
                x2 = mat2cell( v.v2, Blocks{:} );
                s = DoubleDouble.Make( x1{ 1 }, x2{ 1 } );
                c1 = cell( size( x1 ) );
                c2 = cell( size( x2 ) );
                c1{1} = s.v1;
                c2{1} = s.v2;
                for i = 2 : Length
                    s = DoubleDouble.Plus( s, DoubleDouble.Make( x1{ i }, x2{ i } ) );
                    c1{i} = s.v1;
                    c2{i} = s.v2;
                end
            else
                if nargin < 2 || isempty( dim )
                    dim = find( size( v ) > 1, 1 );
                    if isempty( dim )
                        dim = 1;
                    end
                end
                Size = size( v );
                Length = Size( dim );
                Blocks = num2cell( Size );
                Blocks{ dim } = ones( Length, 1 );
                x = mat2cell( v, Blocks{:} );
                s = x{ 1 };
                c1 = cell( size( x ) );
                c2 = cell( size( x ) );
                c1{1} = s;
                c2{1} = zeros( size( s ) );
                for i = 2 : Length
                    s = DoubleDouble.Plus( s, x{ i } );
                    c1{i} = s.v1;
                    c2{i} = s.v2;
                end
            end
            c = DoubleDouble.Make( cell2mat( c1 ), cell2mat( c2 ) );
        end
        
        function s = Prod( v, dim )
            if isa( v, 'DoubleDouble' )
                if nargin < 2 || isempty( dim )
                    dim = find( size( v.v1 ) > 1, 1 );
                    if isempty( dim )
                        dim = 1;
                    end
                end
                Size = size( v.v1 );
                Length = Size( dim );
                Blocks = num2cell( Size );
                Blocks{ dim } = ones( Length, 1 );
                x1 = mat2cell( v.v1, Blocks{:} );
                x2 = mat2cell( v.v2, Blocks{:} );
                s = DoubleDouble.Make( x1{ 1 }, x2{ 1 } );
                for i = 2 : Length
                    s = DoubleDouble.Times( s, DoubleDouble.Make( x1{ i }, x2{ i } ) );
                end
            else
                if nargin < 2 || isempty( dim )
                    dim = find( size( v ) > 1, 1 );
                    if isempty( dim )
                        dim = 1;
                    end
                end
                Size = size( v );
                Length = Size( dim );
                Blocks = num2cell( Size );
                Blocks{ dim } = ones( Length, 1 );
                x = mat2cell( v, Blocks{:} );
                s = x{ 1 };
                for i = 2 : Length
                    s = DoubleDouble.Times( s, x{ i } );
                end
            end
        end
        
        function c = CumProd( v, dim )
            if isa( v, 'DoubleDouble' )
                if nargin < 2 || isempty( dim )
                    dim = find( size( v.v1 ) > 1, 1 );
                    if isempty( dim )
                        dim = 1;
                    end
                end
                Size = size( v.v1 );
                Length = Size( dim );
                Blocks = num2cell( Size );
                Blocks{ dim } = ones( Length, 1 );
                x1 = mat2cell( v.v1, Blocks{:} );
                x2 = mat2cell( v.v2, Blocks{:} );
                s = DoubleDouble.Make( x1{ 1 }, x2{ 1 } );
                c1 = cell( size( x1 ) );
                c2 = cell( size( x2 ) );
                c1{1} = s.v1;
                c2{1} = s.v2;
                for i = 2 : Length
                    s = DoubleDouble.Times( s, DoubleDouble.Make( x1{ i }, x2{ i } ) );
                    c1{i} = s.v1;
                    c2{i} = s.v2;
                end
            else
                if nargin < 2 || isempty( dim )
                    dim = find( size( v ) > 1, 1 );
                    if isempty( dim )
                        dim = 1;
                    end
                end
                Size = size( v );
                Length = Size( dim );
                Blocks = num2cell( Size );
                Blocks{ dim } = ones( Length, 1 );
                x = mat2cell( v, Blocks{:} );
                s = x{ 1 };
                c1 = cell( size( x ) );
                c2 = cell( size( x ) );
                c1{1} = s;
                c2{1} = zeros( size( s ) );
                for i = 2 : Length
                    s = DoubleDouble.Times( s, x{ i } );
                    c1{i} = s.v1;
                    c2{i} = s.v2;
                end
            end
            c = DoubleDouble.Make( cell2mat( c1 ), cell2mat( c2 ) );
        end
        
        function [ s, i ] = Max( a, b, dim )
            if isempty( b )
                if isempty( a )
                    s = DoubleDouble;
                    i = [];
                    return
                end
                if isa( a, 'DoubleDouble' )
                    if nargin < 3 || isempty( dim )
                        dim = find( size( a.v1 ) > 1, 1 );
                        if isempty( dim )
                            dim = 1;
                        end
                    end
                    Size = size( a.v1 );
                    Length = Size( dim );
                    Blocks = num2cell( Size );
                    Blocks{ dim } = ones( Length, 1 );
                    x1 = mat2cell( a.v1, Blocks{:} );
                    x2 = mat2cell( a.v2, Blocks{:} );
                    s = DoubleDouble.Make( x1{ 1 }, x2{ 1 } );
                    Size( dim ) = 1;
                    i = ones( Size );
                    for j = 2 : Length
                        [ s, ii ] = DoubleDouble.Max( DoubleDouble.Make( x1{ j }, x2{ j } ), s );
                        i( ii ) = j;
                    end
                else
                    if nargin < 3 || isempty( dim )
                        dim = find( size( a ) > 1, 1 );
                        if isempty( dim )
                            dim = 1;
                        end
                    end
                    Size = size( a );
                    Length = Size( dim );
                    Blocks = num2cell( Size );
                    Blocks{ dim } = ones( Length, 1 );
                    x = mat2cell( a, Blocks{:} );
                    s = x{ 1 };
                    for j = 2 : Length
                        s = DoubleDouble.Max( s, x{ j } );
                    end
                end
            else
                if ~isa( a, 'DoubleDouble' )
                    a = DoubleDouble( a );
                end
                if ~isa( b, 'DoubleDouble' )
                    b = DoubleDouble( b );
                end
                [ a, b ] = DoubleDouble.ExpandSingleton( a, b );
                i = ( a.v1 > b.v1 ) | ( ( a.v1 == b.v1 ) & ( a.v2 > b.v2 ) );
                s = b;
                s.v1( i ) = a.v1( i );
                s.v2( i ) = a.v2( i );
            end
        end
        
        function c = CumMax( v, dim )
            if isa( v, 'DoubleDouble' )
                if nargin < 3 || isempty( dim )
                    dim = find( size( v.v1 ) > 1, 1 );
                    if isempty( dim )
                        dim = 1;
                    end
                end
                Size = size( v.v1 );
                Length = Size( dim );
                Blocks = num2cell( Size );
                Blocks{ dim } = ones( Length, 1 );
                x1 = mat2cell( v.v1, Blocks{:} );
                x2 = mat2cell( v.v2, Blocks{:} );
                s = DoubleDouble.Make( x1{ 1 }, x2{ 1 } );
                c1 = cell( size( x1 ) );
                c2 = cell( size( x2 ) );
                c1{1} = s.v1;
                c2{1} = s.v2;
                for i = 2 : Length
                    s = DoubleDouble.Max( s, DoubleDouble.Make( x1{ i }, x2{ i } ) );
                    c1{i} = s.v1;
                    c2{i} = s.v2;
                end
            else
                if nargin < 3 || isempty( dim )
                    dim = find( size( v ) > 1, 1 );
                    if isempty( dim )
                        dim = 1;
                    end
                end
                Size = size( v );
                Length = Size( dim );
                Blocks = num2cell( Size );
                Blocks{ dim } = ones( Length, 1 );
                x = mat2cell( v, Blocks{:} );
                s = x{ 1 };
                c1 = cell( size( x ) );
                c2 = cell( size( x ) );
                c1{1} = s;
                c2{1} = zeros( size( s ) );
                for i = 2 : Length
                    s = DoubleDouble.Max( s, x{ i } );
                    c1{i} = s.v1;
                    c2{i} = s.v2;
                end
            end
            c = DoubleDouble.Make( cell2mat( c1 ), cell2mat( c2 ) );
        end
        
        function [ s, i ] = Min( a, b, dim )
            if isempty( b )
                if isa( a, 'DoubleDouble' )
                    if nargin < 3 || isempty( dim )
                        dim = find( size( a.v1 ) > 1, 1 );
                        if isempty( dim )
                            dim = 1;
                        end
                    end
                    Size = size( a.v1 );
                    Length = Size( dim );
                    Blocks = num2cell( Size );
                    Blocks{ dim } = ones( Length, 1 );
                    x1 = mat2cell( a.v1, Blocks{:} );
                    x2 = mat2cell( a.v2, Blocks{:} );
                    s = DoubleDouble.Make( x1{ 1 }, x2{ 1 } );
                    Size( dim ) = 1;
                    i = ones( Size );
                    for j = 2 : Length
                        [ s, ii ] = DoubleDouble.Min( DoubleDouble.Make( x1{ j }, x2{ j } ), s );
                        i( ii ) = j;
                    end
                else
                    if nargin < 3 || isempty( dim )
                        dim = find( size( a ) > 1, 1 );
                        if isempty( dim )
                            dim = 1;
                        end
                    end
                    Size = size( a );
                    Length = Size( dim );
                    Blocks = num2cell( Size );
                    Blocks{ dim } = ones( Length, 1 );
                    x = mat2cell( a, Blocks{:} );
                    s = x{ 1 };
                    for j = 2 : Length
                        s = DoubleDouble.Min( s, x{ j } );
                    end
                end
            else
                if ~isa( a, 'DoubleDouble' )
                    a = DoubleDouble( a );
                end
                if ~isa( b, 'DoubleDouble' )
                    b = DoubleDouble( b );
                end
                [ a, b ] = DoubleDouble.ExpandSingleton( a, b );
                i = ( a.v1 < b.v1 ) | ( ( a.v1 == b.v1 ) & ( a.v2 < b.v2 ) );
                s = b;
                s.v1( i ) = a.v1( i );
                s.v2( i ) = a.v2( i );
            end
        end
        
        function c = CumMin( v, dim )
            if isa( v, 'DoubleDouble' )
                if nargin < 3 || isempty( dim )
                    dim = find( size( v.v1 ) > 1, 1 );
                    if isempty( dim )
                        dim = 1;
                    end
                end
                Size = size( v.v1 );
                Length = Size( dim );
                Blocks = num2cell( Size );
                Blocks{ dim } = ones( Length, 1 );
                x1 = mat2cell( v.v1, Blocks{:} );
                x2 = mat2cell( v.v2, Blocks{:} );
                s = DoubleDouble.Make( x1{ 1 }, x2{ 1 } );
                c1 = cell( size( x1 ) );
                c2 = cell( size( x2 ) );
                c1{1} = s.v1;
                c2{1} = s.v2;
                for i = 2 : Length
                    s = DoubleDouble.Min( s, DoubleDouble.Make( x1{ i }, x2{ i } ) );
                    c1{i} = s.v1;
                    c2{i} = s.v2;
                end
            else
                if nargin < 3 || isempty( dim )
                    dim = find( size( v ) > 1, 1 );
                    if isempty( dim )
                        dim = 1;
                    end
                end
                Size = size( v );
                Length = Size( dim );
                Blocks = num2cell( Size );
                Blocks{ dim } = ones( Length, 1 );
                x = mat2cell( v, Blocks{:} );
                s = x{ 1 };
                c1 = cell( size( x ) );
                c2 = cell( size( x ) );
                c1{1} = s;
                c2{1} = zeros( size( s ) );
                for i = 2 : Length
                    s = DoubleDouble.Min( s, x{ i } );
                    c1{i} = s.v1;
                    c2{i} = s.v2;
                end
            end
            c = DoubleDouble.Make( cell2mat( c1 ), cell2mat( c2 ) );
        end
                
        function v = Dot( a, b, dim )
            if nargin < 3
                dim = [];
            end
            if ( length( a ) == numel( a ) ) && ( length( b ) == numel( b ) )
                a = a(:);
                b = b(:);
            end
            v = DoubleDouble.Sum( a .* b, dim );
        end
        
        function [ a, b ] = ExpandSingleton( a, b )
            sa = size( a );
            sb = size( b );
            if length( sa ) > length( sb )
                sb( ( end + 1 ):length( sa ) ) = 1;
            elseif length( sb ) > length( sa )
                sa( ( end + 1 ):length( sb ) ) = 1;
            end
            s = max( sa, sb );
            a = repmat( a, s ./ sa );
            b = repmat( b, s ./ sb );
        end
    end
    
    methods ( Access = private )
        function v = TimesPowerOf2( v, b )
            assert( isa( b, 'double' ) );
            v.v1 = v.v1 .* b;
            v.v2 = v.v2 .* b;
        end

        function v = ForwardElimination( v, L )
            % For lower triangular L, x = ForwardElimination( b, L ) solves L*x = b.
            [ m, n ] = size( L );
            mn = min( m, n );
            [ vm, vn ] = size( v );
            if vm < n
                v = [ v; zeros( n - vm, vn ) ];
            end
            if isa( L, 'DoubleDouble' )
                [ v.v1( 1, : ), v.v2( 1, : ) ] = DoubleDouble.DDDividedByDD( v.v1( 1, : ), v.v2( 1, : ), L.v1( 1, 1 ), L.v2( 1, 1 ), true );
                for k = 2 : mn
                   j = 1 : k - 1;
                   [ t1, t2 ] = DoubleDouble.DDTimesDD( v.v1( j, : ), v.v2( j, : ), L.v1( k, j ).', L.v2( k, j ).' );
                   t = DoubleDouble.Sum( DoubleDouble.Make( t1, t2 ), 1 );
                   [ t1, t2 ] = DoubleDouble.DDPlusDD( v.v1( k, : ), v.v2( k, : ), -t.v1, -t.v2 );
                   [ v.v1( k, : ), v.v2( k, : ) ] = DoubleDouble.DDDividedByDD( t1, t2, L.v1( k, k ), L.v2( k, k ), true );
                end
            else
                [ v.v1( 1, : ), v.v2( 1, : ) ] = DoubleDouble.DDDividedByDouble( v.v1( 1, : ), v.v2( 1, : ), L( 1, 1 ), true );
                for k = 2 : mn
                   j = 1 : k - 1;
                   [ t1, t2 ] = DoubleDouble.DDTimesDouble( v.v1( j, : ), v.v2( j, : ), L( k, j ).' );
                   t = DoubleDouble.Sum( DoubleDouble.Make( t1, t2 ), 1 );
                   [ t1, t2 ] = DoubleDouble.DDPlusDD( v.v1( k, : ), v.v2( k, : ), -t.v1, -t.v2 );
                   [ v.v1( k, : ), v.v2( k, : ) ] = DoubleDouble.DDDividedByDouble( t1, t2, L( k, k ), true );
                end
            end
        end

        function v = BackSubstitution( v, U )
            % For upper triangular U, x = BackSubstitution( b, U ) solves U*x = b.
            [ m, n ] = size( U );
            mn = min( m, n );
            [ vm, vn ] = size( v );
            if vm < n
                v = [ v; zeros( n - vm, vn ) ];
            end
            if isa( U, 'DoubleDouble' )
                [ v.v1( mn, : ), v.v2( mn, : ) ] = DoubleDouble.DDDividedByDD( v.v1( mn, : ), v.v2( mn, : ), U.v1( mn, mn ), U.v2( mn, mn ), true );
                for k = mn - 1 : -1 : 1
                   j = k + 1 : n;
                   [ t1, t2 ] = DoubleDouble.DDTimesDD( v.v1( j, : ), v.v2( j, : ), U.v1( k, j ).', U.v2( k, j ).' );
                   t = DoubleDouble.Sum( DoubleDouble.Make( t1, t2 ), 1 );
                   [ t1, t2 ] = DoubleDouble.DDPlusDD( v.v1( k, : ), v.v2( k, : ), -t.v1, -t.v2 );
                   [ v.v1( k, : ), v.v2( k, : ) ] = DoubleDouble.DDDividedByDD( t1, t2, U.v1( k, k ), U.v2( k, k ), true );
                end
            else
                [ v.v1( mn, : ), v.v2( mn, : ) ] = DoubleDouble.DDDividedByDouble( v.v1( mn, : ), v.v2( mn, : ), U( mn, mn ), true );
                for k = mn - 1 : -1 : 1
                   j = k + 1 : n;
                   [ t1, t2 ] = DoubleDouble.DDTimesDouble( v.v1( j, : ), v.v2( j, : ), U( k, j ).' );
                   t = DoubleDouble.Sum( DoubleDouble.Make( t1, t2 ), 1 );
                   [ t1, t2 ] = DoubleDouble.DDPlusDD( v.v1( k, : ), v.v2( k, : ), -t.v1, -t.v2 );
                   [ v.v1( k, : ), v.v2( k, : ) ] = DoubleDouble.DDDividedByDouble( t1, t2, U( k, k ), true );
                end
            end
        end        
    end
    
    methods ( Static, Access = private )
        function v = Make( a1, a2 )
            v = DoubleDouble;
            v.v1 = a1;
            v.v2 = a2;
        end
        
        function [ s1, s2 ] = Normalize( a1, a2 )
            s1 = a1 + a2;
            t = s1 - a1;
            s2 = a2 - t;
        end
        
        function [ s1, s2 ] = DDPlusDD( a1, a2, b1, b2 )
            [ s1, s2 ] = DoubleDouble.DoublePlusDouble( a1, b1 );
            [ t1, t2 ] = DoubleDouble.DoublePlusDouble( a2, b2 );
            s2 = s2 + t1;
            [ s1, s2 ] = DoubleDouble.Normalize( s1, s2 );
            s2 = s2 + t2;
            [ s1, s2 ] = DoubleDouble.Normalize( s1, s2 );
        end

        function [ s1, s2 ] = DDPlusDouble( a1, a2, b )
            [ s1, s2 ] = DoubleDouble.DoublePlusDouble( a1, b );
            s2 = s2 + a2;
            [ s1, s2 ] = DoubleDouble.Normalize( s1, s2 );
        end

        function [ s1, s2 ] = DoublePlusDouble( a, b )
            s1 = a + b;
            bb = s1 - a;
            t11 = s1 - bb;
            t2 = b - bb;
            t1 = a - t11;
            s2 = t1 + t2;
        end

        function [ p1, p2 ] = DDTimesDD( a1, a2, b1, b2 )
            [ p1, p2 ] = DoubleDouble.DoubleTimesDouble( a1, b1 );
            t = a1 .* b2 + a2 .* b1;
            p2 = p2 + t;
            [ p1, p2 ] = DoubleDouble.Normalize( p1, p2 );
        end

        function [ p1, p2 ] = DDTimesDouble( a1, a2, b )
            [ p1, p2 ] = DoubleDouble.DoubleTimesDouble( a1, b );
            p2 = p2 + a2 .* b;
            [ p1, p2 ] = DoubleDouble.Normalize( p1, p2 );
        end

        function [ p1, p2 ] = DoubleTimesDouble( a, b )
            p1 = a .* b;
            [ a1, a2 ] = DoubleDouble.Split( a );
            [ b1, b2 ] = DoubleDouble.Split( b );
            t1 = a1 .* b1 - p1;
            t2 = t1 + a1 .* b2 + a2 .* b1;
            p2 = t2 + a2 .* b2;
        end
        
        function [ r1, r2 ] = DDDividedByDD( a1, a2, b1, b2, AnySolutionWillDo )
            if nargin < 5
                AnySolutionWillDo = false;
            end
            q1 = a1 ./ b1;
            [ p1, p2 ] = DoubleDouble.DDTimesDouble( b1, b2, q1 );
            [ r1, r2 ] = DoubleDouble.DDPlusDD( a1, a2, -p1, -p2 );
            q2 = r1 ./ b1;
            [ p1, p2 ] = DoubleDouble.DDTimesDouble( b1, b2, q2 );
            [ r1, ~  ] = DoubleDouble.DDPlusDD( r1, r2, -p1, -p2 );
            q3 = r1 ./ b1;
            [ q1, q2 ] = DoubleDouble.Normalize( q1, q2 );
            [ r1, r2 ] = DoubleDouble.DDPlusDD( q1, q2, q3, zeros( size( q3 ) ) );
            Select = ( b1 == 0 ) & ( b2 == 0 );
            a1Select = a1( Select );
            Tmp( a1Select > 0 ) = Inf;
            Tmp( a1Select < 0 ) = -Inf;
            if AnySolutionWillDo
                Tmp( a1Select == 0 ) = 0;
            else
                Tmp( a1Select == 0 ) = NaN;
            end
            r1( Select ) = Tmp;
            r2( Select ) = Tmp;
        end
        
        function [ r1, r2 ] = DDDividedByDouble( a1, a2, b, AnySolutionWillDo )
            if nargin < 4
                AnySolutionWillDo = false;
            end
            r1 = a1 ./ b;
            [ p1, p2 ] = DoubleDouble.DoubleTimesDouble( r1, b );
            [ s, e ] = DoubleDouble.DoublePlusDouble( a1, -p1 );
            e = e + a2;
            e = e - p2;
            t = s + e;
            r2 = t ./ b;
            [ r1, r2 ] = DoubleDouble.Normalize( r1, r2 );
            Select = b == 0;
            a1Select = a1( Select );
            Tmp( a1Select > 0 ) = Inf;
            Tmp( a1Select < 0 ) = -Inf;
            if AnySolutionWillDo
                Tmp( a1Select == 0 ) = 0;
            else
                Tmp( a1Select == 0 ) = NaN;
            end
            r1( Select ) = Tmp;
            r2( Select ) = Tmp;
        end
        
        function [ r1, r2 ] = DoubleDividedByDouble( a, b, AnySolutionWillDo )
            if nargin < 3
                AnySolutionWillDo = false;
            end
            r1 = a ./ b;
            [ p1, p2 ] = DoubleDouble.DoubleTimesDouble( r1, b );
            [ s, e ] = DoubleDouble.DoublePlusDouble( a, -p1 );
            e = e - p2;
            t = s + e;
            r2 = t ./ b;
            [ r1, r2 ] = DoubleDouble.Normalize( r1, r2 );
            Select = b == 0;
            aSelect = a( Select );
            Tmp( aSelect > 0 ) = Inf;
            Tmp( aSelect < 0 ) = -Inf;
            if AnySolutionWillDo
                Tmp( aSelect == 0 ) = 0;
            else
                Tmp( aSelect == 0 ) = NaN;
            end
            r1( Select ) = Tmp;
            r2( Select ) = Tmp;
        end
        
        function [ a1, a2 ] = Split( a )
            if isreal( a )
                Select = ( a > 6.69692879491417e+299 ) | ( a < -6.69692879491417e+299 ); % 2^996
                a( Select ) = a( Select ) * 3.7252902984619140625e-09; % 2^(-28)
                t1 = 134217729.0 * a; % 2^27 + 1
                t2 = t1 - a;
                a1 = t1 - t2;
                a2 = a - a1;
                a1( Select ) = a1( Select ) * 268435456.0; % 2^28
                a2( Select ) = a2( Select ) * 268435456.0; % 2^28
            else
                [ r1, r2 ] = DoubleDouble.Split( real( a ) );
                [ i1, i2 ] = DoubleDouble.Split( imag( a ) );
                a1 = complex( r1, i1 );
                a2 = complex( r2, i2 );
            end
        end
   end
end
