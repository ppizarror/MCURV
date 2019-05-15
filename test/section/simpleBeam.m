% Viga simple
simplebeam = SectionDesigner('Viga plana');

% Genera los materiales
steel = ElastoplasticSteel('Acero', 420, 200000, 2000, 0.2);
concrete = HognestadConcrete('Hormigon', 25, 0.0025);

% Agrega los elementos a la seccion
simplebeam.addDiscreteRect(0, 0, 350, 700, 10, 10, concrete);
simplebeam.addFiniteArea(-130, -350+55, 1100, steel);
simplebeam.addFiniteArea(-130, 350-55, 1100, steel);
simplebeam.addFiniteArea(130, -350+55, 1100, steel);
simplebeam.addFiniteArea(130, 350-55, 1100, steel);

% Grafica la seccion
simplebeam.plot('showdisc', false);
[x, y] = simplebeam.getCentroid();
fprintf('Centroide ubicado en %.2f,%.2f\n', x, y);