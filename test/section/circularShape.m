% Crea seccion circular
circle = SectionDesigner('Circulo');
steel = ElastoplasticSteel('AceroA36', 294.31, 200894.198, 1120.531847, 0.246197);

circle.addDiscreteCircle(0, 0, 50, 10, steel);
circle.addDiscreteTubular(0, 0, 100, 100, 20, steel);
circle.addDiscreteTubular(0, 0, 150, 200, 40, steel);

circle.disp();
circle.plot('showdisc', true);