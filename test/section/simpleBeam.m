% Viga simple
simplebeam = SectionDesigner('Viga simple');

% Genera los materiales
steel = ElastoplasticSteel('Acero', 420, 200000, 2000, 0.2);
steel.setColor([0, 0, 0.5]);
concrete = HognestadConcrete('Hormigon', 25, 0.0025);

% Agrega los elementos a la seccion
simplebeam.addDiscreteRect(0, 0, 350, 700, 25, 25, concrete, 'rotation', 0);
simplebeam.addFiniteArea(-130, -350+55, 1050, steel);
simplebeam.addFiniteArea(-130, 350-55, 1050, steel);
simplebeam.addFiniteArea(130, -350+55, 1050, steel);
simplebeam.addFiniteArea(130, 350-55, 1050, steel);

simplebeam.disp();

% Grafica la seccion
simplebeam.plot('showdisc', true);

% Ejecuta un analisis
analysis = SectionAnalysis('Analisis', 100, 0.1);
p = linspace(0, 0, 100)';
phix = linspace(0, 1.2e-4, 100)';
phiy = linspace(0, 0, 100)';
e0 = analysis.calc_e0M(simplebeam, p, phix, phiy);

% Grafica resultados
analysis.plot_e0M('plot', 'mphix', 'factor', 1.019716e-7, 'm', 'x', ...
    'sapfile', 'test/section/mcurv-sap2000/simpleBeam.txt', 'sapfactor', 1);
simplebeam.plotStress(e0, phix, phiy, 'i', 1);