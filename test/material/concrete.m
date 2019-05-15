% Testea material concretos

% Modelo hognestad
hognestad = HognestadConcrete('Hognestad', 30, 0.0025);
hognestad.disp();
hognestad.plot('emin', -2e-3, 'emax', 6e-3, 'plotType', 'tension');

% Modelo hognestad modificado
hognestadmod = HognestadModifiedConcrete('HognestadMod', 30, 0.002, 0.004);
hognestadmod.disp();
hognestadmod.plot('emin', -2e-3, 'emax', 6e-3, 'plotType', 'elastic');