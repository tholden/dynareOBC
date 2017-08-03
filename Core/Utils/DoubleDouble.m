% The below code is derived from the QD C++ library.

% QD is Copyright (c) 2003-2009, The Regents of the University of California, through Lawrence Berkeley National Laboratory (subject to receipt of any required approvals from U.S. Dept. of Energy) All rights reserved.

% QD is distributed under the following license:

% 1. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
% (1) Redistributions of source code must retain the copyright notice, this list of conditions and the following disclaimer.
% (2) Redistributions in binary form must reproduce the copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
% (3) Neither the name of the University of California, Lawrence Berkeley National Laboratory, U.S. Dept. of Energy nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
% 2. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 3. You are under no obligation whatsoever to provide any bug fixes, patches, or upgrades to the features, functionality or performance of the source code ("Enhancements") to anyone; however, if you choose to make your Enhancements available either publicly, or directly to Lawrence Berkeley National Laboratory, without imposing a separate written license agreement for such Enhancements, then you hereby grant the following license: a non-exclusive, royalty-free perpetual license to install, use, modify, prepare derivative works, incorporate into other computer software, distribute, and sublicense such enhancements or derivative works thereof, in binary and source code form.

classdef DoubleDouble
    properties ( SetAccess = private, GetAccess = private )
        v1
        v2
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
        
        function s = double( v )
            s = v.v1;
        end
        
        function s = size( v, varargin )
            s = size( v.v1, varargin{:} );
        end
        
        function s = numel( v )
            s = numel( v.v1 );
        end
        
        function n = numArgumentsFromSubscript( v, s, IndexingContext )
            n = numArgumentsFromSubscript( v.v1, s, IndexingContext );
        end
        
        function v = repmat( v, varargin )
            v = DoubleDouble.Make( repmat( v.v1, varargin{:} ), repmat( v.v2, varargin{:} ) );
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
                v = vertcat( horzcat( a, b ), varargin{:} );
            else
                if ~isa( a, 'DoubleDouble' )
                    a = DoubleDouble( a );
                end
                if ~isa( b, 'DoubleDouble' )
                    b = DoubleDouble( b );
                end
                x1 = vertcat( [ a.v1, b.v1 ] );
                x2 = vertcat( [ a.v2, b.v2 ] );
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
        
        function s = subsindex( v )
            s = v.v1;
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
        
        function v = max( a, b, dim )
            if nargin < 3
                dim = [];
                if nargin < 2
                    b = [];
                end
            end
            v = DoubleDouble.Max( a, b, dim );
        end
        
        function v = min( a, b, dim )
            if nargin < 3
                dim = [];
                if nargin < 2
                    b = [];
                end
            end
            v = DoubleDouble.Min( a, b, dim );
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
        
        function disp( v )
            disp( v.v1 );
            disp( '+' );
            disp( v.v2 );
        end
                
    end

    methods ( Static )
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
            v = DoubleDouble.Make( inf( varargin{:}, 'double' ), nan( varargin{:}, 'double' ) );
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
        
        function s = Max( a, b, dim )
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
                    for i = 2 : Length
                        s = DoubleDouble.Max( s, DoubleDouble.Make( x1{ i }, x2{ i } ) );
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
                    for i = 2 : Length
                        s = DoubleDouble.Max( s, x{ i } );
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
                Select = ( a.v1 > b.v1 ) | ( ( a.v1 == b.v1 ) & ( a.v2 > b.v2 ) );
                s = b;
                s.v1( Select ) = a.v1( Select );
                s.v2( Select ) = a.v2( Select );
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
        
        function s = Min( a, b, dim )
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
                    for i = 2 : Length
                        s = DoubleDouble.Min( s, DoubleDouble.Make( x1{ i }, x2{ i } ) );
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
                    for i = 2 : Length
                        s = DoubleDouble.Min( s, x{ i } );
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
                Select = ( a.v1 < b.v1 ) | ( ( a.v1 == b.v1 ) & ( a.v2 < b.v2 ) );
                s = b;
                s.v1( Select ) = a.v1( Select );
                s.v2( Select ) = a.v2( Select );
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

        function [ r1, r2 ] = DDDividedByDD( a1, a2, b1, b2 )
            q1 = a1 ./ b1;
            [ p1, p2 ] = DoubleDouble.DDTimesDouble( b1, b2, q1 );
            [ r1, r2 ] = DoubleDouble.DDPlusDD( a1, a2, -p1, -p2 );
            q2 = r1 ./ b1;
            [ p1, p2 ] = DoubleDouble.DDTimesDouble( b1, b2, q2 );
            [ r1, ~  ] = DoubleDouble.DDPlusDD( r1, r2, -p1, -p2 );
            q3 = r1 ./ b1;
            [ q1, q2 ] = DoubleDouble.Normalize( q1, q2 );
            [ r1, r2 ] = DoubleDouble.DDPlusDD( q1, q2, q3, zeros( size( q3 ) ) );
        end
        
        function [ r1, r2 ] = DDDividedByDouble( a1, a2, b )
            r1 = a1 ./ b;
            [ p1, p2 ] = DoubleDouble.DoubleTimesDouble( r1, b );
            [ s, e ] = DoubleDouble.DoublePlusDouble( a1, -p1 );
            e = e + a2;
            e = e - p2;
            t = s + e;
            r2 = t ./ b;
            [ r1, r2 ] = DoubleDouble.Normalize( r1, r2 );
        end
        
        function [ r1, r2 ] = DoubleDividedByDouble( a, b )
            r1 = a ./ b;
            [ p1, p2 ] = DoubleDouble.DoubleTimesDouble( r1, b );
            [ s, e ] = DoubleDouble.DoublePlusDouble( a, -p1 );
            e = e - p2;
            t = s + e;
            r2 = t ./ b;
            [ r1, r2 ] = DoubleDouble.Normalize( r1, r2 );
        end
        
        function [ a1, a2 ] = Split( a )
            Select = ( a > 6.69692879491417e+299 ) | ( a < -6.69692879491417e+299 ); % 2^996
            a( Select ) = a( Select ) * 3.7252902984619140625e-09; % 2^(-28)
            t1 = 134217729.0 * a; % 2^27 + 1
            t2 = t1 - a;
            a1 = t1 - t2;
            a2 = a - a1;
            a1( Select ) = a1( Select ) * 268435456.0; % 2^28
            a2( Select ) = a2( Select ) * 268435456.0; % 2^28
        end

   end
end