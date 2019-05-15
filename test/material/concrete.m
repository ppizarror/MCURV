% Testea material concretos

hognestad = HognestadConcrete('Hognestad', 30, 0.0025);
hognestad.disp();
hognestad.plot('emin', -2e-3, 'emax', 6e-3, 'plotType', 'tension');