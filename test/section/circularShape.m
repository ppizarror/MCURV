% Crea seccion circular
circle = SectionDesigner('Circulo');
steel = ElastoplasticSteel('Acero A36', 294.31, 200894.198, 1120.531847, 0.246197);

circle.addDiscreteCircle(0, 0, 50, 10, steel);
circle.addDiscreteTubular(0, 0, 100, 100, 20, steel);
circle.addDiscreteTubular(0, 0, 150, 200, 40, steel);

circle.disp();
circle.plot('showdisc', true);

% Crea el analisis
p = linspace(0, 0, 500);
phi = linspace(0, 1e-4, 500);

% Ejecuta el analisis
analysis = SectionAnalysis('Analisis', 1000, 0.01, 'showprogress', true);
e0 = analysis.calc_e0M_angle(circle, p, phi, 45); % Analisis a 45 grados
analysis.plot_e0M('plot', 'mphi', 'm', 'T');
analysis.plot_e0M('plot', 'ephi', 'm', 'T'); % Debe ser siempre 0
analysis.plotStress(2, 'factorM', 1e-6, 'factorP', 1e-3);