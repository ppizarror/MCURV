% Prueba la adicion de secciones avanzadas
ashapes = SectionDesigner('Figuras avanzadas');
steel = ElastoplasticSteel('Acero A36', 294.31, 200894.198, 1120.531847, 0.246197);

ashapes.addDiscreteISection(-100, 100, 300, 200, 100, 20, 20, 6, 20, 50, steel, 'rotation', 30);
ashapes.addDiscreteHSection(100, 100, 300, 200, 20, 6, 20, 50, steel, 'rotation', 30);
ashapes.addDiscreteChannel(100, -100, 25, 20, 5, 5, 10, 10, steel, 'rotation', 45);
ashapes.addDiscreteSquareChannel(-100, -100, 50, 5, 10, steel, 'rotation', 30);
ashapes.addDiscreteSquare(0, 0, 40, 10, steel, 'rotation', 10);

% Grafica
ashapes.disp();
ashapes.plot('showdisc', true);

% Ejecuta un analisis
analysis = SectionAnalysis('Analisis', 100, 0.1);
p = linspace(0, 0, 100)';
phix = linspace(0, 1.2e-4, 100)';
phiy = linspace(0, 0, 100)';
e0 = analysis.calc_e0M(ashapes, p, phix, phiy);

% Grafica resultados
analysis.plot_e0M('plot', 'mphix', 'm', 'x'); % N*mm -> kN*m
analysis.plot_e0M('plot', 'pphix');
ashapes.plotStress(e0, phix, phiy, 'i', 2, 'factorM', 1e-6, 'factorP', 1e-3);