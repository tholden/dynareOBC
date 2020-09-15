disp( 'This script illustrates the determinacy properties of the simple examples from the theory paper.' );

disp( 'We start with the first simple example, without lagged inflation.' );

dynareOBC Simple1.mod

disp( 'Note that M is neither a P matrix nor an S matrix.' );

disp( 'We now look at the second simple example, with lagged inflation.' );

dynareOBC Simple2.mod

disp( 'Again note that M is neither a P matrix nor an S matrix.' );

disp( 'We now revisit the first simple example under price level targeting.' );

dynareOBC Simple1PLT.mod PTest=16

disp( 'Note that M is now an M matrix and an S matrix.' );
