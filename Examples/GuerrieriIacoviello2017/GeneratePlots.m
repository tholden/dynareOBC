load irfP;
load irfN;

% The below plotting code is derived from code kindly provided by Matteo Iacoviello here: https://www2.bc.edu/matteo-iacoviello/research.htm

figure;
subplot(2,2,1)
plot(100*irf1P,'b');  hold on
plot(100*irf1N,'r--');
ylim([-32 32])
grid on
title({'House Prices','% from steady state'})
hold on; plot(0*irf1P,'k','Linewidth',1)

subplot(2,2,2)
plot(100*irf2P,'b');  hold on
plot(100*irf2N,'r--');
ylim([-4.0 4.0])
title({'Consumption','% from steady state'})
hold on; plot(0*irf1P,'k','Linewidth',1)
grid on


subplot(2,2,3)
plot(100*irf3P,'b');  hold on
plot(100*irf3N,'r--');
ylim([-3 3])
title({'Total Hours','% from steady state'})
hold on; plot(0*irf1P,'k','Linewidth',1)
grid on


subplot(2,2,4)
plot(100*irf4P,'b');  hold on
plot(100*irf4N,'r--');
ylim([-0.1 0.1])
title({'Multiplier on Borrowing Constraint','level'})
hold on; plot(0*irf1P,'k','Linewidth',1)
legend('House Price Increase','House Price Decrease')
grid on
