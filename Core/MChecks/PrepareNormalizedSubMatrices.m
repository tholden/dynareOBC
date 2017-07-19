function dynareOBC = PrepareNormalizedSubMatrices( dynareOBC, SlowMode )

    Ts = dynareOBC.TimeToEscapeBounds;
    ns = dynareOBC.NumberOfMax;
    sIndices = dynareOBC.sIndices;
    NormalizeTolerance = sqrt( eps );

    dynareOBC.ssIndices = cell( Ts, 1 );
    dynareOBC.NormalizedSubMMatrices = cell( Ts, 1 );
    dynareOBC.NormalizedSubMsMatrices = cell( Ts, 1 );
    dynareOBC.d1SubMMatrices = cell( Ts, 1 );
    dynareOBC.d1sSubMMatrices = cell( Ts, 1 );
    dynareOBC.d2SubMMatrices = cell( Ts, 1 );
    
    LargestPMatrix = 0;
    
    CPMatrix = true;
    
    for Tss = 1 : Ts
        CssIndices = vec( bsxfun( @plus, (1:Tss)', 0:Ts:((ns-1)*Ts) ) )';
        dynareOBC.ssIndices{ Tss } = CssIndices;

        Mc = dynareOBC.MMatrix( :, CssIndices );
        Msc = dynareOBC.MsMatrix( CssIndices, CssIndices );
        [ ~, ~, d2 ] = NormalizeMatrix( Msc, NormalizeTolerance, NormalizeTolerance );
        Mc = bsxfun( @times, Mc, d2 );
        d1 = 1 ./ CleanSmallVector( max( abs( Mc ), [], 2 ), NormalizeTolerance );
        Mc = bsxfun( @times, d1, Mc );
        Msc = Mc( sIndices( CssIndices ), : );
        
        dynareOBC.NormalizedSubMMatrices{ Tss } = Mc;
        dynareOBC.NormalizedSubMsMatrices{ Tss } = Msc;
        dynareOBC.d1SubMMatrices{ Tss } = d1;
        dynareOBC.d1sSubMMatrices{ Tss } = d1( sIndices( CssIndices ) );
        dynareOBC.d2SubMMatrices{ Tss } = d2';
        
        if ~CPMatrix
            continue;
        end
        
        CPMatrix = false;
        
        if any( diag( Msc ) <= 0 )
            continue;
        end
        
        TssTns = Tss * ns;
        
        if TssTns > 1 && any( abs( angle( eig( Msc ) ) ) >= pi - pi / TssTns )
            continue;
        end
        
        [ ~, pMsc ] = chol( Msc + Msc' );
        if pMsc == 0
            CPMatrix = true;
        else
            CompanionMsc = -abs( Msc );
            CompanionMsc = CompanionMsc - 2 * diag( diag( CompanionMsc ) );
            if min( min( inv( CompanionMsc ) ) ) >= 0 % H matrix check
                CPMatrix = true;
            else
                IminusMsc = eye( TssTns ) - Msc;
                absIminusMsc = abs( IminusMsc );
                if max( abs( eig( absIminusMsc ) ) ) < 1 % corollary 3.2 of https://www.cogentoa.com/article/10.1080/23311835.2016.1271268.pdf
                    CPMatrix = true;
                else
                    IplusMsc = eye( TssTns ) + Msc;
                    norm_absIminusMsc = norm( absIminusMsc );
                    [ ~, pIMscComb ] = chol( IplusMsc' * IplusMsc - ( norm_absIminusMsc * norm_absIminusMsc ) * eye( TssTns ) );
                    if pIMscComb == 0 % theorem 3.4 of https://www.cogentoa.com/article/10.1080/23311835.2016.1271268.pdf
                        CPMatrix = true;
                    else
                        if norm_absIminusMsc < min( svd( IplusMsc ) ) % theorem 3.2 of https://www.cogentoa.com/article/10.1080/23311835.2016.1271268.pdf
                            CPMatrix = true;
                        else
                            if rank( IplusMsc ) == TssTns
                                try
                                    IMscRatio = IplusMsc \ IminusMsc;
                                    if max( eig( abs( IMscRatio ) ) ) < 1 || norm( IplusMsc \ IminusMsc ) < 1 % theorem 3.1 of https://www.cogentoa.com/article/10.1080/23311835.2016.1271268.pdf
                                        CPMatrix = true;
                                    end
                                catch
                                end
                            end
                            if ~CPMatrix && rank( IminusMsc ) == TssTns % theorem 3.1 of https://www.cogentoa.com/article/10.1080/23311835.2016.1271268.pdf
                                try
                                    IMscAltRatio = IminusMsc \ IplusMsc;
                                    if min( svd( IMscAltRatio ) ) > 1
                                        CPMatrix = true;
                                    end
                                catch
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if CPMatrix
            LargestPMatrix = Tss;
        end
    end
    
    dynareOBC.LargestPMatrix = LargestPMatrix;
    
    if SlowMode
        fprintf( '\n' );
        disp( [ 'Largest P-matrix found with a simple criterion included elements up to horizon ' num2str( LargestPMatrix ) ' periods.' ] );
        disp( 'The search for solutions will start from this point.' );
        fprintf( '\n' );
    end
    
end
    