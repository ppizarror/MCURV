% Prueba la adicion de secciones avanzadas
ashapes = SectionDesigner('Advanced Shapes');
steel = ElastoplasticSteel('AceroA36', 294.31, 200894.198, 1120.531847, 0.246197);

ashapes.addDiscreteISection(100, 100, 300, 200, 100, 20, 20, 6, 20, 50, steel, 'rotation', 0);
ashapes.addDiscreteHSection(300, 300, 300, 200, 20, 6, 20, 50, steel);
ashapes.addDiscreteChannel(-200,-200,100,20,5,5,10,10,steel);

% Graica
ashapes.plot('showdisc', true);