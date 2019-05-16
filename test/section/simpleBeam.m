% Viga simple
simplebeam = SectionDesigner('Viga plana');

% Genera los materiales
steel = ElastoplasticSteel('Acero', 420, 200000, 2000, 0.2);
steel.setColor([0, 0, 0.5]);
concrete = HognestadConcrete('Hormigon', 25, 0.0025);

% Agrega los elementos a la seccion
simplebeam.addDiscreteRect(0, 0, 350, 700, 1, 200, concrete);
simplebeam.addFiniteArea(-130, -350+55, 1100, steel);
simplebeam.addFiniteArea(-130, 350-55, 1100, steel);
simplebeam.addFiniteArea(130, -350+55, 1100, steel);
simplebeam.addFiniteArea(130, 350-55, 1100, steel);

simplebeam.disp();

% Grafica la seccion
% simplebeam.plot('showdisc', true);

% Ejecuta un analisis
analysis = SectionAnalysis('Analisis', 100, 0.5);
p = linspace(0, 0, 500)';
phix = linspace(0, 1.2e-4, 500)';
phiy = linspace(0, 0, 500)';
analysis.calc_e0M(simplebeam, p, phix, phiy);
analysis.plot_e0M('plot', 'mphix');