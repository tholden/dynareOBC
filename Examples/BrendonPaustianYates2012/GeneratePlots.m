dynareOBC BPYModel.mod

disp( 'This is one solution to the IRF to a demand shock in the Brendon Paustian Yates (2012) model.' );
disp( 'We will now generate another.' );
disp( 'Press a key to continue:' );
pause;

dynareOBC BPYModel.mod FullHorizon Omega=0.0001

disp( 'Note that while the shock was expansionary in the first solution, it is contractionary in the second.' );
