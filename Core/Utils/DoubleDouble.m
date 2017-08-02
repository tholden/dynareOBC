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
                v.v1 = double( in1 );
                v.v2 = double( in2 );
            elseif nargin == 1
                if isa( in1, 'DoubleDouble' )
                    v.v1 = in1.v1;
                    v.v2 = in1.v2;
                else
                    v.v1 = double( in1 );
                    v.v2 = zeros( size( v.v1 ) );
                end
            else
                v.v1 = 0;
                v.v2 = 0;
            end
        end
        
        function s = double( v )
            s = v.v1 + v.v2;
        end
        
        function v = plus( a, b )
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
            v = DoubleDouble( x1, x2 );
        end
        
        function v = minus( a, b )
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
            v = DoubleDouble( x1, x2 );
        end
        
        function v = uminus( v )
            v.v1 = -v.v1;
            v.v2 = -v.v2;
        end
        
        function v = uplus( v )
        end
        
        function v = times( a, b )
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
            v = DoubleDouble( x1, x2 );
        end
                
        function v = rdivide( a, b )
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
            v = DoubleDouble( x1, x2 );
        end
                
        function v = ldivide( b, a )
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
            v = DoubleDouble( x1, x2 );
        end
        
        function disp( v )
            disp( double( v ) );
        end
                
    end

    methods ( Static, Access = private )
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
            [ r1, r2 ] = DoubleDouble.DDPlusDD( q1, q2, q3, 0 );
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