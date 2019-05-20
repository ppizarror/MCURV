% Viga H
hbeam = SectionDesigner('Viga H Cintac');

% Genera los materiales
steel = ElastoplasticSteel('Acero A36', 294.31, 200894.198, 1120.531847, 0.246197);
steel.setColor([0, 0, 0.5]);
steelw = ElastoplasticSteel('Acero A36', 294.31, 200894.198, 1120.531847, 0.246197);
steelw.setColor([0.5, 0, 0]);
% steel.plot();

% Agrega los elementos a la seccion
d = 300;
bf = 150;
tw = 6;
tf = 20;
hbeam.addDiscreteRect(0, (d - tf)/2, bf, tf, 1, 10, steel);
hbeam.addDiscreteRect(0, (-d + tf)/2, bf, tf, 1, 10, steel);
hbeam.addDiscreteRect(0, 0, tw, d-2*tf, 1, 100, steelw);
hbeam.disp();

% Grafica
hbeam.plot('showdisc', true);

% Ejecuta un analisis
analysis = SectionAnalysis('Analisis', 100, 0.01);
p = linspace(0, 0, 500)'; % N
phix = linspace(0, 1.6e-3, 500)';
phiy = linspace(0, 0, 500)';
analysis.calc_e0M(hbeam, p, phix, phiy);

% N*mm -> kN*m
analysis.plot_e0M('plot', 'mphix', 'factorM', 1e-6, 'm', 'x', ...
    'sapfile', 'test/section/mcurv-sap2000/hBeam.txt', 'sapfactorPhi', 1e-3, ...
    'sapcolumnPhi', 10, 'sapcolumnM', 11);
% analysis.plot_lastIter();