% Prueba la adicion de secciones avanzadas
ashapes = SectionDesigner('Figuras avanzadas');
steel = ElastoplasticSteel('Acero A36', 294.31, 200894.198, 1120.531847, 0.246197);

ashapes.addDiscreteChannel(100, -100, 25, 20, 5, 5, 10, 10, steel, 'rotation', 45);
ashapes.addDiscreteHSection(100, 100, 300, 200, 20, 6, 20, 50, steel, 'rotation', 30);
ashapes.addDiscreteISection(-100, 100, 300, 200, 100, 20, 20, 6, 20, 50, steel, 'rotation', 30);
ashapes.addDiscreteLChannel(-75, 0, 80, 40, 5, 10, 10, steel);
ashapes.addDiscreteRect(175, 150, 100, 25, 20, 10, steel, 'rotation', 0, 'translatex', -30);
ashapes.addDiscreteSquare(0, 0, 40, 10, steel, 'rotation', 10);
ashapes.addDiscreteSquareChannel(-100, -100, 50, 5, 10, steel, 'rotation', 30);
ashapes.addDiscreteTSection(-150, 200, 50, 50, 10, 10, 5, 5, steel, 'rotation', 90);
ashapes.addDiscreteTubular(250, -50, 25, 50, 30, steel);

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