% Viga cuadrada, con borde metalico
boxbeam = SectionDesigner('Viga cuadrada compuesta');

% Genera los materiales
steel = ElastoplasticSteel('Acero A36', 294.31, 200894.198, 1120.531847, 0.246197);
steel.setColor([0, 0, 0.5]);

concrete = HognestadConcrete('Hognestad', 30, 0.0025);

% Valores posibles
model = 1;
d = [400, 500, 600]';
bf = [400, 500, 600]';
t = [25, 25, 25]';

% Agrega los elementos a la seccion
boxbeam.addDiscreteBoxChannel(0, 0, bf(model), d(model), t(model), 1, 10, steel);
boxbeam.addDiscreteRect(0, 0, bf(model)-2*t(model), d(model)-2*t(model), 1, 20, concrete);
boxbeam.disp();

% Grafica
boxbeam.plot('showdisc', true);

% Ejecuta un analisis
analysis = SectionAnalysis('Analisis', 100, 0.01);
p = linspace(0, 0, 500)'; % N
phix = linspace(0, 0.0014, 500)';
phiy = linspace(0, 0, 500)';
analysis.calc_e0M(boxbeam, p, phix, phiy);

% N*mm -> kN*m
analysis.plot_e0M('plot', 'mphix', 'm', 'x', ...
    'sapfile', sprintf('test/section/mcurv-sap2000/boxBeam%d.txt', model), ...
    'sapfactorPhi', 1e-3, 'sapcolumnPhi', 10, 'sapcolumnM', 11);